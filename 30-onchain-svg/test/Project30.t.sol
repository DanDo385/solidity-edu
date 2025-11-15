// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/Project30Solution.sol";

/**
 * @title Project30Test
 * @notice Comprehensive tests for on-chain SVG NFT
 * @dev Tests SVG generation, Base64 encoding, metadata, and attributes
 */
contract Project30Test is Test {
    Project30Solution public nft;
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);

    // Events to test
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function setUp() public {
        vm.prank(owner);
        nft = new Project30Solution();
    }

    // =============================================================
    //                      BASIC MINTING TESTS
    // =============================================================

    function testMint() public {
        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), user1, 0);
        nft.mint();

        assertEq(nft.ownerOf(0), user1);
        assertEq(nft.balanceOf(user1), 1);
    }

    function testMultipleMints() public {
        vm.prank(user1);
        nft.mint();

        vm.prank(user2);
        nft.mint();

        vm.prank(user1);
        nft.mint();

        assertEq(nft.ownerOf(0), user1);
        assertEq(nft.ownerOf(1), user2);
        assertEq(nft.ownerOf(2), user1);
        assertEq(nft.balanceOf(user1), 2);
        assertEq(nft.balanceOf(user2), 1);
    }

    function testCannotMintBeyondMaxSupply() public {
        // Set up: mint max supply
        vm.startPrank(user1);
        uint256 maxSupply = nft.maxSupply();
        for (uint256 i = 0; i < maxSupply; i++) {
            nft.mint();
        }
        vm.stopPrank();

        // Should revert when trying to mint one more
        vm.prank(user1);
        vm.expectRevert("Max supply reached");
        nft.mint();
    }

    // =============================================================
    //                      SVG GENERATION TESTS
    // =============================================================

    function testSVGGeneration() public {
        string memory svg = nft.generateSVG(0);

        // Check SVG has proper structure
        assertTrue(bytes(svg).length > 0, "SVG should not be empty");

        // Convert to lowercase for comparison (Solidity strings are case-sensitive)
        bytes memory svgBytes = bytes(svg);

        // Check for SVG opening tag
        assertTrue(contains(svg, '<svg'), "SVG should contain opening tag");
        assertTrue(contains(svg, '</svg>'), "SVG should contain closing tag");
        assertTrue(contains(svg, 'xmlns'), "SVG should have namespace");
        assertTrue(contains(svg, 'viewBox'), "SVG should have viewBox");
    }

    function testSVGContainsExpectedElements() public {
        string memory svg = nft.generateSVG(1);

        // Should contain gradient definition
        assertTrue(contains(svg, '<defs>'), "SVG should contain defs");
        assertTrue(contains(svg, 'linearGradient'), "SVG should contain gradient");

        // Should contain shapes (at least one type)
        bool hasCircle = contains(svg, '<circle');
        bool hasRect = contains(svg, '<rect');
        bool hasPolygon = contains(svg, '<polygon');
        assertTrue(hasCircle || hasRect || hasPolygon, "SVG should contain shapes");

        // Should contain token ID text
        assertTrue(contains(svg, '<text'), "SVG should contain text");
    }

    function testDifferentTokensGenerateDifferentSVGs() public {
        string memory svg0 = nft.generateSVG(0);
        string memory svg1 = nft.generateSVG(1);
        string memory svg100 = nft.generateSVG(100);

        // Different tokens should produce different SVGs
        assertFalse(equal(svg0, svg1), "Token 0 and 1 should have different SVGs");
        assertFalse(equal(svg0, svg100), "Token 0 and 100 should have different SVGs");
        assertFalse(equal(svg1, svg100), "Token 1 and 100 should have different SVGs");
    }

    function testSVGIsDeterministic() public {
        // Same token ID should always produce the same SVG
        string memory svg1 = nft.generateSVG(42);
        string memory svg2 = nft.generateSVG(42);

        assertTrue(equal(svg1, svg2), "Same token ID should produce identical SVG");
    }

    // =============================================================
    //                      BASE64 ENCODING TESTS
    // =============================================================

    function testBase64EncodeEmpty() public {
        bytes memory empty = "";
        string memory encoded = Base64.encode(empty);
        assertEq(encoded, "", "Empty bytes should encode to empty string");
    }

    function testBase64EncodeSimple() public {
        // Test known Base64 encodings
        // "Man" encodes to "TWFu"
        bytes memory data = "Man";
        string memory encoded = Base64.encode(data);
        assertEq(encoded, "TWFu", "Man should encode to TWFu");
    }

    function testBase64EncodePadding1() public {
        // "Ma" encodes to "TWE=" (needs 1 padding character)
        bytes memory data = "Ma";
        string memory encoded = Base64.encode(data);
        assertEq(encoded, "TWE=", "Ma should encode to TWE=");
    }

    function testBase64EncodePadding2() public {
        // "M" encodes to "TQ==" (needs 2 padding characters)
        bytes memory data = "M";
        string memory encoded = Base64.encode(data);
        assertEq(encoded, "TQ==", "M should encode to TQ==");
    }

    function testBase64EncodeLonger() public {
        // Test longer string
        bytes memory data = "Hello, World!";
        string memory encoded = Base64.encode(data);
        assertEq(encoded, "SGVsbG8sIFdvcmxkIQ==", "Hello, World! encoding incorrect");
    }

    function testBase64EncodeSVG() public {
        // Test encoding actual SVG
        bytes memory svg = '<svg xmlns="http://www.w3.org/2000/svg"><circle r="50"/></svg>';
        string memory encoded = Base64.encode(svg);

        // Should not be empty and should not contain invalid characters
        assertTrue(bytes(encoded).length > 0, "Encoded SVG should not be empty");
        assertFalse(contains(encoded, " "), "Base64 should not contain spaces");
        assertFalse(contains(encoded, "\n"), "Base64 should not contain newlines");
    }

    function testBase64EncodeJSON() public {
        // Test encoding JSON metadata
        bytes memory json = '{"name":"Test","image":"data:image/svg+xml;base64,ABC"}';
        string memory encoded = Base64.encode(json);

        assertTrue(bytes(encoded).length > 0, "Encoded JSON should not be empty");
    }

    // =============================================================
    //                      TOKEN URI TESTS
    // =============================================================

    function testTokenURIExists() public {
        vm.prank(user1);
        nft.mint();

        string memory uri = nft.tokenURI(0);
        assertTrue(bytes(uri).length > 0, "Token URI should not be empty");
    }

    function testTokenURIFormat() public {
        vm.prank(user1);
        nft.mint();

        string memory uri = nft.tokenURI(0);

        // Should be a data URI
        assertTrue(startsWith(uri, "data:application/json;base64,"), "Token URI should be JSON data URI");
    }

    function testTokenURIContainsMetadata() public {
        vm.prank(user1);
        nft.mint();

        string memory uri = nft.tokenURI(0);

        // Decode the base64 (manual check - in production you'd use a decoder)
        // For now, just verify structure
        assertTrue(contains(uri, "base64"), "URI should contain base64");
    }

    function testTokenURIForNonexistentToken() public {
        // Should revert for non-existent token
        vm.expectRevert();
        nft.tokenURI(999);
    }

    function testDifferentTokensHaveDifferentURIs() public {
        vm.prank(user1);
        nft.mint();
        nft.mint();
        nft.mint();

        string memory uri0 = nft.tokenURI(0);
        string memory uri1 = nft.tokenURI(1);
        string memory uri2 = nft.tokenURI(2);

        assertFalse(equal(uri0, uri1), "Token 0 and 1 should have different URIs");
        assertFalse(equal(uri1, uri2), "Token 1 and 2 should have different URIs");
        assertFalse(equal(uri0, uri2), "Token 0 and 2 should have different URIs");
    }

    // =============================================================
    //                      ATTRIBUTE TESTS
    // =============================================================

    function testGetColor() public {
        // Test color generation
        string memory color0 = nft.getColor(0);
        string memory color1 = nft.getColor(1);
        string memory color100 = nft.getColor(100);

        // Should return HSL format
        assertTrue(startsWith(color0, "hsl("), "Color should be in HSL format");
        assertTrue(contains(color0, "%"), "Color should contain percentage");

        // Different tokens should have different colors (usually)
        // Note: Due to modulo, some might be the same, but generally different
    }

    function testGetColorName() public {
        // Test color name generation
        string memory name0 = nft.getColorName(0);
        string memory name1 = nft.getColorName(1);

        assertTrue(bytes(name0).length > 0, "Color name should not be empty");
        assertTrue(bytes(name1).length > 0, "Color name should not be empty");

        // Verify it's one of the expected color names
        bool validColor =
            equal(name0, "Red") ||
            equal(name0, "Orange") ||
            equal(name0, "Yellow") ||
            equal(name0, "Green") ||
            equal(name0, "Cyan") ||
            equal(name0, "Blue") ||
            equal(name0, "Purple") ||
            equal(name0, "Magenta");

        assertTrue(validColor, "Should return valid color name");
    }

    function testGetShape() public {
        string memory shape0 = nft.getShape(0);
        string memory shape1 = nft.getShape(1);
        string memory shape2 = nft.getShape(2);

        // Should cycle through shapes
        assertTrue(
            equal(shape0, "Circles") ||
            equal(shape0, "Squares") ||
            equal(shape0, "Triangles"),
            "Should return valid shape"
        );

        // Tokens 0, 1, 2 should have different shapes
        assertFalse(equal(shape0, shape1), "Shape 0 and 1 should differ");
        assertFalse(equal(shape1, shape2), "Shape 1 and 2 should differ");
    }

    function testGetPattern() public {
        string memory pattern = nft.getPattern(0);

        assertTrue(
            equal(pattern, "Dots") ||
            equal(pattern, "Lines") ||
            equal(pattern, "Rings"),
            "Should return valid pattern"
        );
    }

    function testGetComplexity() public {
        uint256 complexity0 = nft.getComplexity(0);
        uint256 complexity1 = nft.getComplexity(1);

        // Should be between 0 and 100
        assertTrue(complexity0 <= 100, "Complexity should be <= 100");
        assertTrue(complexity1 <= 100, "Complexity should be <= 100");
    }

    function testGetBackgroundColor() public {
        string memory bgColor = nft.getBackgroundColor(0);

        assertTrue(startsWith(bgColor, "hsl("), "Background color should be HSL");
        assertTrue(bytes(bgColor).length > 0, "Background color should not be empty");
    }

    // =============================================================
    //                      RANDOMNESS TESTS
    // =============================================================

    function testGetRandomIsDeterministic() public {
        // Same inputs should produce same output
        uint256 rand1 = nft.getRandom(42, 1);
        uint256 rand2 = nft.getRandom(42, 1);

        assertEq(rand1, rand2, "Same inputs should produce same random value");
    }

    function testGetRandomDifferentSeeds() public {
        // Different seeds should produce different outputs
        uint256 rand1 = nft.getRandom(42, 1);
        uint256 rand2 = nft.getRandom(42, 2);

        assertFalse(rand1 == rand2, "Different seeds should produce different values");
    }

    function testGetRandomDifferentTokenIds() public {
        // Different token IDs should produce different outputs
        uint256 rand1 = nft.getRandom(1, 1);
        uint256 rand2 = nft.getRandom(2, 1);

        assertFalse(rand1 == rand2, "Different token IDs should produce different values");
    }

    // =============================================================
    //                      EDGE CASES
    // =============================================================

    function testTokenZero() public {
        vm.prank(user1);
        nft.mint();

        // Token 0 should work correctly
        string memory svg = nft.generateSVG(0);
        string memory uri = nft.tokenURI(0);

        assertTrue(bytes(svg).length > 0, "Token 0 should have valid SVG");
        assertTrue(bytes(uri).length > 0, "Token 0 should have valid URI");
    }

    function testLargeTokenId() public {
        // Test with large token ID values (as pure functions)
        string memory svg = nft.generateSVG(999);
        string memory color = nft.getColor(999);

        assertTrue(bytes(svg).length > 0, "Large token ID should have valid SVG");
        assertTrue(bytes(color).length > 0, "Large token ID should have valid color");
    }

    function testVeryLargeTokenId() public {
        // Test with very large numbers
        uint256 largeId = type(uint256).max - 1;

        string memory svg = nft.generateSVG(largeId);
        string memory color = nft.getColor(largeId);

        assertTrue(bytes(svg).length > 0, "Very large token ID should have valid SVG");
        assertTrue(bytes(color).length > 0, "Very large token ID should have valid color");
    }

    // =============================================================
    //                      GAS BENCHMARKS
    // =============================================================

    function testGasMinting() public {
        vm.prank(user1);
        uint256 gasBefore = gasleft();
        nft.mint();
        uint256 gasUsed = gasBefore - gasleft();

        // Log gas used (will appear with -vv flag)
        console.log("Gas used for minting:", gasUsed);

        // On-chain SVG minting should use reasonable gas
        // Note: This will be higher than off-chain metadata
        assertTrue(gasUsed < 2_000_000, "Minting should use reasonable gas");
    }

    function testGasTokenURI() public {
        vm.prank(user1);
        nft.mint();

        uint256 gasBefore = gasleft();
        nft.tokenURI(0);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for tokenURI:", gasUsed);

        // Reading token URI should be efficient (it's a view function)
        assertTrue(gasUsed < 5_000_000, "tokenURI should use reasonable gas");
    }

    // =============================================================
    //                      HELPER FUNCTIONS
    // =============================================================

    /**
     * @notice Check if string contains substring
     */
    function contains(string memory str, string memory substr) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory substrBytes = bytes(substr);

        if (substrBytes.length > strBytes.length) return false;
        if (substrBytes.length == 0) return true;

        bool found = false;
        for (uint256 i = 0; i <= strBytes.length - substrBytes.length; i++) {
            bool match = true;
            for (uint256 j = 0; j < substrBytes.length; j++) {
                if (strBytes[i + j] != substrBytes[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                found = true;
                break;
            }
        }
        return found;
    }

    /**
     * @notice Check if string starts with prefix
     */
    function startsWith(string memory str, string memory prefix) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory prefixBytes = bytes(prefix);

        if (prefixBytes.length > strBytes.length) return false;

        for (uint256 i = 0; i < prefixBytes.length; i++) {
            if (strBytes[i] != prefixBytes[i]) return false;
        }

        return true;
    }

    /**
     * @notice Check if two strings are equal
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

/*
 * TEST COVERAGE SUMMARY:
 *
 * 1. Basic Minting
 *    - Single mint
 *    - Multiple mints
 *    - Max supply enforcement
 *
 * 2. SVG Generation
 *    - Valid SVG structure
 *    - Expected elements (shapes, gradients, text)
 *    - Uniqueness across tokens
 *    - Deterministic generation
 *
 * 3. Base64 Encoding
 *    - Empty input
 *    - Simple strings
 *    - Padding scenarios (0, 1, 2 padding chars)
 *    - Longer strings
 *    - SVG and JSON encoding
 *
 * 4. Token URI
 *    - URI existence
 *    - Correct format (data URI)
 *    - Uniqueness
 *    - Nonexistent token handling
 *
 * 5. Attributes
 *    - Color generation
 *    - Color names
 *    - Shape types
 *    - Pattern types
 *    - Complexity scores
 *    - Background colors
 *
 * 6. Randomness
 *    - Deterministic behavior
 *    - Seed variation
 *    - Token ID variation
 *
 * 7. Edge Cases
 *    - Token 0
 *    - Large token IDs
 *    - Maximum uint256 values
 *
 * 8. Gas Benchmarks
 *    - Minting costs
 *    - tokenURI costs
 *
 * To run tests:
 *   forge test -vv                    # Run all tests with logs
 *   forge test --match-test testSVG   # Run specific test pattern
 *   forge test --gas-report           # Show gas usage report
 */
