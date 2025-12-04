// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {ContractFactory, SimpleContract} from "../src/solution/ContractFactorySolution.sol";

/**
 * @title Project 16 Tests
 * @notice Comprehensive tests for CREATE2 factory implementation
 * @dev Tests address prediction, deployment, salt usage, and edge cases
 */
contract ContractFactoryTest is Test {
    ContractFactory public factory;

    // Test parameters
    address public testOwner = address(0x1234);
    uint256 public testValue = 42;
    string public testMessage = "Hello CREATE2";

    // Events to test
    event ContractDeployed(address indexed deployedAddress, bytes32 indexed salt, address indexed deployer);

    function setUp() public {
        factory = new ContractFactory();
    }

    /*//////////////////////////////////////////////////////////////
                        ADDRESS PREDICTION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test basic address prediction matches deployment
    function test_PredictAddress_MatchesDeployment() public {
        bytes32 salt = bytes32(uint256(1));

        // Predict address before deployment
        address predicted = factory.predictSimpleContractAddress(salt, testOwner, testValue, testMessage);

        // Deploy contract
        address deployed = factory.deploy(salt, testOwner, testValue, testMessage);

        // Verify prediction was correct
        assertEq(deployed, predicted, "Deployed address should match prediction");
    }

    /// @notice Test address prediction with different salts
    function test_PredictAddress_DifferentSalts() public {
        bytes32 salt1 = bytes32(uint256(1));
        bytes32 salt2 = bytes32(uint256(2));

        address predicted1 = factory.predictSimpleContractAddress(salt1, testOwner, testValue, testMessage);
        address predicted2 = factory.predictSimpleContractAddress(salt2, testOwner, testValue, testMessage);

        // Different salts should produce different addresses
        assertTrue(predicted1 != predicted2, "Different salts should give different addresses");
    }

    /// @notice Test address prediction with different constructor arguments
    function test_PredictAddress_DifferentConstructorArgs() public {
        bytes32 salt = bytes32(uint256(1));

        address predicted1 = factory.predictSimpleContractAddress(salt, testOwner, testValue, "Message 1");
        address predicted2 = factory.predictSimpleContractAddress(salt, testOwner, testValue, "Message 2");

        // Different constructor args = different bytecode = different address
        assertTrue(predicted1 != predicted2, "Different constructor args should give different addresses");
    }

    /// @notice Test manual address prediction using raw bytecode
    function test_PredictAddress_ManualCalculation() public {
        bytes32 salt = keccak256("test-salt");

        // Get the bytecode manually
        bytes memory bytecode = factory.getCreationBytecode(testOwner, testValue, testMessage);

        // Predict using raw bytecode
        address predicted = factory.predictAddress(salt, bytecode);

        // Deploy
        address deployed = factory.deploy(salt, testOwner, testValue, testMessage);

        assertEq(deployed, predicted, "Manual prediction should match deployment");
    }

    /// @notice Test that prediction is deterministic (same inputs = same output)
    function test_PredictAddress_Deterministic() public {
        bytes32 salt = keccak256("deterministic-test");

        address predicted1 = factory.predictSimpleContractAddress(salt, testOwner, testValue, testMessage);
        address predicted2 = factory.predictSimpleContractAddress(salt, testOwner, testValue, testMessage);

        assertEq(predicted1, predicted2, "Prediction should be deterministic");
    }

    /*//////////////////////////////////////////////////////////////
                        DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test basic deployment with CREATE2
    function test_Deploy_Basic() public {
        bytes32 salt = bytes32(uint256(1));

        // Deploy
        address deployed = factory.deploy(salt, testOwner, testValue, testMessage);

        // Verify contract exists
        assertTrue(factory.isDeployed(deployed), "Contract should be deployed");
        assertTrue(deployed.code.length > 0, "Contract should have code");

        // Verify initialization
        SimpleContract instance = SimpleContract(deployed);
        assertEq(instance.owner(), testOwner, "Owner should be set correctly");
        assertEq(instance.value(), testValue, "Value should be set correctly");
        assertEq(instance.message(), testMessage, "Message should be set correctly");
    }

    /// @notice Test deployment emits event
    function test_Deploy_EmitsEvent() public {
        bytes32 salt = bytes32(uint256(1));

        address predicted = factory.predictSimpleContractAddress(salt, testOwner, testValue, testMessage);

        // Expect event
        vm.expectEmit(true, true, true, true);
        emit ContractDeployed(predicted, salt, address(this));

        factory.deploy(salt, testOwner, testValue, testMessage);
    }

    /// @notice Test deployment tracking in mapping
    function test_Deploy_TracksDeployment() public {
        bytes32 salt = bytes32(uint256(1));

        address deployed = factory.deploy(salt, testOwner, testValue, testMessage);

        // Check deployment is tracked
        assertEq(factory.getDeployment(salt), deployed, "Deployment should be tracked by salt");
        assertEq(factory.deployments(salt), deployed, "Deployments mapping should be updated");
    }

    /// @notice Test deployment tracking in array
    function test_Deploy_AddsToArray() public {
        bytes32 salt1 = bytes32(uint256(1));
        bytes32 salt2 = bytes32(uint256(2));

        assertEq(factory.getDeploymentCount(), 0, "Should start with 0 deployments");

        factory.deploy(salt1, testOwner, testValue, testMessage);
        assertEq(factory.getDeploymentCount(), 1, "Should have 1 deployment");

        factory.deploy(salt2, testOwner, testValue, testMessage);
        assertEq(factory.getDeploymentCount(), 2, "Should have 2 deployments");
    }

    /// @notice Test cannot deploy twice with same salt
    function test_Deploy_RevertsOnDuplicate() public {
        bytes32 salt = bytes32(uint256(1));

        // First deployment succeeds
        factory.deploy(salt, testOwner, testValue, testMessage);

        // Second deployment with same salt should revert
        vm.expectRevert();
        factory.deploy(salt, testOwner, testValue, testMessage);
    }

    /// @notice Test can deploy with different salts
    function test_Deploy_MultipleSalts() public {
        bytes32 salt1 = keccak256("salt1");
        bytes32 salt2 = keccak256("salt2");
        bytes32 salt3 = keccak256("salt3");

        address deployed1 = factory.deploy(salt1, testOwner, testValue, testMessage);
        address deployed2 = factory.deploy(salt2, testOwner, testValue, testMessage);
        address deployed3 = factory.deploy(salt3, testOwner, testValue, testMessage);

        // All addresses should be different
        assertTrue(deployed1 != deployed2, "Deployment 1 and 2 should differ");
        assertTrue(deployed1 != deployed3, "Deployment 1 and 3 should differ");
        assertTrue(deployed2 != deployed3, "Deployment 2 and 3 should differ");

        // All should be tracked
        assertEq(factory.getDeployment(salt1), deployed1);
        assertEq(factory.getDeployment(salt2), deployed2);
        assertEq(factory.getDeployment(salt3), deployed3);
    }

    /*//////////////////////////////////////////////////////////////
                    ASSEMBLY DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test deployment with assembly
    function test_DeployWithAssembly_Basic() public {
        bytes32 salt = keccak256("assembly-test");

        // Get bytecode
        bytes memory bytecode = factory.getCreationBytecode(testOwner, testValue, testMessage);

        // Deploy with assembly
        address deployed = factory.deployWithAssembly(salt, bytecode);

        // Verify deployment
        assertTrue(factory.isDeployed(deployed), "Contract should be deployed");
        assertTrue(deployed.code.length > 0, "Contract should have code");

        // Verify it's tracked
        assertEq(factory.getDeployment(salt), deployed, "Assembly deployment should be tracked");
    }

    /// @notice Test assembly deployment matches prediction
    function test_DeployWithAssembly_MatchesPrediction() public {
        bytes32 salt = keccak256("assembly-prediction");

        bytes memory bytecode = factory.getCreationBytecode(testOwner, testValue, testMessage);

        // Predict
        address predicted = factory.predictAddress(salt, bytecode);

        // Deploy with assembly
        address deployed = factory.deployWithAssembly(salt, bytecode);

        assertEq(deployed, predicted, "Assembly deployment should match prediction");
    }

    /// @notice Test assembly deployment initializes correctly
    function test_DeployWithAssembly_Initializes() public {
        bytes32 salt = keccak256("assembly-init");

        bytes memory bytecode = factory.getCreationBytecode(testOwner, testValue, testMessage);
        address deployed = factory.deployWithAssembly(salt, bytecode);

        // Check initialization
        SimpleContract instance = SimpleContract(deployed);
        assertEq(instance.owner(), testOwner);
        assertEq(instance.value(), testValue);
        assertEq(instance.message(), testMessage);
    }

    /*//////////////////////////////////////////////////////////////
                        BYTECODE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test getting creation bytecode
    function test_GetCreationBytecode_Valid() public {
        bytes memory bytecode = factory.getCreationBytecode(testOwner, testValue, testMessage);

        // Should not be empty
        assertTrue(bytecode.length > 0, "Bytecode should not be empty");

        // Should be longer than just creation code (includes constructor args)
        assertTrue(
            bytecode.length > type(SimpleContract).creationCode.length,
            "Bytecode should include constructor args"
        );
    }

    /// @notice Test bytecode with different args produces different bytecode
    function test_GetCreationBytecode_DifferentArgs() public {
        bytes memory bytecode1 = factory.getCreationBytecode(testOwner, testValue, "Message 1");
        bytes memory bytecode2 = factory.getCreationBytecode(testOwner, testValue, "Message 2");

        // Different args = different bytecode
        assertTrue(
            keccak256(bytecode1) != keccak256(bytecode2), "Different args should produce different bytecode"
        );
    }

    /*//////////////////////////////////////////////////////////////
                        SALT GENERATION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test salt generation is deterministic per user
    function test_GenerateSalt_Deterministic() public {
        uint256 nonce = 1;

        bytes32 salt1 = factory.generateSalt(nonce);
        bytes32 salt2 = factory.generateSalt(nonce);

        assertEq(salt1, salt2, "Same nonce should produce same salt");
    }

    /// @notice Test salt generation differs by nonce
    function test_GenerateSalt_DifferentNonces() public {
        bytes32 salt1 = factory.generateSalt(1);
        bytes32 salt2 = factory.generateSalt(2);

        assertTrue(salt1 != salt2, "Different nonces should produce different salts");
    }

    /// @notice Test salt generation differs by sender
    function test_GenerateSalt_DifferentSenders() public {
        uint256 nonce = 1;

        bytes32 salt1 = factory.generateSalt(nonce);

        // Switch to different sender
        vm.prank(address(0x9999));
        bytes32 salt2 = factory.generateSalt(nonce);

        assertTrue(salt1 != salt2, "Different senders should produce different salts");
    }

    /*//////////////////////////////////////////////////////////////
                    HELPER FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test isDeployed returns false for undeployed address
    function test_IsDeployed_FalseForEOA() public {
        address eoa = address(0x1234);
        assertFalse(factory.isDeployed(eoa), "EOA should not be deployed");
    }

    /// @notice Test isDeployed returns true after deployment
    function test_IsDeployed_TrueAfterDeploy() public {
        bytes32 salt = bytes32(uint256(1));
        address deployed = factory.deploy(salt, testOwner, testValue, testMessage);

        assertTrue(factory.isDeployed(deployed), "Deployed contract should return true");
    }

    /// @notice Test deployment count tracking
    function test_GetDeploymentCount_Accurate() public {
        assertEq(factory.getDeploymentCount(), 0);

        factory.deploy(bytes32(uint256(1)), testOwner, testValue, testMessage);
        assertEq(factory.getDeploymentCount(), 1);

        factory.deploy(bytes32(uint256(2)), testOwner, testValue, testMessage);
        assertEq(factory.getDeploymentCount(), 2);

        factory.deploy(bytes32(uint256(3)), testOwner, testValue, testMessage);
        assertEq(factory.getDeploymentCount(), 3);
    }

    /// @notice Test getDeployment returns zero for unused salt
    function test_GetDeployment_ZeroForUnused() public {
        bytes32 unusedSalt = keccak256("unused");
        assertEq(factory.getDeployment(unusedSalt), address(0), "Unused salt should return zero address");
    }

    /*//////////////////////////////////////////////////////////////
                    DEPLOY AND VERIFY TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test deployAndVerify function
    function test_DeployAndVerify_Success() public {
        bytes32 salt = keccak256("verify-test");

        address deployed = factory.deployAndVerify(salt, testOwner, testValue, testMessage);

        // Should be deployed
        assertTrue(factory.isDeployed(deployed));

        // Should match prediction
        address predicted = factory.predictSimpleContractAddress(salt, testOwner, testValue, testMessage);
        assertEq(deployed, predicted);
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Fuzz test: prediction always matches deployment
    function testFuzz_PredictionMatchesDeployment(bytes32 salt, uint256 value, address owner) public {
        // Skip if salt already used
        if (factory.getDeployment(salt) != address(0)) return;

        // Ensure valid owner (not zero address)
        vm.assume(owner != address(0));

        string memory message = "Fuzz test";

        // Predict
        address predicted = factory.predictSimpleContractAddress(salt, owner, value, message);

        // Deploy
        address deployed = factory.deploy(salt, owner, value, message);

        // Should match
        assertEq(deployed, predicted, "Fuzz: deployed should match predicted");
    }

    /// @notice Fuzz test: different salts produce different addresses
    function testFuzz_DifferentSalts(bytes32 salt1, bytes32 salt2) public {
        vm.assume(salt1 != salt2);

        address predicted1 = factory.predictSimpleContractAddress(salt1, testOwner, testValue, testMessage);
        address predicted2 = factory.predictSimpleContractAddress(salt2, testOwner, testValue, testMessage);

        assertTrue(predicted1 != predicted2, "Fuzz: different salts should give different addresses");
    }

    /// @notice Fuzz test: generated salts are unique per nonce
    function testFuzz_GeneratedSaltsUnique(uint256 nonce1, uint256 nonce2) public {
        vm.assume(nonce1 != nonce2);

        bytes32 salt1 = factory.generateSalt(nonce1);
        bytes32 salt2 = factory.generateSalt(nonce2);

        assertTrue(salt1 != salt2, "Fuzz: different nonces should give different salts");
    }

    /*//////////////////////////////////////////////////////////////
                        INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Integration test: full workflow
    function test_Integration_FullWorkflow() public {
        // 1. Generate a salt
        bytes32 salt = factory.generateSalt(1);

        // 2. Predict address
        address predicted = factory.predictSimpleContractAddress(salt, testOwner, testValue, testMessage);

        // 3. Verify not deployed yet
        assertFalse(factory.isDeployed(predicted));

        // 4. Deploy
        address deployed = factory.deploy(salt, testOwner, testValue, testMessage);

        // 5. Verify prediction was correct
        assertEq(deployed, predicted);

        // 6. Verify it's now deployed
        assertTrue(factory.isDeployed(deployed));

        // 7. Verify tracking
        assertEq(factory.getDeployment(salt), deployed);
        assertEq(factory.getDeploymentCount(), 1);

        // 8. Verify contract state
        SimpleContract instance = SimpleContract(deployed);
        assertEq(instance.owner(), testOwner);
        assertEq(instance.value(), testValue);
        assertEq(instance.message(), testMessage);
    }

    /// @notice Integration test: multiple deployments with different params
    function test_Integration_MultipleDeployments() public {
        // Deploy three different contracts
        address deployed1 = factory.deploy(keccak256("salt1"), address(0x111), 111, "First");

        address deployed2 = factory.deploy(keccak256("salt2"), address(0x222), 222, "Second");

        address deployed3 = factory.deploy(keccak256("salt3"), address(0x333), 333, "Third");

        // Verify all are different
        assertTrue(deployed1 != deployed2);
        assertTrue(deployed1 != deployed3);
        assertTrue(deployed2 != deployed3);

        // Verify all are tracked
        assertEq(factory.getDeploymentCount(), 3);

        // Verify each contract's state
        assertEq(SimpleContract(deployed1).owner(), address(0x111));
        assertEq(SimpleContract(deployed2).owner(), address(0x222));
        assertEq(SimpleContract(deployed3).owner(), address(0x333));

        assertEq(SimpleContract(deployed1).value(), 111);
        assertEq(SimpleContract(deployed2).value(), 222);
        assertEq(SimpleContract(deployed3).value(), 333);
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test deployment with zero salt
    function test_EdgeCase_ZeroSalt() public {
        bytes32 salt = bytes32(0);

        address deployed = factory.deploy(salt, testOwner, testValue, testMessage);

        assertTrue(factory.isDeployed(deployed), "Should deploy with zero salt");
    }

    /// @notice Test deployment with max uint256 as value
    function test_EdgeCase_MaxValue() public {
        bytes32 salt = keccak256("max-value");
        uint256 maxValue = type(uint256).max;

        address deployed = factory.deploy(salt, testOwner, maxValue, testMessage);

        SimpleContract instance = SimpleContract(deployed);
        assertEq(instance.value(), maxValue, "Should handle max uint256");
    }

    /// @notice Test deployment with empty string
    function test_EdgeCase_EmptyString() public {
        bytes32 salt = keccak256("empty-string");

        address deployed = factory.deploy(salt, testOwner, testValue, "");

        SimpleContract instance = SimpleContract(deployed);
        assertEq(instance.message(), "", "Should handle empty string");
    }

    /// @notice Test deployment with very long string
    function test_EdgeCase_LongString() public {
        bytes32 salt = keccak256("long-string");
        string memory longMessage = "This is a very long message that exceeds typical string lengths "
            "to test how the CREATE2 deployment handles larger constructor arguments "
            "and ensures that bytecode calculation is correct even with variable-length data";

        address deployed = factory.deploy(salt, testOwner, testValue, longMessage);

        SimpleContract instance = SimpleContract(deployed);
        assertEq(instance.message(), longMessage, "Should handle long strings");
    }
}
