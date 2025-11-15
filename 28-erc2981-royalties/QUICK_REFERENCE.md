# ERC-2981 Quick Reference Guide

## Essential Interface

```solidity
interface IERC2981 {
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}
```

## Interface ID

```solidity
bytes4 constant ERC2981_INTERFACE_ID = 0x2a55205a;
```

## Basis Points System

| Basis Points | Percentage | Example on 10 ETH |
|--------------|------------|-------------------|
| 100          | 1%         | 0.1 ETH           |
| 250          | 2.5%       | 0.25 ETH          |
| 500          | 5%         | 0.5 ETH           |
| 750          | 7.5%       | 0.75 ETH          |
| 1000         | 10%        | 1 ETH             |

Formula: `royaltyAmount = (salePrice * basisPoints) / 10000`

## OpenZeppelin Implementation

### Basic Setup

```solidity
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract MyNFT is ERC721, ERC2981 {
    constructor() ERC721("MyNFT", "MNFT") {
        _setDefaultRoyalty(msg.sender, 500); // 5% to deployer
    }

    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```

### Key Functions

```solidity
// Set global royalty for all tokens
_setDefaultRoyalty(address receiver, uint96 feeNumerator);

// Set royalty for specific token
_setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator);

// Remove token-specific royalty (revert to default)
_resetTokenRoyalty(uint256 tokenId);

// Remove global default royalty
_deleteDefaultRoyalty();
```

## Common Patterns

### Pattern 1: Global Royalty
```solidity
constructor() {
    _setDefaultRoyalty(creator, 500); // 5% to creator for all tokens
}
```

### Pattern 2: Per-Token Royalty
```solidity
function mint(address artist, uint96 royaltyFee) external {
    uint256 tokenId = _nextTokenId++;
    _mint(artist, tokenId);
    _setTokenRoyalty(tokenId, artist, royaltyFee);
}
```

### Pattern 3: Updatable Royalty
```solidity
function updateRoyalty(address newReceiver, uint96 newFee) external onlyOwner {
    require(newFee <= 1000, "Max 10%");
    _setDefaultRoyalty(newReceiver, newFee);
}
```

## Marketplace Integration

### Detection
```solidity
bool supportsRoyalties = IERC165(nft).supportsInterface(0x2a55205a);
```

### Query Royalty
```solidity
if (supportsRoyalties) {
    (address receiver, uint256 amount) = IERC2981(nft).royaltyInfo(tokenId, salePrice);
}
```

### Payment Flow
```solidity
// 1. Pay royalty
if (royaltyAmount > 0) {
    payable(royaltyReceiver).transfer(royaltyAmount);
}

// 2. Pay seller
payable(seller).transfer(salePrice - royaltyAmount);

// 3. Transfer NFT
IERC721(nft).transferFrom(seller, buyer, tokenId);
```

## Testing Checklist

- [ ] `supportsInterface(0x2a55205a)` returns true
- [ ] `royaltyInfo()` returns correct receiver
- [ ] Royalty calculation is accurate
- [ ] Fee validation (not exceeding max)
- [ ] Per-token royalties override global
- [ ] Reset functionality works
- [ ] Zero address handling
- [ ] Edge cases (zero price, max price)

## Common Gotchas

1. **Forgot to override `supportsInterface`**
   ```solidity
   // Wrong - only overrides one parent
   function supportsInterface(bytes4 interfaceId)
       public view override(ERC721) returns (bool)

   // Correct - overrides both parents
   function supportsInterface(bytes4 interfaceId)
       public view override(ERC721, ERC2981) returns (bool)
   ```

2. **Royalty fee too high**
   ```solidity
   // Always validate maximum fee
   require(feeNumerator <= 1000, "Max 10%");
   ```

3. **Zero address receiver**
   ```solidity
   // Always validate receiver
   require(receiver != address(0), "Invalid receiver");
   ```

4. **Not calling super.supportsInterface**
   ```solidity
   // Wrong - loses parent functionality
   return ERC721.supportsInterface(interfaceId);

   // Correct - checks all parents
   return super.supportsInterface(interfaceId);
   ```

## Royalty Calculation Examples

```solidity
// Example 1: 5% of 10 ETH
(receiver, amount) = royaltyInfo(tokenId, 10 ether);
// amount = (10 ether * 500) / 10000 = 0.5 ether

// Example 2: 2.5% of 100 ETH
(receiver, amount) = royaltyInfo(tokenId, 100 ether);
// amount = (100 ether * 250) / 10000 = 2.5 ether

// Example 3: 10% of 1 ETH
(receiver, amount) = royaltyInfo(tokenId, 1 ether);
// amount = (1 ether * 1000) / 10000 = 0.1 ether
```

## Best Practices

1. ✅ Set reasonable royalty percentages (2.5% - 10%)
2. ✅ Validate all inputs (max fees, non-zero addresses)
3. ✅ Emit events for royalty changes
4. ✅ Use global royalties for simplicity
5. ✅ Use per-token for flexibility
6. ✅ Cap maximum royalties
7. ✅ Implement access controls
8. ✅ Document royalty structure
9. ✅ Test with marketplaces
10. ✅ Consider gas costs

## Limitations

⚠️ **Not Enforceable**: ERC-2981 only provides information, doesn't enforce payment

⚠️ **Marketplace Dependent**: Only works if marketplace checks ERC-2981

⚠️ **Direct Transfers**: Cannot prevent wallet-to-wallet transfers without royalties

⚠️ **Voluntary**: Marketplaces can choose to ignore or cap royalties

## Resources

- [EIP-2981 Specification](https://eips.ethereum.org/EIPS/eip-2981)
- [OpenZeppelin ERC2981](https://docs.openzeppelin.com/contracts/4.x/api/token/common#ERC2981)
- [Interface ID Calculator](https://eips.ethereum.org/EIPS/eip-165)

## CLI Commands

```bash
# Check interface support
cast call $NFT "supportsInterface(bytes4)" 0x2a55205a

# Get royalty info (token 0, 10 ETH sale)
cast call $NFT "royaltyInfo(uint256,uint256)" 0 10000000000000000000

# Set default royalty (5% to address)
cast send $NFT "setDefaultRoyalty(address,uint96)" $RECEIVER 500 --private-key $KEY

# Set token royalty
cast send $NFT "setTokenRoyalty(uint256,address,uint96)" $TOKEN_ID $RECEIVER 750 --private-key $KEY
```

## Example Contract

See `/home/user/solidity-edu/28-erc2981-royalties/src/solution/Project28Solution.sol` for complete implementation.
