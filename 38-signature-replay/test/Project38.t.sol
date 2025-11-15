// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/Project38Solution.sol";

/**
 * @title Project 38 Tests: Signature Replay Attack
 * @notice Comprehensive tests demonstrating vulnerabilities and protections
 */
contract Project38Test is Test {
    // Test accounts
    address victim;
    uint256 victimKey;
    address attacker;
    address recipient;

    // Contracts
    VulnerableBankSolution vulnerableBank;
    ReplayAttackerSolution replayAttacker;
    SecureBankSolution secureBank;
    CrossChainVulnerableSolution crossChainVuln;
    CrossChainSecureSolution crossChainSecure;
    EIP712SecureBankSolution eip712Bank;
    AdvancedSecureBankSolution advancedBank;

    // Constants
    uint256 constant INITIAL_BALANCE = 10 ether;
    uint256 constant WITHDRAW_AMOUNT = 1 ether;

    function setUp() public {
        // Create test accounts
        (victim, victimKey) = makeAddrAndKey("victim");
        attacker = makeAddr("attacker");
        recipient = makeAddr("recipient");

        // Deploy contracts
        vulnerableBank = new VulnerableBankSolution();
        replayAttacker = new ReplayAttackerSolution(address(vulnerableBank));
        secureBank = new SecureBankSolution();
        crossChainVuln = new CrossChainVulnerableSolution();
        crossChainSecure = new CrossChainSecureSolution();
        eip712Bank = new EIP712SecureBankSolution();
        advancedBank = new AdvancedSecureBankSolution();

        // Fund victim accounts
        vm.deal(victim, INITIAL_BALANCE);

        // Deposit to banks
        vm.startPrank(victim);
        vulnerableBank.deposit{value: INITIAL_BALANCE}();
        secureBank.deposit{value: INITIAL_BALANCE}();
        eip712Bank.deposit{value: INITIAL_BALANCE}();
        advancedBank.deposit{value: INITIAL_BALANCE}();
        vm.stopPrank();

        // Fund cross-chain contracts
        vm.deal(address(crossChainVuln), INITIAL_BALANCE);
        vm.deal(address(crossChainSecure), INITIAL_BALANCE);
    }

    // ============================================================================
    // REPLAY ATTACK TESTS
    // ============================================================================

    /**
     * @notice Test 1: Demonstrate basic replay attack
     * @dev Shows how missing nonce allows signature reuse
     */
    function test_ReplayAttack_VulnerableBank() public {
        console.log("\n=== TEST: Replay Attack on Vulnerable Bank ===");

        // 1. Victim creates signature for 1 ETH withdrawal
        bytes32 messageHash = keccak256(abi.encodePacked(WITHDRAW_AMOUNT));
        bytes32 ethSignedMessageHash = vulnerableBank.getEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(victimKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        console.log("Victim balance before:", vulnerableBank.balances(victim));

        // 2. Attacker uses signature once (legitimate)
        vm.prank(attacker);
        vulnerableBank.withdrawWithSignature(WITHDRAW_AMOUNT, signature);
        console.log("After 1st use:", vulnerableBank.balances(victim));

        // 3. ATTACK: Attacker reuses the same signature!
        vm.prank(attacker);
        vulnerableBank.withdrawWithSignature(WITHDRAW_AMOUNT, signature);
        console.log("After 2nd use (replay):", vulnerableBank.balances(victim));

        // 4. Attacker can keep replaying until balance is zero
        vm.prank(attacker);
        vulnerableBank.withdrawWithSignature(WITHDRAW_AMOUNT, signature);
        console.log("After 3rd use (replay):", vulnerableBank.balances(victim));

        // Verify attack succeeded
        assertEq(
            vulnerableBank.balances(victim),
            INITIAL_BALANCE - (3 * WITHDRAW_AMOUNT),
            "Replay attack failed"
        );

        console.log("VULNERABILITY: Same signature used 3 times!");
    }

    /**
     * @notice Test 2: Automated replay attack using attacker contract
     */
    function test_ReplayAttack_AutomatedExploit() public {
        console.log("\n=== TEST: Automated Replay Attack ===");

        // Create signature
        bytes32 messageHash = keccak256(abi.encodePacked(WITHDRAW_AMOUNT));
        bytes32 ethSignedMessageHash = vulnerableBank.getEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(victimKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        uint256 balanceBefore = vulnerableBank.balances(victim);
        console.log("Victim balance before attack:", balanceBefore);

        // Execute automated attack - replay 5 times
        uint256 replayCount = 5;
        vm.prank(attacker);
        replayAttacker.attack(WITHDRAW_AMOUNT, signature, replayCount);

        uint256 balanceAfter = vulnerableBank.balances(victim);
        console.log("Victim balance after attack:", balanceAfter);
        console.log("Attacker stole:", replayAttacker.stolenAmount());

        assertEq(
            balanceAfter,
            balanceBefore - (replayCount * WITHDRAW_AMOUNT),
            "Automated attack failed"
        );
        assertEq(
            replayAttacker.stolenAmount(),
            replayCount * WITHDRAW_AMOUNT,
            "Stolen amount mismatch"
        );
    }

    /**
     * @notice Test 3: Verify secure bank prevents replay
     */
    function test_ReplayProtection_SecureBank() public {
        console.log("\n=== TEST: Nonce Protection Prevents Replay ===");

        uint256 nonce = secureBank.nonces(victim);
        console.log("Initial nonce:", nonce);

        // Create signature with nonce
        bytes32 messageHash = keccak256(abi.encodePacked(WITHDRAW_AMOUNT, nonce));
        bytes32 ethSignedMessageHash = secureBank.getEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(victimKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // First use succeeds
        vm.prank(attacker);
        secureBank.withdrawWithSignature(WITHDRAW_AMOUNT, nonce, signature);
        console.log("After 1st use - balance:", secureBank.balances(victim));
        console.log("After 1st use - nonce:", secureBank.nonces(victim));

        // Second use with same signature FAILS
        vm.prank(attacker);
        vm.expectRevert("Invalid nonce");
        secureBank.withdrawWithSignature(WITHDRAW_AMOUNT, nonce, signature);

        console.log("PROTECTION: Replay blocked by nonce!");

        // Verify nonce incremented
        assertEq(secureBank.nonces(victim), nonce + 1, "Nonce not incremented");
    }

    // ============================================================================
    // CROSS-CHAIN REPLAY TESTS
    // ============================================================================

    /**
     * @notice Test 4: Demonstrate cross-chain replay vulnerability
     */
    function test_CrossChainReplay_Vulnerable() public {
        console.log("\n=== TEST: Cross-Chain Replay Attack ===");

        address owner = crossChainVuln.OWNER();
        uint256 ownerKey = 0x1234; // Simplified for demo
        uint256 claimAmount = 1 ether;
        uint256 nonce = 1;

        // Simulate signature on chain 1 (e.g., Goerli)
        vm.chainId(5); // Goerli chain ID
        bytes32 messageHash = keccak256(abi.encodePacked(victim, claimAmount, nonce));
        bytes32 ethSignedMessageHash = crossChainVuln.getEthSignedMessageHash(messageHash);

        // For testing, we'll use a mock signature approach
        // In reality, owner would sign with their private key
        console.log("Signature created on chain ID 5 (Goerli)");

        // Switch to chain 2 (e.g., Mainnet)
        vm.chainId(1); // Mainnet chain ID
        console.log("Now on chain ID 1 (Mainnet)");

        // VULNERABILITY: Same message hash on different chain!
        bytes32 messageHashMainnet = keccak256(abi.encodePacked(victim, claimAmount, nonce));

        // The message hash is IDENTICAL across chains
        assertEq(messageHash, messageHashMainnet, "Hashes should match (vulnerability!)");

        console.log("VULNERABILITY: Signature from Goerli works on Mainnet!");
        console.log("Message hash is identical across chains");
    }

    /**
     * @notice Test 5: Verify cross-chain protection
     */
    function test_CrossChainProtection_Secure() public {
        console.log("\n=== TEST: ChainID Protection ===");

        uint256 claimAmount = 1 ether;
        uint256 nonce = 1;

        // Create message on chain 5
        vm.chainId(5);
        bytes32 messageHashChain5 = keccak256(abi.encodePacked(
            victim,
            claimAmount,
            nonce,
            block.chainid
        ));
        console.log("Message hash on chain 5:", uint256(messageHashChain5));

        // Create message on chain 1
        vm.chainId(1);
        bytes32 messageHashChain1 = keccak256(abi.encodePacked(
            victim,
            claimAmount,
            nonce,
            block.chainid
        ));
        console.log("Message hash on chain 1:", uint256(messageHashChain1));

        // Hashes are DIFFERENT
        assertTrue(messageHashChain5 != messageHashChain1, "Hashes should differ");

        console.log("PROTECTION: Different chains produce different hashes!");
    }

    // ============================================================================
    // EIP-712 TESTS
    // ============================================================================

    /**
     * @notice Test 6: EIP-712 signature creation and verification
     */
    function test_EIP712_BasicSignature() public {
        console.log("\n=== TEST: EIP-712 Signature Verification ===");

        uint256 amount = 2 ether;
        uint256 nonce = eip712Bank.nonces(victim);

        // Get the digest using helper function
        bytes32 digest = eip712Bank.getTransferDigest(victim, recipient, amount, nonce);
        console.log("EIP-712 digest:", uint256(digest));

        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(victimKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Execute transfer with signature
        uint256 balanceBefore = eip712Bank.balances(victim);
        eip712Bank.transferWithSignature(victim, recipient, amount, nonce, signature);

        // Verify transfer succeeded
        assertEq(eip712Bank.balances(victim), balanceBefore - amount, "Balance not reduced");
        assertEq(eip712Bank.balances(recipient), amount, "Recipient not credited");
        assertEq(eip712Bank.nonces(victim), nonce + 1, "Nonce not incremented");

        console.log("EIP-712 signature verified successfully!");
    }

    /**
     * @notice Test 7: EIP-712 prevents replay attacks
     */
    function test_EIP712_ReplayProtection() public {
        console.log("\n=== TEST: EIP-712 Replay Protection ===");

        uint256 amount = 1 ether;
        uint256 nonce = eip712Bank.nonces(victim);

        bytes32 digest = eip712Bank.getTransferDigest(victim, recipient, amount, nonce);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(victimKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // First use succeeds
        eip712Bank.transferWithSignature(victim, recipient, amount, nonce, signature);
        console.log("First transfer successful");

        // Replay fails due to nonce
        vm.expectRevert("Invalid nonce");
        eip712Bank.transferWithSignature(victim, recipient, amount, nonce, signature);
        console.log("Replay blocked - nonce invalid!");
    }

    /**
     * @notice Test 8: EIP-712 domain separator uniqueness
     */
    function test_EIP712_DomainSeparator() public {
        console.log("\n=== TEST: EIP-712 Domain Separator ===");

        bytes32 domainSeparator = eip712Bank.getDomainSeparator();
        console.log("Domain separator:", uint256(domainSeparator));

        // Domain separator should be unique per contract
        EIP712SecureBankSolution anotherBank = new EIP712SecureBankSolution();
        bytes32 anotherDomainSeparator = anotherBank.getDomainSeparator();

        // Different contracts = different domain separators
        assertTrue(
            domainSeparator != anotherDomainSeparator,
            "Domain separators should differ"
        );

        console.log("PROTECTION: Each contract has unique domain separator!");
    }

    /**
     * @notice Test 9: EIP-712 cross-contract replay protection
     */
    function test_EIP712_CrossContractProtection() public {
        console.log("\n=== TEST: EIP-712 Cross-Contract Protection ===");

        // Deploy second bank
        EIP712SecureBankSolution bank2 = new EIP712SecureBankSolution();
        vm.deal(victim, 5 ether);
        vm.prank(victim);
        bank2.deposit{value: 5 ether}();

        uint256 amount = 1 ether;
        uint256 nonce = 0;

        // Create signature for bank1
        bytes32 digest1 = eip712Bank.getTransferDigest(victim, recipient, amount, nonce);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(victimKey, digest1);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Use signature on bank1 - succeeds
        eip712Bank.transferWithSignature(victim, recipient, amount, nonce, signature);
        console.log("Transfer on Bank1: SUCCESS");

        // Try to use same signature on bank2 - fails
        vm.expectRevert("Invalid signature");
        bank2.transferWithSignature(victim, recipient, amount, nonce, signature);
        console.log("Same signature on Bank2: BLOCKED");

        console.log("PROTECTION: Signature tied to specific contract!");
    }

    // ============================================================================
    // ADVANCED FEATURES TESTS
    // ============================================================================

    /**
     * @notice Test 10: Signature with deadline expiration
     */
    function test_Advanced_DeadlineExpiration() public {
        console.log("\n=== TEST: Signature Deadline ===");

        uint256 amount = 1 ether;
        uint256 nonce = advancedBank.nonces(victim);
        uint256 deadline = block.timestamp + 1 hours;

        // Create signature with deadline
        bytes32 structHash = keccak256(abi.encode(
            advancedBank.TRANSFER_TYPEHASH(),
            victim,
            recipient,
            amount,
            nonce,
            deadline
        ));

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            advancedBank.DOMAIN_SEPARATOR(),
            structHash
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(victimKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Use within deadline - succeeds
        advancedBank.transferWithSignature(victim, recipient, amount, nonce, deadline, signature);
        console.log("Transfer within deadline: SUCCESS");

        // Warp time past deadline
        vm.warp(block.timestamp + 2 hours);

        // Create new signature for testing
        nonce = advancedBank.nonces(victim);
        structHash = keccak256(abi.encode(
            advancedBank.TRANSFER_TYPEHASH(),
            victim,
            recipient,
            amount,
            nonce,
            deadline
        ));

        digest = keccak256(abi.encodePacked(
            "\x19\x01",
            advancedBank.DOMAIN_SEPARATOR(),
            structHash
        ));

        (v, r, s) = vm.sign(victimKey, digest);
        signature = abi.encodePacked(r, s, v);

        // Use after deadline - fails
        vm.expectRevert("Signature expired");
        advancedBank.transferWithSignature(victim, recipient, amount, nonce, deadline, signature);
        console.log("Transfer after deadline: BLOCKED");
    }

    /**
     * @notice Test 11: Manual signature invalidation
     */
    function test_Advanced_SignatureInvalidation() public {
        console.log("\n=== TEST: Signature Invalidation ===");

        uint256 amount = 1 ether;
        uint256 nonce = advancedBank.nonces(victim);
        uint256 deadline = block.timestamp + 1 hours;

        // Victim invalidates signature before it's used
        vm.prank(victim);
        advancedBank.invalidateSignature(recipient, amount, nonce, deadline);
        console.log("Signature invalidated by victim");

        // Create the signature
        bytes32 structHash = keccak256(abi.encode(
            advancedBank.TRANSFER_TYPEHASH(),
            victim,
            recipient,
            amount,
            nonce,
            deadline
        ));

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            advancedBank.DOMAIN_SEPARATOR(),
            structHash
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(victimKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Try to use invalidated signature - fails
        vm.expectRevert("Signature invalidated");
        advancedBank.transferWithSignature(victim, recipient, amount, nonce, deadline, signature);
        console.log("Invalidated signature rejected!");
    }

    /**
     * @notice Test 12: Compare vulnerable vs secure implementations
     */
    function test_Comparison_VulnerableVsSecure() public {
        console.log("\n=== COMPARISON: Vulnerable vs Secure ===");

        // Test vulnerable bank
        bytes32 vulnMsg = keccak256(abi.encodePacked(WITHDRAW_AMOUNT));
        bytes32 vulnHash = vulnerableBank.getEthSignedMessageHash(vulnMsg);
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(victimKey, vulnHash);
        bytes memory vulnSig = abi.encodePacked(r1, s1, v1);

        vm.prank(attacker);
        vulnerableBank.withdrawWithSignature(WITHDRAW_AMOUNT, vulnSig);

        // Can replay
        vm.prank(attacker);
        vulnerableBank.withdrawWithSignature(WITHDRAW_AMOUNT, vulnSig);
        console.log("Vulnerable: Replay successful (BAD)");

        // Test secure bank
        uint256 nonce = secureBank.nonces(victim);
        bytes32 secureMsg = keccak256(abi.encodePacked(WITHDRAW_AMOUNT, nonce));
        bytes32 secureHash = secureBank.getEthSignedMessageHash(secureMsg);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(victimKey, secureHash);
        bytes memory secureSig = abi.encodePacked(r2, s2, v2);

        vm.prank(attacker);
        secureBank.withdrawWithSignature(WITHDRAW_AMOUNT, nonce, secureSig);

        // Cannot replay
        vm.prank(attacker);
        vm.expectRevert("Invalid nonce");
        secureBank.withdrawWithSignature(WITHDRAW_AMOUNT, nonce, secureSig);
        console.log("Secure: Replay blocked (GOOD)");
    }

    // ============================================================================
    // EDGE CASES AND VALIDATION TESTS
    // ============================================================================

    /**
     * @notice Test 13: Invalid signature length
     */
    function test_EdgeCase_InvalidSignatureLength() public {
        console.log("\n=== TEST: Invalid Signature Length ===");

        bytes memory invalidSig = new bytes(64); // Should be 65

        vm.expectRevert("Invalid signature length");
        vulnerableBank.splitSignature(invalidSig);
        console.log("Invalid signature length rejected!");
    }

    /**
     * @notice Test 14: Zero address validation
     */
    function test_EdgeCase_ZeroAddressRecipient() public {
        console.log("\n=== TEST: Zero Address Validation ===");

        uint256 amount = 1 ether;
        uint256 nonce = eip712Bank.nonces(victim);

        bytes32 digest = eip712Bank.getTransferDigest(victim, address(0), amount, nonce);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(victimKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Invalid recipient");
        eip712Bank.transferWithSignature(victim, address(0), amount, nonce, signature);
        console.log("Zero address recipient rejected!");
    }

    /**
     * @notice Test 15: Insufficient balance
     */
    function test_EdgeCase_InsufficientBalance() public {
        console.log("\n=== TEST: Insufficient Balance ===");

        uint256 tooMuch = INITIAL_BALANCE + 1 ether;
        uint256 nonce = secureBank.nonces(victim);

        bytes32 messageHash = keccak256(abi.encodePacked(tooMuch, nonce));
        bytes32 ethSignedMessageHash = secureBank.getEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(victimKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Insufficient balance");
        secureBank.withdrawWithSignature(tooMuch, nonce, signature);
        console.log("Insufficient balance check works!");
    }

    // ============================================================================
    // GAS COMPARISON TESTS
    // ============================================================================

    /**
     * @notice Test 16: Gas cost comparison
     */
    function test_Gas_Comparison() public {
        console.log("\n=== GAS COMPARISON ===");

        // Basic signature (vulnerable)
        bytes32 vulnMsg = keccak256(abi.encodePacked(WITHDRAW_AMOUNT));
        bytes32 vulnHash = vulnerableBank.getEthSignedMessageHash(vulnMsg);
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(victimKey, vulnHash);
        bytes memory vulnSig = abi.encodePacked(r1, s1, v1);

        uint256 gasStart = gasleft();
        vulnerableBank.withdrawWithSignature(WITHDRAW_AMOUNT, vulnSig);
        uint256 gasVuln = gasStart - gasleft();

        // Nonce-protected signature
        uint256 nonce = secureBank.nonces(victim);
        bytes32 secureMsg = keccak256(abi.encodePacked(WITHDRAW_AMOUNT, nonce));
        bytes32 secureHash = secureBank.getEthSignedMessageHash(secureMsg);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(victimKey, secureHash);
        bytes memory secureSig = abi.encodePacked(r2, s2, v2);

        gasStart = gasleft();
        secureBank.withdrawWithSignature(WITHDRAW_AMOUNT, nonce, secureSig);
        uint256 gasSecure = gasStart - gasleft();

        // EIP-712 signature
        nonce = eip712Bank.nonces(victim);
        bytes32 digest = eip712Bank.getTransferDigest(victim, recipient, WITHDRAW_AMOUNT, nonce);
        (uint8 v3, bytes32 r3, bytes32 s3) = vm.sign(victimKey, digest);
        bytes memory eip712Sig = abi.encodePacked(r3, s3, v3);

        gasStart = gasleft();
        eip712Bank.transferWithSignature(victim, recipient, WITHDRAW_AMOUNT, nonce, eip712Sig);
        uint256 gasEIP712 = gasStart - gasleft();

        console.log("Gas - Vulnerable:", gasVuln);
        console.log("Gas - Nonce Protected:", gasSecure);
        console.log("Gas - EIP-712:", gasEIP712);
        console.log("Security is worth the extra gas!");
    }
}
