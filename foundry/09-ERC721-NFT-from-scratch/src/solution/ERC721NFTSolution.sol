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

/**
 * @title ERC721NFTSolution
 * @notice Complete ERC721 NFT implementation - non-fungible tokens
 * 
 * PURPOSE: Digital ownership of unique, indivisible tokens (vs ERC20's fungible tokens)
 * CS CONCEPTS: Hash tables (tokenId → owner), count tracking (balanceOf), delegation
 * 
 * CONNECTIONS:
 * - Project 01: Mapping storage (tokenId → owner, address → count)
 * - Project 08: Similar approval pattern but per-token (not amount-based)
 * - Project 03: Transfer events (required by standard)
 * 
 * KEY DIFFERENCE FROM ERC20: Tracks individual tokens (tokenId) vs amounts
 */
contract ERC721NFTSolution {
    // ════════════════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ════════════════════════════════════════════════════════════════════════

    string public name;
    string public symbol;
    uint256 private _tokenIdCounter;  // Auto-incrementing token ID counter

    /**
     * @notice Mapping from tokenId to owner address
     * @dev CONNECTION TO PROJECT 01: Mapping storage pattern!
     *      O(1) lookup: ~100 gas (warm) or ~2,100 gas (cold)
     */
    mapping(uint256 => address) public ownerOf;

    /**
     * @notice Mapping from address to number of NFTs owned
     * @dev CONNECTION TO PROJECT 01: Mapping storage pattern!
     *      Tracks count, not amount (unlike ERC20)
     */
    mapping(address => uint256) public balanceOf;

    /**
     * @notice Mapping from tokenId to approved address
     * @dev Single token approval (different from ERC20's allowance pattern)
     */
    mapping(uint256 => address) public getApproved;

    /**
     * @notice Mapping from owner => operator => approved
     * @dev Operator approval for ALL tokens (gas-efficient for marketplaces)
     *      CONNECTION TO PROJECT 01: Nested mapping storage pattern!
     */
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /**
     * @notice Mapping from tokenId to metadata URI
     * @dev CONNECTION TO PROJECT 01: String storage (expensive!)
     *      Usually points to IPFS for decentralized metadata storage
     */
    mapping(uint256 => string) public tokenURI;

    // ════════════════════════════════════════════════════════════════════════
    // EVENTS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Emitted when NFT is transferred
     * @dev CONNECTION TO PROJECT 03: Event emission!
     *      All three parameters are indexed (unlike ERC20 Transfer event)
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @notice Emitted when single token approval is set
     * @dev CONNECTION TO PROJECT 03: Event emission!
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @notice Emitted when operator approval is set
     * @dev CONNECTION TO PROJECT 03: Event emission!
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // ════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ════════════════════════════════════════════════════════════════════════

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    // ════════════════════════════════════════════════════════════════════════
    // MINT FUNCTION
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Mint a new NFT
     * @param to Address to mint NFT to
     * @param uri Metadata URI (usually IPFS)
     * @return tokenId The ID of the newly minted NFT
     *
     * @dev MINTING OPERATION: Creating New NFTs
     * ═══════════════════════════════════════════
     *
     *      This function creates a new NFT with a unique tokenId.
     *      TokenId is auto-incremented to ensure uniqueness.
     *
     *      EXECUTION FLOW:
     *      ┌─────────────────────────────────────────┐
     *      │ 1. VALIDATION: Check recipient            │
     *      │    - Must not be zero address             │
     *      │    ↓                                      │
     *      │ 2. GENERATE TOKENID: Increment counter   │
     *      │    - _tokenIdCounter++                   │
     *      │    ↓                                      │
     *      │ 3. UPDATE BALANCE: Increase owner count  │
     *      │    - balanceOf[to]++                     │
     *      │    ↓                                      │
     *      │ 4. SET OWNER: Map tokenId to owner       │
     *      │    - ownerOf[tokenId] = to               │
     *      │    ↓                                      │
     *      │ 5. STORE METADATA: Set token URI          │
     *      │    - tokenURI[tokenId] = uri             │
     *      │    ↓                                      │
     *      │ 6. EMIT EVENT: Transfer from address(0)  │
     *      │    - Indicates minting                   │
     *      └─────────────────────────────────────────┘
     *
     *      CONNECTION TO PROJECT 01: Multiple Storage Writes!
     *      ═══════════════════════════════════════════════════
     *
     *      We're writing to multiple storage locations:
     *      - balanceOf: Mapping storage (~5,000 gas warm)
     *      - ownerOf: Mapping storage (~5,000 gas warm)
     *      - tokenURI: String storage (~20,000+ gas)
     *
     *      GAS COST BREAKDOWN:
     *      ┌─────────────────────┬──────────────┬─────────────────┐
     *      │ Operation           │ Gas (warm)   │ Gas (cold)      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ require() check     │ ~3 gas       │ ~3 gas          │
     *      │ Increment counter   │ ~5,000 gas   │ ~20,000 gas     │
     *      │ SSTORE balanceOf    │ ~5,000 gas   │ ~20,000 gas     │
     *      │ SSTORE ownerOf      │ ~5,000 gas   │ ~20,000 gas     │
     *      │ SSTORE tokenURI     │ ~20,000 gas  │ ~20,000 gas     │
     *      │ Event emission      │ ~1,500 gas   │ ~1,500 gas      │
     *      ├─────────────────────┼──────────────┼─────────────────┤
     *      │ TOTAL (warm)        │ ~36,503 gas  │                 │
     *      │ TOTAL (cold)        │              │ ~85,503 gas     │
     *      └─────────────────────┴──────────────┴─────────────────┘
     *
     *      REAL-WORLD ANALOGY:
     *      ═══════════════════
     *
     *      Like printing a certificate of ownership:
     *      - **TokenId** = Certificate number (unique)
     *      - **Owner** = Who owns the certificate
     *      - **URI** = Link to actual artwork/metadata
     *      - **Minting** = Creating the certificate
     */
    function mint(address to, string memory uri) public returns (uint256) {
        require(to != address(0), "Invalid recipient");
        
        uint256 tokenId = _tokenIdCounter++;  // Auto-increment for uniqueness
        
        balanceOf[to]++;                      // Increase owner's NFT count
        ownerOf[tokenId] = to;                // Set token owner
        tokenURI[tokenId] = uri;              // Store metadata URI
        
        emit Transfer(address(0), to, tokenId);  // Minting event
        return tokenId;
    }

    // ════════════════════════════════════════════════════════════════════════
    // TRANSFER FUNCTION
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Transfer NFT from one address to another
     * @param from Address to transfer from
     * @param to Address to transfer to
     * @param tokenId ID of the NFT to transfer
     *
     * @dev TRANSFER OPERATION: Moving NFTs
     * ═══════════════════════════════════════
     *
     *      This function transfers a specific NFT (identified by tokenId)
     *      from one address to another. Unlike ERC20, we transfer by tokenId,
     *      not by amount!
     *
     *      CONNECTION TO PROJECT 08: ERC20 Comparison!
     *      ══════════════════════════════════════════
     *
     *      ERC20: transfer(to, amount) - transfers amount of tokens
     *      ERC721: transferFrom(from, to, tokenId) - transfers specific token
     *
     *      KEY DIFFERENCE: ERC721 transfers individual tokens, ERC20 transfers amounts!
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(from == ownerOf[tokenId], "Not owner");
        require(to != address(0), "Invalid recipient");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        
        balanceOf[from]--;                    // Decrease sender's count
        balanceOf[to]++;                     // Increase recipient's count
        ownerOf[tokenId] = to;               // Update token owner
        delete getApproved[tokenId];          // Clear single token approval
        
        emit Transfer(from, to, tokenId);
    }

    // ════════════════════════════════════════════════════════════════════════
    // SAFE TRANSFER FUNCTIONS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Safe transfer without data
     * @dev Convenience function that calls safeTransferFrom with empty data
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    /**
     * @notice Safe transfer with callback check
     * @param from Address to transfer from
     * @param to Address to transfer to
     * @param tokenId ID of the NFT to transfer
     * @param data Additional data to pass to callback
     *
     * @dev SAFE TRANSFER: Preventing Stuck NFTs
     * ═══════════════════════════════════════════
     *
     *      Safe transfer checks if recipient is a contract and can handle NFTs.
     *      This prevents NFTs from being stuck in contracts that can't handle them!
     *
     *      HOW IT WORKS:
     *      1. Call regular transferFrom
     *      2. Check if recipient has code (is contract)
     *      3. If contract, call onERC721Received callback
     *      4. Verify callback returns correct selector
     *      5. Revert if callback fails or returns wrong value
     *
     *      WHY THIS MATTERS:
     *      - Prevents NFTs stuck in contracts
     *      - Ensures recipient can handle NFTs
     *      - Standard practice for NFT transfers
     *
     *      REAL-WORLD ANALOGY:
     *      Like sending a package with signature required - ensures recipient
     *      can actually receive and handle the package!
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);  // Do the transfer first
        
        // Check if recipient is a contract
        if (to.code.length > 0) {
            // Call callback on recipient contract
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                // Verify callback returned correct selector
                require(retval == IERC721Receiver.onERC721Received.selector, "Invalid receiver");
            } catch {
                revert("Transfer to non-receiver");
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // APPROVAL FUNCTIONS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Approve specific token for transfer
     * @param to Address approved to transfer token
     * @param tokenId ID of token to approve
     *
     * @dev SINGLE TOKEN APPROVAL: Approve One NFT
     * ════════════════════════════════════════════
     *
     *      This approves a specific token for transfer by another address.
     *      Only the owner or an operator can approve.
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf[tokenId];
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "Not authorized");
        
        getApproved[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    
    /**
     * @notice Approve or revoke operator for all tokens
     * @param operator Address to approve/revoke
     * @param approved True to approve, false to revoke
     *
     * @dev OPERATOR APPROVAL: Approve All NFTs
     * ═══════════════════════════════════════════
     *
     *      This approves an operator to transfer ALL NFTs owned by the caller.
     *      More gas-efficient for marketplaces that need to transfer multiple NFTs.
     *
     *      USE CASES:
     *      - Marketplaces (OpenSea, Rarible)
     *      - NFT management contracts
     *      - Batch operations
     */
    function setApprovalForAll(address operator, bool approved) public {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // ════════════════════════════════════════════════════════════════════════
    // HELPER FUNCTIONS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Check if address is approved or owner
     * @param spender Address to check
     * @param tokenId Token ID to check
     * @return True if spender is owner, approved, or operator
     *
     * @dev AUTHORIZATION CHECK: Three Ways to Be Authorized
     * ═══════════════════════════════════════════════════════
     *
     *      An address can transfer an NFT if:
     *      1. It's the owner
     *      2. It's approved for the specific token
     *      3. It's an operator for all tokens
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf[tokenId];
        return (spender == owner || getApproved[tokenId] == spender || isApprovedForAll[owner][spender]);
    }
    
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. ERC721 IS FOR NON-FUNGIBLE TOKENS
 *    ✅ Each token is unique (identified by tokenId)
 *    ✅ Transfer by tokenId, not amount
 *    ✅ balanceOf returns count, not amount
 *    ✅ Real-world: Trading cards vs currency
 *
 * 2. SAFE TRANSFER PREVENTS STUCK NFTs
 *    ✅ Checks if recipient is contract
 *    ✅ Calls onERC721Received callback
 *    ✅ Verifies callback return value
 *    ✅ Prevents NFTs stuck in contracts
 *
 * 3. TWO TYPES OF APPROVALS
 *    ✅ Single token: approve(to, tokenId) - one NFT
 *    ✅ Operator: setApprovalForAll(operator, true) - all NFTs
 *    ✅ Operator more gas-efficient for marketplaces
 *
 * 4. METADATA STORED OFF-CHAIN
 *    ✅ tokenURI points to metadata (usually IPFS)
 *    ✅ Decentralized storage (IPFS)
 *    ✅ NFT is certificate, URI is link to artwork
 *
 * 5. MINTING CREATES UNIQUE TOKENS
 *    ✅ Auto-incrementing tokenId ensures uniqueness
 *    ✅ Transfer from address(0) indicates minting
 *    ✅ Each NFT has unique metadata URI
 *
 * 6. AUTHORIZATION HAS THREE LEVELS
 *    ✅ Owner: Can always transfer
 *    ✅ Approved: Can transfer specific token
 *    ✅ Operator: Can transfer all tokens
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Not using safeTransferFrom (NFTs stuck in contracts!)
 * ❌ Not clearing single token approval after transfer
 * ❌ Not checking authorization correctly
 * ❌ Confusing ERC721 (tokenId) with ERC20 (amount)
 * ❌ Not verifying callback return value
 * ❌ Storing metadata on-chain (expensive!)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study OpenZeppelin ERC721 implementation
 * • Add metadata extension (ERC721Metadata)
 * • Implement royalties (ERC2981)
 * • Learn about ERC721A (gas-optimized version)
 * • Move to Project 10 to learn about upgradeability
 */
