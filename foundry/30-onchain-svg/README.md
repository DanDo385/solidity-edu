# Project 30: On-Chain SVG Rendering

Learn how to create fully on-chain NFTs with dynamically generated SVG artwork stored entirely on the blockchain.

## Overview

This project teaches you how to create NFTs where both metadata and artwork are stored completely on-chain, making them truly permanent and decentralized. You'll learn to generate SVG images programmatically in Solidity and encode them as data URIs.

## Learning Objectives

- Understand on-chain vs off-chain metadata storage
- Master SVG generation in Solidity
- Implement Base64 encoding for data URIs
- Create dynamic NFT attributes
- Build generative art algorithms
- Optimize gas costs for on-chain storage
- Construct proper JSON metadata

## On-Chain vs Off-Chain Metadata: Storage Trade-offs

**FIRST PRINCIPLES: Decentralization vs Cost**

Understanding the trade-offs between on-chain and off-chain metadata is crucial for NFT design. Each approach has different costs and benefits!

**CONNECTION TO PROJECT 09**:
- **Project 09**: ERC721 NFTs with off-chain metadata (IPFS)
- **Project 30**: On-chain SVG generation (no IPFS needed!)
- Both valid approaches - choose based on requirements!

### Off-Chain Metadata (Traditional)

**HOW IT WORKS**:
```
Token -> tokenURI -> IPFS/Server -> JSON -> Image URL -> IPFS/Server -> Image
```

**CONNECTION TO PROJECT 03**:
We learned about events in Project 03. Off-chain metadata uses similar pattern - data stored off-chain, referenced on-chain!

**PROS**:
- Low gas costs (from Project 01: storage is expensive!)
  - Only store URI string: ~20,000 gas
  - Image stored off-chain (free!)
  
- Can store high-resolution images
  - No size constraints
  - Complex media (videos, 3D models)
  
- Easy to update
  - Change metadata without redeploying
  - Update images independently

**CONS**:
- Requires external storage (IPFS, centralized servers)
  - Dependency on external systems
  - IPFS requires pinning services
  
- Risk of link rot
  - If IPFS node goes down, metadata unavailable
  - Centralized servers can be censored
  
- Not truly decentralized
  - Relies on external infrastructure
  - Can be taken down

### On-Chain Metadata (This Project)

**HOW IT WORKS**:
```
Token -> Smart Contract -> Generated SVG + JSON -> Data URI
```

**UNDERSTANDING DATA URIs**:

```
Data URI Format:
data:image/svg+xml;base64,<base64_encoded_svg>
```

**PROS**:
- Truly permanent and decentralized
  - Stored on blockchain forever
  - No external dependencies
  
- Cannot be censored or taken down
  - Blockchain is immutable
  - No single point of failure
  
- Guaranteed availability
  - As long as blockchain exists, NFT exists
  - No link rot possible

**CONS**:
- Higher gas costs (from Project 01 knowledge)
  - Storage: ~20,000 gas per write
  - SVG strings: ~5 gas per byte
  - For 1KB SVG: ~25,000 gas (storage) + ~5,000 gas (data) = ~30,000 gas
  
- Limited to simple graphics
  - SVG only (no videos, 3D models)
  - Size constraints (gas limits)
  
- Cannot update without upgradeable contracts
  - Immutable once deployed
  - Need proxies (Project 10) for updates

**GAS COST COMPARISON** (from Project 01 & 03 knowledge):

**Off-Chain**:
- Store URI: ~20,000 gas (string storage)
- Image: FREE (off-chain)
- Total: ~20,000 gas

**On-Chain**:
- Store SVG: ~20,000 gas (base) + ~5 gas/byte
- For 1KB SVG: ~25,000 gas
- For 10KB SVG: ~70,000 gas
- Total: 25,000-70,000+ gas (depends on size)

**REAL-WORLD ANALOGY**: 
- **Off-Chain**: Like storing artwork in a museum (cheap, but museum can close)
- **On-Chain**: Like engraving artwork in stone (expensive, but permanent)

## SVG Basics for NFTs

### What is SVG?

SVG (Scalable Vector Graphics) is an XML-based format for 2D graphics that's perfect for on-chain NFTs because:

1. **Text-based**: Can be generated as strings in Solidity
2. **Scalable**: Looks crisp at any size
3. **Small file size**: Efficient for on-chain storage
4. **Browser support**: All modern browsers render SVGs
5. **Dynamic**: Easy to parameterize and generate programmatically

### Basic SVG Structure

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Shapes go here -->
  <rect x="50" y="50" width="100" height="100" fill="blue" />
  <circle cx="200" cy="200" r="50" fill="red" />
  <text x="200" y="350" text-anchor="middle" font-size="24">Hello</text>
</svg>
```

### Common SVG Elements

**Shapes:**
- `<rect>` - Rectangles
- `<circle>` - Circles
- `<ellipse>` - Ellipses
- `<line>` - Lines
- `<polyline>` - Connected lines
- `<polygon>` - Closed shapes
- `<path>` - Complex curves

**Styling:**
- `fill` - Fill color
- `stroke` - Border color
- `stroke-width` - Border thickness
- `opacity` - Transparency

**Text:**
- `<text>` - Text elements
- `font-size`, `font-family`, `text-anchor`

## Base64 Encoding

### Why Base64?

Base64 encoding converts binary data (or strings) into ASCII text, allowing us to embed SVG and JSON directly in URIs.

### Data URI Format

```
data:[<mediatype>][;base64],<data>
```

**Examples:**
```
data:image/svg+xml;base64,PHN2ZyB4bWxucz0i...
data:application/json;base64,eyJuYW1lIjoi...
```

### Base64 in Solidity

Solidity doesn't have built-in Base64 encoding, so we need to implement it:

```solidity
// Base64 alphabet
string constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

function encode(bytes memory data) internal pure returns (string memory) {
    // Encoding logic: converts 3 bytes into 4 base64 characters
    // Handles padding with '=' for data not divisible by 3
}
```

## Dynamic NFTs

Dynamic NFTs change based on various factors:

### 1. Token ID-Based
```solidity
// Different colors for each token
function getColor(uint256 tokenId) internal pure returns (string memory) {
    uint256 hue = (tokenId * 137) % 360;  // Golden angle distribution
    return string.concat("hsl(", toString(hue), ",70%,50%)");
}
```

### 2. Time-Based
```solidity
// Changes based on block timestamp
function getPattern(uint256 tokenId) internal view returns (string memory) {
    uint256 timeOfDay = (block.timestamp % 86400) / 3600;  // Hour of day
    if (timeOfDay < 6) return "night";
    if (timeOfDay < 12) return "morning";
    if (timeOfDay < 18) return "afternoon";
    return "evening";
}
```

### 3. Trait-Based
```solidity
// Based on stored attributes
struct Traits {
    uint8 shape;
    uint8 pattern;
    uint8 rarity;
}

mapping(uint256 => Traits) public tokenTraits;
```

### 4. Interactive
```solidity
// Changes based on user actions
function levelUp(uint256 tokenId) external {
    require(ownerOf(tokenId) == msg.sender);
    tokenLevel[tokenId]++;
    // SVG changes to reflect new level
}
```

## Gas Costs of On-Chain Storage

### Storage Costs

Gas costs for on-chain data (approximate):
- **SSTORE** (new): ~20,000 gas per 32 bytes
- **SSTORE** (update): ~5,000 gas per 32 bytes
- **Contract code**: ~200 gas per byte

### Optimization Strategies

#### 1. Use String Concatenation Efficiently
```solidity
// Bad: Creates many intermediate strings
string memory svg = "<svg>";
svg = string.concat(svg, "<rect/>");
svg = string.concat(svg, "<circle/>");

// Better: Concatenate in fewer operations
string memory svg = string.concat(
    "<svg>",
    "<rect/>",
    "<circle/>"
);
```

#### 2. Store Reusable Components
```solidity
// Store common strings as constants (in bytecode, not storage)
string constant SVG_HEADER = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">';
string constant SVG_FOOTER = '</svg>';
```

#### 3. Pack Data Efficiently
```solidity
// Bad: Each trait uses 256 bits
uint256 shape;
uint256 color;
uint256 pattern;

// Good: Pack into single uint256
uint256 packedTraits;  // [8 bits shape][8 bits color][8 bits pattern][232 bits unused]
```

#### 4. Use Events for Historical Data
```solidity
// Don't store everything in state
event MetadataUpdate(uint256 indexed tokenId, string metadata);

// Emit events for historical records, only store current state
```

### Real-World Gas Costs

**Typical On-Chain NFT Mint:**
- Off-chain metadata: ~50,000-100,000 gas
- On-chain metadata: ~200,000-500,000 gas
- Complex generative art: ~500,000-1,000,000+ gas

**Cost Analysis** (at 50 gwei, ETH = $2000):
- Simple on-chain NFT: $20-50
- Complex generative NFT: $50-100+

## Generative Art Patterns

### 1. Geometric Patterns

```solidity
function generateCircles(uint256 tokenId) internal pure returns (string memory) {
    string memory circles;
    for (uint256 i = 0; i < 5; i++) {
        uint256 cx = (tokenId * (i + 1) * 73) % 400;
        uint256 cy = (tokenId * (i + 1) * 31) % 400;
        uint256 r = 20 + (i * 10);

        circles = string.concat(
            circles,
            '<circle cx="', toString(cx),
            '" cy="', toString(cy),
            '" r="', toString(r),
            '" fill="hsl(', toString(i * 72), ',70%,50%)" />'
        );
    }
    return circles;
}
```

### 2. Color Schemes

```solidity
// Golden ratio for pleasing color distribution
function getHue(uint256 seed, uint256 index) internal pure returns (uint256) {
    return (seed + index * 137) % 360;  // 137.5° is golden angle
}

// Complementary colors
function getComplementary(uint256 hue) internal pure returns (uint256) {
    return (hue + 180) % 360;
}

// Triadic colors
function getTriadic(uint256 hue, uint256 index) internal pure returns (uint256) {
    return (hue + index * 120) % 360;
}
```

### 3. Pseudo-Random Generation

```solidity
// Deterministic randomness from token ID
function getRandom(uint256 tokenId, uint256 seed) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(tokenId, seed)));
}

// Multiple random values
function getRandomPattern(uint256 tokenId) internal pure returns (uint256[] memory) {
    uint256[] memory randoms = new uint256[](5);
    for (uint256 i = 0; i < 5; i++) {
        randoms[i] = getRandom(tokenId, i);
    }
    return randoms;
}
```

### 4. Mathematical Patterns

```solidity
// Spiral pattern
function getSpiral(uint256 index, uint256 totalPoints) internal pure returns (uint256 x, uint256 y) {
    uint256 angle = (index * 360 * 3) / totalPoints;  // 3 full rotations
    uint256 radius = 50 + (index * 100) / totalPoints;

    x = 200 + (radius * cos(angle)) / 1000;
    y = 200 + (radius * sin(angle)) / 1000;
}

// Grid pattern
function getGrid(uint256 index, uint256 cols) internal pure returns (uint256 x, uint256 y) {
    x = (index % cols) * 50 + 25;
    y = (index / cols) * 50 + 25;
}
```

## Use Cases for On-Chain NFTs

### 1. Generative Art Projects
- **Art Blocks**: Pioneered on-chain generative art
- **Autoglyphs**: First on-chain generative art on Ethereum
- **Chain Runners**: Fully on-chain pixel art characters

### 2. Gaming Assets
- **Loot**: Text-based adventure game items
- **On-chain games**: Assets that can't be taken down
- **Provably fair randomness**: All logic verifiable on-chain

### 3. Credentials & Certificates
- **Educational certificates**: Permanent proof of achievement
- **Professional licenses**: Verifiable credentials
- **Event attendance**: POAPs and similar

### 4. Identity & Profile
- **ENS names**: On-chain domain names
- **Profile pictures**: Permanent social media avatars
- **Reputation systems**: Immutable achievement records

### 5. Financial Instruments
- **Bonds**: Visual representation of financial positions
- **Derivatives**: Complex financial products
- **Receipts**: Proof of transactions

## JSON Metadata Structure

### ERC721 Metadata Standard

```json
{
  "name": "Token Name #1",
  "description": "Description of the token",
  "image": "data:image/svg+xml;base64,...",
  "attributes": [
    {
      "trait_type": "Background",
      "value": "Blue"
    },
    {
      "trait_type": "Pattern",
      "value": "Circles"
    },
    {
      "trait_type": "Rarity",
      "value": "Legendary",
      "display_type": "string"
    },
    {
      "trait_type": "Power",
      "value": 95,
      "display_type": "number",
      "max_value": 100
    }
  ]
}
```

### Attribute Display Types

- `string`: Default text display
- `number`: Numeric value (shows progress bar on OpenSea)
- `boost_number`: Numerical boost
- `boost_percentage`: Percentage boost
- `date`: Unix timestamp (shows as date)

### Generating JSON in Solidity

```solidity
function getMetadata(uint256 tokenId) internal view returns (string memory) {
    return string.concat(
        '{"name":"Token #', toString(tokenId),
        '","description":"On-chain SVG NFT",',
        '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(getSVG(tokenId))),
        '","attributes":[',
        '{"trait_type":"Color","value":"', getColorName(tokenId), '"},',
        '{"trait_type":"Pattern","value":"', getPatternName(tokenId), '"}',
        ']}'
    );
}
```

## Implementation Patterns

### Pattern 1: Simple Static SVG

```solidity
function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">'
        '<rect width="400" height="400" fill="blue"/>'
        '<text x="200" y="200" text-anchor="middle" font-size="48" fill="white">NFT</text>'
        '</svg>';

    string memory json = string.concat(
        '{"name":"Token #', toString(tokenId), '",',
        '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'
    );

    return string.concat('data:application/json;base64,', Base64.encode(bytes(json)));
}
```

### Pattern 2: Token ID-Based Colors

```solidity
function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory color = getColor(tokenId);

    string memory svg = string.concat(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">',
        '<rect width="400" height="400" fill="', color, '"/>',
        '</svg>'
    );

    // ... rest of metadata generation
}

function getColor(uint256 tokenId) internal pure returns (string memory) {
    uint256 hue = (tokenId * 137) % 360;
    return string.concat('hsl(', toString(hue), ',70%,50%)');
}
```

### Pattern 3: Complex Generative Art

```solidity
function tokenURI(uint256 tokenId) public view override returns (string memory) {
    // Generate multiple components
    string memory background = generateBackground(tokenId);
    string memory shapes = generateShapes(tokenId);
    string memory effects = generateEffects(tokenId);

    string memory svg = string.concat(
        SVG_HEADER,
        background,
        shapes,
        effects,
        SVG_FOOTER
    );

    // Generate traits
    string memory attributes = generateAttributes(tokenId);

    string memory json = string.concat(
        '{"name":"Generative #', toString(tokenId), '",',
        '"description":"Complex on-chain generative art",',
        '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '",',
        '"attributes":', attributes,
        '}'
    );

    return string.concat('data:application/json;base64,', Base64.encode(bytes(json)));
}
```

## Best Practices

### 1. Gas Optimization
- Minimize storage reads/writes
- Use `pure` and `view` functions when possible
- Batch string concatenations
- Store constants in bytecode, not storage

### 2. SVG Generation
- Keep SVGs simple and clean
- Use viewBox for responsiveness
- Avoid excessive nesting
- Test rendering in browsers

### 3. Metadata Quality
- Follow ERC721 metadata standard
- Provide meaningful attributes
- Use proper JSON formatting
- Include description and name

### 4. Testing
- Test Base64 encoding/decoding
- Verify SVG renders correctly
- Check JSON validity
- Test with various token IDs

### 5. Security
- Validate all inputs
- Prevent overflow in calculations
- Handle edge cases (tokenId = 0, max uint256)
- Ensure deterministic output

## Common Pitfalls

1. **Gas Costs**: Underestimating minting costs
2. **String Handling**: Inefficient concatenation
3. **SVG Syntax**: Invalid XML/SVG that won't render
4. **JSON Formatting**: Broken JSON that marketplaces can't parse
5. **Base64 Encoding**: Incorrect implementation
6. **Number Conversion**: toString() not implemented
7. **Non-Deterministic**: Using block.timestamp in ways that change historical tokens

## Advanced Techniques

### 1. Layered Composition

```solidity
function buildLayers(uint256 tokenId) internal pure returns (string memory) {
    return string.concat(
        getLayer("background", tokenId),
        getLayer("base", tokenId),
        getLayer("pattern", tokenId),
        getLayer("overlay", tokenId)
    );
}
```

### 2. Animation

```solidity
string memory animated = string.concat(
    '<circle cx="200" cy="200" r="50" fill="red">',
    '<animate attributeName="r" values="50;75;50" dur="2s" repeatCount="indefinite"/>',
    '</circle>'
);
```

### 3. Filters and Effects

```solidity
string memory withEffects = string.concat(
    '<defs>',
    '<filter id="blur"><feGaussianBlur in="SourceGraphic" stdDeviation="5"/></filter>',
    '</defs>',
    '<rect width="400" height="400" fill="blue" filter="url(#blur)"/>'
);
```

## Your Task

Complete the skeleton contract in `src/Project30.sol` to create a fully on-chain NFT with dynamic SVG generation:

1. Implement Base64 encoding
2. Generate dynamic SVGs based on token ID
3. Create colorful, interesting artwork
4. Build proper JSON metadata
5. Implement tokenURI function
6. Add multiple dynamic attributes

## Testing

Run the test suite:
```bash
forge test -vv
```

Test specific functions:
```bash
forge test --match-test testSVGGeneration -vvvv
```

## Deployment

Deploy to a testnet:
```bash
forge script script/DeployProject30.s.sol:DeployProject30 --rpc-url sepolia --broadcast --verify
```

View your on-chain NFT metadata:
1. Mint a token
2. Call tokenURI(tokenId)
3. Copy the data URI
4. Paste into browser address bar
5. See your fully on-chain metadata and artwork!

### Study the Solutions

After implementing your own solutions, compare with:
- `src/solution/OnChainSVGSolution.sol` - Reference contract implementation with CS concept explanations
- `script/solution/DeployOnChainSVGSolution.s.sol` - Deployment script patterns
- `test/solution/OnChainSVGSolution.t.sol` - Comprehensive test examples

**Important**: Try to implement everything yourself first! The solutions are there to help you learn, not to copy.

**Solution File Features**:
- **CS Concepts**: Explains string concatenation, Base64 encoding, data URI construction
- **Connections to Project 09**: ERC721 NFT standard (this adds on-chain metadata)
- **Connections to Project 01**: String storage costs (on-chain metadata is expensive but permanent)
- **Real-World Context**: Fully decentralized NFTs - no IPFS dependency

## Resources

- [SVG Tutorial - MDN](https://developer.mozilla.org/en-US/docs/Web/SVG/Tutorial)
- [ERC721 Metadata Standard](https://eips.ethereum.org/EIPS/eip-721)
- [OpenSea Metadata Standards](https://docs.opensea.io/docs/metadata-standards)
- [Base64 Encoding](https://en.wikipedia.org/wiki/Base64)
- [Art Blocks](https://www.artblocks.io/)
- [Loot Project](https://www.lootproject.com/)

## Examples of On-Chain NFT Projects

1. **Autoglyphs** - First on-chain generative art
2. **Loot** - Text-based adventure gear
3. **Chain Runners** - Pixel art characters
4. **Blitmap** - Collaborative pixel art
5. **Nouns** - Daily generative avatars
6. **On-Chain Monkey** - First PFP with on-chain metadata

Good luck creating your fully on-chain NFT collection!
