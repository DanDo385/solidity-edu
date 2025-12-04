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
 *
 * FUN FACT: The EVM stores logs separately from contract storage and builds
 * bloom filters so nodes can scan topics quickly. That design choice is why
 * explorers and rollups can cheaply filter events without touching full state.
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
    // Tip: Mirroring ERC20's Transfer schema makes block explorers and The Graph
    // integrations trivial. Indexed addresses act like filterable columns.

    // TODO: Declare event 'Approval' with:
    //       - indexed owner (address)
    //       - indexed spender (address)
    //       - amount (uint256)
    // Layer 2 angle: lean topic sets reduce calldata in rollup proofs.

    // TODO: Declare event 'Deposit' with:
    //       - indexed user (address)
    //       - amount (uint256)
    //       - timestamp (uint256)

    // TODO: Declare event 'StatusChanged' with:
    //       - indexed user (address)
    //       - oldStatus (string)
    //       - newStatus (string)
    // Strings live in event data (cheaper than storage writes) and are great for
    // human-readable dashboards, though not indexable.

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
        // Events here are your public receipts; they are cheaper than storing a
        // full transfer history and keep chain state slim (good for long-term
        // ETH issuance pressure).
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
