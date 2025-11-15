// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 36: Access Control Bugs
 * @notice Learn about common access control vulnerabilities
 * @dev This contract contains intentional vulnerabilities for educational purposes
 */

// ============================================================================
// Vulnerable Contract 1: Uninitialized Owner
// ============================================================================

/**
 * @notice Wallet with uninitialized owner
 * @dev TODO: Find the vulnerability and write an exploit
 * Hint: What happens when owner is not set in the constructor?
 */
contract UninitializedWallet {
    address public owner;

    // TODO: What's wrong with this contract?
    // Hint: Is owner initialized anywhere?

    receive() external payable {}

    function setOwner(address newOwner) public {
        // TODO: Find the bug in this function
        require(owner == address(0), "Owner already set");
        owner = newOwner;
    }

    function withdraw() public {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }
}

// ============================================================================
// Vulnerable Contract 2: Missing Modifier
// ============================================================================

/**
 * @notice Contract with missing access control modifier
 * @dev TODO: Identify which function is missing protection
 */
contract MissingModifier {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // TODO: What's missing from this function?
    // Hint: Should anyone be able to call this?
    function emergencyWithdraw() public {
        payable(owner).transfer(address(this).balance);
    }

    function updateOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

// ============================================================================
// Vulnerable Contract 3: tx.origin Authentication
// ============================================================================

/**
 * @notice Contract using tx.origin for authentication
 * @dev TODO: Write a phishing contract to exploit this
 * Hint: What's the difference between tx.origin and msg.sender?
 */
contract TxOriginWallet {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    // TODO: Why is using tx.origin dangerous?
    // Hint: Can you trick the owner into calling your contract?
    function withdraw(address payable to, uint256 amount) public {
        require(tx.origin == owner, "Not owner");
        to.transfer(amount);
    }
}

/**
 * @notice TODO: Create a phishing contract to exploit TxOriginWallet
 * @dev This contract should trick the owner into draining their wallet
 */
contract TxOriginExploit {
    // TODO: Implement the exploit
    // Hint: Make the owner call a function that calls withdraw()

    // Your code here
}

// ============================================================================
// Vulnerable Contract 4: Role Escalation
// ============================================================================

/**
 * @notice Contract with role escalation vulnerability
 * @dev TODO: Find how anyone can become an admin
 */
contract VulnerableRoles {
    address public owner;
    mapping(address => bool) public admins;
    mapping(address => bool) public moderators;

    constructor() {
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    // TODO: What's wrong with this function?
    // Hint: Who can call this function?
    function addModerator(address newModerator) public {
        moderators[newModerator] = true;
    }

    // TODO: What's the issue here?
    // Hint: Should moderators be able to promote themselves?
    function promoteToAdmin(address user) public {
        require(moderators[msg.sender], "Not moderator");
        admins[user] = true;
    }

    function criticalOperation() public onlyAdmin {
        // Critical admin-only operation
    }
}

// ============================================================================
// Vulnerable Contract 5: Public Initialization
// ============================================================================

/**
 * @notice Upgradeable-style contract with public initializer
 * @dev TODO: Find how to take control of this contract
 * Hint: Can you call initialize after deployment?
 */
contract PublicInitializer {
    address public owner;
    bool private initialized;
    uint256 public totalSupply;
    mapping(address => uint256) public balances;

    // TODO: What's wrong with this initialization pattern?
    // Hint: Who can call this function?
    function initialize(address _owner) public {
        require(!initialized, "Already initialized");
        owner = _owner;
        totalSupply = 1000000;
        balances[_owner] = totalSupply;
        initialized = true;
    }

    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}

// ============================================================================
// Vulnerable Contract 6: Constructor Name Bug
// ============================================================================

/**
 * @notice Contract simulating old Solidity constructor name bug
 * @dev TODO: Understand how this was exploited (pre-0.5.0)
 * Note: This is a historical vulnerability
 */
contract ConstructorBug {
    address public owner;

    // In old Solidity, if you renamed the contract but not the constructor,
    // it became a regular public function!

    // Imagine this was originally called "OldContractName"
    // TODO: What happens if the constructor name doesn't match?

    constructor() {
        owner = msg.sender;
    }

    // This simulates what happened with Rubixi
    function OldContractName() public {
        owner = msg.sender;
    }

    function withdraw() public {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}

// ============================================================================
// Vulnerable Contract 7: Unprotected Delegatecall
// ============================================================================

/**
 * @notice Contract with unprotected delegatecall
 * @dev TODO: Write a malicious library to exploit this
 * Hint: Delegatecall executes in the caller's context
 */
contract UnprotectedDelegatecall {
    address public owner;
    uint256 public value;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    // TODO: Why is this dangerous?
    // Hint: What can a malicious library do?
    function executeLibrary(address library, bytes memory data) public {
        (bool success, ) = library.delegatecall(data);
        require(success, "Delegatecall failed");
    }
}

/**
 * @notice TODO: Create a malicious library to exploit delegatecall
 * @dev This should allow you to take ownership
 */
contract MaliciousLibrary {
    // TODO: Implement the exploit
    // Hint: Remember storage layout in delegatecall

    // Your code here
}

// ============================================================================
// Vulnerable Contract 8: No Access Control on Critical Function
// ============================================================================

/**
 * @notice Token contract with missing access control
 * @dev TODO: Find the function that anyone can call
 */
contract VulnerableToken {
    string public name = "Vulnerable Token";
    string public symbol = "VULN";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public owner;
    mapping(address => uint256) public balanceOf;

    constructor(uint256 initialSupply) {
        owner = msg.sender;
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function transfer(address to, uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }

    // TODO: What's missing from this function?
    // Hint: Should anyone be able to mint tokens?
    function mint(address to, uint256 amount) public {
        totalSupply += amount;
        balanceOf[to] += amount;
    }

    function burn(uint256 amount) public onlyOwner {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
    }
}

// ============================================================================
// TODO: Implement Exploits
// ============================================================================

/**
 * @notice Exploit for UninitializedWallet
 * @dev TODO: Take ownership and drain funds
 */
contract UninitializedWalletExploit {
    // TODO: Implement
    // Steps:
    // 1. Call setOwner with your address
    // 2. Call withdraw

    function exploit(UninitializedWallet wallet) public {
        // Your code here
    }
}

/**
 * @notice Exploit for MissingModifier
 * @dev TODO: Call the unprotected function
 */
contract MissingModifierExploit {
    // TODO: Implement
    // Steps:
    // 1. Call emergencyWithdraw directly

    function exploit(MissingModifier target) public {
        // Your code here
    }
}

/**
 * @notice Exploit for VulnerableRoles
 * @dev TODO: Escalate from nothing to admin
 */
contract RoleEscalationExploit {
    // TODO: Implement
    // Steps:
    // 1. Add yourself as moderator
    // 2. Promote yourself to admin
    // 3. Call critical function

    function exploit(VulnerableRoles target) public {
        // Your code here
    }
}

/**
 * @notice Exploit for PublicInitializer
 * @dev TODO: Initialize with yourself as owner
 */
contract PublicInitializerExploit {
    // TODO: Implement
    // Steps:
    // 1. Call initialize with your address
    // 2. Transfer all tokens to yourself

    function exploit(PublicInitializer target) public {
        // Your code here
    }
}

/**
 * @notice Exploit for VulnerableToken
 * @dev TODO: Mint unlimited tokens
 */
contract VulnerableTokenExploit {
    // TODO: Implement
    // Steps:
    // 1. Call mint with your address and large amount

    function exploit(VulnerableToken token) public {
        // Your code here
    }
}

// ============================================================================
// TODO: Create Secure Versions
// ============================================================================

/**
 * @notice TODO: Create a secure wallet with proper initialization
 * @dev Fix the UninitializedWallet vulnerabilities
 */
contract SecureWallet {
    // TODO: Implement secure version
    // Requirements:
    // 1. Owner initialized in constructor
    // 2. All privileged functions protected

    // Your code here
}

/**
 * @notice TODO: Create a secure contract with all modifiers in place
 * @dev Fix the MissingModifier vulnerabilities
 */
contract SecureModifiers {
    // TODO: Implement secure version
    // Requirements:
    // 1. All functions have appropriate modifiers
    // 2. No privileged function is public without protection

    // Your code here
}

/**
 * @notice TODO: Create a secure wallet using msg.sender
 * @dev Fix the TxOriginWallet vulnerability
 */
contract SecureMsgSenderWallet {
    // TODO: Implement secure version
    // Requirements:
    // 1. Use msg.sender instead of tx.origin
    // 2. Proper access control

    // Your code here
}

/**
 * @notice TODO: Create a secure role-based system
 * @dev Fix the VulnerableRoles issues
 */
contract SecureRoles {
    // TODO: Implement secure version
    // Requirements:
    // 1. Proper role hierarchy
    // 2. Protected role management functions
    // 3. No escalation paths

    // Your code here
}

/**
 * @notice TODO: Create a properly initialized contract
 * @dev Fix the PublicInitializer vulnerability
 */
contract SecureInitializer {
    // TODO: Implement secure version
    // Requirements:
    // 1. Protected initialization
    // 2. Single initialization guarantee

    // Your code here
}

/**
 * @notice TODO: Create a secure token with proper access control
 * @dev Fix the VulnerableToken issues
 */
contract SecureToken {
    // TODO: Implement secure version
    // Requirements:
    // 1. Mint function protected
    // 2. All privileged functions have modifiers

    // Your code here
}
