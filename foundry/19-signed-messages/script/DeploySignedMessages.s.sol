// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SignedMessages.sol";
import "../src/solution/SignedMessagesSolution.sol";

/**
 * @title DeploySignedMessages
 * @notice Deployment script for Project 19: Signed Messages & EIP-712
 * @dev Deploys both skeleton and solution contracts
 */
contract DeploySignedMessages is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy skeleton contract
        SignedMessages project19 = new SignedMessages();
        console.log("SignedMessages (Skeleton) deployed at:", address(project19));

        // Deploy solution contract
        SignedMessagesSolution solution = new SignedMessagesSolution();
        console.log("SignedMessagesSolution deployed at:", address(solution));

        // Log domain separator info
        console.log("\n=== EIP-712 Domain Information ===");
        console.log("Domain Separator:", vm.toString(solution.DOMAIN_SEPARATOR()));
        console.log("Chain ID:", block.chainid);
        console.log("Verifying Contract:", address(solution));

        vm.stopBroadcast();
    }

    /**
     * @notice Deploy only the skeleton contract
     */
    function deploySkeleton() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        SignedMessages project19 = new SignedMessages();
        console.log("SignedMessages (Skeleton) deployed at:", address(project19));

        vm.stopBroadcast();
    }

    /**
     * @notice Deploy only the solution contract
     */
    function deploySolution() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        SignedMessagesSolution solution = new SignedMessagesSolution();
        console.log("SignedMessagesSolution deployed at:", address(solution));
        console.log("Domain Separator:", vm.toString(solution.DOMAIN_SEPARATOR()));
        console.log("Voucher Issuer:", solution.voucherIssuer());

        vm.stopBroadcast();
    }
}

/**
 * @title InteractSignedMessages
 * @notice Script for interacting with deployed contracts
 * @dev Demonstrates signature creation and verification
 */
contract InteractSignedMessages is Script {
    SignedMessagesSolution public solution;

    function setUp() public {
        // Load deployed contract address
        address contractAddress = vm.envAddress("CONTRACT_ADDRESS");
        solution = SignedMessagesSolution(payable(contractAddress));
    }

    /**
     * @notice Demonstrate creating and executing a permit
     */
    function demonstratePermit() external {
        uint256 signerPrivateKey = vm.envUint("PRIVATE_KEY");
        address signer = vm.addr(signerPrivateKey);

        address spender = vm.envAddress("SPENDER_ADDRESS");
        uint256 value = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = solution.nonces(signer);

        console.log("\n=== Creating Permit Signature ===");
        console.log("Owner:", signer);
        console.log("Spender:", spender);
        console.log("Value:", value);
        console.log("Nonce:", nonce);
        console.log("Deadline:", deadline);

        // Create struct hash
        bytes32 structHash = keccak256(
            abi.encode(
                solution.PERMIT_TYPEHASH(),
                signer,
                spender,
                value,
                nonce,
                deadline
            )
        );

        // Create digest
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", solution.DOMAIN_SEPARATOR(), structHash)
        );

        // Sign
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        console.log("\n=== Signature Components ===");
        console.log("Digest:", vm.toString(digest));
        console.log("v:", v);
        console.log("r:", vm.toString(r));
        console.log("s:", vm.toString(s));

        // Execute permit
        vm.broadcast(signerPrivateKey);
        solution.permit(signer, spender, value, deadline, v, r, s);

        console.log("\n=== Permit Executed ===");
        console.log("Allowance set:", solution.allowance(signer, spender));
        console.log("New nonce:", solution.nonces(signer));
    }

    /**
     * @notice Demonstrate creating a meta-transaction
     */
    function demonstrateMetaTx() external {
        uint256 signerPrivateKey = vm.envUint("PRIVATE_KEY");
        address signer = vm.addr(signerPrivateKey);

        address recipient = vm.envAddress("RECIPIENT_ADDRESS");
        uint256 amount = 50 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = solution.nonces(signer);

        console.log("\n=== Creating Meta-Transaction ===");
        console.log("From:", signer);
        console.log("To:", recipient);
        console.log("Amount:", amount);
        console.log("Nonce:", nonce);

        // Create signature
        bytes32 structHash = keccak256(
            abi.encode(
                solution.METATX_TYPEHASH(),
                signer,
                recipient,
                amount,
                nonce,
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", solution.DOMAIN_SEPARATOR(), structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        console.log("\n=== Signature Created ===");
        console.log("v:", v);
        console.log("r:", vm.toString(r));
        console.log("s:", vm.toString(s));

        // Note: In practice, a relayer would execute this
        console.log("\n=== Ready for Relayer ===");
        console.log("Relayer can call executeMetaTx with these parameters");
    }

    /**
     * @notice Demonstrate creating a voucher
     */
    function createVoucher() external {
        uint256 issuerPrivateKey = vm.envUint("PRIVATE_KEY");
        address issuer = vm.addr(issuerPrivateKey);

        require(issuer == solution.voucherIssuer(), "Not authorized issuer");

        address claimer = vm.envAddress("CLAIMER_ADDRESS");
        uint256 amount = 100 ether;
        uint256 deadline = block.timestamp + 7 days;

        console.log("\n=== Creating Voucher ===");
        console.log("Issuer:", issuer);
        console.log("Claimer:", claimer);
        console.log("Amount:", amount);
        console.log("Valid until:", deadline);

        // Create signature
        bytes32 structHash = keccak256(
            abi.encode(
                solution.METATX_TYPEHASH(),
                issuer,
                claimer,
                amount,
                uint256(0),
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", solution.DOMAIN_SEPARATOR(), structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(issuerPrivateKey, digest);

        console.log("\n=== Voucher Created ===");
        console.log("Voucher Hash:", vm.toString(digest));
        console.log("v:", v);
        console.log("r:", vm.toString(r));
        console.log("s:", vm.toString(s));
        console.log("\nClaimer can call claimVoucher with these parameters");
    }

    /**
     * @notice Display domain separator information
     */
    function displayDomainInfo() external view {
        console.log("\n=== EIP-712 Domain Information ===");
        console.log("Domain Separator:", vm.toString(solution.DOMAIN_SEPARATOR()));
        console.log("Chain ID:", block.chainid);
        console.log("Contract Address:", address(solution));
        console.log("Permit TypeHash:", vm.toString(solution.PERMIT_TYPEHASH()));
        console.log("MetaTx TypeHash:", vm.toString(solution.METATX_TYPEHASH()));
    }
}
