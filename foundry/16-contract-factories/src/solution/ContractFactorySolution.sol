// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ContractFactorySolution
 * @notice CREATE2 factory pattern - deterministic contract deployment
 * 
 * PURPOSE: Deploy contracts at predictable addresses (counterfactual deployments)
 * CS CONCEPTS: Deterministic hashing, address prediction, bytecode handling
 * 
 * CONNECTIONS:
 * - Project 01: keccak256 for address calculation (like mapping slots)
 * - Project 14: ABI encoding for bytecode construction
 * - Project 17: Used with minimal proxies for gas-efficient cloning
 * 
 * KEY: CREATE2 enables address prediction before deployment - enables counterfactual patterns
 */

/**
 * @title SimpleContract
 * @notice A simple contract to be deployed by the factory
 * @dev This contract will be deployed using CREATE2 for demonstration
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
 * @dev Complete implementation with address prediction and deployment tracking
 */
contract ContractFactory {
    // ============================================================
    // STATE VARIABLES
    // ============================================================

    // State - track deployments by salt
    mapping(bytes32 => address) public deployments;
    address[] public allDeployments;

    // ============================================================
    // CUSTOM ERRORS
    // ============================================================

    // Custom errors for better gas efficiency
    error AlreadyDeployed(bytes32 salt, address existing);
    error DeploymentFailed();

    // ============================================================
    // EVENTS
    // ============================================================

    event ContractDeployed(address indexed deployedAddress, bytes32 indexed salt, address indexed deployer);

    /**
     * @notice Predicts the address where a contract will be deployed
     * @dev Uses CREATE2 address calculation formula from EIP-1014
     * @param salt The salt for deterministic deployment
     * @param bytecode The creation bytecode (initcode) of the contract
     * @return predicted The predicted deployment address
     *
     * CREATE2 Formula:
     * address = keccak256(0xff ++ address ++ salt ++ keccak256(initCode))[12:]
     *
     * Breakdown:
     * 1. 0xff - Constant prefix to distinguish from CREATE
     * 2. address(this) - Factory contract address (deployer)
     * 3. salt - 32-byte value for uniqueness
     * 4. keccak256(bytecode) - Hash of the initcode
     * 5. [12:] - Take last 20 bytes (address is 20 bytes, hash is 32)
     * 
     * GAS OPTIMIZATION: Why use abi.encodePacked here?
     * - abi.encodePacked: Concatenates without padding
     * - For CREATE2 formula: We need exact byte concatenation
     * - abi.encode would add padding/offsets, breaking the formula
     * - Gas: ~2,100 gas (keccak256) + ~100 gas (memory operations)
     * 
     * ALTERNATIVE: Using assembly for CREATE2
     *   assembly {
     *     let ptr := mload(0x40)
     *     // ... manual bytecode construction
     *   }
     *   Costs: Similar gas, but more complex
     *   Trade-off: Current approach is clearer and maintainable
     * 
     * REAL-WORLD ANALOGY: Like calculating a GPS coordinate before
     * traveling there - you know exactly where you'll end up.
     */
    function predictAddress(bytes32 salt, bytes memory bytecode) public view returns (address predicted) {
        // Calculate the hash according to CREATE2 formula
        // GAS: ~2,100 gas for keccak256 + ~100 gas for memory operations
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), // Prefix to distinguish from CREATE
                address(this), // Deployer address (this factory)
                salt, // User-provided salt for uniqueness
                keccak256(bytecode) // Hash of the contract's initcode
            )
        );

        // Convert hash to address (take last 20 bytes)
        // uint160 is the size of an address
        // GAS: ~3 gas (type conversion)
        predicted = address(uint160(uint256(hash)));
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
     * The {salt: salt} syntax is Solidity's built-in CREATE2 support
     * It's syntactic sugar for the assembly create2 opcode
     * 
     * GAS COST BREAKDOWN:
     * - Deployment: ~32,000 gas (CREATE2 opcode)
     * - Constructor execution: ~20,000 gas (storage writes)
     * - Event emission: ~1,500 gas
     * - Storage tracking: ~5,000 gas (mapping + array push)
     * - Total: ~58,500 gas per deployment
     * 
     * GAS OPTIMIZATION: Why check deployments mapping first?
     * - Reading deployments[salt]: 1 SLOAD = ~100 gas (warm)
     * - If already deployed, saves: ~58,400 gas (entire deployment)
     * - Trade-off: Extra SLOAD on every call, but prevents wasted gas
     * 
     * REAL-WORLD ANALOGY: Like checking if a parking spot is already
     * taken before trying to park there - saves time and gas.
     */
    function deploy(bytes32 salt, address owner, uint256 value, string memory message)
        public
        returns (address deployed)
    {
        // Check if already deployed with this salt
        // GAS: 1 SLOAD = ~100 gas (warm), saves ~58k gas if already deployed
        if (deployments[salt] != address(0)) {
            revert AlreadyDeployed(salt, deployments[salt]);
        }

        // Deploy using CREATE2 with the {salt: salt} syntax
        // This is Solidity's high-level interface to CREATE2
        SimpleContract instance = new SimpleContract{salt: salt}(owner, value, message);
        deployed = address(instance);

        // Track the deployment
        deployments[salt] = deployed;
        allDeployments.push(deployed);

        // Emit event for off-chain tracking
        emit ContractDeployed(deployed, salt, msg.sender);
    }

    /**
     * @notice Deploys a contract using assembly and CREATE2
     * @dev Low-level CREATE2 deployment with arbitrary bytecode
     * @param salt The salt for deterministic deployment
     * @param bytecode The complete creation bytecode (initcode)
     * @return deployed The address of the deployed contract
     *
     * Assembly CREATE2 Breakdown:
     * ---------------------------
     * create2(v, p, n, s)
     * - v: value (ETH to send) - we use 0
     * - p: position/pointer (where bytecode starts in memory)
     * - n: size (length of bytecode in bytes)
     * - s: salt (32-byte value)
     *
     * Memory Layout:
     * --------------
     * When Solidity stores bytes in memory:
     * [0x00-0x1f]: 32 bytes storing the length
     * [0x20-...]: The actual bytes data
     *
     * That's why we use add(bytecode, 0x20) to skip the length prefix
     * and mload(bytecode) to read the length
     */
    function deployWithAssembly(bytes32 salt, bytes memory bytecode) public returns (address deployed) {
        assembly {
            // Call CREATE2 opcode
            // 0: send 0 ETH
            // add(bytecode, 0x20): skip length prefix (first 32 bytes)
            // mload(bytecode): read length from first 32 bytes
            // salt: the salt value
            deployed := create2(0, add(bytecode, 0x20), mload(bytecode), salt)

            // Check if deployment succeeded
            // extcodesize returns the size of code at an address
            // If 0, deployment failed
            if iszero(extcodesize(deployed)) {
                // Revert with no message (saves gas)
                revert(0, 0)
            }
        }

        // Track deployment
        deployments[salt] = deployed;
        allDeployments.push(deployed);

        emit ContractDeployed(deployed, salt, msg.sender);
    }

    /**
     * @notice Gets the creation bytecode for SimpleContract with constructor args
     * @dev Combines creationCode with encoded constructor arguments
     * @param owner Constructor argument
     * @param value Constructor argument
     * @param message Constructor argument
     * @return bytecode The complete creation bytecode (initcode)
     *
     * InitCode Composition:
     * ---------------------
     * The initcode is the bytecode that runs during contract creation.
     * It consists of two parts:
     *
     * 1. Creation Code (type(Contract).creationCode):
     *    - The bytecode that runs the constructor
     *    - Generated by the Solidity compiler
     *    - Does NOT include constructor arguments
     *
     * 2. Constructor Arguments (abi.encode(...)):
     *    - ABI-encoded constructor parameters
     *    - Appended to the creation code
     *    - Decoded by the constructor during execution
     *
     * The initcode runs once during deployment and returns the runtime code,
     * which is the actual contract code stored on-chain.
     */
    function getCreationBytecode(address owner, uint256 value, string memory message)
        public
        pure
        returns (bytes memory bytecode)
    {
        // Get the creation code (constructor bytecode without args)
        bytes memory creationCode = type(SimpleContract).creationCode;

        // Encode constructor arguments
        bytes memory constructorArgs = abi.encode(owner, value, message);

        // Concatenate: creationCode + constructorArgs = complete initcode
        bytecode = abi.encodePacked(creationCode, constructorArgs);
    }

    /**
     * @notice Predicts the address for a SimpleContract deployment
     * @dev Convenience function that builds bytecode and predicts address
     * @param salt The salt for deployment
     * @param owner Constructor argument
     * @param value Constructor argument
     * @param message Constructor argument
     * @return predicted The predicted deployment address
     *
     * This demonstrates the full flow:
     * 1. Build the initcode with constructor args
     * 2. Hash the initcode
     * 3. Calculate CREATE2 address
     *
     * Important: The constructor arguments affect the address!
     * Different args = different bytecode = different address
     */
    function predictSimpleContractAddress(bytes32 salt, address owner, uint256 value, string memory message)
        public
        view
        returns (address predicted)
    {
        // Get complete initcode with constructor arguments
        bytes memory bytecode = getCreationBytecode(owner, value, message);

        // Predict the deployment address
        predicted = predictAddress(salt, bytecode);
    }

    /**
     * @notice Generates a salt based on the sender and a nonce
     * @dev Helps create unique salts for each user
     * @param nonce A user-specific nonce
     * @return generatedSalt The generated salt
     *
     * Salt Generation Strategies:
     * ---------------------------
     * 1. User-based: keccak256(abi.encodePacked(user))
     * 2. User + nonce: keccak256(abi.encodePacked(user, nonce))
     * 3. Version-based: keccak256("v1.0.0")
     * 4. Time-based: keccak256(abi.encodePacked(block.timestamp, user))
     * 5. Random: keccak256(abi.encodePacked(blockhash(block.number - 1), user))
     *
     * This function uses user + nonce for maximum flexibility
     */
    function generateSalt(uint256 nonce) public view returns (bytes32 generatedSalt) {
        // Hash sender address and nonce for unique salt per user
        generatedSalt = keccak256(abi.encodePacked(msg.sender, nonce));
    }

    /**
     * @notice Checks if a contract has been deployed at an address
     * @param account The address to check
     * @return hasCode True if contract exists, false otherwise
     *
     * Uses extcodesize via .code.length
     * - 0: No contract (EOA or undeployed)
     * - >0: Contract deployed
     *
     * Note: In the same transaction as creation, extcodesize returns 0
     * until the constructor finishes. This is normal behavior.
     */
    function isDeployed(address account) public view returns (bool hasCode) {
        hasCode = account.code.length > 0;
    }

    /**
     * @notice Gets the total number of deployments
     * @return count The count of all deployments
     */
    function getDeploymentCount() public view returns (uint256 count) {
        count = allDeployments.length;
    }

    /**
     * @notice Gets the deployment address for a given salt
     * @param salt The salt used for deployment
     * @return deployment The deployed contract address (address(0) if not deployed)
     */
    function getDeployment(bytes32 salt) public view returns (address deployment) {
        deployment = deployments[salt];
    }

    /**
     * @notice Deploys and verifies the address matches prediction
     * @dev Helper function demonstrating the prediction workflow
     * @param salt The salt for deployment
     * @param owner Constructor argument
     * @param value Constructor argument
     * @param message Constructor argument
     * @return deployed The deployed contract address
     *
     * This function demonstrates that:
     * 1. We can predict the address before deployment
     * 2. The actual deployment matches the prediction
     * 3. Both use the same address calculation
     */
    function deployAndVerify(bytes32 salt, address owner, uint256 value, string memory message)
        public
        returns (address deployed)
    {
        // Predict the address first
        address predicted = predictSimpleContractAddress(salt, owner, value, message);

        // Deploy the contract
        deployed = deploy(salt, owner, value, message);

        // Verify they match (this assertion should never fail)
        assert(deployed == predicted);
    }
}

/**
 * EDUCATIONAL NOTES:
 * ==================
 *
 * 1. CREATE2 vs CREATE:
 * ---------------------
 * CREATE:  address = keccak256(rlp([sender, nonce]))[12:]
 * CREATE2: address = keccak256(0xff ++ sender ++ salt ++ initCodeHash)[12:]
 *
 * Key differences:
 * - CREATE depends on nonce (changes with each tx)
 * - CREATE2 depends on salt and bytecode (deterministic)
 * - CREATE2 enables address prediction before deployment
 *
 * 2. Bytecode Types:
 * ------------------
 * - Creation Code (initcode): Runs during deployment, includes constructor
 * - Runtime Code: Stored on-chain, executed when contract is called
 * - type(C).creationCode: Creation code WITHOUT constructor args
 * - type(C).runtimeCode: The final code that will be stored
 *
 * 3. Constructor Arguments:
 * -------------------------
 * Constructor args are ABI-encoded and APPENDED to creation code:
 * initCode = creationCode ++ abi.encode(arg1, arg2, ...)
 *
 * This means different constructor args = different initcode = different address!
 *
 * 4. Memory Layout:
 * -----------------
 * Solidity bytes in memory:
 * [0x00-0x1f]: length (32 bytes)
 * [0x20-...]: data
 *
 * Assembly operations:
 * - mload(bytecode): read 32 bytes at bytecode (the length)
 * - add(bytecode, 0x20): pointer to start of actual data
 *
 * 5. Assembly CREATE2:
 * --------------------
 * create2(value, offset, size, salt):
 * - value: Wei to send (usually 0)
 * - offset: Memory location of bytecode
 * - size: Bytecode length
 * - salt: 32-byte salt
 * - Returns: deployed address (0x0 if failed)
 *
 * Always check extcodesize after create2 to verify success!
 *
 * 6. Use Cases:
 * -------------
 * - State channels: Deploy only if dispute occurs
 * - Counterfactual contracts: Use address before deployment
 * - Cross-chain: Same address on multiple chains
 * - Account abstraction: Predictable wallet addresses
 * - Minimal proxies: Deterministic clone addresses
 *
 * 7. Security:
 * ------------
 * - Same salt = same address = revert if already deployed
 * - Frontrunning: Attacker can deploy with your salt first
 * - Bytecode verification: Ensure bytecode matches expectations
 * - After Cancun (EIP-6780): Cannot redeploy after selfdestruct
 *
 * 8. Gas Considerations:
 * ----------------------
 * - CREATE2 costs same as CREATE (32000 gas base)
 * - Assembly version might save small amount vs high-level
 * - Prediction is view function (free off-chain)
 * - Store deployments mapping for tracking
 *
 * 9. Cross-Chain Deployment:
 * --------------------------
 * To deploy to same address on multiple chains:
 * - Same factory address on each chain
 * - Same salt
 * - Same bytecode (same Solidity version, settings, args)
 * - Deploy from same nonce on each chain (for factory deployment)
 *
 * 10. Common Pitfalls:
 * --------------------
 * - Forgetting constructor args in bytecode
 * - Using wrong factory address in prediction
 * - Compiler settings affecting bytecode
 * - Assuming bytecode is constant across versions
 * - Not checking if address is already deployed
 */

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. CREATE2 ENABLES DETERMINISTIC DEPLOYMENT
 *    ✅ Address = keccak256(0xff ++ sender ++ salt ++ initCodeHash)[12:]
 *    ✅ Independent of nonce (unlike CREATE)
 *    ✅ Predictable before deployment
 *    ✅ Real-world: Like reserving a parking spot before arriving
 *
 * 2. ADDRESS DEPENDS ON THREE FACTORS
 *    ✅ Factory address (deployer)
 *    ✅ Salt (32-byte value)
 *    ✅ Initcode hash (bytecode + constructor args)
 *    ✅ Change any = different address
 *
 * 3. INITCODE INCLUDES CONSTRUCTOR ARGS
 *    ✅ initcode = creationCode + abi.encode(constructor args)
 *    ✅ Different constructor args = different address
 *    ✅ Must include args in address calculation
 *    ✅ Real-world: Like including your name when reserving a spot
 *
 * 4. CREATE2 ENABLES COUNTERFACTUAL CONTRACTS
 *    ✅ Predict address before deployment
 *    ✅ Send funds to predicted address
 *    ✅ Deploy only when needed
 *    ✅ Saves gas in optimistic cases
 *
 * 5. SALT PROVIDES UNIQUENESS
 *    ✅ Same salt + same bytecode = same address
 *    ✅ Different salt = different address
 *    ✅ Use user-specific salts to prevent collisions
 *    ✅ Common: keccak256(userAddress, nonce)
 *
 * 6. SECURITY CONSIDERATIONS
 *    ✅ Check if address already deployed (prevents reverts)
 *    ✅ Protect against frontrunning (authorize deployers)
 *    ✅ Verify bytecode matches expectations
 *    ✅ After Cancun: Cannot redeploy after selfdestruct
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Forgetting constructor args in initcode (wrong address!)
 * ❌ Using wrong factory address in prediction
 * ❌ Not checking if address already deployed
 * ❌ Assuming bytecode is constant (compiler settings matter!)
 * ❌ Not protecting against frontrunning
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study minimal proxy pattern (Project 17) - uses CREATE2
 * • Explore counterfactual contract patterns
 * • Learn about cross-chain deployment strategies
 * • Move to Project 17 to learn about minimal proxies
 */
