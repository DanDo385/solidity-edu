// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DatatypesStorage
 * @notice Skeleton contract for learning Solidity datatypes and storage
 * @dev Complete the TODOs to implement all functionality
 *
 * LEARNING GOALS:
 * 1. Understand value types vs reference types
 * 2. Master storage, memory, and calldata locations
 * 3. Analyze gas costs of different data structures
 * 4. Implement efficient struct packing
 */
contract DatatypesStorage {
    // ============================================================
    // STATE VARIABLES (Storage)
    // ============================================================

    // TODO: Declare a public uint256 variable called 'number'

    // TODO: Declare a public address variable called 'owner'

    // TODO: Declare a public bool variable called 'isActive'

    // TODO: Declare a public bytes32 variable called 'data'

    // TODO: Declare a mapping from address to uint256 called 'balances'

    // TODO: Declare a dynamic array of uint256 called 'numbers'

    // TODO: Define a struct called 'User' with:
    //       - address wallet
    //       - uint256 balance
    //       - bool isRegistered

    // TODO: Declare a mapping from address to User called 'users'

    // TODO: Define a struct called 'PackedData' with optimal packing:
    //       - uint128 smallNumber1
    //       - uint128 smallNumber2
    //       - uint64 timestamp
    //       - address user (20 bytes)
    //       - bool flag
    //       Hint: Order matters for gas efficiency!

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    // TODO: Implement constructor that sets owner to msg.sender

    // ============================================================
    // VALUE TYPE FUNCTIONS
    // ============================================================

    /**
     * @notice Set the number value
     * @param _number The new number value
     */
    function setNumber(uint256 _number) public {
        // TODO: Implement
    }

    /**
     * @notice Get the number value
     * @return The current number value
     */
    function getNumber() public view returns (uint256) {
        // TODO: Implement
    }

    /**
     * @notice Increment the number by 1
     */
    function incrementNumber() public {
        // TODO: Implement
    }

    // ============================================================
    // MAPPING FUNCTIONS
    // ============================================================

    /**
     * @notice Set balance for an address
     * @param _address The address to set balance for
     * @param _balance The balance amount
     */
    function setBalance(address _address, uint256 _balance) public {
        // TODO: Implement using the balances mapping
    }

    /**
     * @notice Get balance for an address
     * @param _address The address to query
     * @return The balance amount
     */
    function getBalance(address _address) public view returns (uint256) {
        // TODO: Implement
    }

    // ============================================================
    // ARRAY FUNCTIONS
    // ============================================================

    /**
     * @notice Add a number to the numbers array
     * @param _number The number to add
     */
    function addNumber(uint256 _number) public {
        // TODO: Implement using push
    }

    /**
     * @notice Get the length of the numbers array
     * @return The array length
     */
    function getNumbersLength() public view returns (uint256) {
        // TODO: Implement
    }

    /**
     * @notice Get a number at a specific index
     * @param _index The index to query
     * @return The number at that index
     */
    function getNumberAt(uint256 _index) public view returns (uint256) {
        // TODO: Implement with bounds checking
    }

    // ============================================================
    // STRUCT FUNCTIONS
    // ============================================================

    /**
     * @notice Register a user
     * @param _wallet The user's wallet address
     * @param _balance The initial balance
     */
    function registerUser(address _wallet, uint256 _balance) public {
        // TODO: Create a User struct and store in users mapping
        // Set isRegistered to true
    }

    /**
     * @notice Get user information
     * @param _wallet The user's wallet address
     * @return wallet address
     * @return balance amount
     * @return isRegistered status
     */
    function getUser(address _wallet)
        public
        view
        returns (address wallet, uint256 balance, bool isRegistered)
    {
        // TODO: Implement - return user data from mapping
    }

    // ============================================================
    // DATA LOCATION DEMONSTRATION
    // ============================================================

    /**
     * @notice Demonstrates memory usage - modifies a copy
     * @param _arr Array to process (in memory)
     * @return The sum of array elements
     */
    function sumMemoryArray(uint256[] memory _arr) public pure returns (uint256) {
        // TODO: Implement
        // Loop through _arr and sum all elements
        // Note: This is a MEMORY array, changes don't persist
    }

    /**
     * @notice Demonstrates calldata usage - read-only
     * @param _arr Array to process (in calldata)
     * @return The first element
     */
    function getFirstElement(uint256[] calldata _arr) public pure returns (uint256) {
        // TODO: Implement
        // Return the first element if array is not empty
        // Note: calldata is read-only and gas-efficient
    }

    // ============================================================
    // HELPER FUNCTIONS
    // ============================================================

    /**
     * @notice Check if an address has a non-zero balance
     * @param _address The address to check
     * @return true if balance > 0
     */
    function hasBalance(address _address) public view returns (bool) {
        // TODO: Implement
    }
}
