// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FunctionsPayableSolution
 * @notice Minimal reference for visibility, payable flows, and safe ETH handling.
 * @dev Focuses on syntax and CEI ordering; the README carries the full theory and examples.
 */
contract FunctionsPayableSolution {
    address public owner; // Slot 0: set once, reused for access checks.
    mapping(address => uint256) public balances; // Slot 1: deposit tracking (Project 01 mapping layout).

    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);

    constructor() {
        owner = msg.sender; // Classic deployer-owns pattern you’ll generalize in Project 04.
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

    function demoInternalCall(uint256 x) public pure returns (uint256 doubled, uint256 tripled) {
        doubled = internalDouble(x);
        tripled = privateTriple(x);
    }
}
