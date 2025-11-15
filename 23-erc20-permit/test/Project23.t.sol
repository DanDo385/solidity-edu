// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/Project23Solution.sol";

/**
 * @title Project23Test
 * @notice Comprehensive tests for ERC-20 Permit (EIP-2612)
 * @dev Tests cover signature creation, verification, gas comparisons, and security
 */
contract Project23Test is Test {
    Project23Solution public token;
    Project23CustomImplementation public customToken;
    PermitHelper public helper;

    // Test accounts with known private keys
    address public alice;
    uint256 public alicePrivateKey;

    address public bob;
    uint256 public bobPrivateKey;

    address public spender;

    // Constants
    uint256 constant INITIAL_SUPPLY = 1_000_000e18;
    uint256 constant PERMIT_AMOUNT = 100e18;

    // Events to test
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        // Create test accounts with known private keys
        alicePrivateKey = 0xA11CE;
        alice = vm.addr(alicePrivateKey);

        bobPrivateKey = 0xB0B;
        bob = vm.addr(bobPrivateKey);

        spender = makeAddr("spender");

        // Deploy contracts
        token = new Project23Solution();
        customToken = new Project23CustomImplementation();
        helper = new PermitHelper();

        // Give Alice some tokens
        token.transfer(alice, INITIAL_SUPPLY / 2);
        customToken.transfer(alice, INITIAL_SUPPLY / 2);

        // Label addresses for better trace output
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(spender, "Spender");
        vm.label(address(token), "PermitToken");
        vm.label(address(customToken), "CustomPermitToken");
    }

    /*//////////////////////////////////////////////////////////////
                        BASIC PERMIT TESTS
    //////////////////////////////////////////////////////////////*/

    function testPermitSetsApproval() public {
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);

        // Create permit signature
        (uint8 v, bytes32 r, bytes32 s) = _signPermit(
            address(token), alice, alicePrivateKey, spender, PERMIT_AMOUNT, nonce, deadline
        );

        // Execute permit
        vm.expectEmit(true, true, false, true);
        emit Approval(alice, spender, PERMIT_AMOUNT);

        token.permit(alice, spender, PERMIT_AMOUNT, deadline, v, r, s);

        // Verify approval was set
        assertEq(token.allowance(alice, spender), PERMIT_AMOUNT);
        assertEq(token.nonces(alice), nonce + 1);
    }

    function testPermitAndTransferFrom() public {
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);

        // Create permit signature
        (uint8 v, bytes32 r, bytes32 s) = _signPermit(
            address(token), alice, alicePrivateKey, spender, PERMIT_AMOUNT, nonce, deadline
        );

        // Execute permit
        token.permit(alice, spender, PERMIT_AMOUNT, deadline, v, r, s);

        // Use the approval
        uint256 aliceBalanceBefore = token.balanceOf(alice);
        uint256 bobBalanceBefore = token.balanceOf(bob);

        vm.prank(spender);
        token.transferFrom(alice, bob, PERMIT_AMOUNT);

        // Verify transfer
        assertEq(token.balanceOf(alice), aliceBalanceBefore - PERMIT_AMOUNT);
        assertEq(token.balanceOf(bob), bobBalanceBefore + PERMIT_AMOUNT);
        assertEq(token.allowance(alice, spender), 0);
    }

    function testPermitWithMaxApproval() public {
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);
        uint256 maxAmount = type(uint256).max;

        (uint8 v, bytes32 r, bytes32 s) =
            _signPermit(address(token), alice, alicePrivateKey, spender, maxAmount, nonce, deadline);

        token.permit(alice, spender, maxAmount, deadline, v, r, s);

        assertEq(token.allowance(alice, spender), maxAmount);
    }

    function testPermitNonceIncrement() public {
        uint256 deadline = block.timestamp + 1 hours;

        for (uint256 i = 0; i < 3; i++) {
            uint256 nonce = token.nonces(alice);
            assertEq(nonce, i);

            (uint8 v, bytes32 r, bytes32 s) =
                _signPermit(address(token), alice, alicePrivateKey, spender, PERMIT_AMOUNT, nonce, deadline);

            token.permit(alice, spender, PERMIT_AMOUNT, deadline, v, r, s);

            assertEq(token.nonces(alice), i + 1);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        DEADLINE TESTS
    //////////////////////////////////////////////////////////////*/

    function testPermitRevertsOnExpiredDeadline() public {
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(
            address(token), alice, alicePrivateKey, spender, PERMIT_AMOUNT, nonce, deadline
        );

        // Fast forward past deadline
        vm.warp(deadline + 1);

        // Should revert
        vm.expectRevert("ERC20Permit: expired deadline");
        token.permit(alice, spender, PERMIT_AMOUNT, deadline, v, r, s);
    }

    function testPermitWorksAtExactDeadline() public {
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(
            address(token), alice, alicePrivateKey, spender, PERMIT_AMOUNT, nonce, deadline
        );

        // Move to exact deadline
        vm.warp(deadline);

        // Should work (deadline is inclusive)
        token.permit(alice, spender, PERMIT_AMOUNT, deadline, v, r, s);

        assertEq(token.allowance(alice, spender), PERMIT_AMOUNT);
    }

    function testPermitWithVeryLongDeadline() public {
        uint256 deadline = type(uint256).max; // Far future
        uint256 nonce = token.nonces(alice);

        (uint8 v, bytes32 r, bytes32 s) =
            _signPermit(address(token), alice, alicePrivateKey, spender, PERMIT_AMOUNT, nonce, deadline);

        token.permit(alice, spender, PERMIT_AMOUNT, deadline, v, r, s);

        assertEq(token.allowance(alice, spender), PERMIT_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////
                        SIGNATURE TESTS
    //////////////////////////////////////////////////////////////*/

    function testPermitRevertsOnInvalidSignature() public {
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);

        // Create valid signature
        (uint8 v, bytes32 r, bytes32 s) = _signPermit(
            address(token), alice, alicePrivateKey, spender, PERMIT_AMOUNT, nonce, deadline
        );

        // Tamper with signature
        s = bytes32(uint256(s) + 1);

        // Should revert
        vm.expectRevert("ECDSA: invalid signature");
        token.permit(alice, spender, PERMIT_AMOUNT, deadline, v, r, s);
    }

    function testPermitRevertsOnWrongSigner() public {
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);

        // Bob signs but claims to be Alice
        (uint8 v, bytes32 r, bytes32 s) =
            _signPermit(address(token), bob, bobPrivateKey, spender, PERMIT_AMOUNT, nonce, deadline);

        // Should revert - signature is from Bob, not Alice
        vm.expectRevert("ECDSA: invalid signature");
        token.permit(alice, spender, PERMIT_AMOUNT, deadline, v, r, s);
    }

    function testPermitRevertsOnWrongNonce() public {
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);

        // Sign with wrong nonce
        (uint8 v, bytes32 r, bytes32 s) = _signPermit(
            address(token), alice, alicePrivateKey, spender, PERMIT_AMOUNT, nonce + 1, deadline
        );

        // Should revert
        vm.expectRevert("ECDSA: invalid signature");
        token.permit(alice, spender, PERMIT_AMOUNT, deadline, v, r, s);
    }

    function testPermitRevertsOnReplay() public {
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(
            address(token), alice, alicePrivateKey, spender, PERMIT_AMOUNT, nonce, deadline
        );

        // First use - should work
        token.permit(alice, spender, PERMIT_AMOUNT, deadline, v, r, s);

        // Second use - should revert (nonce incremented)
        vm.expectRevert("ECDSA: invalid signature");
        token.permit(alice, spender, PERMIT_AMOUNT, deadline, v, r, s);
    }

    function testPermitRevertsOnTamperedAmount() public {
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);

        // Sign for 100 tokens
        (uint8 v, bytes32 r, bytes32 s) = _signPermit(
            address(token), alice, alicePrivateKey, spender, PERMIT_AMOUNT, nonce, deadline
        );

        // Try to use for 200 tokens
        vm.expectRevert("ECDSA: invalid signature");
        token.permit(alice, spender, PERMIT_AMOUNT * 2, deadline, v, r, s);
    }

    /*//////////////////////////////////////////////////////////////
                        GAS COMPARISON TESTS
    //////////////////////////////////////////////////////////////*/

    function testGasComparisonApproveVsPermit() public {
        // Measure traditional approve
        uint256 gasBefore = gasleft();
        vm.prank(alice);
        token.approve(spender, PERMIT_AMOUNT);
        uint256 approveGas = gasBefore - gasleft();

        // Reset approval
        vm.prank(alice);
        token.approve(spender, 0);

        // Measure permit
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(
            address(token), alice, alicePrivateKey, spender, PERMIT_AMOUNT, nonce, deadline
        );

        gasBefore = gasleft();
        token.permit(alice, spender, PERMIT_AMOUNT, deadline, v, r, s);
        uint256 permitGas = gasBefore - gasleft();

        // Log gas usage
        console.log("Approve gas:", approveGas);
        console.log("Permit gas:", permitGas);
        console.log("Difference:", approveGas > permitGas ? approveGas - permitGas : permitGas - approveGas);

        // Both should result in same approval
        assertEq(token.allowance(alice, spender), PERMIT_AMOUNT);
    }

    function testGasComparisonTwoTxVsPermitAndTransfer() public {
        // Scenario 1: Traditional approve + transferFrom (2 transactions)
        uint256 gas1;
        {
            uint256 gasBefore = gasleft();
            vm.prank(alice);
            token.approve(spender, PERMIT_AMOUNT);
            uint256 approveGas = gasBefore - gasleft();

            gasBefore = gasleft();
            vm.prank(spender);
            token.transferFrom(alice, bob, PERMIT_AMOUNT);
            uint256 transferGas = gasBefore - gasleft();

            gas1 = approveGas + transferGas;
        }

        // Scenario 2: Permit + transferFrom (1 transaction for user)
        uint256 gas2;
        {
            uint256 deadline = block.timestamp + 1 hours;
            uint256 nonce = token.nonces(alice);

            (uint8 v, bytes32 r, bytes32 s) = _signPermit(
                address(token), alice, alicePrivateKey, spender, PERMIT_AMOUNT, nonce, deadline
            );

            uint256 gasBefore = gasleft();
            token.permit(alice, spender, PERMIT_AMOUNT, deadline, v, r, s);
            vm.prank(spender);
            token.transferFrom(alice, bob, PERMIT_AMOUNT);
            gas2 = gasBefore - gasleft();
        }

        console.log("\n=== GAS COMPARISON ===");
        console.log("Traditional (approve + transferFrom):", gas1);
        console.log("With Permit (permit + transferFrom):", gas2);
        console.log("Savings:", gas1 > gas2 ? gas1 - gas2 : 0);
        console.log("Savings %:", gas1 > gas2 ? ((gas1 - gas2) * 100) / gas1 : 0);
    }

    function testGasIntegratedPermit() public {
        uint256 transferAmount = PERMIT_AMOUNT;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);

        (uint8 v, bytes32 r, bytes32 s) =
            _signPermit(address(token), alice, alicePrivateKey, address(helper), transferAmount, nonce, deadline);

        // Measure integrated permit + transfer
        uint256 bobBalanceBefore = token.balanceOf(bob);
        uint256 gasBefore = gasleft();

        helper.transferWithPermit(token, alice, bob, transferAmount, deadline, v, r, s);

        uint256 gasUsed = gasBefore - gasleft();

        console.log("\n=== INTEGRATED PERMIT ===");
        console.log("Gas for transferWithPermit:", gasUsed);

        assertEq(token.balanceOf(bob), bobBalanceBefore + transferAmount);
    }

    /*//////////////////////////////////////////////////////////////
                        DOMAIN SEPARATOR TESTS
    //////////////////////////////////////////////////////////////*/

    function testDomainSeparator() public {
        bytes32 separator = token.DOMAIN_SEPARATOR();

        // Should be non-zero
        assertTrue(separator != bytes32(0));

        // Should be consistent
        assertEq(token.DOMAIN_SEPARATOR(), separator);
    }

    function testDomainSeparatorIsUnique() public {
        // Deploy another token
        Project23Solution token2 = new Project23Solution();

        // Domain separators should be different (different addresses)
        assertTrue(token.DOMAIN_SEPARATOR() != token2.DOMAIN_SEPARATOR());
    }

    function testPermitDoesNotWorkAcrossTokens() public {
        // Create permit for token1
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(
            address(token), alice, alicePrivateKey, spender, PERMIT_AMOUNT, nonce, deadline
        );

        // Try to use on token2 (different domain separator)
        Project23Solution token2 = new Project23Solution();
        token2.transfer(alice, PERMIT_AMOUNT);

        vm.expectRevert("ECDSA: invalid signature");
        token2.permit(alice, spender, PERMIT_AMOUNT, deadline, v, r, s);
    }

    /*//////////////////////////////////////////////////////////////
                        CUSTOM IMPLEMENTATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testCustomImplementationWorks() public {
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = customToken.nonces(alice);

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(
            address(customToken), alice, alicePrivateKey, spender, PERMIT_AMOUNT, nonce, deadline
        );

        customToken.permit(alice, spender, PERMIT_AMOUNT, deadline, v, r, s);

        assertEq(customToken.allowance(alice, spender), PERMIT_AMOUNT);
    }

    function testCustomImplementationRevertsOnExpiry() public {
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = customToken.nonces(alice);

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(
            address(customToken), alice, alicePrivateKey, spender, PERMIT_AMOUNT, nonce, deadline
        );

        vm.warp(deadline + 1);

        vm.expectRevert(Project23CustomImplementation.ERC20Permit__ExpiredDeadline.selector);
        customToken.permit(alice, spender, PERMIT_AMOUNT, deadline, v, r, s);
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    function testPermitWithZeroAmount() public {
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);

        (uint8 v, bytes32 r, bytes32 s) =
            _signPermit(address(token), alice, alicePrivateKey, spender, 0, nonce, deadline);

        token.permit(alice, spender, 0, deadline, v, r, s);

        assertEq(token.allowance(alice, spender), 0);
    }

    function testPermitToZeroAddress() public {
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);

        (uint8 v, bytes32 r, bytes32 s) =
            _signPermit(address(token), alice, alicePrivateKey, address(0), PERMIT_AMOUNT, nonce, deadline);

        // OpenZeppelin's _approve allows zero address, but it's not recommended
        token.permit(alice, address(0), PERMIT_AMOUNT, deadline, v, r, s);

        assertEq(token.allowance(alice, address(0)), PERMIT_AMOUNT);
    }

    function testMultiplePermitsFromSameUser() public {
        uint256 deadline = block.timestamp + 1 hours;

        address spender1 = makeAddr("spender1");
        address spender2 = makeAddr("spender2");

        // Permit to spender1
        uint256 nonce1 = token.nonces(alice);
        (uint8 v1, bytes32 r1, bytes32 s1) =
            _signPermit(address(token), alice, alicePrivateKey, spender1, PERMIT_AMOUNT, nonce1, deadline);
        token.permit(alice, spender1, PERMIT_AMOUNT, deadline, v1, r1, s1);

        // Permit to spender2
        uint256 nonce2 = token.nonces(alice);
        (uint8 v2, bytes32 r2, bytes32 s2) =
            _signPermit(address(token), alice, alicePrivateKey, spender2, PERMIT_AMOUNT * 2, nonce2, deadline);
        token.permit(alice, spender2, PERMIT_AMOUNT * 2, deadline, v2, r2, s2);

        // Verify both approvals
        assertEq(token.allowance(alice, spender1), PERMIT_AMOUNT);
        assertEq(token.allowance(alice, spender2), PERMIT_AMOUNT * 2);
    }

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Helper to create permit signature
     * @dev Creates EIP-712 signature for permit
     */
    function _signPermit(
        address tokenAddress,
        address owner,
        uint256 ownerPrivateKey,
        address spenderAddress,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        // Get domain separator from token
        bytes32 domainSeparator;
        if (tokenAddress == address(token)) {
            domainSeparator = token.DOMAIN_SEPARATOR();
        } else if (tokenAddress == address(customToken)) {
            domainSeparator = customToken.DOMAIN_SEPARATOR();
        } else {
            domainSeparator = Project23Solution(tokenAddress).DOMAIN_SEPARATOR();
        }

        // Create struct hash
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner,
                spenderAddress,
                value,
                nonce,
                deadline
            )
        );

        // Create digest
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        // Sign
        (v, r, s) = vm.sign(ownerPrivateKey, digest);
    }

    /**
     * @notice Fuzz test for permit with various amounts
     */
    function testFuzzPermitAmount(uint256 amount) public {
        // Bound to reasonable values
        amount = bound(amount, 0, INITIAL_SUPPLY / 2);

        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(alice);

        (uint8 v, bytes32 r, bytes32 s) =
            _signPermit(address(token), alice, alicePrivateKey, spender, amount, nonce, deadline);

        token.permit(alice, spender, amount, deadline, v, r, s);

        assertEq(token.allowance(alice, spender), amount);
    }

    /**
     * @notice Fuzz test for permit with various deadlines
     */
    function testFuzzPermitDeadline(uint256 deadline) public {
        // Deadline must be in the future
        deadline = bound(deadline, block.timestamp, type(uint256).max);

        uint256 nonce = token.nonces(alice);

        (uint8 v, bytes32 r, bytes32 s) =
            _signPermit(address(token), alice, alicePrivateKey, spender, PERMIT_AMOUNT, nonce, deadline);

        token.permit(alice, spender, PERMIT_AMOUNT, deadline, v, r, s);

        assertEq(token.allowance(alice, spender), PERMIT_AMOUNT);
    }
}
