// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EventsLogging
 * @notice Skeleton contract for learning Solidity events and logging
 * @dev Complete the TODOs to implement all functionality
 *
 * LEARNING GOALS:
 * 1. Declare events with indexed parameters
 * 2. Emit events for state changes
 * 3. Understand gas costs of events vs storage
 * 4. Design event schemas for off-chain indexing
 */
contract EventsLogging {
    // ============================================================
    // STATE VARIABLES
    // ============================================================

    // TODO: Declare public address variable 'owner'
    // TODO: Declare mapping 'balances' from address to uint256
    // TODO: Declare mapping 'allowances' from address to address to uint256

    // ============================================================
    // EVENTS
    // ============================================================

    // TODO: Declare event 'Transfer' with:
    //       - indexed sender (address)
    //       - indexed recipient (address)
    //       - amount (uint256)

    // TODO: Declare event 'Approval' with:
    //       - indexed owner (address)
    //       - indexed spender (address)
    //       - amount (uint256)

    // TODO: Declare event 'Deposit' with:
    //       - indexed user (address)
    //       - amount (uint256)
    //       - timestamp (uint256)

    // TODO: Declare event 'StatusChanged' with:
    //       - indexed user (address)
    //       - oldStatus (string)
    //       - newStatus (string)

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    constructor() {
        // TODO: Set owner to msg.sender
    }

    // ============================================================
    // FUNCTIONS THAT EMIT EVENTS
    // ============================================================

    function transfer(address _to, uint256 _amount) public {
        // TODO: Implement transfer logic
        // 1. Check balance sufficient
        // 2. Update balances
        // 3. Emit Transfer event
    }

    function approve(address _spender, uint256 _amount) public {
        // TODO: Implement approval logic
        // 1. Update allowances mapping
        // 2. Emit Approval event
    }

    function deposit() public payable {
        // TODO: Implement deposit logic
        // 1. Update balance
        // 2. Emit Deposit event with block.timestamp
    }

    function updateStatus(string memory _newStatus) public {
        // TODO: Implement status update
        // 1. Store old status (if tracking)
        // 2. Update to new status
        // 3. Emit StatusChanged event
    }

    // ============================================================
    // VIEW FUNCTIONS
    // ============================================================

    function balanceOf(address _account) public view returns (uint256) {
        // TODO: Return balance of account
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        // TODO: Return allowance
    }
}
