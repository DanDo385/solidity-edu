// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ABIEncodingSolution
 * @notice Complete implementation demonstrating ABI encoding, function selectors, and security
 * @dev Educational contract showing encoding methods and their security implications
 *
 * REAL-WORLD ANALOGY: ABI encoding is like packaging data for shipping:
 * - abi.encode: Like a padded box with labels - safe but takes more space
 * - abi.encodePacked: Like cramming items tightly - efficient but can mix up items
 * - Function selectors: Like shipping labels - tell the EVM which function to call
 * 
 * Key Concepts Demonstrated:
 * 1. abi.encode vs abi.encodePacked - padding and collision risks
 * 2. Function selector calculation and usage
 * 3. Hash collision vulnerabilities
 * 4. Manual function routing with fallback
 * 5. Gas optimization with pre-computed selectors
 */
contract ABIEncodingSolution {

    // Events for demonstrating encoding behavior
    event EncodingResult(bytes data, uint256 length);
    event SelectorCalculated(bytes4 selector, string signature);
    event HashCollision(bytes32 hash1, bytes32 hash2, bool isCollision);

    /**
     * @notice Demonstrates abi.encode with padding
     * @dev abi.encode adds padding and offsets, making it unambiguous but larger
     * @param a First string to encode
     * @param b Second string to encode
     * @return Encoded bytes with ABI padding
     * 
     * GAS COST: abi.encode for dynamic types
     * - Fixed-size types: 32 bytes each (padded)
     * - Dynamic types: 32 bytes (offset) + 32 bytes (length) + padded data
     * - For two strings "hello" (5 bytes each):
     *   - Total: 32 (offset1) + 32 (offset2) + 32 (len1) + 32 (data1) + 32 (len2) + 32 (data2)
     *   - = 192 bytes total
     * - Gas: ~3 gas per byte = ~576 gas for encoding
     * 
     * TRADE-OFF:
     *   ✅ Safe from collisions (padding prevents ambiguity)
     *   ✅ Can decode back to original types
     *   ❌ Larger size (more gas)
     * 
     * REAL-WORLD ANALOGY: Like putting each item in its own labeled box
     * before shipping - safe but takes more space.
     */
    function demonstrateEncode(string memory a, string memory b) public returns (bytes memory) {
        bytes memory encoded = abi.encode(a, b);
        emit EncodingResult(encoded, encoded.length);
        return encoded;
    }

    /**
     * @notice Demonstrates abi.encodePacked without padding
     * @dev encodePacked is compact but can lead to collisions with variable-length types
     * @param a First string to encode
     * @param b Second string to encode
     * @return Tightly packed bytes without padding
     * 
     * GAS OPTIMIZATION: abi.encodePacked vs abi.encode
     * - encodePacked: Only stores actual data (no padding)
     * - For two strings "hello" (5 bytes each): 10 bytes total
     * - encode: 192 bytes (as shown above)
     * - Savings: ~182 bytes = ~546 gas per encoding!
     * 
     * SECURITY WARNING: Collision risk!
     * - encodePacked("A", "BC") == encodePacked("AB", "C")
     * - Both produce identical bytes: "ABC"
     * - NEVER use for signatures or critical hashing!
     * 
     * WHEN TO USE encodePacked:
     * - Single variable-length argument: Safe
     * - Multiple fixed-size arguments: Safe
     * - Multiple variable-length arguments: DANGEROUS!
     * 
     * REAL-WORLD ANALOGY: Like cramming items into one box without dividers -
     * efficient but items can get mixed up if boundaries aren't clear.
     */
    function demonstrateEncodePacked(string memory a, string memory b) public returns (bytes memory) {
        bytes memory packed = abi.encodePacked(a, b);
        emit EncodingResult(packed, packed.length);
        return packed;
    }

    /**
     * @notice Demonstrates hash collision vulnerability with encodePacked
     * @dev Shows that encodePacked("A", "BC") == encodePacked("AB", "C")
     * @return true if collision detected (which it will be!)
     *
     * SECURITY WARNING: This is why you should never use encodePacked
     * with multiple variable-length arguments for signatures or critical hashing!
     */
    function demonstrateHashCollision() public returns (bool) {
        // These produce IDENTICAL hashes - a critical vulnerability!
        bytes32 hash1 = keccak256(abi.encodePacked("A", "BC"));
        bytes32 hash2 = keccak256(abi.encodePacked("AB", "C"));

        bool isCollision = (hash1 == hash2);
        emit HashCollision(hash1, hash2, isCollision);

        return isCollision; // Will return true!
    }

    /**
     * @notice Demonstrates safe hashing with abi.encode
     * @dev abi.encode prevents collisions by adding padding and offsets
     * @return false - hashes are different (safe!)
     */
    function demonstrateSafeHashing() public returns (bool) {
        // abi.encode adds padding, preventing collisions
        bytes32 hash1 = keccak256(abi.encode("A", "BC"));
        bytes32 hash2 = keccak256(abi.encode("AB", "C"));

        bool isCollision = (hash1 == hash2);
        emit HashCollision(hash1, hash2, isCollision);

        return isCollision; // Will return false - safe!
    }

    /**
     * @notice Calculates the function selector for ERC20 transfer
     * @dev Selector is first 4 bytes of keccak256(signature)
     * @return The function selector (0xa9059cbb for transfer)
     *
     * Function selectors are used by the EVM to route calls to the correct function
     */
    function getTransferSelector() public pure returns (bytes4) {
        // Standard ERC20 transfer selector
        return bytes4(keccak256("transfer(address,uint256)"));
        // Returns: 0xa9059cbb
    }

    /**
     * @notice Calculates selector for any function signature
     * @dev Generic selector calculator for learning purposes
     * @param signature Function signature string (e.g., "transfer(address,uint256)")
     * @return 4-byte function selector
     */
    function calculateSelector(string memory signature) public returns (bytes4) {
        bytes4 selector = bytes4(keccak256(bytes(signature)));
        emit SelectorCalculated(selector, signature);
        return selector;
    }

    /**
     * @notice Encodes a transfer call using encodeWithSignature
     * @dev Creates the complete calldata for a transfer function call
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return Complete encoded function call data
     */
    function encodeTransferCall(address to, uint256 amount) public pure returns (bytes memory) {
        // Encodes: selector + ABI-encoded parameters
        return abi.encodeWithSignature("transfer(address,uint256)", to, amount);
    }

    /**
     * @notice Encodes using pre-computed selector (gas optimization)
     * @dev More efficient than encodeWithSignature as selector is pre-computed
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return Encoded function call data
     *
     * GAS OPTIMIZATION: Pre-computed selector vs encodeWithSignature
     * - encodeWithSignature("transfer(address,uint256)", ...):
     *   Costs: keccak256("transfer(address,uint256)") = ~30 gas + encoding
     * - encodeWithSelector(0xa9059cbb, ...):
     *   Costs: Just encoding (no hash calculation)
     * - Savings: ~30 gas per call
     * 
     * GAS COST BREAKDOWN:
     * - encodeWithSignature: ~30 (hash) + ~200 (encoding) = ~230 gas
     * - encodeWithSelector: ~200 (encoding only) = ~200 gas
     * - Savings: ~30 gas (13% reduction)
     * 
     * WHEN TO USE:
     * - encodeWithSelector: When selector is known (common functions)
     * - encodeWithSignature: When selector is dynamic or unknown
     * 
     * REAL-WORLD ANALOGY: Like using a pre-printed shipping label instead
     * of writing it out each time - faster and cheaper.
     * 
     * LANGUAGE COMPARISON:
     *   TypeScript: Function references (like pre-computed selectors)
     *   Go: Function pointers (similar concept)
     *   Rust: Function pointers or closures
     *   Solidity: Selectors are like function pointers but encoded as bytes4
     */
    function encodeWithSelector(address to, uint256 amount) public pure returns (bytes memory) {
        // Gas efficient: use pre-computed selector
        bytes4 selector = 0xa9059cbb; // transfer(address,uint256)
        return abi.encodeWithSelector(selector, to, amount);
    }

    // Storage for manual routing demonstration
    mapping(bytes4 => bool) public allowedSelectors;
    uint256 public value;

    /**
     * @notice Registers a function selector as allowed
     * @dev Used with fallback function for manual routing
     * @param signature Function signature to allow
     *
     * Example: registerSelector("setValue(uint256)") allows that function
     */
    function registerSelector(string memory signature) public {
        bytes4 selector = bytes4(keccak256(bytes(signature)));
        allowedSelectors[selector] = true;
    }

    /**
     * @notice Manual function routing using fallback
     * @dev Demonstrates how contracts dispatch calls using selectors
     *
     * SECURITY NOTE: In production, always validate selectors carefully!
     * This is a simplified example for educational purposes.
     *
     * The fallback extracts the 4-byte selector and checks if it's allowed.
     */
    fallback() external payable {
        // Extract function selector from calldata
        bytes4 selector = msg.sig; // Equivalent to bytes4(msg.data)

        // Require the selector is registered
        require(allowedSelectors[selector], "Selector not allowed");

        // For demonstration: set a value
        value = 123;

        // In a real proxy, you would:
        // (bool success, ) = implementation.delegatecall(msg.data);
        // require(success, "Call failed");
    }

    /**
     * @notice Compares encoding sizes for different types
     * @dev Shows how different types are encoded and their sizes
     * @return Lengths of encoded data for each type
     *
     * Educational: Understanding encoding sizes helps optimize gas usage
     */
    function compareEncodingTypes() public returns (
        uint256 uint256Length,
        uint256 addressLength,
        uint256 stringLength,
        uint256 bytesLength
    ) {
        // All fixed-size types are padded to 32 bytes
        uint256Length = abi.encode(uint256(42)).length; // 32 bytes
        addressLength = abi.encode(address(this)).length; // 32 bytes

        // Dynamic types include offset, length, and padded data
        stringLength = abi.encode("hello").length; // 96 bytes (offset + length + data)
        bytesLength = abi.encode(bytes("hello")).length; // 96 bytes

        return (uint256Length, addressLength, stringLength, bytesLength);
    }

    /**
     * @notice Demonstrates encoding with different numbers of arguments
     * @dev Shows how ABI encoding scales with parameters
     */
    function encodeMultipleArgs(
        uint256 a,
        address b,
        string memory c
    ) public pure returns (bytes memory) {
        return abi.encode(a, b, c);
    }

    /**
     * @notice Shows the danger of selector collisions
     * @dev With only 4 bytes, collisions are possible (birthday paradox)
     * @return The selector - only 2^32 possible values
     *
     * SECURITY NOTE: Don't rely on selectors alone for authentication!
     * With ~77,000 random function signatures, there's a 50% chance of collision.
     */
    function demonstrateSelectorSpace() public pure returns (bytes4) {
        // Only 4 bytes = 4,294,967,296 possible selectors
        // Birthday paradox: ~77k functions → 50% collision chance
        return bytes4(keccak256("collisionRisk()"));
    }

    /**
     * @notice Demonstrates safe multi-argument hashing
     * @dev Best practices for hashing multiple values
     */
    function safeHashMultipleValues(
        string memory a,
        string memory b,
        string memory c
    ) public pure returns (bytes32) {
        // OPTION 1: Use abi.encode (safest)
        return keccak256(abi.encode(a, b, c));

        // OPTION 2: Add separators with encodePacked
        // return keccak256(abi.encodePacked(a, ":", b, ":", c));

        // NEVER: keccak256(abi.encodePacked(a, b, c)) - collision risk!
    }

    /**
     * @notice Demonstrates decoding encoded data
     * @dev Shows how to reverse the encoding process
     */
    function demonstrateDecode(bytes memory data) public pure returns (
        string memory a,
        string memory b
    ) {
        // Decode the data back to original types
        (a, b) = abi.decode(data, (string, string));
        return (a, b);
    }

    /**
     * @notice Helper to manually extract selector from calldata
     * @dev Educational function showing low-level calldata manipulation
     */
    function extractSelector(bytes memory data) public pure returns (bytes4) {
        require(data.length >= 4, "Data too short");

        // Manual extraction of first 4 bytes
        bytes4 selector;
        assembly {
            selector := mload(add(data, 32)) // Skip length prefix
        }
        return selector;
    }

    /**
     * @notice Compares gas costs of different encoding methods
     * @dev Run with --gas-report to see differences
     * 
     * GAS COMPARISON SUMMARY:
     * - abi.encode: More gas (larger output) but safe
     * - abi.encodePacked: Less gas (smaller output) but collision risk
     * - For production: Use abi.encode for hashing, encodePacked only when safe
     * 
     * REAL-WORLD ANALOGY: Like choosing between a padded shipping box
     * (safe but expensive) vs a tight envelope (cheap but fragile).
     */
    function gasComparisonEncode(string memory a, string memory b) public pure returns (bytes memory) {
        return abi.encode(a, b);
    }

    function gasComparisonEncodePacked(string memory a, string memory b) public pure returns (bytes memory) {
        return abi.encodePacked(a, b);
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. abi.encode IS SAFE BUT LARGER
 *    ✅ Adds padding and offsets (unambiguous)
 *    ✅ Can decode back to original types
 *    ✅ Safe from collisions
 *    ❌ Larger size (more gas)
 *    ✅ Use for function calls and critical hashing
 *
 * 2. abi.encodePacked IS COMPACT BUT DANGEROUS
 *    ✅ No padding (gas-efficient)
 *    ✅ Smaller output
 *    ❌ Hash collision risk with multiple variable-length args
 *    ✅ Safe for single variable-length arg or fixed-size args
 *    ❌ NEVER use for signatures or critical hashing!
 *
 * 3. FUNCTION SELECTORS ARE FIRST 4 BYTES
 *    ✅ Calculated as keccak256(functionSignature)[0:4]
 *    ✅ Used to route calls to correct function
 *    ✅ Can have collisions (different signatures, same selector)
 *    ✅ Always verify function signature matches!
 *
 * 4. HASH COLLISIONS ARE REAL RISKS
 *    ✅ encodePacked("A", "BC") == encodePacked("AB", "C")
 *    ✅ Can break signature verification
 *    ✅ Can break merkle tree proofs
 *    ✅ Always use abi.encode for critical hashing!
 *
 * 5. ENCODING METHODS HAVE DIFFERENT USE CASES
 *    ✅ abi.encode: Function calls, critical hashing
 *    ✅ abi.encodePacked: Single arg hashing, gas optimization
 *    ✅ abi.encodeWithSignature: Function call encoding
 *    ✅ Choose based on security vs gas trade-off
 *
 * 6. DECODING REQUIRES CORRECT TYPES
 *    ✅ abi.decode(data, (type1, type2, ...))
 *    ✅ Types must match encoding exactly
 *    ✅ Wrong types = garbage data or revert
 *    ✅ Always validate decoded data
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Using encodePacked for signatures (hash collisions!)
 * ❌ Using encodePacked with multiple variable-length args
 * ❌ Not verifying function selectors match signatures
 * ❌ Decoding with wrong types
 * ❌ Assuming encoding is deterministic without testing
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study EIP-712 for structured data hashing
 * • Learn about signature verification patterns
 * • Explore merkle tree implementations
 * • Move to Project 15 to learn about low-level calls
 */
