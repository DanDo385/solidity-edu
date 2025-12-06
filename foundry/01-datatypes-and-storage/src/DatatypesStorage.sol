// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DatatypesStorage
 * @notice Skeleton contract for learning Solidity datatypes and storage
 * @dev Complete the TODOs to implement all functionality.
 *      Think about the "why" behind each task.
 *
 * LEARNING GOALS:
 * 1. Understand value types (uint, address) vs. reference types (mappings, arrays)
 * 2. Master storage, memory, and calldata locations and their gas implications
 * 3. Analyze gas costs of different data structures
 * 4. Implement efficient struct packing to save gas
 * 5. Learn about payable functions and receiving ETH
 */
contract DatatypesStorage {
    // ============================================================
    // TYPE DECLARATIONS
    // ============================================================

    // TODO: Define a struct called 'User' with:
    //       - address wallet
    //       - uint256 balance
    //       - bool isRegistered
    // Structs are reference types. How does their storage layout work in a mapping?
    struct User {
        address wallet;
        uint256 balance;
        bool isRegistered;
    }

    // TODO: Define a struct called 'PackedData' with optimal packing.
    // Research "struct packing" in Solidity. How should you order these fields?
    //       - uint128 smallNumber1
    //       - address user (20 bytes)
    //       - uint64 timestamp
    //       - bool flag
    //       - uint128 smallNumber2
    // How many storage slots does your packed struct use vs. an unpacked one?

    // ============================================================
    // STATE VARIABLES (Storage)
    // ============================================================

    // TODO: Declare a public uint256 variable called 'number'.
    // Why is uint256 the most common integer type in Solidity? What are the alternatives?
    uint256 public number;

    // TODO: Declare a public address variable called 'owner'.
    // What is the difference between an address and an address payable?
    address public owner;

    // TODO: Declare a public bool variable called 'isActive'.
    // What is the default value for a bool in storage?
    bool public isActive;

    // TODO: Declare a public bytes32 variable called 'data'.
    // When would you use bytes32 vs. string or bytes?
    bytes32 public data;

    // TODO: Declare a public string variable called 'message'.
    // Why are strings generally more expensive to use than bytes32?
    string public message;

    // TODO: Declare a public mapping from address to uint256 called 'balances'.
    // What happens if you try to access a key that doesn't exist in a mapping?
    mapping(address => uint256) public balances;

    // TODO: Declare a dynamic array of uint256 called 'numbers'.
    // What are the gas implications of using a dynamic array?
    uint256[] public numbers;

    // TODO: Declare a public mapping from address to User called 'users'.
    mapping(address => User) public users;

    // ============================================================
    // EVENTS
    // ============================================================

    // TODO: Declare an event 'NumberUpdated' that logs the old and new number value.
    // Why are events useful for off-chain applications?
    event NumberUpdated(uint256 indexed oldValue, uint256 newValue);
    // TODO: Declare an event 'UserRegistered' that logs the user's wallet and balance.
    event UserRegistered(address indexed wallet, uint256 balance);
    // TODO: Declare an event 'FundsDeposited' that logs the depositor and the amount.
    event FundsDeposited(address indexed depositor, uint256 amount);
    // TODO: Declare an event 'MessageUpdated' that logs the old and new message.
    event MessageUpdated(string oldMessage, string newMessage);
    // TODO: Declare an event 'BalanceUpdated' that logs the address and the balance.
    event BalanceUpdated(address addr, uint256 balance);
    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    // TODO: Implement the constructor.
    // It should set the 'owner' to the address that deployed the contract (msg.sender).
    // It should also set 'isActive' to true.
    constructor() {
        owner = msg.sender;
        isActive = true;
    }

    // ============================================================
    // ETHER HANDLING
    // ============================================================

    /**
     * @notice Allows users to deposit ETH into the contract.
     * @dev This function should be payable. The sent ETH should be added to the sender's balance.
     */
    function deposit() public payable {
        // TODO: Implement this payable function.
        // 1. Check if msg.value is greater than 0.
        // 2. Add the sent ETH (msg.value) to the sender's balance in the 'balances' mapping.
        // 3. Emit a 'FundsDeposited' event.
        require(msg.value > 0, "Amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    // ============================================================
    // VALUE & REFERENCE TYPE FUNCTIONS
    // ============================================================

    /**
     * @notice Set the 'number' state variable.
     * @param _number The new number value.
     */
    function setNumber(uint256 _number) public {
        // TODO: Implement this function.
        // 1. Store the old number in a temporary variable.
        // 2. Update the 'number' state variable to _number.
        // 3. Emit the 'NumberUpdated' event with the old and new values.
        uint256 oldValue = number;
        number = _number;
        emit NumberUpdated(oldValue, _number);
    }

    /**
     * @notice Get the current value of 'number'.
     * @return The current number value.
     */
    function getNumber() public view returns (uint256) {
        // TODO: Implement to return the 'number' state variable.
        return number;
    }

    /**
     * @notice Increment the 'number' by 1.
     * @dev What happens if 'number' is at its maximum value (type(uint256).max)?
     */
    function incrementNumber() public {
        // TODO: Implement to increment 'number'.
        number += 1;
    }

    /**
     * @notice Set the 'message' state variable.
     * @param _message The new message.
     */
    function setMessage(string memory _message) public {
        // TODO: Implement to update the 'message' state variable.
        string memory oldMessage = message;
        message = _message;
        emit MessageUpdated(oldMessage, _message);
    }

    // ============================================================
    // MAPPING FUNCTIONS
    // ============================================================

    /**
     * @notice Set the balance for a specific address.
     * @param _addr The address to set the balance for.
     * @param _balance The balance amount.
     */
    function setBalance(address _addr, uint256 _balance) public {
        // TODO: Implement using the 'balances' mapping.
        balances[_addr] = _balance;
        emit BalanceUpdated(_addr, _balance);
    }

    /**
     * @notice Get the balance for a specific address.
     * @param _addr The address to query.
     * @return The balance amount.
     */
    function getBalance(address _addr) public view returns (uint256) {
        // TODO: Implement to return the balance from the 'balances' mapping.
        return balances[_addr];
    }

    // ============================================================
    // ARRAY FUNCTIONS
    // ============================================================

    /**
     * @notice Add a number to the 'numbers' array.
     * @param _number The number to add.
     */
    function addNumber(uint256 _number) public {
        // TODO: Implement using array's 'push' method.
        numbers.push(_number);
    }

    /**
     * @notice Get the length of the 'numbers' array.
     * @return The array length.
     */
    function getNumbersLength() public view returns (uint256) {
        // TODO: Implement to return the array's length.
        return numbers.length;
    }

    /**
     * @notice Get a number at a specific index in the 'numbers' array.
     * @param _index The index to query.
     * @return The number at that index.
     */
    function getNumberAt(uint256 _index) public view returns (uint256) {
        // TODO: Implement with a bounds check to prevent errors.
        // Use a require() statement.
        require(_index < numbers.length, "Index out of bounds");
        return numbers[_index];
    }

    /**
     * @notice Remove a number at a specific index from the 'numbers' array.
     * @dev This is a complex operation. How do you remove an element and keep the array packed?
     *      Hint: You may need to shift elements.
     * @param _index The index of the element to remove.
     */
    function removeNumber(uint256 _index) public {
        // TODO: Advanced - Implement this function.
        // 1. Check if the index is valid.
        // 2. Move the last element to the place of the one to be removed.
        // 3. Remove the last element of the array.
        require(_index < numbers.length, "Index out of bounds");
        uint256 lastIndex = numbers.length - 1;
        numbers[lastIndex] = numbers[_index];
        numbers.pop();
    }

    // ============================================================
    // STRUCT FUNCTIONS
    // ============================================================

    /**
     * @notice Register a new user.
     * @param _wallet The user's wallet address.
     * @param _balance The initial balance.
     */
    function registerUser(address _wallet, uint256 _balance) public {
        // TODO: Create a User struct in the 'users' mapping.
        // Set 'isRegistered' to true.
        // Emit the 'UserRegistered' event.
        

    }

    /**
     * @notice Get user information.
     * @param _wallet The user's wallet address.
     * @return wallet The user's wallet address.
     * @return balance The user's balance.
     * @return isRegistered The user's registration status.
     */
    function getUser(address _wallet)
        public
        view
        returns (address wallet, uint256 balance, bool isRegistered)
    {
        // TODO: Implement to return data from the 'users' mapping.
        // What does this function return for a non-existent user?
        return users[_wallet].wallet, users[_wallet].balance, users[_wallet].isRegistered;
    }

    // ============================================================
    // DATA LOCATION DEMONSTRATION
    // ============================================================

    /**
     * @notice Demonstrates 'memory' usage. This function sums an array without affecting storage.
     * @param _arr The array to process (passed in memory).
     * @return The sum of the array elements.
     */
    function sumMemoryArray(uint256[] memory _arr) public pure returns (uint256) {
        // TODO: Implement the sum of the array.
        uint256 sum = 0;
        for (uint256 i = 0; i < _arr.length; i++) {
            sum += _arr[i];
        }
        return sum;
        // Why is this function 'pure'? What's the difference between 'view' and 'pure'?
    }

    /**
     * @notice Demonstrates 'calldata' usage. It's read-only and gas-efficient.
     * @param _arr The array to process (passed in calldata).
     * @return The first element of the array.
     */
    function getFirstElement(uint256[] calldata _arr) public pure returns (uint256) {
        // TODO: Implement to return the first element.
        return _arr[0];
        // Why can this function be 'pure'? Why is 'calldata' cheaper than 'memory'?
    }

    // ============================================================
    // HELPER FUNCTIONS
    // ============================================================

    /**
     * @notice Checks if an address has a non-zero balance.
     * @param _addr The address to check.
     * @return True if the balance is greater than 0, false otherwise.
     */
    function hasBalance(address _addr) public view returns (bool) {
        // TODO: Implement this helper function.
        return balances[_addr] > 0;
    }
}
