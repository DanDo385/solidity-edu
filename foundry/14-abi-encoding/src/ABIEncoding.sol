// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ABIEncoding
 * @notice Learn about ABI encoding methods, function selectors, and security implications
 * @dev Complete the TODOs to understand low-level encoding in Solidity
 */
contract ABIEncoding {
    // ============================================================
    // STATE VARIABLES
    // ============================================================

    // Storage for manual routing example
    mapping(bytes4 => bool) public allowedSelectors;
    uint256 public value;

    // ============================================================
    // EVENTS
    // ============================================================

    // Event to log encoding results
    event EncodingResult(bytes data, uint256 length);
    event SelectorCalculated(bytes4 selector, string signature);
    event HashCollision(bytes32 hash1, bytes32 hash2, bool isCollision);

    // TODO: Implement a function that demonstrates abi.encode
    // Function should accept two strings and return the encoded bytes
    // Also emit the length of the result
    function demonstrateEncode(string memory a, string memory b) public returns (bytes memory) {
        // TODO: Use abi.encode to encode the two strings
        // TODO: Emit EncodingResult event with the encoded data and its length
        // TODO: Return the encoded bytes
    }

    // TODO: Implement a function that demonstrates abi.encodePacked
    // Function should accept two strings and return the packed bytes
    // Also emit the length to compare with abi.encode
    function demonstrateEncodePacked(string memory a, string memory b) public returns (bytes memory) {
        // TODO: Use abi.encodePacked to encode the two strings
        // TODO: Emit EncodingResult event with the packed data and its length
        // TODO: Return the packed bytes
    }

    // TODO: Implement a function that demonstrates hash collision with encodePacked
    // Show that encodePacked("A", "BC") produces the same hash as encodePacked("AB", "C")
    function demonstrateHashCollision() public returns (bool) {
        // TODO: Create hash1 using keccak256(abi.encodePacked("A", "BC"))
        // TODO: Create hash2 using keccak256(abi.encodePacked("AB", "C"))
        // TODO: Emit HashCollision event
        // TODO: Return true if hashes are equal
    }

    // TODO: Implement a function that demonstrates safe hashing with abi.encode
    // Show that abi.encode prevents the collision
    function demonstrateSafeHashing() public returns (bool) {
        // TODO: Create hash1 using keccak256(abi.encode("A", "BC"))
        // TODO: Create hash2 using keccak256(abi.encode("AB", "C"))
        // TODO: Emit HashCollision event
        // TODO: Return false (hashes should NOT be equal)
    }

    // TODO: Implement a function to calculate the selector for "transfer(address,uint256)"
    function getTransferSelector() public pure returns (bytes4) {
        // TODO: Calculate selector using bytes4(keccak256("transfer(address,uint256)"))
        // TODO: Return the selector (should be 0xa9059cbb)
    }

    // TODO: Implement a function to calculate selector for any function signature
    function calculateSelector(string memory signature) public returns (bytes4) {
        // TODO: Calculate the selector from the signature string
        // TODO: Emit SelectorCalculated event
        // TODO: Return the selector
    }

    // TODO: Implement a function that encodes a function call manually
    // Should create the same data as calling transfer(address,uint256)
    function encodeTransferCall(address to, uint256 amount) public pure returns (bytes memory) {
        // TODO: Use abi.encodeWithSignature to encode the transfer call
        // TODO: Return the encoded call data
    }

    // TODO: Implement a function that encodes using a pre-calculated selector
    // This is more gas efficient than encodeWithSignature
    function encodeWithSelector(address to, uint256 amount) public pure returns (bytes memory) {
        // TODO: Use abi.encodeWithSelector with the transfer selector
        // TODO: Return the encoded call data
    }

    // TODO: Implement a function to register allowed function selectors
    function registerSelector(string memory signature) public {
        // TODO: Calculate the selector from signature
        // TODO: Store it in allowedSelectors mapping as true
    }

    // ============================================================
    // FALLBACK FUNCTION
    // ============================================================

    // TODO: Implement a fallback function that routes calls based on selector
    // Should only execute if the selector is in allowedSelectors
    fallback() external payable {
        // TODO: Extract the function selector from msg.data (first 4 bytes)
        // TODO: Require that the selector is allowed
        // TODO: For demonstration, just set value = 123
    }

    // TODO: Create a helper function that demonstrates encoding different types
    // Compare gas usage and output size for: uint256, address, string, bytes
    function compareEncodingTypes() public returns (
        uint256 uint256Length,
        uint256 addressLength,
        uint256 stringLength,
        uint256 bytesLength
    ) {
        // TODO: Encode a uint256 and get its length
        // TODO: Encode an address and get its length
        // TODO: Encode a string and get its length
        // TODO: Encode bytes and get its length
        // TODO: Return all lengths for comparison
    }
}
