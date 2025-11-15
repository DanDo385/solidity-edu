# Project 28: ERC-2981 Royalties

A comprehensive guide to implementing on-chain NFT royalties using the EIP-2981 standard.

## Learning Objectives

- Understand the EIP-2981 royalty standard
- Implement on-chain royalty information
- Calculate royalty fees correctly
- Manage global and per-token royalties
- Integrate with NFT marketplaces
- Handle royalty recipient updates
- Understand limitations and considerations

## What is EIP-2981?

EIP-2981 is a standardized way to retrieve royalty payment information for Non-Fungible Tokens (NFTs). It allows NFT creators to receive ongoing royalties from secondary sales across different marketplaces.

### Key Features

1. **Standardized Interface**: All compliant contracts expose the same `royaltyInfo()` function
2. **Marketplace Agnostic**: Works with any marketplace that supports the standard
3. **Flexible Configuration**: Supports both global and per-token royalty settings
4. **On-Chain Information**: Royalty data is stored directly on the blockchain

### The Standard Interface

```solidity
interface IERC2981 {
    /// @notice Called with the sale price to determine how much royalty
    ///         is owed and to whom.
    /// @param tokenId - the NFT asset queried for royalty information
    /// @param salePrice - the sale price of the NFT asset specified by tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for salePrice
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}
```

## How Royalties Work On-Chain

### Royalty Calculation

The `royaltyInfo()` function takes two parameters:
- `tokenId`: The specific NFT being sold
- `salePrice`: The price at which the NFT is being sold

It returns:
- `receiver`: The address that should receive the royalty
- `royaltyAmount`: The calculated royalty amount in the sale currency

### Fee Calculation Example

If a marketplace sells an NFT for 10 ETH with a 5% royalty:

```solidity
(address receiver, uint256 royaltyAmount) = nft.royaltyInfo(tokenId, 10 ether);
// receiver = 0x123... (creator's address)
// royaltyAmount = 0.5 ether (5% of 10 ETH)
```

### Basis Points System

Royalties are typically stored as basis points (1 basis point = 0.01%):
- 100 basis points = 1%
- 250 basis points = 2.5%
- 500 basis points = 5%
- 1000 basis points = 10%

Maximum recommended: 10,000 basis points (100%)

## Implementation Patterns

### 1. Global Royalties

Set a single royalty percentage for all tokens:

```solidity
// All tokens have the same royalty
_setDefaultRoyalty(receiver, feeNumerator); // e.g., feeNumerator = 500 (5%)
```

**Pros**:
- Simple to implement
- Lower gas costs
- Easy to manage

**Cons**:
- Less flexible
- Cannot customize per token

### 2. Per-Token Royalties

Set different royalties for each token:

```solidity
// Customize royalty per token
_setTokenRoyalty(tokenId, receiver, feeNumerator);
```

**Pros**:
- Highly flexible
- Different creators can have different rates
- Can support collaborative works

**Cons**:
- Higher gas costs
- More complex management
- Requires more storage

### 3. Hybrid Approach

Combine both methods:

```solidity
// Set default for most tokens
_setDefaultRoyalty(defaultReceiver, 500);

// Override for specific tokens
_setTokenRoyalty(specialTokenId, specialReceiver, 1000);
```

## Marketplace Integration

### How Marketplaces Use ERC-2981

1. **Check Support**: Verify the contract implements ERC-2981

```solidity
// Check via ERC165
bool supportsRoyalties = nft.supportsInterface(0x2a55205a); // ERC2981 interface ID
```

2. **Calculate Royalty**: Call `royaltyInfo()` with sale price

```solidity
(address royaltyReceiver, uint256 royaltyAmount) = nft.royaltyInfo(tokenId, salePrice);
```

3. **Process Payment**: Pay royalty to receiver, remainder to seller

```solidity
// Pay royalty
payable(royaltyReceiver).transfer(royaltyAmount);

// Pay seller
payable(seller).transfer(salePrice - royaltyAmount);
```

### Example Marketplace Integration

```solidity
contract SimpleMarketplace {
    function buyNFT(address nftContract, uint256 tokenId) external payable {
        uint256 salePrice = msg.value;

        // Check if NFT supports royalties
        bool supportsRoyalties = IERC165(nftContract).supportsInterface(0x2a55205a);

        if (supportsRoyalties) {
            // Get royalty info
            (address royaltyReceiver, uint256 royaltyAmount) =
                IERC2981(nftContract).royaltyInfo(tokenId, salePrice);

            // Pay royalty
            if (royaltyAmount > 0) {
                payable(royaltyReceiver).transfer(royaltyAmount);
                salePrice -= royaltyAmount;
            }
        }

        // Pay seller the remaining amount
        address seller = IERC721(nftContract).ownerOf(tokenId);
        payable(seller).transfer(salePrice);

        // Transfer NFT to buyer
        IERC721(nftContract).transferFrom(seller, msg.sender, tokenId);
    }
}
```

## Royalty Recipient Management

### Setting Royalty Recipients

```solidity
// Set default recipient for all tokens
function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
}

// Set recipient for specific token
function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
) external onlyOwner {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
}
```

### Updating Royalties

Important considerations when updating royalties:

1. **Access Control**: Only authorized addresses should update royalties
2. **Maximum Caps**: Enforce maximum royalty percentages (typically 10%)
3. **Validation**: Ensure receiver addresses are valid
4. **Events**: Emit events when royalties are updated

```solidity
function updateRoyalty(address newReceiver, uint96 newFee) external onlyOwner {
    require(newFee <= 1000, "Royalty too high"); // Max 10%
    require(newReceiver != address(0), "Invalid receiver");

    _setDefaultRoyalty(newReceiver, newFee);

    emit RoyaltyUpdated(newReceiver, newFee);
}
```

## Fee Calculation Best Practices

### Preventing Overflow

Always use safe math or Solidity ^0.8.0 for automatic overflow checks:

```solidity
// Safe calculation in OpenZeppelin's ERC2981
function royaltyInfo(uint256 tokenId, uint256 salePrice)
    public
    view
    returns (address, uint256)
{
    uint256 royaltyAmount = (salePrice * _feeDenominator) / 10000;
    return (_receiver, royaltyAmount);
}
```

### Rounding Considerations

Division in Solidity rounds down:
- Sale price: 1.999 ETH
- Royalty: 5% (500 basis points)
- Calculation: (1999000000000000000 * 500) / 10000 = 99950000000000000 (0.09995 ETH)

### Minimum Royalties

Consider setting minimum royalty amounts for small sales:

```solidity
uint256 royaltyAmount = (salePrice * feeNumerator) / 10000;
if (royaltyAmount > 0 && royaltyAmount < MIN_ROYALTY) {
    royaltyAmount = MIN_ROYALTY;
}
```

## Limitations and Considerations

### Not Enforceable

**Critical**: ERC-2981 provides royalty *information* but does not *enforce* payment.

- Marketplaces must voluntarily honor royalties
- Direct transfers bypass royalty mechanisms
- No on-chain enforcement is possible without restricting transfers

### Marketplace Adoption

Not all marketplaces support ERC-2981:
- OpenSea: Supports (but moving to operator filter)
- LooksRare: Supports
- X2Y2: Supports
- Blur: Does not enforce creator royalties
- Direct transfers: No royalties

### Gas Considerations

- **Global royalties**: Low gas overhead
- **Per-token royalties**: Higher gas costs
- **Reading royalty info**: Very cheap (view function)

### Currency Agnostic

Royalties are calculated as a percentage:
- Works with ETH, WETH, ERC20s
- Marketplace responsible for currency handling
- Royalty amount is in same units as sale price

### Privacy

All royalty information is public:
- Receiver addresses are visible on-chain
- Royalty percentages are transparent
- Cannot hide or obfuscate royalty data

## OpenZeppelin Implementation

The OpenZeppelin `ERC2981` contract provides:

1. **Default Royalty**: `_setDefaultRoyalty(receiver, feeNumerator)`
2. **Token Royalty**: `_setTokenRoyalty(tokenId, receiver, feeNumerator)`
3. **Delete Royalty**: `_deleteDefaultRoyalty()` and `_resetTokenRoyalty(tokenId)`
4. **Interface Support**: Automatic ERC165 registration

### Basic Integration

```solidity
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract MyNFT is ERC721, ERC2981 {
    constructor() ERC721("MyNFT", "MNFT") {
        // Set 5% royalty to contract deployer
        _setDefaultRoyalty(msg.sender, 500);
    }

    // Override supportsInterface for both ERC721 and ERC2981
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```

## Advanced Patterns

### Split Royalties

Multiple recipients can be implemented via a splitter contract:

```solidity
// Set royalty receiver to a PaymentSplitter contract
_setDefaultRoyalty(address(paymentSplitter), 500);
```

### Dynamic Royalties

Royalties that change based on conditions:

```solidity
function royaltyInfo(uint256 tokenId, uint256 salePrice)
    public
    view
    override
    returns (address, uint256)
{
    // Higher royalty for rare tokens
    uint256 feeBps = isRare(tokenId) ? 1000 : 500;
    uint256 royaltyAmount = (salePrice * feeBps) / 10000;

    return (royaltyReceiver, royaltyAmount);
}
```

### Decreasing Royalties

Royalties that decrease over time:

```solidity
function royaltyInfo(uint256 tokenId, uint256 salePrice)
    public
    view
    override
    returns (address, uint256)
{
    uint256 age = block.timestamp - mintTimestamp[tokenId];
    uint256 feeBps = age > 365 days ? 250 : 500; // Reduce after 1 year
    uint256 royaltyAmount = (salePrice * feeBps) / 10000;

    return (royaltyReceiver, royaltyAmount);
}
```

## Common Pitfalls

1. **Integer Division**: Always multiply before dividing to avoid precision loss
2. **Zero Address**: Validate receiver addresses
3. **Fee Caps**: Enforce maximum royalty percentages
4. **Interface Support**: Remember to override `supportsInterface()`
5. **Denominator**: Use 10000 as denominator for basis points

## Testing Checklist

- [ ] Verify correct interface ID (0x2a55205a)
- [ ] Test royalty calculation accuracy
- [ ] Validate fee percentages
- [ ] Test both global and per-token royalties
- [ ] Verify royalty updates work correctly
- [ ] Test with zero address handling
- [ ] Ensure maximum royalty caps
- [ ] Test edge cases (zero sale price, maximum values)

## Project Structure

```
28-erc2981-royalties/
├── src/
│   ├── Project28.sol           # Skeleton contract (your task)
│   └── solution/
│       └── Project28Solution.sol  # Complete solution
├── test/
│   └── Project28.t.sol         # Comprehensive tests
├── script/
│   └── DeployProject28.s.sol   # Deployment script
└── README.md                    # This file
```

## Getting Started

1. Review the concepts above
2. Examine `src/Project28.sol` and complete the TODOs
3. Run tests: `forge test --match-path test/Project28.t.sol`
4. Compare with `src/solution/Project28Solution.sol`
5. Deploy: `forge script script/DeployProject28.s.sol`

## Additional Resources

- [EIP-2981 Specification](https://eips.ethereum.org/EIPS/eip-2981)
- [OpenZeppelin ERC2981 Documentation](https://docs.openzeppelin.com/contracts/4.x/api/token/common#ERC2981)
- [NFT Royalty Standard Explainer](https://eips.ethereum.org/EIPS/eip-2981)
- [Marketplace Royalty Support](https://royaltyregistry.xyz/)

## Next Steps

After mastering ERC-2981, explore:
- Project 29: Operator Filter Registry (enforcing royalties)
- Payment splitters for multiple royalty recipients
- Cross-chain royalty tracking
- Alternative royalty enforcement mechanisms

## License

MIT
