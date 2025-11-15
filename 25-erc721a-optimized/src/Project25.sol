// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 25: ERC-721A Optimized NFT Collection
 * @notice Implement an ERC-721A compliant NFT with gas-optimized batch minting
 * @dev This skeleton helps you learn Azuki's ERC-721A optimization techniques
 *
 * Learning Objectives:
 * 1. Understand batch minting optimization
 * 2. Implement ownership inference
 * 3. Use storage packing efficiently
 * 4. Master sequential token IDs
 * 5. Compare gas costs with standard ERC-721
 *
 * ERC-721A saves gas by:
 * - Only storing ownership for batch start tokens
 * - Inferring ownership by scanning backwards
 * - Packing data into single storage slots
 * - Sequential token ID minting
 */

contract OptimizedNFT {
    // =============================================================
    //                           STRUCTS
    // =============================================================

    /**
     * @dev Ownership data packed into a single storage slot (256 bits)
     *      addr: 160 bits - Owner address
     *      startTimestamp: 64 bits - When ownership started
     *      burned: 8 bits - Whether token is burned
     *      Total: 232 bits (24 bits unused for future use)
     */
    struct TokenOwnership {
        // TODO: Define the struct with packed fields
        // Hint: Use smaller types to fit in one slot
        // - address addr
        // - uint64 startTimestamp
        // - bool burned
    }

    /**
     * @dev Address data for balance and auxiliary tracking
     *      balance: 64 bits - Number of tokens owned
     *      numberMinted: 64 bits - Total ever minted to this address
     *      numberBurned: 64 bits - Total burned from this address
     *      aux: 64 bits - Auxiliary data for custom use
     */
    struct AddressData {
        // TODO: Define the struct for tracking address data
        // Hint: Pack multiple uint64 values
        // - uint64 balance
        // - uint64 numberMinted
        // - uint64 numberBurned
        // - uint64 aux
    }

    // =============================================================
    //                           STORAGE
    // =============================================================

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // TODO: Add mapping for token ownership
    // Hint: mapping(uint256 => TokenOwnership) private _ownerships;

    // TODO: Add mapping for address data
    // Hint: mapping(address => AddressData) private _addressData;

    // TODO: Add mapping for token approvals
    // Hint: mapping(uint256 => address) private _tokenApprovals;

    // TODO: Add mapping for operator approvals
    // Hint: mapping(address => mapping(address => bool)) private _operatorApprovals;

    // TODO: Add currentIndex to track next token ID
    // Hint: uint256 private _currentIndex;

    // TODO: Add burnCounter to track burned tokens
    // Hint: uint256 private _burnCounter;

    // Maximum supply of tokens
    uint256 public constant MAX_SUPPLY = 10000;

    // Mint price
    uint256 public constant MINT_PRICE = 0.01 ether;

    // Max mint per transaction
    uint256 public constant MAX_MINT_PER_TX = 20;

    // =============================================================
    //                           EVENTS
    // =============================================================

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // =============================================================
    //                           ERRORS
    // =============================================================

    error MaxSupplyReached();
    error InvalidQuantity();
    error InsufficientPayment();
    error TokenDoesNotExist();
    error NotOwnerNorApproved();
    error TransferToZeroAddress();
    error MintToZeroAddress();
    error MaxMintPerTxExceeded();

    // =============================================================
    //                         CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        // TODO: Initialize _currentIndex
        // Hint: Start at 0 or use _startTokenId()
    }

    // =============================================================
    //                        IERC721 METADATA
    // =============================================================

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        // TODO: Implement tokenURI
        // Hint: Check token exists, return base URI + token ID
        return "";
    }

    // =============================================================
    //                         IERC721
    // =============================================================

    /**
     * @notice Get the total number of tokens in circulation
     * @dev Returns total minted minus burned tokens
     */
    function totalSupply() public view returns (uint256) {
        // TODO: Implement totalSupply
        // Hint: _currentIndex - _burnCounter - _startTokenId()
        return 0;
    }

    /**
     * @notice Get the balance of an address
     * @param owner Address to query
     * @dev Reads from packed AddressData struct
     */
    function balanceOf(address owner) public view returns (uint256) {
        // TODO: Implement balanceOf
        // Hint: Return _addressData[owner].balance
        // Don't forget to check for zero address
        return 0;
    }

    /**
     * @notice Find the owner of a token
     * @param tokenId Token ID to query
     * @dev Uses ownership inference - scans backwards to find owner
     *
     * CRITICAL OPTIMIZATION:
     * Instead of storing owner for every token, we only store it for
     * the first token in a batch. To find an owner, we scan backwards
     * until we find a non-zero address.
     *
     * Example:
     * Batch mint tokens 0-4 to Alice:
     *   _ownerships[0] = {addr: alice, ...}
     *   _ownerships[1-4] = {addr: 0x0, ...} (empty)
     *
     * ownerOf(3) scans: 3 → 2 → 1 → 0 (found alice!)
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        // TODO: Implement ownerOf with backward scanning
        // Hint: Start at tokenId, scan backwards until _ownerships[curr].addr != 0
        // Steps:
        // 1. Check token exists (tokenId < _currentIndex)
        // 2. Start at curr = tokenId
        // 3. Loop backwards while curr >= _startTokenId()
        // 4. If _ownerships[curr].addr != 0, return it
        // 5. Decrement curr
        // 6. Revert if not found
        return address(0);
    }

    /**
     * @notice Approve an address to transfer a token
     * @param to Address to approve
     * @param tokenId Token to approve
     */
    function approve(address to, uint256 tokenId) public {
        // TODO: Implement approve
        // Hint:
        // 1. Get owner using ownerOf(tokenId)
        // 2. Check msg.sender is owner or approved operator
        // 3. Set _tokenApprovals[tokenId] = to
        // 4. Emit Approval event
    }

    /**
     * @notice Get approved address for a token
     * @param tokenId Token to query
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        // TODO: Implement getApproved
        // Hint: Check token exists, return _tokenApprovals[tokenId]
        return address(0);
    }

    /**
     * @notice Set operator approval for all tokens
     * @param operator Address to set approval for
     * @param approved Whether to approve or revoke
     */
    function setApprovalForAll(address operator, bool approved) public {
        // TODO: Implement setApprovalForAll
        // Hint:
        // 1. Require operator != msg.sender
        // 2. Set _operatorApprovals[msg.sender][operator] = approved
        // 3. Emit ApprovalForAll event
    }

    /**
     * @notice Check if operator is approved for all tokens of owner
     * @param owner Owner address
     * @param operator Operator address
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        // TODO: Implement isApprovedForAll
        // Hint: Return _operatorApprovals[owner][operator]
        return false;
    }

    /**
     * @notice Transfer a token
     * @param from Current owner
     * @param to New owner
     * @param tokenId Token to transfer
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        // TODO: Implement transferFrom
        // Hint: Call _transfer after checking approval
        // 1. Verify msg.sender is owner, approved, or operator
        // 2. Call _transfer(from, to, tokenId)
    }

    /**
     * @notice Safe transfer with contract check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @notice Safe transfer with data
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);
        // TODO: Add safe transfer check
        // Hint: Check if 'to' is contract, call onERC721Received if so
    }

    // =============================================================
    //                      MINTING FUNCTIONS
    // =============================================================

    /**
     * @notice Public mint function
     * @param quantity Number of tokens to mint
     * @dev This is where ERC-721A shines! Minting 5 costs nearly the same as 1.
     *
     * Gas Comparison:
     * Standard ERC-721 (5 tokens): ~750,000 gas (150k each)
     * ERC-721A (5 tokens):        ~175,000 gas (35k each)
     * Savings:                     ~575,000 gas (77% reduction!)
     */
    function mint(uint256 quantity) external payable {
        // TODO: Implement public minting
        // Checks:
        // 1. quantity > 0 and <= MAX_MINT_PER_TX
        // 2. _currentIndex + quantity <= MAX_SUPPLY
        // 3. msg.value >= MINT_PRICE * quantity
        // Then call _mint(msg.sender, quantity)
    }

    /**
     * @notice Owner mint for airdrops (free)
     * @param to Address to mint to
     * @param quantity Number of tokens
     */
    function ownerMint(address to, uint256 quantity) external {
        // TODO: Add owner check and call _mint
        // This would normally have an onlyOwner modifier
    }

    // =============================================================
    //                     INTERNAL MINT LOGIC
    // =============================================================

    /**
     * @notice Internal mint function - THE CORE OPTIMIZATION
     * @param to Address to mint to
     * @param quantity Number of tokens to mint
     *
     * KEY OPTIMIZATION EXPLAINED:
     * Instead of updating storage for each token:
     *   for i in 0..quantity:
     *     _owners[tokenId + i] = to  // 5 SSTORE = expensive!
     *
     * We only update storage ONCE for the batch:
     *   _ownerships[startTokenId] = TokenOwnership(to, timestamp, false)
     *   // 1 SSTORE = cheap!
     *
     * The other tokens (startTokenId+1 to startTokenId+quantity-1) have
     * empty ownership. When queried, ownerOf() scans backwards to find 'to'.
     */
    function _mint(address to, uint256 quantity) internal {
        // TODO: Implement the batch minting optimization
        //
        // Steps:
        // 1. Validate inputs (to != address(0), quantity > 0)
        // 2. Get startTokenId = _currentIndex
        // 3. Update _addressData[to]:
        //    - balance += quantity
        //    - numberMinted += quantity
        // 4. Set ownership for ONLY the first token in batch:
        //    _ownerships[startTokenId] = TokenOwnership({
        //        addr: to,
        //        startTimestamp: uint64(block.timestamp),
        //        burned: false
        //    })
        // 5. Emit Transfer events for each token (required by ERC-721)
        //    for (uint256 i = 0; i < quantity; i++):
        //        emit Transfer(address(0), to, startTokenId + i)
        // 6. Update _currentIndex += quantity
        //
        // IMPORTANT: Notice we only write to _ownerships ONCE, not quantity times!
        // This is the gas optimization!
    }

    // =============================================================
    //                    INTERNAL TRANSFER LOGIC
    // =============================================================

    /**
     * @notice Internal transfer function
     * @param from Current owner
     * @param to New owner
     * @param tokenId Token to transfer
     *
     * TRANSFER COMPLEXITY:
     * Transfers are more complex in ERC-721A because we need to maintain
     * the ownership chain. When transferring a token from a batch:
     *
     * Before: Tokens 0-4 owned by Alice (only token 0 has explicit ownership)
     * Transfer token 2 to Bob
     * After: We need:
     *   - Token 0-1: Still Alice (token 0 has explicit ownership)
     *   - Token 2: Bob (token 2 now has explicit ownership)
     *   - Token 3-4: Still Alice (need NEW explicit ownership at token 3!)
     *
     * If we don't set token 3's ownership, ownerOf(3) would scan back to
     * token 2 and incorrectly return Bob!
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        // TODO: Implement transfer with ownership chain maintenance
        //
        // Steps:
        // 1. Get current owner (should equal 'from')
        // 2. Validate: to != address(0)
        // 3. Clear approvals: delete _tokenApprovals[tokenId]
        // 4. Update balances:
        //    _addressData[from].balance -= 1
        //    _addressData[to].balance += 1
        // 5. Set new ownership for transferred token:
        //    _ownerships[tokenId] = TokenOwnership({
        //        addr: to,
        //        startTimestamp: uint64(block.timestamp),
        //        burned: false
        //    })
        // 6. CRITICAL: Update ownership of next token if it's in the same batch
        //    If _ownerships[tokenId + 1].addr == address(0):
        //        _ownerships[tokenId + 1] = TokenOwnership({
        //            addr: from,
        //            startTimestamp: prevOwnership.startTimestamp,
        //            burned: false
        //        })
        // 7. Emit Transfer event
    }

    // =============================================================
    //                       HELPER FUNCTIONS
    // =============================================================

    /**
     * @notice Get the starting token ID
     * @dev Override this to start from a different number (default 0)
     */
    function _startTokenId() internal pure returns (uint256) {
        return 0;
    }

    /**
     * @notice Check if msg.sender is owner or approved
     * @param tokenId Token to check
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        // TODO: Implement approval check
        // Hint: Check if spender is owner, approved, or operator
        return false;
    }

    /**
     * @notice Get ownership data for a token
     * @dev Internal function that returns the raw ownership data
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        // TODO: Implement ownership lookup with scanning
        // Similar to ownerOf but returns full struct
        return TokenOwnership({addr: address(0), startTimestamp: 0, burned: false});
    }

    // =============================================================
    //                         GAS ANALYSIS
    // =============================================================

    /**
     * Gas Costs Breakdown:
     *
     * MINTING (Single Token):
     * - Standard ERC-721: ~150,000 gas
     *   - SSTORE _owners[tokenId]: ~20,000 (warm) or ~22,100 (cold)
     *   - SSTORE _balances[owner]: ~20,000 (warm) or ~22,100 (cold)
     *   - Event emission: ~1,500
     *   - Logic overhead: ~5,000
     *
     * - ERC-721A: ~160,000 gas (slightly MORE for single!)
     *   - SSTORE _ownerships[tokenId]: ~22,100 (cold, larger struct)
     *   - SSTORE _addressData[owner]: ~22,100 (cold, larger struct)
     *   - Event emission: ~1,500
     *   - Logic overhead: ~10,000 (more complex)
     *
     * MINTING (Batch of 5):
     * - Standard ERC-721: ~750,000 gas
     *   - 5 × SSTORE _owners: ~110,000
     *   - 1 × SSTORE _balances: ~22,100
     *   - 5 × Events: ~7,500
     *   - Logic: ~25,000
     *
     * - ERC-721A: ~175,000 gas (77% SAVINGS!)
     *   - 1 × SSTORE _ownerships: ~22,100 (only first token!)
     *   - 1 × SSTORE _addressData: ~22,100
     *   - 5 × Events: ~7,500
     *   - Logic: ~15,000
     *
     * WHY THE SAVINGS?
     * Standard ERC-721: O(n) SSTORE operations for n tokens
     * ERC-721A: O(1) SSTORE operations regardless of n!
     */
}

/**
 * LEARNING CHECKPOINTS:
 *
 * 1. Storage Packing
 *    - How does packing addr + timestamp + burned save gas?
 *    - What's the maximum value for uint64 timestamp?
 *    - How many bits are wasted in TokenOwnership?
 *
 * 2. Ownership Inference
 *    - Why is scanning backwards safe?
 *    - What's the worst-case scenario for ownerOf()?
 *    - How does this affect transfer gas costs?
 *
 * 3. Batch Minting
 *    - Why is ERC-721A slower for single mints?
 *    - At what batch size do savings appear?
 *    - What's the maximum recommended batch size?
 *
 * 4. Trade-offs
 *    - When would you NOT use ERC-721A?
 *    - How do transfers differ from standard ERC-721?
 *    - What are the enumeration limitations?
 *
 * 5. Gas Optimization
 *    - Calculate gas per token for batch of 10
 *    - Compare with standard ERC-721
 *    - What's the break-even point?
 */
