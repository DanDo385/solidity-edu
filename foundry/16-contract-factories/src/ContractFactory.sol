// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Project 16: Contract Factories (CREATE2)
 * @notice Learn deterministic contract deployment with CREATE2
 * @dev Implement a factory that deploys contracts to predictable addresses
 */

/**
 * @title SimpleContract
 * @notice A simple contract to be deployed by the factory
 * @dev This contract will be deployed using CREATE2
 */
contract SimpleContract {
    address public owner;
    uint256 public value;
    string public message;

    event Initialized(address indexed owner, uint256 value, string message);

    constructor(address _owner, uint256 _value, string memory _message) {
        owner = _owner;
        value = _value;
        message = _message;
        emit Initialized(_owner, _value, _message);
    }

    function getValue() external view returns (uint256) {
        return value;
    }
}

/**
 * @title ContractFactory
 * @notice Factory for deploying contracts with CREATE2
 * @dev Implements deterministic deployment and address prediction
 */
contract ContractFactory {
    // ============================================================
    // STATE VARIABLES
    // ============================================================

    mapping(bytes32 => address) public deployments;
    address[] public allDeployments;

    // ============================================================
    // EVENTS
    // ============================================================

    event ContractDeployed(address indexed deployedAddress, bytes32 indexed salt, address indexed deployer);

    /**
     * @notice Predicts the address where a contract will be deployed
     * @dev Uses CREATE2 address calculation formula
     * @param salt The salt for deterministic deployment
     * @param bytecode The creation bytecode of the contract
     * @return The predicted address
     *
     * Formula: keccak256(0xff ++ address ++ salt ++ keccak256(initCode))[12:]
     *
     * TODO: Implement address prediction
     * 1. Create the hash using abi.encodePacked with:
     *    - bytes1(0xff)
     *    - address(this) - the factory address
     *    - salt
     *    - keccak256(bytecode) - hash of the initcode
     * 2. Convert the hash to an address
     * 3. Return the predicted address
     */
    function predictAddress(bytes32 salt, bytes memory bytecode) public view returns (address) {
        // TODO: Calculate and return the CREATE2 address
        return address(0); // Placeholder
    }

    /**
     * @notice Deploys a SimpleContract using CREATE2
     * @dev Deploys to deterministic address based on salt
     * @param salt The salt for deterministic deployment
     * @param owner The owner of the deployed contract
     * @param value The initial value
     * @param message The initial message
     * @return deployed The address of the deployed contract
     *
     * TODO: Implement CREATE2 deployment
     * 1. Check that this salt hasn't been used (deployments[salt] == address(0))
     * 2. Deploy using: new SimpleContract{salt: salt}(owner, value, message)
     * 3. Store the deployment in the mapping
     * 4. Add to allDeployments array
     * 5. Emit ContractDeployed event
     * 6. Return the deployed address
     */
    function deploy(bytes32 salt, address owner, uint256 value, string memory message)
        public
        returns (address deployed)
    {
        // TODO: Implement CREATE2 deployment
        // Hint: Use the {salt: salt} syntax with new
        return address(0); // Placeholder
    }

    /**
     * @notice Deploys a contract using assembly and CREATE2
     * @dev Low-level CREATE2 deployment with arbitrary bytecode
     * @param salt The salt for deterministic deployment
     * @param bytecode The complete creation bytecode (initcode)
     * @return deployed The address of the deployed contract
     *
     * TODO: Implement assembly-based CREATE2
     * 1. Use assembly { } block
     * 2. Call create2(value, offset, size, salt)
     *    - value: 0 (no ETH sent)
     *    - offset: add(bytecode, 0x20) - skip length prefix
     *    - size: mload(bytecode) - read length
     *    - salt: salt value
     * 3. Check deployment succeeded with extcodesize
     * 4. Revert if deployment failed
     * 5. Return the deployed address
     */
    function deployWithAssembly(bytes32 salt, bytes memory bytecode) public returns (address deployed) {
        // TODO: Implement assembly CREATE2
        // assembly {
        //     deployed := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        //     if iszero(extcodesize(deployed)) {
        //         revert(0, 0)
        //     }
        // }
        return address(0); // Placeholder
    }

    /**
     * @notice Gets the creation bytecode for SimpleContract with constructor args
     * @dev Combines creationCode with encoded constructor arguments
     * @param owner Constructor argument
     * @param value Constructor argument
     * @param message Constructor argument
     * @return The complete creation bytecode (initcode)
     *
     * TODO: Implement bytecode generation
     * 1. Get the creation code: type(SimpleContract).creationCode
     * 2. Encode constructor arguments: abi.encode(owner, value, message)
     * 3. Concatenate them: abi.encodePacked(creationCode, constructorArgs)
     * 4. Return the complete bytecode
     */
    function getCreationBytecode(address owner, uint256 value, string memory message)
        public
        pure
        returns (bytes memory)
    {
        // TODO: Return creation bytecode with constructor args
        return ""; // Placeholder
    }

    /**
     * @notice Predicts the address for a SimpleContract deployment
     * @dev Convenience function that builds bytecode and predicts address
     * @param salt The salt for deployment
     * @param owner Constructor argument
     * @param value Constructor argument
     * @param message Constructor argument
     * @return The predicted deployment address
     *
     * TODO: Implement convenience prediction
     * 1. Get the creation bytecode using getCreationBytecode
     * 2. Call predictAddress with the salt and bytecode
     * 3. Return the predicted address
     */
    function predictSimpleContractAddress(bytes32 salt, address owner, uint256 value, string memory message)
        public
        view
        returns (address)
    {
        // TODO: Generate bytecode and predict address
        return address(0); // Placeholder
    }

    /**
     * @notice Generates a salt based on the sender and a nonce
     * @dev Helps create unique salts for each user
     * @param nonce A user-specific nonce
     * @return The generated salt
     *
     * TODO: Implement salt generation
     * 1. Hash msg.sender and nonce together
     * 2. Return the resulting bytes32 hash
     */
    function generateSalt(uint256 nonce) public view returns (bytes32) {
        // TODO: Generate unique salt for msg.sender
        return bytes32(0); // Placeholder
    }

    /**
     * @notice Checks if a contract has been deployed at an address
     * @param account The address to check
     * @return True if contract exists, false otherwise
     */
    function isDeployed(address account) public view returns (bool) {
        return account.code.length > 0;
    }

    /**
     * @notice Gets the total number of deployments
     * @return The count of all deployments
     */
    function getDeploymentCount() public view returns (uint256) {
        return allDeployments.length;
    }

    /**
     * @notice Gets the deployment address for a given salt
     * @param salt The salt used for deployment
     * @return The deployed contract address (address(0) if not deployed)
     */
    function getDeployment(bytes32 salt) public view returns (address) {
        return deployments[salt];
    }
}

/**
 * LEARNING NOTES:
 *
 * CREATE2 Address Formula:
 * -------------------------
 * address = keccak256(0xff ++ deployer ++ salt ++ keccak256(initCode))[12:]
 *
 * Components:
 * - 0xff: Constant prefix (1 byte)
 * - deployer: Factory contract address (20 bytes)
 * - salt: User-provided salt (32 bytes)
 * - keccak256(initCode): Hash of creation bytecode (32 bytes)
 *
 * InitCode vs Runtime Code:
 * -------------------------
 * - InitCode: Bytecode that runs during deployment (includes constructor)
 * - Runtime Code: Code stored on-chain after deployment
 * - type(Contract).creationCode returns initCode WITHOUT constructor args
 * - Must append encoded constructor args to creationCode
 *
 * Assembly CREATE2:
 * -----------------
 * create2(value, offset, size, salt)
 * - value: ETH to send (usually 0)
 * - offset: Where bytecode starts in memory
 * - size: Length of bytecode
 * - salt: 32-byte salt value
 * - Returns: deployed address (0 on failure)
 *
 * Memory Layout:
 * --------------
 * bytes memory data in Solidity:
 * [0x00-0x1f]: length (32 bytes)
 * [0x20-...]: actual data
 *
 * That's why we use add(bytecode, 0x20) - to skip the length prefix
 *
 * Security Considerations:
 * ------------------------
 * 1. Same salt = same address (will revert if already deployed)
 * 2. Different constructor args = different bytecode = different address
 * 3. Different factory = different address
 * 4. Can predict address before deployment
 * 5. After Cancun: cannot redeploy to same address after selfdestruct
 *
 * Use Cases:
 * ----------
 * - Counterfactual contracts (state channels, payment channels)
 * - Deterministic wallet addresses
 * - Cross-chain deployment to same address
 * - Minimal proxy factories (EIP-1167)
 * - Account abstraction (EIP-4337)
 */
