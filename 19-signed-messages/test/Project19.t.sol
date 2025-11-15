// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/Project19Solution.sol";

/**
 * @title Project19Test
 * @notice Comprehensive tests for EIP-712 signature verification
 * @dev Tests cover signature creation, verification, replay protection, and security
 */
contract Project19Test is Test {
    Project19Solution public project;

    // Test accounts
    address public owner;
    uint256 public ownerPrivateKey;

    address public spender;
    uint256 public spenderPrivateKey;

    address public relayer;
    address public issuer;
    uint256 public issuerPrivateKey;

    // Constants
    uint256 constant INITIAL_BALANCE = 1000 ether;

    // Events to test
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event MetaTxExecuted(address indexed from, address indexed to, uint256 amount);
    event VoucherClaimed(address indexed claimer, uint256 amount, bytes32 voucherHash);

    function setUp() public {
        // Create test accounts with known private keys
        ownerPrivateKey = 0xA11CE;
        owner = vm.addr(ownerPrivateKey);

        spenderPrivateKey = 0xB0B;
        spender = vm.addr(spenderPrivateKey);

        relayer = makeAddr("relayer");

        // Deploy contract as issuer
        issuerPrivateKey = 0xABCD;
        issuer = vm.addr(issuerPrivateKey);

        vm.prank(issuer);
        project = new Project19Solution();

        // Fund owner
        vm.deal(owner, INITIAL_BALANCE);
        vm.prank(owner);
        project.deposit{value: INITIAL_BALANCE}();
    }

    /*//////////////////////////////////////////////////////////////
                        PERMIT TESTS
    //////////////////////////////////////////////////////////////*/

    function testPermitSignature() public {
        uint256 value = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = project.nonces(owner);

        // Create permit signature
        bytes32 structHash = keccak256(
            abi.encode(
                project.PERMIT_TYPEHASH(),
                owner,
                spender,
                value,
                nonce,
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        // Execute permit
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, value);

        project.permit(owner, spender, value, deadline, v, r, s);

        // Verify approval set
        assertEq(project.allowance(owner, spender), value);

        // Verify nonce incremented
        assertEq(project.nonces(owner), nonce + 1);
    }

    function testPermitExpired() public {
        uint256 value = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = project.nonces(owner);

        // Create signature
        bytes32 structHash = keccak256(
            abi.encode(project.PERMIT_TYPEHASH(), owner, spender, value, nonce, deadline)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        // Warp past deadline
        vm.warp(deadline + 1);

        // Should revert
        vm.expectRevert(Project19Solution.SignatureExpired.selector);
        project.permit(owner, spender, value, deadline, v, r, s);
    }

    function testPermitWrongSigner() public {
        uint256 value = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = project.nonces(owner);

        // Create signature
        bytes32 structHash = keccak256(
            abi.encode(project.PERMIT_TYPEHASH(), owner, spender, value, nonce, deadline)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );

        // Sign with wrong key (spender instead of owner)
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(spenderPrivateKey, digest);

        // Should revert
        vm.expectRevert(Project19Solution.InvalidSignature.selector);
        project.permit(owner, spender, value, deadline, v, r, s);
    }

    function testPermitReplayAttack() public {
        uint256 value = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = project.nonces(owner);

        // Create signature
        bytes32 structHash = keccak256(
            abi.encode(project.PERMIT_TYPEHASH(), owner, spender, value, nonce, deadline)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        // First permit succeeds
        project.permit(owner, spender, value, deadline, v, r, s);

        // Try to replay same signature - should fail (nonce changed)
        vm.expectRevert(Project19Solution.InvalidSignature.selector);
        project.permit(owner, spender, value, deadline, v, r, s);
    }

    function testPermitInvalidNonce() public {
        uint256 value = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 wrongNonce = project.nonces(owner) + 1; // Future nonce

        // Create signature with wrong nonce
        bytes32 structHash = keccak256(
            abi.encode(project.PERMIT_TYPEHASH(), owner, spender, value, wrongNonce, deadline)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        // Should revert (signature valid but nonce doesn't match)
        vm.expectRevert(Project19Solution.InvalidSignature.selector);
        project.permit(owner, spender, value, deadline, v, r, s);
    }

    /*//////////////////////////////////////////////////////////////
                    META-TRANSACTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testMetaTxSignature() public {
        uint256 amount = 50 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = project.nonces(owner);

        // Create meta-tx signature
        bytes32 structHash = keccak256(
            abi.encode(
                project.METATX_TYPEHASH(),
                owner,
                spender,
                amount,
                nonce,
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        // Relayer executes meta-tx
        uint256 ownerBalanceBefore = project.balances(owner);
        uint256 spenderBalanceBefore = project.balances(spender);

        vm.expectEmit(true, true, false, true);
        emit MetaTxExecuted(owner, spender, amount);

        vm.prank(relayer);
        project.executeMetaTx(owner, spender, amount, deadline, v, r, s);

        // Verify balances changed
        assertEq(project.balances(owner), ownerBalanceBefore - amount);
        assertEq(project.balances(spender), spenderBalanceBefore + amount);

        // Verify nonce incremented
        assertEq(project.nonces(owner), nonce + 1);
    }

    function testMetaTxInsufficientBalance() public {
        uint256 amount = INITIAL_BALANCE + 1; // More than owner has
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = project.nonces(owner);

        // Create signature
        bytes32 structHash = keccak256(
            abi.encode(project.METATX_TYPEHASH(), owner, spender, amount, nonce, deadline)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        // Should revert
        vm.expectRevert(Project19Solution.InsufficientBalance.selector);
        project.executeMetaTx(owner, spender, amount, deadline, v, r, s);
    }

    function testMetaTxExpired() public {
        uint256 amount = 50 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = project.nonces(owner);

        // Create signature
        bytes32 structHash = keccak256(
            abi.encode(project.METATX_TYPEHASH(), owner, spender, amount, nonce, deadline)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        // Warp past deadline
        vm.warp(deadline + 1);

        vm.expectRevert(Project19Solution.SignatureExpired.selector);
        project.executeMetaTx(owner, spender, amount, deadline, v, r, s);
    }

    function testMetaTxZeroAddress() public {
        uint256 amount = 50 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = project.nonces(owner);

        // Create signature with zero address as recipient
        bytes32 structHash = keccak256(
            abi.encode(project.METATX_TYPEHASH(), owner, address(0), amount, nonce, deadline)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        vm.expectRevert(Project19Solution.ZeroAddress.selector);
        project.executeMetaTx(owner, address(0), amount, deadline, v, r, s);
    }

    function testMetaTxReplayProtection() public {
        uint256 amount = 50 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = project.nonces(owner);

        // Create signature
        bytes32 structHash = keccak256(
            abi.encode(project.METATX_TYPEHASH(), owner, spender, amount, nonce, deadline)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        // First execution succeeds
        project.executeMetaTx(owner, spender, amount, deadline, v, r, s);

        // Replay attempt should fail
        vm.expectRevert(Project19Solution.InvalidSignature.selector);
        project.executeMetaTx(owner, spender, amount, deadline, v, r, s);
    }

    /*//////////////////////////////////////////////////////////////
                        VOUCHER TESTS
    //////////////////////////////////////////////////////////////*/

    function testVoucherClaim() public {
        uint256 amount = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;

        // Create voucher signature (signed by issuer)
        bytes32 structHash = keccak256(
            abi.encode(
                project.METATX_TYPEHASH(),
                issuer, // from = issuer
                owner,  // to = claimer
                amount,
                uint256(0), // nonce = 0 for vouchers
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(issuerPrivateKey, digest);

        // Claim voucher
        uint256 balanceBefore = project.balances(owner);

        vm.expectEmit(true, false, false, true);
        emit VoucherClaimed(owner, amount, digest);

        project.claimVoucher(owner, amount, deadline, v, r, s);

        // Verify balance increased
        assertEq(project.balances(owner), balanceBefore + amount);

        // Verify voucher marked as used
        assertTrue(project.isVoucherUsed(digest));
    }

    function testVoucherDoubleSpend() public {
        uint256 amount = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;

        // Create voucher signature
        bytes32 structHash = keccak256(
            abi.encode(
                project.METATX_TYPEHASH(),
                issuer,
                owner,
                amount,
                uint256(0),
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(issuerPrivateKey, digest);

        // First claim succeeds
        project.claimVoucher(owner, amount, deadline, v, r, s);

        // Second claim should fail
        vm.expectRevert(Project19Solution.VoucherAlreadyUsed.selector);
        project.claimVoucher(owner, amount, deadline, v, r, s);
    }

    function testVoucherUnauthorizedIssuer() public {
        uint256 amount = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;

        // Create signature with wrong signer (not issuer)
        bytes32 structHash = keccak256(
            abi.encode(
                project.METATX_TYPEHASH(),
                issuer,
                owner,
                amount,
                uint256(0),
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );

        // Sign with owner's key instead of issuer's
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        // Should revert
        vm.expectRevert(Project19Solution.InvalidSignature.selector);
        project.claimVoucher(owner, amount, deadline, v, r, s);
    }

    function testVoucherExpired() public {
        uint256 amount = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;

        // Create signature
        bytes32 structHash = keccak256(
            abi.encode(
                project.METATX_TYPEHASH(),
                issuer,
                owner,
                amount,
                uint256(0),
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(issuerPrivateKey, digest);

        // Warp past deadline
        vm.warp(deadline + 1);

        vm.expectRevert(Project19Solution.SignatureExpired.selector);
        project.claimVoucher(owner, amount, deadline, v, r, s);
    }

    /*//////////////////////////////////////////////////////////////
                    SIGNATURE SECURITY TESTS
    //////////////////////////////////////////////////////////////*/

    function testMalleableSignature() public {
        uint256 value = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = project.nonces(owner);

        // Create digest
        bytes32 structHash = keccak256(
            abi.encode(project.PERMIT_TYPEHASH(), owner, spender, value, nonce, deadline)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        // Create malleable signature (flip s)
        bytes32 n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
        bytes32 sMalleable = bytes32(uint256(n) - uint256(s));
        uint8 vMalleable = v == 27 ? 28 : 27;

        // Original signature should work
        project.permit(owner, spender, value, deadline, v, r, s);

        // Malleable signature should fail (nonce already used)
        // Even though it's technically valid ECDSA, it's rejected
        vm.expectRevert(Project19Solution.InvalidSignature.selector);
        project.permit(owner, spender, value, deadline, vMalleable, r, sMalleable);
    }

    function testInvalidSignature() public {
        uint256 value = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;

        // Create random invalid signature
        uint8 v = 27;
        bytes32 r = keccak256("random");
        bytes32 s = keccak256("signature");

        vm.expectRevert();
        project.permit(owner, spender, value, deadline, v, r, s);
    }

    /*//////////////////////////////////////////////////////////////
                    DOMAIN SEPARATOR TESTS
    //////////////////////////////////////////////////////////////*/

    function testDomainSeparator() public {
        bytes32 expected = keccak256(
            abi.encode(
                project.EIP712_DOMAIN_TYPEHASH(),
                keccak256(bytes("Project19")),
                keccak256(bytes("1")),
                block.chainid,
                address(project)
            )
        );

        assertEq(project.getDomainSeparator(), expected);
    }

    function testCrossChainReplayProtection() public {
        // Domain separator includes chainId
        bytes32 domainSep1 = project.DOMAIN_SEPARATOR();

        // Simulate different chain
        vm.chainId(999);

        // Deploy new contract on different chain
        Project19Solution projectOtherChain = new Project19Solution();

        // Domain separators should be different
        bytes32 domainSep2 = projectOtherChain.DOMAIN_SEPARATOR();

        assertTrue(domainSep1 != domainSep2);

        // Signature valid on one chain won't work on another
        vm.chainId(1);
        uint256 value = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = project.nonces(owner);

        bytes32 structHash = keccak256(
            abi.encode(project.PERMIT_TYPEHASH(), owner, spender, value, nonce, deadline)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        // Works on original chain
        project.permit(owner, spender, value, deadline, v, r, s);

        // Would fail on other chain (can't test directly due to domain separator difference)
    }

    /*//////////////////////////////////////////////////////////////
                        UTILITY TESTS
    //////////////////////////////////////////////////////////////*/

    function testDepositWithdraw() public {
        uint256 amount = 10 ether;

        vm.deal(spender, amount);
        vm.startPrank(spender);

        project.deposit{value: amount}();
        assertEq(project.balances(spender), amount);

        project.withdraw(amount);
        assertEq(project.balances(spender), 0);
        assertEq(spender.balance, amount);

        vm.stopPrank();
    }

    function testGetNonce() public {
        assertEq(project.getNonce(owner), 0);

        // Execute a meta-tx to increment nonce
        uint256 amount = 50 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = 0;

        bytes32 structHash = keccak256(
            abi.encode(project.METATX_TYPEHASH(), owner, spender, amount, nonce, deadline)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        project.executeMetaTx(owner, spender, amount, deadline, v, r, s);

        assertEq(project.getNonce(owner), 1);
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzzPermit(uint256 value, uint256 timeOffset) public {
        // Bound inputs
        value = bound(value, 0, type(uint128).max);
        timeOffset = bound(timeOffset, 1, 365 days);

        uint256 deadline = block.timestamp + timeOffset;
        uint256 nonce = project.nonces(owner);

        // Create signature
        bytes32 structHash = keccak256(
            abi.encode(project.PERMIT_TYPEHASH(), owner, spender, value, nonce, deadline)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        // Should succeed
        project.permit(owner, spender, value, deadline, v, r, s);

        assertEq(project.allowance(owner, spender), value);
    }

    function testFuzzMetaTx(uint256 amount, uint256 timeOffset) public {
        // Bound inputs
        amount = bound(amount, 0, INITIAL_BALANCE);
        timeOffset = bound(timeOffset, 1, 365 days);

        uint256 deadline = block.timestamp + timeOffset;
        uint256 nonce = project.nonces(owner);

        // Create signature
        bytes32 structHash = keccak256(
            abi.encode(project.METATX_TYPEHASH(), owner, spender, amount, nonce, deadline)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", project.DOMAIN_SEPARATOR(), structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        // Should succeed
        project.executeMetaTx(owner, spender, amount, deadline, v, r, s);

        assertEq(project.balances(spender), amount);
    }
}
