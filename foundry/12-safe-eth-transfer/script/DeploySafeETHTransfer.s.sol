// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/SafeETHTransferSolution.sol";

/**
 * @title DeploySafeETHTransfer
 * @notice Deployment script for Safe ETH Transfer Library
 * @dev Demonstrates deployment and basic interactions
 *
 * USAGE:
 * Deploy to local network:
 *   forge script script/DeploySafeETHTransfer.s.sol --rpc-url http://localhost:8545 --broadcast
 *
 * Deploy to testnet:
 *   forge script script/DeploySafeETHTransfer.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
 *
 * Simulate (no broadcast):
 *   forge script script/DeploySafeETHTransfer.s.sol
 */
contract DeploySafeETHTransfer is Script {
    // ============================================
    // STATE VARIABLES
    // ============================================

    SafeETHTransferSolution public safeTransfer;

    // Test amounts
    uint256 constant DEPOSIT_AMOUNT = 1 ether;

    // ============================================
    // MAIN DEPLOYMENT FUNCTION
    // ============================================

    function run() public {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("Deploying Safe ETH Transfer Library");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance / 1 ether, "ETH");
        console.log("");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the contract
        safeTransfer = new SafeETHTransferSolution();

        console.log("Contract deployed at:", address(safeTransfer));
        console.log("");

        // Stop broadcasting
        vm.stopBroadcast();

        // Run example interactions (simulation only, not broadcast)
        runExamples();

        // Print summary
        printSummary();
    }

    // ============================================
    // EXAMPLE INTERACTIONS
    // ============================================

    /**
     * @notice Demonstrate contract usage with examples
     * @dev These are simulated, not broadcast to network
     */
    function runExamples() internal {
        console.log("========================================");
        console.log("Example Interactions (Simulated)");
        console.log("========================================");

        // Create test accounts
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        // Fund test accounts
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);

        // Example 1: Alice deposits
        console.log("\n1. Alice deposits 1 ETH");
        console.log("   Alice balance before:", alice.balance / 1 ether, "ETH");

        vm.prank(alice);
        safeTransfer.deposit{value: DEPOSIT_AMOUNT}();

        console.log("   Alice balance after:", alice.balance / 1 ether, "ETH");
        console.log(
            "   Alice pending withdrawal:",
            safeTransfer.getBalance(alice) / 1 ether,
            "ETH"
        );
        console.log(
            "   Contract balance:",
            safeTransfer.getContractBalance() / 1 ether,
            "ETH"
        );

        // Example 2: Bob deposits via direct transfer
        console.log("\n2. Bob deposits 2 ETH (direct transfer)");
        console.log("   Bob balance before:", bob.balance / 1 ether, "ETH");

        vm.prank(bob);
        (bool success, ) = address(safeTransfer).call{value: 2 ether}("");
        require(success, "Transfer failed");

        console.log("   Bob balance after:", bob.balance / 1 ether, "ETH");
        console.log(
            "   Bob pending withdrawal:",
            safeTransfer.getBalance(bob) / 1 ether,
            "ETH"
        );
        console.log(
            "   Contract balance:",
            safeTransfer.getContractBalance() / 1 ether,
            "ETH"
        );

        // Example 3: Alice withdraws
        console.log("\n3. Alice withdraws her balance");
        console.log("   Alice balance before:", alice.balance / 1 ether, "ETH");

        vm.prank(alice);
        safeTransfer.withdraw();

        console.log("   Alice balance after:", alice.balance / 1 ether, "ETH");
        console.log(
            "   Alice pending withdrawal:",
            safeTransfer.getBalance(alice) / 1 ether,
            "ETH"
        );
        console.log(
            "   Contract balance:",
            safeTransfer.getContractBalance() / 1 ether,
            "ETH"
        );

        // Example 4: Bob partial withdrawal
        console.log("\n4. Bob withdraws 1 ETH (partial)");
        console.log("   Bob balance before:", bob.balance / 1 ether, "ETH");

        vm.prank(bob);
        safeTransfer.withdrawAmount(1 ether);

        console.log("   Bob balance after:", bob.balance / 1 ether, "ETH");
        console.log(
            "   Bob pending withdrawal:",
            safeTransfer.getBalance(bob) / 1 ether,
            "ETH"
        );
        console.log(
            "   Contract balance:",
            safeTransfer.getContractBalance() / 1 ether,
            "ETH"
        );

        // Example 5: Batch credit
        console.log("\n5. Batch credit to multiple users");

        address charlie = makeAddr("charlie");
        address dave = makeAddr("dave");

        address[] memory recipients = new address[](2);
        recipients[0] = charlie;
        recipients[1] = dave;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 3 ether;
        amounts[1] = 2 ether;

        vm.deal(alice, 10 ether); // Refund Alice for batch credit

        vm.prank(alice);
        safeTransfer.batchCredit{value: 5 ether}(recipients, amounts);

        console.log(
            "   Charlie pending:",
            safeTransfer.getBalance(charlie) / 1 ether,
            "ETH"
        );
        console.log(
            "   Dave pending:",
            safeTransfer.getBalance(dave) / 1 ether,
            "ETH"
        );
        console.log(
            "   Contract balance:",
            safeTransfer.getContractBalance() / 1 ether,
            "ETH"
        );
    }

    // ============================================
    // SUMMARY
    // ============================================

    /**
     * @notice Print deployment summary and instructions
     */
    function printSummary() internal view {
        console.log("\n========================================");
        console.log("Deployment Summary");
        console.log("========================================");
        console.log("Contract:", address(safeTransfer));
        console.log("");
        console.log("Key Functions:");
        console.log("  deposit()                    - Deposit ETH");
        console.log("  withdraw()                   - Withdraw all pending ETH");
        console.log("  withdrawAmount(uint256)      - Withdraw specific amount");
        console.log("  getBalance(address)          - Check pending balance");
        console.log("  getContractBalance()         - Check contract ETH");
        console.log("");
        console.log("Example Usage:");
        console.log('  cast send <CONTRACT> "deposit()" --value 1ether');
        console.log('  cast send <CONTRACT> "withdraw()"');
        console.log('  cast call <CONTRACT> "getBalance(address)" <YOUR_ADDRESS>');
        console.log("");
        console.log("========================================");
    }

    // ============================================
    // VERIFICATION HELPER
    // ============================================

    /**
     * @notice Verify deployment
     * @dev Check that contract is properly deployed and functional
     */
    function verifyDeployment() public view returns (bool) {
        // Check contract exists
        if (address(safeTransfer).code.length == 0) {
            console.log("ERROR: Contract not deployed");
            return false;
        }

        // Check initial state
        if (safeTransfer.getTotalDeposited() != 0) {
            console.log("ERROR: Initial total deposited should be 0");
            return false;
        }

        if (safeTransfer.getTotalWithdrawn() != 0) {
            console.log("ERROR: Initial total withdrawn should be 0");
            return false;
        }

        if (safeTransfer.getContractBalance() != 0) {
            console.log("ERROR: Initial contract balance should be 0");
            return false;
        }

        if (!safeTransfer.verifyAccounting()) {
            console.log("ERROR: Accounting verification failed");
            return false;
        }

        console.log("[OK] Deployment verified successfully");
        return true;
    }
}

/**
 * ============================================
 * DEPLOYMENT CHECKLIST
 * ============================================
 *
 * Pre-Deployment:
 * [ ] Set PRIVATE_KEY in .env
 * [ ] Set RPC_URL in .env (if deploying to testnet/mainnet)
 * [ ] Fund deployer account with ETH for gas
 * [ ] Review contract code one final time
 * [ ] Run tests: forge test
 * [ ] Check gas estimates: forge test --gas-report
 *
 * Deployment:
 * [ ] Deploy to local network first for testing
 * [ ] Deploy to testnet (Sepolia/Goerli)
 * [ ] Verify on block explorer
 * [ ] Test all functions on testnet
 * [ ] Deploy to mainnet (if ready)
 *
 * Post-Deployment:
 * [ ] Save contract address
 * [ ] Verify on Etherscan
 * [ ] Test deposit function
 * [ ] Test withdrawal function
 * [ ] Monitor for any issues
 * [ ] Update documentation with contract address
 *
 * ============================================
 * NETWORK CONFIGURATION
 * ============================================
 *
 * Local (Anvil):
 *   forge script script/DeploySafeETHTransfer.s.sol \
 *     --rpc-url http://localhost:8545 \
 *     --broadcast
 *
 * Sepolia Testnet:
 *   forge script script/DeploySafeETHTransfer.s.sol \
 *     --rpc-url $SEPOLIA_RPC_URL \
 *     --broadcast \
 *     --verify \
 *     --etherscan-api-key $ETHERSCAN_API_KEY
 *
 * Mainnet (Use with caution!):
 *   forge script script/DeploySafeETHTransfer.s.sol \
 *     --rpc-url $MAINNET_RPC_URL \
 *     --broadcast \
 *     --verify \
 *     --etherscan-api-key $ETHERSCAN_API_KEY \
 *     --slow
 *
 * ============================================
 * INTERACTING WITH DEPLOYED CONTRACT
 * ============================================
 *
 * Using cast (Foundry):
 *
 * 1. Deposit ETH:
 *    cast send <CONTRACT_ADDRESS> "deposit()" \
 *      --value 1ether \
 *      --private-key $PRIVATE_KEY \
 *      --rpc-url $RPC_URL
 *
 * 2. Check balance:
 *    cast call <CONTRACT_ADDRESS> "getBalance(address)" <YOUR_ADDRESS> \
 *      --rpc-url $RPC_URL
 *
 * 3. Withdraw:
 *    cast send <CONTRACT_ADDRESS> "withdraw()" \
 *      --private-key $PRIVATE_KEY \
 *      --rpc-url $RPC_URL
 *
 * 4. Check contract balance:
 *    cast call <CONTRACT_ADDRESS> "getContractBalance()" \
 *      --rpc-url $RPC_URL
 *
 * 5. Send ETH directly (triggers receive):
 *    cast send <CONTRACT_ADDRESS> \
 *      --value 1ether \
 *      --private-key $PRIVATE_KEY \
 *      --rpc-url $RPC_URL
 *
 * ============================================
 * SECURITY REMINDERS
 * ============================================
 *
 * 1. Never commit private keys to git
 * 2. Use hardware wallet for mainnet deployments
 * 3. Test thoroughly on testnet first
 * 4. Consider getting a security audit for mainnet
 * 5. Start with small amounts on mainnet
 * 6. Monitor contract for unusual activity
 * 7. Have emergency response plan
 * 8. Keep deployer key secure and backed up
 *
 * ============================================
 * GAS ESTIMATES
 * ============================================
 *
 * Deployment: ~800,000 gas
 * Deposit (first): ~45,000 gas
 * Deposit (subsequent): ~30,000 gas
 * Withdraw: ~35,000-55,000 gas
 * withdrawAmount: ~35,000-55,000 gas
 *
 * At 50 gwei gas price:
 * Deployment: ~0.04 ETH
 * Deposit: ~0.0015-0.0023 ETH
 * Withdraw: ~0.0018-0.0028 ETH
 *
 * ============================================
 */
