// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/ABIEncodingSolution.sol";

/**
 * @title ABIEncodingTest
 * @notice Comprehensive tests for ABI encoding concepts
 * @dev Tests demonstrate encoding differences, collisions, and security implications
 */
contract ABIEncodingTest is Test {
    ABIEncodingSolution public encoder;

    function setUp() public {
        encoder = new ABIEncodingSolution();
    }

    /**
     * @notice Test abi.encode produces padded output
     */
    function test_EncodeProducesPaddedOutput() public {
        bytes memory encoded = encoder.demonstrateEncode("AA", "BB");

        // abi.encode includes offsets, lengths, and padding
        // Expected to be much larger than just "AABB"
        assertGt(encoded.length, 4, "Encoded should be larger than raw data");

        // Typical abi.encode output for two strings is ~192 bytes
        emit log_named_uint("abi.encode length", encoded.length);
        emit log_named_bytes("abi.encode output", encoded);
    }

    /**
     * @notice Test abi.encodePacked produces compact output
     */
    function test_EncodePackedProducesCompactOutput() public {
        bytes memory packed = encoder.demonstrateEncodePacked("AA", "BB");

        // abi.encodePacked should be just the bytes: "AABB" = 4 bytes
        assertEq(packed.length, 4, "Packed should be exactly 4 bytes");
        assertEq(packed, bytes("AABB"), "Packed should be literal concatenation");

        emit log_named_uint("abi.encodePacked length", packed.length);
        emit log_named_bytes("abi.encodePacked output", packed);
    }

    /**
     * @notice Test encode vs encodePacked size difference
     */
    function test_CompareSizeDifference() public {
        bytes memory encoded = encoder.demonstrateEncode("AA", "BB");
        bytes memory packed = encoder.demonstrateEncodePacked("AA", "BB");

        emit log_named_uint("abi.encode length", encoded.length);
        emit log_named_uint("abi.encodePacked length", packed.length);

        // abi.encode is much larger due to padding
        assertGt(encoded.length, packed.length, "encode should be larger than encodePacked");
    }

    /**
     * @notice CRITICAL: Demonstrates hash collision with encodePacked
     * @dev This is a MAJOR security vulnerability!
     */
    function test_HashCollisionWithEncodePacked() public {
        bool hasCollision = encoder.demonstrateHashCollision();

        // These should collide - this is the DANGER of encodePacked!
        assertTrue(hasCollision, "encodePacked should cause hash collision");

        // Verify the collision manually
        bytes32 hash1 = keccak256(abi.encodePacked("A", "BC"));
        bytes32 hash2 = keccak256(abi.encodePacked("AB", "C"));

        assertEq(hash1, hash2, "Hashes should be identical - COLLISION!");

        emit log_named_bytes32("Hash of ('A', 'BC')", hash1);
        emit log_named_bytes32("Hash of ('AB', 'C')", hash2);
        emit log_string("WARNING: These hashes are IDENTICAL - this is a security risk!");
    }

    /**
     * @notice Test that abi.encode prevents collisions
     */
    function test_SafeHashingWithEncode() public {
        bool hasCollision = encoder.demonstrateSafeHashing();

        // Should NOT collide with abi.encode
        assertFalse(hasCollision, "abi.encode should prevent collision");

        // Verify manually
        bytes32 hash1 = keccak256(abi.encode("A", "BC"));
        bytes32 hash2 = keccak256(abi.encode("AB", "C"));

        assertTrue(hash1 != hash2, "Hashes should be different - SAFE!");

        emit log_named_bytes32("Hash of ('A', 'BC')", hash1);
        emit log_named_bytes32("Hash of ('AB', 'C')", hash2);
        emit log_string("SAFE: These hashes are different!");
    }

    /**
     * @notice Test more collision scenarios
     */
    function test_MoreCollisionExamples() public {
        // Multiple collision scenarios
        bytes32 collision1a = keccak256(abi.encodePacked("AAA", ""));
        bytes32 collision1b = keccak256(abi.encodePacked("AA", "A"));
        assertEq(collision1a, collision1b, "Collision: ('AAA','') == ('AA','A')");

        bytes32 collision2a = keccak256(abi.encodePacked("", "XYZ"));
        bytes32 collision2b = keccak256(abi.encodePacked("X", "YZ"));
        assertEq(collision2a, collision2b, "Collision: ('','XYZ') == ('X','YZ')");

        // With three arguments, even more collisions!
        bytes32 collision3a = keccak256(abi.encodePacked("A", "B", "C"));
        bytes32 collision3b = keccak256(abi.encodePacked("AB", "", "C"));
        bytes32 collision3c = keccak256(abi.encodePacked("", "AB", "C"));
        assertEq(collision3a, collision3b, "3-arg collision");
        assertEq(collision3a, collision3c, "3-arg collision");
    }

    /**
     * @notice Test function selector calculation
     */
    function test_TransferSelectorCalculation() public {
        bytes4 selector = encoder.getTransferSelector();

        // Standard ERC20 transfer selector
        bytes4 expected = 0xa9059cbb;
        assertEq(selector, expected, "Transfer selector should be 0xa9059cbb");

        emit log_named_bytes4("transfer(address,uint256) selector", selector);
    }

    /**
     * @notice Test calculating selectors for various functions
     */
    function test_CalculateVariousSelectors() public {
        // Test multiple function signatures
        bytes4 transferSelector = encoder.calculateSelector("transfer(address,uint256)");
        assertEq(transferSelector, bytes4(0xa9059cbb));

        bytes4 approveSelector = encoder.calculateSelector("approve(address,uint256)");
        assertEq(approveSelector, bytes4(0x095ea7b3));

        bytes4 transferFromSelector = encoder.calculateSelector("transferFrom(address,address,uint256)");
        assertEq(transferFromSelector, bytes4(0x23b872dd));

        emit log_named_bytes4("transfer", transferSelector);
        emit log_named_bytes4("approve", approveSelector);
        emit log_named_bytes4("transferFrom", transferFromSelector);
    }

    /**
     * @notice Test encoding a complete function call
     */
    function test_EncodeTransferCall() public {
        address to = address(0x1234);
        uint256 amount = 1000;

        bytes memory callData = encoder.encodeTransferCall(to, amount);

        // Should start with transfer selector
        bytes4 selector;
        assembly {
            selector := mload(add(callData, 32))
        }
        assertEq(selector, bytes4(0xa9059cbb), "Should start with transfer selector");

        emit log_named_bytes("Encoded transfer call", callData);
        emit log_named_uint("Call data length", callData.length);
    }

    /**
     * @notice Test encodeWithSelector vs encodeWithSignature
     */
    function test_EncodeWithSelectorVsSignature() public {
        address to = address(0x1234);
        uint256 amount = 1000;

        bytes memory withSignature = encoder.encodeTransferCall(to, amount);
        bytes memory withSelector = encoder.encodeWithSelector(to, amount);

        // Both should produce identical output
        assertEq(withSignature, withSelector, "Both methods should produce same output");

        emit log_named_bytes("encodeWithSignature", withSignature);
        emit log_named_bytes("encodeWithSelector", withSelector);
    }

    /**
     * @notice Test manual selector routing with fallback
     */
    function test_FallbackSelectorRouting() public {
        // Register a selector
        encoder.registerSelector("setValue(uint256)");

        // Calculate the selector
        bytes4 selector = bytes4(keccak256("setValue(uint256)"));

        // Verify it's registered
        assertTrue(encoder.allowedSelectors(selector), "Selector should be registered");

        // Make a call with that selector (will hit fallback)
        bytes memory callData = abi.encodeWithSignature("setValue(uint256)", 42);
        (bool success, ) = address(encoder).call(callData);

        assertTrue(success, "Call should succeed");
        assertEq(encoder.value(), 123, "Fallback should set value to 123");
    }

    /**
     * @notice Test that fallback rejects unregistered selectors
     */
    function test_FallbackRejectsUnregisteredSelector() public {
        // Try to call an unregistered function
        bytes memory callData = abi.encodeWithSignature("unregisteredFunction()");

        (bool success, ) = address(encoder).call(callData);
        assertFalse(success, "Call should fail for unregistered selector");
    }

    /**
     * @notice Test encoding different types shows different lengths
     */
    function test_CompareEncodingTypes() public {
        (
            uint256 uint256Length,
            uint256 addressLength,
            uint256 stringLength,
            uint256 bytesLength
        ) = encoder.compareEncodingTypes();

        // Fixed types are 32 bytes
        assertEq(uint256Length, 32, "uint256 should be 32 bytes");
        assertEq(addressLength, 32, "address should be 32 bytes");

        // Dynamic types include offset, length, and data
        assertGt(stringLength, 32, "string should be larger than 32 bytes");
        assertGt(bytesLength, 32, "bytes should be larger than 32 bytes");

        emit log_named_uint("uint256 length", uint256Length);
        emit log_named_uint("address length", addressLength);
        emit log_named_uint("string length", stringLength);
        emit log_named_uint("bytes length", bytesLength);
    }

    /**
     * @notice Test decoding encoded data
     */
    function test_EncodeAndDecode() public {
        string memory a = "Hello";
        string memory b = "World";

        // Encode
        bytes memory encoded = encoder.demonstrateEncode(a, b);

        // Decode
        (string memory decodedA, string memory decodedB) = encoder.demonstrateDecode(encoded);

        assertEq(decodedA, a, "Decoded A should match original");
        assertEq(decodedB, b, "Decoded B should match original");
    }

    /**
     * @notice Test extracting selector from calldata
     */
    function test_ExtractSelector() public {
        bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", address(0x1234), 1000);

        bytes4 extracted = encoder.extractSelector(callData);
        bytes4 expected = bytes4(keccak256("transfer(address,uint256)"));

        assertEq(extracted, expected, "Extracted selector should match");
    }

    /**
     * @notice Test that selectors are only 4 bytes
     */
    function test_SelectorSize() public {
        bytes4 selector = encoder.getTransferSelector();

        // Selectors are always exactly 4 bytes
        emit log_named_uint("Selector size in bytes", 4);
        emit log_named_uint("Total possible selectors", 2**32);
        emit log_string("Note: ~77k random functions give 50% collision chance (birthday paradox)");
    }

    /**
     * @notice Demonstrate real-world collision risk
     */
    function test_SelectorCollisionRisk() public {
        // With only 2^32 possible values, collisions are possible
        // Birthday paradox: sqrt(2^32) ≈ 77,163 functions → 50% collision

        bytes4 selector1 = bytes4(keccak256("collide_me_if_you_can()"));
        bytes4 selector2 = bytes4(keccak256("different_function_name()"));

        // These MIGHT collide (unlikely with just 2, but possible with many)
        emit log_named_bytes4("Selector 1", selector1);
        emit log_named_bytes4("Selector 2", selector2);

        if (selector1 == selector2) {
            emit log_string("COLLISION FOUND!");
        } else {
            emit log_string("No collision (expected with just 2 functions)");
        }
    }

    /**
     * @notice Gas comparison test
     */
    function test_GasComparison() public {
        string memory a = "Hello";
        string memory b = "World";

        // Measure encode gas
        uint256 gasBefore = gasleft();
        encoder.gasComparisonEncode(a, b);
        uint256 encodeGas = gasBefore - gasleft();

        // Measure encodePacked gas
        gasBefore = gasleft();
        encoder.gasComparisonEncodePacked(a, b);
        uint256 encodePackedGas = gasBefore - gasleft();

        emit log_named_uint("abi.encode gas", encodeGas);
        emit log_named_uint("abi.encodePacked gas", encodePackedGas);

        // encodePacked should use less gas
        assertLt(encodePackedGas, encodeGas, "encodePacked should use less gas");
    }

    /**
     * @notice Test safe multi-argument hashing
     */
    function test_SafeHashingMultipleValues() public {
        bytes32 hash1 = encoder.safeHashMultipleValues("A", "B", "C");
        bytes32 hash2 = encoder.safeHashMultipleValues("AB", "", "C");

        // With abi.encode, these should be different
        assertTrue(hash1 != hash2, "Safe hashing should prevent collision");

        emit log_named_bytes32("Hash ('A','B','C')", hash1);
        emit log_named_bytes32("Hash ('AB','','C')", hash2);
    }

    /**
     * @notice Test real-world vulnerability scenario
     */
    function test_VulnerabilityScenario_SignatureReplay() public {
        // Imagine a contract that verifies signatures like this:
        // bytes32 hash = keccak256(abi.encodePacked(user, token));
        //
        // Attacker could claim:
        // ("userA", "token1") has same hash as ("userAtoken", "1")
        //
        // This is a real vulnerability!

        string memory user1 = "userA";
        string memory token1 = "token1";

        string memory user2 = "userAtoken";
        string memory token2 = "1";

        bytes32 hash1 = keccak256(abi.encodePacked(user1, token1));
        bytes32 hash2 = keccak256(abi.encodePacked(user2, token2));

        // VULNERABLE: These hashes are identical!
        assertEq(hash1, hash2, "VULNERABILITY: Signature replay possible!");

        emit log_string("SECURITY WARNING: Signature replay vulnerability demonstrated!");
        emit log_named_bytes32("Victim hash", hash1);
        emit log_named_bytes32("Attacker hash", hash2);
    }

    /**
     * @notice Test that msg.sig gives the function selector
     */
    function test_MsgSigGivesFunctionSelector() public {
        // msg.sig is a built-in that gives the function selector
        bytes4 thisSelector = this.test_MsgSigGivesFunctionSelector.selector;

        emit log_named_bytes4("This function's selector", thisSelector);

        // Can be used for access control or routing
        assertTrue(thisSelector != bytes4(0), "Selector should not be zero");
    }

    /**
     * @notice Test encoding with arrays
     */
    function test_EncodeArrays() public {
        uint256[] memory arr = new uint256[](3);
        arr[0] = 1;
        arr[1] = 2;
        arr[2] = 3;

        bytes memory encoded = abi.encode(arr);
        bytes memory packed = abi.encodePacked(arr);

        // Arrays in encodePacked lose length info!
        emit log_named_uint("abi.encode array length", encoded.length);
        emit log_named_uint("abi.encodePacked array length", packed.length);

        // encodePacked is dangerous with arrays too!
        assertGt(encoded.length, packed.length);
    }
}
