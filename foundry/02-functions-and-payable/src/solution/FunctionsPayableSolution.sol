// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FunctionsPayableSolution
 * @notice Educational contract demonstrating function visibility, payable functions, and ETH handling
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 *                        CONTRACT PURPOSE
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * This contract builds on Project 01's storage concepts and introduces:
 * 
 * 1. **Function Visibility**: public, external, internal, private
 *    - Controls who can call functions
 *    - Affects gas costs and call patterns
 *    - Essential for access control and code organization
 * 
 * 2. **Payable Functions**: Receiving native ETH
 *    - Functions that can receive ETH with transactions
 *    - msg.value contains the amount sent
 *    - Critical for DeFi protocols and payment systems
 * 
 * 3. **Checks-Effects-Interactions (CEI) Pattern**
 *    - THE most important security pattern in Solidity
 *    - Prevents reentrancy attacks
 *    - Used by all secure DeFi protocols
 * 
 * 4. **Special Functions**: receive() and fallback()
 *    - Handle unexpected calls and plain ETH transfers
 *    - Important for contract composability
 * 
 * REAL-WORLD USE CASES:
 * - Simple banking contracts (deposit/withdraw)
 * - Payment escrow systems
 * - Foundation for DeFi protocols (lending, staking)
 * - Any contract that handles native ETH
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 *                    COMPUTER SCIENCE CONCEPTS
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * 1. **Function Visibility (Access Control)**
 *    - Similar to public/private/protected in OOP languages
 *    - Controls function callability (who can call)
 *    - Affects gas costs (external saves calldata copy)
 * 
 * 2. **Message Passing with Value**
 *    - Functions can receive value (ETH) along with call
 *    - Similar to sending money with a message
 *    - msg.value contains amount in wei
 * 
 * 3. **State Machine Pattern (CEI)**
 *    - Checks: Validate inputs first
 *    - Effects: Update state second
 *    - Interactions: External calls last
 *    - Prevents reentrancy (critical security pattern)
 * 
 * 4. **Function Overloading (receive/fallback)**
 *    - Special functions for handling unexpected calls
 *    - receive(): Plain ETH transfers
 *    - fallback(): Unknown function calls
 * 
 * CONNECTION TO PROJECT 01:
 * - Uses mapping storage pattern for balances
 * - Uses owner pattern for access control
 * - Builds on storage layout concepts
 * 
 * @dev This is the SECOND project - builds on storage concepts from Project 01
 */
contract FunctionsPayableSolution {
    address public owner; // Slot 0: set once, reused for access checks.
    mapping(address => uint256) public balances; // Slot 1: deposit tracking (Project 01 mapping layout).

    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);

    constructor() payable {
        owner = msg.sender; // Classic deployer-owns pattern you’ll generalize in Project 04.
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
       
    }

    // VISIBILITY & PURE/VIEWS -------------------------------------------------
    function publicSquare(uint256 x) public pure returns (uint256) {
        return x * x; // Callable internally and externally.
    }

    function externalCube(uint256 x) external pure returns (uint256) {
        return x * x * x; // External only—saves calldata copy when called from off-chain.
    }

    function internalDouble(uint256 x) internal pure returns (uint256) {
        return 2 * x; // Internal use only; demonstrates keyword.
    }

    function privateTriple(uint256 x) private pure returns (uint256) {
        return 3 * x; // Private to this contract.
    }

    // PAYABLE ENTRYPOINTS -----------------------------------------------------
    function deposit() public payable {
        require(msg.value > 0, "No ETH sent");
        balances[msg.sender] += msg.value; // Read-modify-write; keeps running total.
        emit Deposit(msg.sender, msg.value);
    }

    receive() external payable {
        balances[msg.sender] += msg.value; // Same accounting path as deposit(); minimal logic per best practice.
        emit Deposit(msg.sender, msg.value);
    }

    fallback() external payable {
        // Fallback handles unexpected function selectors; keep tiny to avoid reentrancy surface.
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // WITHDRAWALS & CEI -------------------------------------------------------
    function withdraw(uint256 amount) public {
        require(amount > 0, "Amount must be > 0");
        require(balances[msg.sender] >= amount, "Insufficient funds");

        balances[msg.sender] -= amount; // Effects before interaction (CEI pattern from Project 02 theory).
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    function ownerWithdraw(uint256 amount) public {
        require(msg.sender == owner, "Not owner");
        require(address(this).balance >= amount, "Insufficient contract balance");

        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "Owner withdraw failed");

        emit Withdraw(owner, amount);
    }

    // HELPERS -----------------------------------------------------------------
    function viewBalance(address account) public view returns (uint256) {
        return balances[account];
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function demoInternalCall(uint256 x) public pure returns (uint256 doubled, uint256 tripled) {
        doubled = internalDouble(x);
        tripled = privateTriple(x);
    }
}
