// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Project30Solution - On-Chain SVG NFT
 * @notice A fully on-chain NFT with dynamically generated SVG artwork
 * @dev All metadata and artwork are stored on-chain, making it truly permanent
 *
 * This implementation creates beautiful generative art with:
 * - Dynamic color schemes based on golden angle distribution
 * - Multiple geometric shapes (circles, squares, triangles)
 * - Unique patterns for each token
 * - Complete JSON metadata with traits
 * - Optimized gas usage through efficient string handling
 */
contract Project30Solution is ERC721, Ownable {
    // =============================================================
    //                           STORAGE
    // =============================================================

    uint256 private _nextTokenId;
    uint256 public maxSupply = 1000;

    // SVG constants (stored in bytecode, not storage - gas efficient!)
    // These are reused for every token without additional storage cost
    string constant SVG_HEADER = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">';
    string constant SVG_FOOTER = '</svg>';

    // =============================================================
    //                         CONSTRUCTOR
    // =============================================================

    constructor() ERC721("OnChainSVG", "OCSVG") Ownable(msg.sender) {}

    // =============================================================
    //                        MINTING LOGIC
    // =============================================================

    /**
     * @notice Mint a new on-chain SVG NFT
     * @dev The artwork is generated dynamically based on the token ID
     * Each token gets unique colors, shapes, and patterns
     */
    function mint() external {
        require(_nextTokenId < maxSupply, "Max supply reached");

        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
    }

    // =============================================================
    //                      METADATA GENERATION
    // =============================================================

    /**
     * @notice Returns the complete token URI with on-chain metadata and SVG
     * @dev Returns a data URI containing Base64 encoded JSON with embedded SVG
     * @param tokenId The token ID to get metadata for
     * @return A data URI string containing all metadata and artwork
     *
     * IMPLEMENTATION NOTES:
     * 1. Generate the SVG artwork
     * 2. Base64 encode the SVG
     * 3. Build JSON metadata with the encoded SVG as the image
     * 4. Base64 encode the entire JSON
     * 5. Return as a data URI that browsers and marketplaces can read
     *
     * The returned format is: data:application/json;base64,BASE64_ENCODED_JSON
     * This allows the metadata to be stored entirely on-chain with no external dependencies
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        // Step 1: Generate the SVG artwork for this token
        string memory svg = generateSVG(tokenId);

        // Step 2: Build the JSON metadata
        // Format: {"name":"...","description":"...","image":"...","attributes":[...]}
        string memory json = string.concat(
            '{',
            '"name":"OnChain SVG #', toString(tokenId), '",',
            '"description":"Fully on-chain generative art with dynamic SVG rendering. Each piece is unique and stored permanently on the blockchain.",',
            // Image is embedded as base64 encoded SVG
            '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '",',
            // Attributes provide trait information for marketplaces
            '"attributes":[',
            '{"trait_type":"Background","value":"', getColorName(tokenId), '"},',
            '{"trait_type":"Shape","value":"', getShape(tokenId), '"},',
            '{"trait_type":"Pattern","value":"', getPattern(tokenId), '"},',
            '{"trait_type":"Complexity","value":', toString(getComplexity(tokenId)), ',"display_type":"number","max_value":100}',
            ']',
            '}'
        );

        // Step 3: Base64 encode the entire JSON and return as data URI
        // This creates a fully self-contained token URI with no external dependencies
        return string.concat('data:application/json;base64,', Base64.encode(bytes(json)));
    }

    /**
     * @notice Generates the complete SVG for a token
     * @param tokenId The token ID to generate SVG for
     * @return Complete SVG markup as a string
     *
     * IMPLEMENTATION NOTES:
     * This function creates a visually interesting generative art piece by:
     * 1. Creating a gradient background based on token ID
     * 2. Adding multiple geometric shapes with varying sizes and colors
     * 3. Creating patterns based on deterministic randomness
     * 4. Adding text to display the token ID
     *
     * All elements are positioned and colored based on the token ID,
     * ensuring each NFT is unique and deterministic (same tokenId always
     * produces the same artwork).
     */
    function generateSVG(uint256 tokenId) public pure returns (string memory) {
        // Generate background - uses gradient for visual interest
        string memory background = generateBackground(tokenId);

        // Generate geometric shapes - circles, squares, triangles
        string memory shapes = generateShapes(tokenId);

        // Generate pattern overlay - adds texture and complexity
        string memory pattern = generatePattern(tokenId);

        // Add token ID text
        string memory text = string.concat(
            '<text x="200" y="370" text-anchor="middle" font-size="24" ',
            'font-family="monospace" fill="white" opacity="0.8">#',
            toString(tokenId),
            '</text>'
        );

        // Combine all elements into final SVG
        // Order matters: background -> shapes -> pattern -> text (back to front)
        return string.concat(
            SVG_HEADER,
            background,
            shapes,
            pattern,
            text,
            SVG_FOOTER
        );
    }

    /**
     * @notice Generate background with gradient
     * @param tokenId The token ID
     * @return SVG markup for background
     *
     * IMPLEMENTATION NOTES:
     * Creates a linear gradient background that changes based on token ID.
     * Gradients make the art more visually appealing than solid colors.
     * The gradient angle and colors are derived from the token ID for uniqueness.
     */
    function generateBackground(uint256 tokenId) internal pure returns (string memory) {
        // Get two colors for the gradient
        uint256 hue1 = (tokenId * 137) % 360;  // Golden angle distribution
        uint256 hue2 = (hue1 + 180) % 360;     // Complementary color

        // Create gradient definition
        // SVG gradients are defined in <defs> section and referenced by id
        string memory gradient = string.concat(
            '<defs>',
            '<linearGradient id="bg', toString(tokenId), '" x1="0%" y1="0%" x2="100%" y2="100%">',
            '<stop offset="0%" style="stop-color:hsl(', toString(hue1), ',70%,40%);stop-opacity:1" />',
            '<stop offset="100%" style="stop-color:hsl(', toString(hue2), ',70%,60%);stop-opacity:1" />',
            '</linearGradient>',
            '</defs>'
        );

        // Apply gradient to background rectangle
        string memory rect = string.concat(
            '<rect width="400" height="400" fill="url(#bg', toString(tokenId), ')"/>'
        );

        return string.concat(gradient, rect);
    }

    /**
     * @notice Generate geometric shapes for the artwork
     * @param tokenId The token ID
     * @return SVG markup for shapes
     *
     * IMPLEMENTATION NOTES:
     * Creates multiple geometric shapes positioned and colored based on token ID.
     * Uses deterministic "randomness" from keccak256 to vary positions and sizes.
     * Shapes are layered to create depth and visual interest.
     */
    function generateShapes(uint256 tokenId) internal pure returns (string memory) {
        string memory shapes = "";

        // Determine primary shape type based on token ID
        uint256 shapeType = tokenId % 3;  // 0=circles, 1=squares, 2=triangles

        // Generate 5 shapes with varying properties
        for (uint256 i = 0; i < 5; i++) {
            // Generate pseudo-random values for this shape
            uint256 rand = getRandom(tokenId, i);

            // Extract properties from random value (each byte gives a different property)
            // This is a common technique to get multiple random values from one hash
            uint256 x = (rand % 300) + 50;           // X position: 50-350
            uint256 y = ((rand >> 8) % 300) + 50;    // Y position: 50-350
            uint256 size = ((rand >> 16) % 60) + 30; // Size: 30-90
            uint256 hue = (rand >> 24) % 360;        // Color hue: 0-360

            // Create the shape based on type
            if (shapeType == 0) {
                // Circles with semi-transparency for layering effect
                shapes = string.concat(
                    shapes,
                    '<circle cx="', toString(x),
                    '" cy="', toString(y),
                    '" r="', toString(size),
                    '" fill="hsl(', toString(hue), ',80%,60%)" opacity="0.6"/>'
                );
            } else if (shapeType == 1) {
                // Squares (rectangles) with rotation for visual interest
                shapes = string.concat(
                    shapes,
                    '<rect x="', toString(x - size / 2),
                    '" y="', toString(y - size / 2),
                    '" width="', toString(size),
                    '" height="', toString(size),
                    '" fill="hsl(', toString(hue), ',75%,55%)" opacity="0.7" ',
                    'transform="rotate(', toString((rand >> 32) % 360), ' ', toString(x), ' ', toString(y), ')"/>'
                );
            } else {
                // Triangles using polygon points
                // Calculate three points for an equilateral triangle
                shapes = string.concat(
                    shapes,
                    '<polygon points="',
                    toString(x), ',', toString(y - size), ' ',  // Top point
                    toString(x - size), ',', toString(y + size), ' ',  // Bottom left
                    toString(x + size), ',', toString(y + size),  // Bottom right
                    '" fill="hsl(', toString(hue), ',70%,50%)" opacity="0.65"/>'
                );
            }
        }

        return shapes;
    }

    /**
     * @notice Generate pattern overlay
     * @param tokenId The token ID
     * @return SVG markup for pattern
     *
     * IMPLEMENTATION NOTES:
     * Adds a subtle pattern over the shapes to create texture.
     * Uses small circles in a grid pattern with varying opacity.
     * The pattern density and style vary based on token ID.
     */
    function generatePattern(uint256 tokenId) internal pure returns (string memory) {
        string memory pattern = "";

        // Pattern type based on token ID
        uint256 patternType = (tokenId >> 4) % 3;

        if (patternType == 0) {
            // Dot pattern - small circles in a grid
            for (uint256 i = 0; i < 8; i++) {
                for (uint256 j = 0; j < 8; j++) {
                    uint256 x = i * 50 + 25;
                    uint256 y = j * 50 + 25;
                    pattern = string.concat(
                        pattern,
                        '<circle cx="', toString(x),
                        '" cy="', toString(y),
                        '" r="2" fill="white" opacity="0.3"/>'
                    );
                }
            }
        } else if (patternType == 1) {
            // Line pattern - horizontal lines
            for (uint256 i = 0; i < 20; i++) {
                uint256 y = i * 20;
                pattern = string.concat(
                    pattern,
                    '<line x1="0" y1="', toString(y),
                    '" x2="400" y2="', toString(y),
                    '" stroke="white" stroke-width="1" opacity="0.2"/>'
                );
            }
        } else {
            // Ring pattern - concentric circles
            for (uint256 i = 1; i <= 5; i++) {
                uint256 r = i * 40;
                pattern = string.concat(
                    pattern,
                    '<circle cx="200" cy="200" r="', toString(r),
                    '" fill="none" stroke="white" stroke-width="1" opacity="0.25"/>'
                );
            }
        }

        return pattern;
    }

    // =============================================================
    //                      HELPER FUNCTIONS
    // =============================================================

    /**
     * @notice Get a color for the token (HSL format)
     * @param tokenId The token ID
     * @return Color string in HSL format
     *
     * IMPLEMENTATION NOTES:
     * Uses the golden angle (approximately 137.5 degrees) for color distribution.
     * This creates visually pleasing color variety across the collection.
     * The golden angle is derived from the golden ratio and ensures colors
     * are spread evenly around the color wheel without obvious patterns.
     */
    function getColor(uint256 tokenId) public pure returns (string memory) {
        // Golden angle distribution: 137 degrees
        // This ensures colors are well-distributed across the spectrum
        uint256 hue = (tokenId * 137) % 360;

        // Return HSL color: hsl(hue, saturation%, lightness%)
        // 70% saturation and 50% lightness create vibrant, balanced colors
        return string.concat('hsl(', toString(hue), ',70%,50%)');
    }

    /**
     * @notice Get a human-readable color name for metadata
     * @param tokenId The token ID
     * @return Color name string
     *
     * IMPLEMENTATION NOTES:
     * Converts the numeric hue to a color name for better readability
     * in marketplace trait displays. Maps hue ranges to color names.
     */
    function getColorName(uint256 tokenId) public pure returns (string memory) {
        uint256 hue = (tokenId * 137) % 360;

        // Map hue ranges to color names
        if (hue < 30) return "Red";
        if (hue < 60) return "Orange";
        if (hue < 90) return "Yellow";
        if (hue < 150) return "Green";
        if (hue < 210) return "Cyan";
        if (hue < 270) return "Blue";
        if (hue < 330) return "Purple";
        return "Magenta";
    }

    /**
     * @notice Get the background color for a token
     * @param tokenId The token ID
     * @return Background color string
     *
     * IMPLEMENTATION NOTES:
     * Background uses complementary color (opposite on color wheel)
     * for visual contrast with foreground elements.
     */
    function getBackgroundColor(uint256 tokenId) public pure returns (string memory) {
        // Complementary color is 180 degrees opposite on the color wheel
        uint256 hue = (tokenId * 137 + 180) % 360;
        return string.concat('hsl(', toString(hue), ',60%,30%)');
    }

    /**
     * @notice Get the shape type for a token
     * @param tokenId The token ID
     * @return Shape name
     *
     * IMPLEMENTATION NOTES:
     * Uses modulo to cycle through three shape types.
     * This creates variety across the collection while keeping
     * the distribution even.
     */
    function getShape(uint256 tokenId) public pure returns (string memory) {
        uint256 shapeType = tokenId % 3;

        if (shapeType == 0) return "Circles";
        if (shapeType == 1) return "Squares";
        return "Triangles";
    }

    /**
     * @notice Get the pattern type for a token
     * @param tokenId The token ID
     * @return Pattern name
     *
     * IMPLEMENTATION NOTES:
     * Uses a different bit shift to create pattern variety
     * independent of shape selection. This increases overall
     * trait combinations.
     */
    function getPattern(uint256 tokenId) public pure returns (string memory) {
        uint256 patternType = (tokenId >> 4) % 3;

        if (patternType == 0) return "Dots";
        if (patternType == 1) return "Lines";
        return "Rings";
    }

    /**
     * @notice Get complexity score for a token
     * @param tokenId The token ID
     * @return Complexity score 0-100
     *
     * IMPLEMENTATION NOTES:
     * Calculates a complexity score based on various token properties.
     * This creates a numeric trait that marketplaces can display
     * with a progress bar.
     */
    function getComplexity(uint256 tokenId) public pure returns (uint256) {
        // Combine multiple factors to create complexity score
        uint256 colorVariance = (tokenId * 137) % 40;  // 0-40 points
        uint256 shapeBonus = (tokenId % 3) * 20;       // 0-40 points
        uint256 patternBonus = ((tokenId >> 4) % 3) * 10;  // 0-20 points

        return colorVariance + shapeBonus + patternBonus;
    }

    /**
     * @notice Generate a pseudo-random number from token ID
     * @param tokenId The token ID
     * @param seed Additional seed for variation
     * @return Pseudo-random uint256
     *
     * IMPLEMENTATION NOTES:
     * Creates deterministic "randomness" using keccak256 hash.
     * This is NOT cryptographically secure randomness, but it's
     * perfect for generative art because:
     * 1. It's deterministic (same inputs = same output)
     * 2. It appears random enough for visual variety
     * 3. It's gas-efficient
     *
     * IMPORTANT: This is DETERMINISTIC, not random! The same tokenId
     * and seed will always produce the same result, which is exactly
     * what we want for NFT artwork.
     */
    function getRandom(uint256 tokenId, uint256 seed) public pure returns (uint256) {
        // Hash the token ID and seed together
        // This creates a pseudo-random uint256 that appears random
        // but is completely deterministic and reproducible
        return uint256(keccak256(abi.encodePacked(tokenId, seed)));
    }

    /**
     * @notice Convert uint256 to string
     * @param value The number to convert
     * @return String representation of the number
     *
     * IMPLEMENTATION NOTES:
     * Converts a number to its string representation by:
     * 1. Determining the length (number of digits)
     * 2. Allocating a bytes buffer of that length
     * 3. Filling the buffer from right to left with digits
     * 4. Converting bytes to string
     *
     * This is necessary because Solidity doesn't have built-in
     * number-to-string conversion.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Handle zero case separately
        if (value == 0) {
            return "0";
        }

        // Count digits to determine buffer size
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        // Allocate buffer for the string
        bytes memory buffer = new bytes(digits);

        // Fill buffer from right to left with ASCII digits
        while (value != 0) {
            digits -= 1;
            // Convert digit to ASCII ('0' = 48 in ASCII)
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }
}

/**
 * @title Base64
 * @notice Provides Base64 encoding functionality
 * @dev Implements standard Base64 encoding for on-chain data
 *
 * ALGORITHM EXPLANATION:
 *
 * Base64 encoding converts binary data into ASCII text by:
 * 1. Taking 3 bytes (24 bits) of input at a time
 * 2. Splitting those 24 bits into 4 groups of 6 bits each
 * 3. Mapping each 6-bit value (0-63) to a Base64 character
 * 4. Using '=' for padding when input isn't divisible by 3
 *
 * Example:
 * Input:  "Man" = [77, 97, 110] = [01001101, 01100001, 01101110]
 * Binary: 010011 010110 000101 101110
 * Decimal: [19, 22, 5, 46]
 * Output: "TWFu" (from TABLE[19], TABLE[22], TABLE[5], TABLE[46])
 *
 * The alphabet is: A-Z (0-25), a-z (26-51), 0-9 (52-61), + (62), / (63)
 */
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @notice Encode bytes to base64 string
     * @param data Bytes to encode
     * @return Base64 encoded string
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        // Empty input returns empty output
        if (data.length == 0) return "";

        // Load the table into memory for efficient access
        // This is more gas efficient than accessing storage repeatedly
        string memory table = TABLE;

        // Calculate encoded length
        // Base64 produces 4 characters for every 3 bytes of input
        // Formula: ceil(input_length / 3) * 4
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // Allocate output buffer
        // Add 32 bytes for the length prefix that Solidity strings have
        string memory result = new string(encodedLen + 32);

        /// @solidity memory-safe-assembly
        assembly {
            // Store the table in memory for lookups
            let tablePtr := add(table, 1)

            // Set up pointers:
            // - resultPtr: where we write output
            // - dataPtr: where we read input
            // - endPtr: when to stop (input end - 2 bytes for lookahead)
            let resultPtr := add(result, 32)  // Skip length prefix
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))  // End of input

            // Main encoding loop: process 3 bytes at a time
            // We stop 2 bytes before the end to handle padding separately
            for {} lt(dataPtr, sub(endPtr, 2)) {} {
                dataPtr := add(dataPtr, 3)  // Advance input pointer

                // Read 3 bytes (24 bits) from input
                let input := mload(dataPtr)

                // Split 24 bits into four 6-bit values and encode each
                // Each mstore8 writes one byte to output

                // Bits 23-18 (first 6 bits)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)

                // Bits 17-12 (second 6 bits)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)

                // Bits 11-6 (third 6 bits)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)

                // Bits 5-0 (fourth 6 bits)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // Handle remaining bytes (padding)
            // Base64 requires padding with '=' when input isn't divisible by 3
            switch mod(mload(data), 3)
            case 1 {
                // 1 byte remaining: encode to 2 characters + 2 padding '='
                dataPtr := add(dataPtr, 1)
                let input := mload(dataPtr)

                // First 6 bits
                mstore8(resultPtr, mload(add(tablePtr, and(shr(2, input), 0x3F))))
                resultPtr := add(resultPtr, 1)

                // Last 2 bits shifted left to make 6 bits
                mstore8(resultPtr, mload(add(tablePtr, and(shl(4, input), 0x3F))))
                resultPtr := add(resultPtr, 1)

                // Two padding characters
                mstore8(resultPtr, 0x3d)  // '='
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, 0x3d)  // '='
                resultPtr := add(resultPtr, 1)
            }
            case 2 {
                // 2 bytes remaining: encode to 3 characters + 1 padding '='
                dataPtr := add(dataPtr, 2)
                let input := mload(dataPtr)

                // First 6 bits
                mstore8(resultPtr, mload(add(tablePtr, and(shr(10, input), 0x3F))))
                resultPtr := add(resultPtr, 1)

                // Second 6 bits
                mstore8(resultPtr, mload(add(tablePtr, and(shr(4, input), 0x3F))))
                resultPtr := add(resultPtr, 1)

                // Last 4 bits shifted left to make 6 bits
                mstore8(resultPtr, mload(add(tablePtr, and(shl(2, input), 0x3F))))
                resultPtr := add(resultPtr, 1)

                // One padding character
                mstore8(resultPtr, 0x3d)  // '='
                resultPtr := add(resultPtr, 1)
            }

            // Update result length
            // The first 32 bytes of a string store its length
            mstore(result, encodedLen)
        }

        return result;
    }
}

/*
 * DETAILED IMPLEMENTATION NOTES:
 *
 * 1. ON-CHAIN STORAGE:
 *    - Everything is stored in contract bytecode and computed on-demand
 *    - No external calls or storage reads needed for metadata
 *    - This makes the NFT truly permanent and decentralized
 *
 * 2. GAS OPTIMIZATION:
 *    - Constants stored in bytecode, not storage
 *    - Functions marked as pure/view to avoid state changes
 *    - String concatenation uses string.concat() (gas efficient)
 *    - Base64 encoding uses assembly for efficiency
 *
 * 3. DETERMINISTIC GENERATION:
 *    - Same token ID always produces same artwork
 *    - Uses keccak256 for pseudo-randomness (deterministic)
 *    - No dependence on block properties (except in special cases)
 *
 * 4. SVG BEST PRACTICES:
 *    - Valid XML syntax
 *    - Proper namespace declaration
 *    - ViewBox for responsiveness
 *    - Layered composition (background -> shapes -> pattern -> text)
 *
 * 5. METADATA STANDARDS:
 *    - Follows ERC721 metadata standard
 *    - Compatible with OpenSea and other marketplaces
 *    - Includes name, description, image, and attributes
 *    - Uses data URIs for complete on-chain storage
 *
 * 6. COLOR THEORY:
 *    - Golden angle (137°) for color distribution
 *    - HSL color space for easy manipulation
 *    - Complementary colors for contrast
 *    - Consistent saturation and lightness
 *
 * 7. GENERATIVE ART TECHNIQUES:
 *    - Pseudo-random positioning from hash
 *    - Multiple layers for depth
 *    - Variation through modulo operations
 *    - Combination of deterministic and derived properties
 *
 * 8. BASE64 ENCODING:
 *    - Standard Base64 algorithm
 *    - Handles padding correctly
 *    - Uses assembly for gas efficiency
 *    - Tested and production-ready
 */
