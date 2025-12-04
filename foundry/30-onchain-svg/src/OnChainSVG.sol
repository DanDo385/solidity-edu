// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Project30 - On-Chain SVG NFT
 * @notice A fully on-chain NFT with dynamically generated SVG artwork
 * @dev All metadata and artwork are stored on-chain, making it truly permanent
 *
 * Learning Objectives:
 * 1. Generate SVG images programmatically in Solidity
 * 2. Implement Base64 encoding for data URIs
 * 3. Create dynamic NFT attributes based on token ID
 * 4. Build proper JSON metadata
 * 5. Optimize gas costs for on-chain storage
 */
contract Project30 is ERC721, Ownable {
    // =============================================================
    //                           STORAGE
    // =============================================================

    uint256 private _nextTokenId;
    uint256 public maxSupply = 1000;

    // SVG constants (stored in bytecode, not storage - gas efficient!)
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
     * TODO: Implement this function
     * 1. Generate the SVG using generateSVG()
     * 2. Build JSON metadata with name, description, image, and attributes
     * 3. Base64 encode the JSON
     * 4. Return as data URI: "data:application/json;base64,..."
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        // TODO: Generate SVG
        string memory svg = generateSVG(tokenId);

        // TODO: Build JSON metadata
        // Include: name, description, image (base64 encoded SVG), attributes

        // TODO: Base64 encode the JSON

        // TODO: Return data URI
        return "";
    }

    /**
     * @notice Generates the complete SVG for a token
     * @param tokenId The token ID to generate SVG for
     * @return Complete SVG markup as a string
     *
     * TODO: Implement SVG generation
     * 1. Create a background with dynamic color
     * 2. Add geometric shapes (circles, rectangles, etc.)
     * 3. Add text showing the token ID
     * 4. Make it visually interesting!
     */
    function generateSVG(uint256 tokenId) public pure returns (string memory) {
        // TODO: Generate background color based on tokenId

        // TODO: Generate shapes/patterns based on tokenId

        // TODO: Add token ID text

        // TODO: Combine all parts into complete SVG
        return string.concat(
            SVG_HEADER,
            // Your SVG elements here
            SVG_FOOTER
        );
    }

    // =============================================================
    //                      HELPER FUNCTIONS
    // =============================================================

    /**
     * @notice Get a color for the token (HSL format)
     * @param tokenId The token ID
     * @return Color string in HSL format
     *
     * TODO: Implement color generation
     * Use the golden angle (137 degrees) for pleasing color distribution
     * Return format: "hsl(HUE, 70%, 50%)"
     */
    function getColor(uint256 tokenId) public pure returns (string memory) {
        // TODO: Calculate hue using golden angle distribution
        // Hint: (tokenId * 137) % 360

        // TODO: Return HSL color string
        return "";
    }

    /**
     * @notice Get the background color for a token
     * @param tokenId The token ID
     * @return Background color string
     */
    function getBackgroundColor(uint256 tokenId) public pure returns (string memory) {
        // TODO: Implement background color
        // Could be different from main color or same
        return "";
    }

    /**
     * @notice Get the shape type for a token
     * @param tokenId The token ID
     * @return Shape name ("circle", "square", "triangle", etc.)
     */
    function getShape(uint256 tokenId) public pure returns (string memory) {
        // TODO: Determine shape based on tokenId
        // Use modulo to cycle through different shapes
        return "";
    }

    /**
     * @notice Get the pattern type for a token
     * @param tokenId The token ID
     * @return Pattern name
     */
    function getPattern(uint256 tokenId) public pure returns (string memory) {
        // TODO: Determine pattern based on tokenId
        return "";
    }

    /**
     * @notice Generate a pseudo-random number from token ID
     * @param tokenId The token ID
     * @param seed Additional seed for variation
     * @return Pseudo-random uint256
     */
    function getRandom(uint256 tokenId, uint256 seed) public pure returns (uint256) {
        // TODO: Implement deterministic randomness
        // Hint: Use keccak256(abi.encodePacked(tokenId, seed))
        return 0;
    }

    /**
     * @notice Convert uint256 to string
     * @param value The number to convert
     * @return String representation of the number
     *
     * TODO: Implement number to string conversion
     * This is essential for building SVG and JSON
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        // TODO: Implement conversion
        // Hint: Repeatedly divide by 10 and collect digits
        return "";
    }

    // =============================================================
    //                      BASE64 ENCODING
    // =============================================================

    /**
     * @notice Base64 encode bytes data
     * @param data The bytes to encode
     * @return Base64 encoded string
     *
     * TODO: Implement Base64 encoding
     * Base64 converts 3 bytes (24 bits) into 4 base64 characters (6 bits each)
     * Use the standard Base64 alphabet: A-Z, a-z, 0-9, +, /
     * Pad with '=' if data length is not divisible by 3
     */
    function base64Encode(bytes memory data) internal pure returns (string memory) {
        // TODO: Implement Base64 encoding
        // This is complex! See the solution for detailed implementation
        return "";
    }
}

/**
 * @title Base64
 * @notice Provides Base64 encoding functionality
 * @dev Implement this library for encoding SVG and JSON data
 *
 * TODO: Complete the Base64 encoding implementation
 */
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @notice Encode bytes to base64 string
     * @param data Bytes to encode
     * @return Base64 encoded string
     *
     * Algorithm:
     * 1. Take 3 bytes (24 bits) at a time
     * 2. Split into 4 groups of 6 bits
     * 3. Map each 6-bit value to base64 character
     * 4. Handle padding for data not divisible by 3
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // TODO: Calculate encoded length
        // Formula: ((data.length + 2) / 3) * 4

        // TODO: Allocate result string

        // TODO: Encode each 3-byte group into 4 base64 characters

        // TODO: Handle padding if needed

        return "";
    }
}

/*
 * HINTS AND TIPS:
 *
 * 1. SVG Generation:
 *    - Start simple with a solid background
 *    - Add shapes one at a time
 *    - Use string.concat() to build the SVG
 *    - Test in browser by creating a data URI
 *
 * 2. Base64 Encoding:
 *    - This is the trickiest part!
 *    - Study the algorithm carefully
 *    - Use bitwise operations: &, |, >>
 *    - Remember to handle padding
 *
 * 3. Colors:
 *    - HSL format is easiest: hsl(hue, saturation%, lightness%)
 *    - Hue: 0-360 (0=red, 120=green, 240=blue)
 *    - Use golden angle (137°) for distribution
 *
 * 4. JSON Metadata:
 *    - Must be valid JSON (use online validator)
 *    - Escape quotes inside strings if needed
 *    - Include attributes array for traits
 *
 * 5. Testing:
 *    - Test each function individually
 *    - Copy tokenURI output to browser to see result
 *    - Verify JSON is valid
 *    - Check SVG renders correctly
 *
 * 6. Gas Optimization:
 *    - Use string.concat() for concatenation
 *    - Mark functions as pure/view when possible
 *    - Store constants, not in storage
 *    - Minimize state reads
 */
