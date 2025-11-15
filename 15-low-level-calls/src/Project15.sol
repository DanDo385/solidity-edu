// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TargetContract
 * @notice A simple contract to test low-level calls against
 */
contract TargetContract {
    uint256 public value;
    address public sender;
    uint256 public receivedValue;

    event ValueSet(uint256 newValue, address setter);

    // TODO: Implement setValue function
    // Should update value, sender, and emit event

    // TODO: Implement getValue view function
    // Should return current value

    // TODO: Implement a function that reverts with a custom error
    // Use this to test error bubbling

    // TODO: Implement a payable function
    // Test receiving ETH via low-level calls
}

/**
 * @title Caller
 * @notice Demonstrates call() - executes in target's context
 */
contract Caller {
    event CallResult(bool success, bytes data);

    // TODO: Implement callSetValue
    // Should use call() to execute setValue on target
    // Should return success status and decoded value

    // TODO: Implement callWithValue
    // Should send ETH along with the call

    // TODO: Implement callAndBubbleError
    // Should properly bubble up errors from failed calls

    // TODO: Implement staticCallGetValue
    // Should use staticcall() to safely read from target
}

/**
 * @title DelegateTarget
 * @notice Target contract for delegatecall demonstrations
 * WARNING: Storage layout must match caller!
 */
contract DelegateTarget {
    uint256 public value;  // Slot 0
    address public sender; // Slot 1

    // TODO: Implement setValue function
    // When delegatecalled, this will modify CALLER's storage!

    // TODO: Implement dangerousFunction
    // Show how delegatecall can corrupt storage
}

/**
 * @title DelegateCaller
 * @notice Demonstrates delegatecall() - executes in caller's context
 * CRITICAL: Storage layout must match DelegateTarget!
 */
contract DelegateCaller {
    uint256 public value;  // Slot 0 - MUST MATCH DelegateTarget
    address public sender; // Slot 1 - MUST MATCH DelegateTarget

    event DelegateCallResult(bool success, bytes data);

    // TODO: Implement delegateSetValue
    // Should use delegatecall to modify OUR storage

    // TODO: Implement getStorageValues
    // Helper to verify storage was modified
}

/**
 * @title StorageCorruptionExample
 * @notice Demonstrates the dangers of storage layout mismatch
 * DO NOT USE IN PRODUCTION - FOR EDUCATIONAL PURPOSES ONLY
 */
contract VulnerableProxy {
    address public implementation; // Slot 0
    address public owner;         // Slot 1

    // TODO: Implement constructor
    // Set initial implementation and owner

    // TODO: Implement delegateToImplementation
    // Delegates call to implementation contract
    // DANGER: If implementation has wrong layout, storage corruption!
}

/**
 * @title MaliciousImplementation
 * @notice Malicious contract with misaligned storage
 * FOR EDUCATIONAL PURPOSES ONLY
 */
contract MaliciousImplementation {
    address public owner; // Slot 0 - MISALIGNED!

    // TODO: Implement takeOver function
    // When delegatecalled, this overwrites proxy's implementation address!
}

/**
 * @title SafeProxy
 * @notice Properly aligned proxy contract
 */
contract SafeProxy {
    address public implementation; // Slot 0
    address public owner;         // Slot 1

    // TODO: Implement with proper storage alignment
    // Show the correct way to use delegatecall
}

/**
 * @title SafeImplementation
 * @notice Properly aligned implementation
 */
contract SafeImplementation {
    address public implementation; // Slot 0 - MATCHES SafeProxy
    address public owner;         // Slot 1 - MATCHES SafeProxy
    uint256 public value;         // Slot 2 - Additional storage OK

    // TODO: Implement safe functions
    // These can safely modify proxy storage
}

/**
 * @title StaticCallExample
 * @notice Demonstrates staticcall() - read-only enforcement
 */
contract StaticCallExample {
    uint256 public value;

    event StaticCallAttempted(bool success);

    // TODO: Implement safeRead
    // Use staticcall to safely read from external contract

    // TODO: Implement attemptWrite
    // Try to modify state - should fail with staticcall
}

/**
 * @title ReturnDataExample
 * @notice Demonstrates proper return data handling
 */
contract ReturnDataExample {
    // TODO: Implement callAndDecode
    // Call external function and decode return data

    // TODO: Implement handleMultipleReturns
    // Handle functions that return multiple values

    // TODO: Implement bubbleError
    // Properly bubble up error messages from failed calls
}
