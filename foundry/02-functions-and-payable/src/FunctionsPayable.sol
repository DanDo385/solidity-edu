// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FunctionsPayable
 * @notice Skeleton contract for learning functions, payable, and ETH handling
 * @dev Complete the TODOs to implement all functionality
 *
 * LEARNING GOALS:
 * 1. Master function visibility (public, external, internal, private)
 * 2. Understand the payable modifier
 * 3. Implement receive() and fallback() functions
 * 4. Learn safe ETH transfer patterns
 * 
 * FUN FACT: Solidity compiles to Yul and then to bytecode. Marking helpers
 * internal often lets the optimizer inline them, shaving jumps and saving gas.
 * On rollups, trimming calldata and storage writes matters even more because
 * those bytes ultimately get posted to L1 during dispute windows.
 */
contract FunctionsPayable {
    // ============================================================
    // STATE VARIABLES
    // ============================================================

    // TODO: Declare a public address variable called 'owner'

    // TODO: Declare a mapping from address to uint256 called 'balances'

    // ============================================================
    // EVENTS
    // ============================================================

    // TODO: Define an event 'Deposited' with indexed sender (address) and amount (uint256)

    // TODO: Define an event 'Withdrawn' with indexed recipient (address) and amount (uint256)

    // TODO: Define an event 'Received' with indexed sender (address) and amount (uint256)

    // TODO: Define an event 'FallbackCalled' with indexed sender (address), amount (uint256), and data (bytes)

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    // TODO: Implement a payable constructor that:
    //       1. Sets owner to msg.sender
    //       2. Accepts ETH during deployment

    // ============================================================
    // RECEIVE AND FALLBACK
    // ============================================================

    // TODO: Implement receive() function that:
    //       1. Is external payable
    //       2. Emits Received event

    // TODO: Implement fallback() function that:
    //       1. Is external payable
    //       2. Emits FallbackCalled event with msg.data
    // These two functions are like the mailroom of your contract: receive()
    // handles plain envelopes (empty calldata) while fallback() routes unknown
    // parcels. Istanbul and later forks repriced gas, so avoid hardcoded limits
    // like transfer/send and stick to call with proper checks.

    // ============================================================
    // DEPOSIT FUNCTIONS
    // ============================================================

    /**
     * @notice Deposit ETH into the contract
     * @dev Increases sender's balance by msg.value
     */
    function deposit() public payable {
        // TODO: Implement
        // 1. Require msg.value > 0
        // 2. Increase balances[msg.sender] by msg.value
        // 3. Emit Deposited event
    }

    /**
     * @notice Deposit ETH for a specific address
     * @param _recipient The address to credit
     */
    function depositFor(address _recipient) public payable {
        // TODO: Implement
        // 1. Require msg.value > 0
        // 2. Require _recipient is not zero address
        // 3. Increase balances[_recipient] by msg.value
        // 4. Emit Deposited event for _recipient
    }

    // ============================================================
    // WITHDRAWAL FUNCTIONS
    // ============================================================

    /**
     * @notice Withdraw ETH from your balance
     * @param _amount The amount to withdraw
     */
    function withdraw(uint256 _amount) public {
        // TODO: Implement using checks-effects-interactions pattern
        // CHECKS:
        //   1. Require _amount > 0
        //   2. Require balances[msg.sender] >= _amount
        // EFFECTS:
        //   3. Decrease balances[msg.sender] by _amount
        // INTERACTIONS:
        //   4. Send ETH using .call{value: _amount}("")
        //   5. Require the call succeeded
        //   6. Emit Withdrawn event
        // Think of this as settling a tab: close your books before handing out cash
        // so a reentrant caller cannot ask twice. Rollups replay these calls in
        // fraud proofs, so deterministic ordering keeps disputes simple.
    }

    /**
     * @notice Withdraw all your balance
     */
    function withdrawAll() public {
        // TODO: Implement
        // Use the same pattern as withdraw()
    }

    /**
     * @notice Owner-only function to withdraw contract's unreserved funds
     * @param _amount Amount to withdraw
     */
    function ownerWithdraw(uint256 _amount) public {
        // TODO: Implement
        // 1. Require msg.sender == owner
        // 2. Calculate reserved funds (sum of all user balances conceptually)
        // 3. For simplicity, check contract balance >= _amount
        // 4. Send ETH to owner using .call
        // 5. Require success
    }

    // ============================================================
    // VIEW FUNCTIONS
    // ============================================================

    /**
     * @notice Get the balance of an address
     * @param _address The address to query
     * @return The balance
     */
    function getBalance(address _address) public view returns (uint256) {
        // TODO: Implement
    }

    /**
     * @notice Get the contract's total ETH balance
     * @return The contract balance in wei
     */
    function getContractBalance() public view returns (uint256) {
        // TODO: Implement
        // Return address(this).balance
    }

    // ============================================================
    // FUNCTION VISIBILITY DEMONSTRATIONS
    // ============================================================

    /**
     * @notice Public function - callable from anywhere
     * @return A message string
     */
    function publicFunction() public pure returns (string memory) {
        // TODO: Return "This is public"
    }

    /**
     * @notice External function - only callable from outside
     * @return A message string
     */
    function externalFunction() external pure returns (string memory) {
        // TODO: Return "This is external"
    }

    /**
     * @notice Internal function - callable from this contract and derived contracts
     * @return A message string
     */
    function internalFunction() internal pure returns (string memory) {
        // TODO: Return "This is internal"
    }

    /**
     * @notice Private function - only callable from this contract
     * @return A message string
     */
    function privateFunction() private pure returns (string memory) {
        // TODO: Return "This is private"
    }

    /**
     * @notice Wrapper to demonstrate calling internal function
     * @return The result from internal function
     */
    function callInternalFunction() public pure returns (string memory) {
        // TODO: Call and return result from internalFunction()
    }

    /**
     * @notice Wrapper to demonstrate calling private function
     * @return The result from private function
     */
    function callPrivateFunction() public pure returns (string memory) {
        // TODO: Call and return result from privateFunction()
    }
}
