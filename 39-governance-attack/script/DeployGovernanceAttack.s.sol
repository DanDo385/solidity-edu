// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/GovernanceAttackSolution.sol";

/**
 * @title Deploy Project 39: Governance Attack Simulation
 * @notice Deployment script for governance attack demonstration
 * @dev WARNING: These contracts contain intentional vulnerabilities
 *      NEVER deploy to mainnet or use with real funds
 */
contract DeployGovernanceAttack is Script {
    // Deployed contracts
    GovernanceTokenSolution public govToken;
    VulnerableDAOSolution public vulnerableDAO;
    SafeDAOSolution public safeDAO;
    SimpleFlashloanProviderSolution public flashloanProvider;
    FlashloanGovernanceAttackerSolution public attacker;
    MaliciousTreasurySolution public treasury;
    VoteBuyingAttackerSolution public voteBuyer;

    // Configuration
    address public guardian;
    uint256 public flashloanLiquidity = 500_000 * 1e18;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Guardian should be a multisig in production
        guardian = vm.envOr("GUARDIAN_ADDRESS", deployer);

        console.log("========================================");
        console.log("DEPLOYING GOVERNANCE ATTACK SIMULATION");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("Guardian:", guardian);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Governance Token
        console.log("Deploying Governance Token...");
        govToken = new GovernanceTokenSolution();
        console.log("  GovernanceToken deployed at:", address(govToken));

        // 2. Deploy Vulnerable DAO
        console.log("\nDeploying Vulnerable DAO...");
        vulnerableDAO = new VulnerableDAOSolution(address(govToken));
        console.log("  VulnerableDAO deployed at:", address(vulnerableDAO));

        // 3. Deploy Safe DAO
        console.log("\nDeploying Safe DAO...");
        safeDAO = new SafeDAOSolution(address(govToken), guardian);
        console.log("  SafeDAO deployed at:", address(safeDAO));

        // 4. Deploy Flashloan Provider
        console.log("\nDeploying Flashloan Provider...");
        flashloanProvider = new SimpleFlashloanProviderSolution(address(govToken));
        console.log("  FlashloanProvider deployed at:", address(flashloanProvider));

        // 5. Fund Flashloan Provider
        console.log("\nFunding Flashloan Provider...");
        govToken.approve(address(flashloanProvider), flashloanLiquidity);
        flashloanProvider.depositTokens(flashloanLiquidity);
        console.log("  Deposited:", flashloanLiquidity / 1e18, "GOV tokens");

        // 6. Deploy Attacker Contract
        console.log("\nDeploying Attacker Contract...");
        attacker = new FlashloanGovernanceAttackerSolution(
            address(vulnerableDAO),
            address(flashloanProvider),
            address(govToken)
        );
        console.log("  Attacker deployed at:", address(attacker));

        // 7. Deploy Vote Buyer
        console.log("\nDeploying Vote Buyer...");
        voteBuyer = new VoteBuyingAttackerSolution(
            address(govToken),
            address(vulnerableDAO)
        );
        console.log("  VoteBuyer deployed at:", address(voteBuyer));

        // 8. Deploy Treasury
        console.log("\nDeploying Treasury...");
        treasury = new MaliciousTreasurySolution();
        console.log("  Treasury deployed at:", address(treasury));

        vm.stopBroadcast();

        // Print summary
        console.log("\n========================================");
        console.log("DEPLOYMENT COMPLETE");
        console.log("========================================");
        console.log("\nCONTRACT ADDRESSES:");
        console.log("-------------------");
        console.log("GovernanceToken:    ", address(govToken));
        console.log("VulnerableDAO:      ", address(vulnerableDAO));
        console.log("SafeDAO:            ", address(safeDAO));
        console.log("FlashloanProvider:  ", address(flashloanProvider));
        console.log("Attacker:           ", address(attacker));
        console.log("VoteBuyer:          ", address(voteBuyer));
        console.log("Treasury:           ", address(treasury));
        console.log("Guardian:           ", guardian);

        console.log("\nCONFIGURATION:");
        console.log("--------------");
        console.log("Flashloan Liquidity:", flashloanLiquidity / 1e18, "GOV");
        console.log("Deployer Balance:   ", govToken.balanceOf(deployer) / 1e18, "GOV");

        console.log("\nVULNERABLE DAO PARAMS:");
        console.log("----------------------");
        console.log("Voting Period:       ", vulnerableDAO.votingPeriod(), "blocks");
        console.log("Voting Delay:        ", vulnerableDAO.votingDelay(), "blocks");
        console.log("Proposal Threshold:  ", vulnerableDAO.proposalThreshold() / 1e18, "GOV");
        console.log("Quorum:              ", vulnerableDAO.quorumVotes() / 1e18, "GOV");

        console.log("\nSAFE DAO PARAMS:");
        console.log("----------------");
        console.log("Voting Period:       ", safeDAO.votingPeriod(), "blocks");
        console.log("Voting Delay:        ", safeDAO.votingDelay(), "blocks");
        console.log("Proposal Threshold:  ", safeDAO.proposalThreshold() / 1e18, "GOV");
        console.log("Quorum:              ", safeDAO.quorumVotes() / 1e18, "GOV");
        console.log("Timelock Period:     ", safeDAO.timelockPeriod(), "seconds");
        console.log("Max Proposal Value:  ", safeDAO.maxProposalValue() / 1 ether, "ETH");

        console.log("\n⚠️  WARNING: These contracts contain intentional vulnerabilities!");
        console.log("⚠️  FOR EDUCATIONAL PURPOSES ONLY - DO NOT USE WITH REAL FUNDS!");
    }

    /**
     * @notice Deploy minimal setup for quick testing
     */
    function deployQuick() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        guardian = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        govToken = new GovernanceTokenSolution();
        vulnerableDAO = new VulnerableDAOSolution(address(govToken));
        flashloanProvider = new SimpleFlashloanProviderSolution(address(govToken));

        // Fund flashloan provider
        govToken.approve(address(flashloanProvider), flashloanLiquidity);
        flashloanProvider.depositTokens(flashloanLiquidity);

        vm.stopBroadcast();

        console.log("Quick deployment complete!");
        console.log("GovernanceToken:", address(govToken));
        console.log("VulnerableDAO:", address(vulnerableDAO));
        console.log("FlashloanProvider:", address(flashloanProvider));
    }
}

/**
 * @title Interact with deployed contracts
 * @notice Helper script for interacting with deployed governance contracts
 */
contract InteractGovernanceAttack is Script {
    function createProposal(
        address daoAddress,
        address target,
        string memory description
    ) external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        VulnerableDAOSolution dao = VulnerableDAOSolution(payable(daoAddress));

        uint256 proposalId = dao.propose(
            target,
            0,
            "",
            description
        );

        console.log("Proposal created with ID:", proposalId);

        vm.stopBroadcast();
    }

    function vote(
        address daoAddress,
        uint256 proposalId,
        bool support
    ) external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        VulnerableDAOSolution dao = VulnerableDAOSolution(payable(daoAddress));
        dao.castVote(proposalId, support);

        console.log("Vote cast on proposal", proposalId);
        console.log("Support:", support);

        vm.stopBroadcast();
    }

    function executeProposal(address daoAddress, uint256 proposalId) external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        VulnerableDAOSolution dao = VulnerableDAOSolution(payable(daoAddress));
        dao.execute(proposalId);

        console.log("Proposal", proposalId, "executed!");

        vm.stopBroadcast();
    }

    function simulateAttack(
        address attackerAddress,
        uint256 proposalId,
        uint256 flashloanAmount
    ) external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        FlashloanGovernanceAttackerSolution attacker = FlashloanGovernanceAttackerSolution(
            attackerAddress
        );

        console.log("Executing flashloan attack...");
        console.log("Proposal ID:", proposalId);
        console.log("Flashloan amount:", flashloanAmount / 1e18, "GOV");

        attacker.attack(proposalId, true, flashloanAmount);

        console.log("Attack executed successfully!");

        vm.stopBroadcast();
    }
}
