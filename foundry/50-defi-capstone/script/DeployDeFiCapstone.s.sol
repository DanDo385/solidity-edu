// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/solution/DeFiCapstoneSolution.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeployDeFiCapstone
 * @notice Complete deployment script for the entire DeFi protocol
 * @dev Deploys all contracts with proper initialization and configuration
 *
 * Usage:
 * forge script script/DeployDeFiCapstone.s.sol:DeployDeFiCapstone --rpc-url $RPC_URL --broadcast --verify
 *
 * For local testing:
 * forge script script/DeployDeFiCapstone.s.sol:DeployDeFiCapstone --fork-url http://localhost:8545 --broadcast
 */
contract DeployDeFiCapstone is Script {
    // Deployment addresses
    ProtocolToken public protoToken;
    NFTMembership public nftMembership;
    PriceOracle public oracle;
    Governance public governance;
    DeFiVault public vault;
    MultiSigTreasury public treasury;

    // Configuration
    address public admin;
    address[] public multiSigSigners;
    uint256 public requiredSignatures = 3;

    // Protocol parameters
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 1e18; // 100M tokens for initial distribution
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;   // 1B max supply

    function setUp() public {
        // Get deployer as admin
        admin = vm.envOr("ADMIN_ADDRESS", msg.sender);

        // Setup multi-sig signers (default to example addresses, override via env)
        multiSigSigners.push(vm.envOr("SIGNER_1", makeAddr("signer1")));
        multiSigSigners.push(vm.envOr("SIGNER_2", makeAddr("signer2")));
        multiSigSigners.push(vm.envOr("SIGNER_3", makeAddr("signer3")));
        multiSigSigners.push(vm.envOr("SIGNER_4", makeAddr("signer4")));
        multiSigSigners.push(vm.envOr("SIGNER_5", makeAddr("signer5")));

        console.log("=== Deployment Configuration ===");
        console.log("Admin:", admin);
        console.log("Multi-sig signers:", multiSigSigners.length);
        console.log("Required signatures:", requiredSignatures);
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0));

        if (deployerPrivateKey == 0) {
            console.log("Warning: No private key found, using default for testing");
            deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        }

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n=== Starting DeFi Protocol Deployment ===\n");

        // Step 1: Deploy Protocol Token
        deployProtocolToken();

        // Step 2: Deploy NFT Membership
        deployNFTMembership();

        // Step 3: Deploy Oracle System
        deployOracle();

        // Step 4: Deploy Multi-sig Treasury
        deployTreasury();

        // Step 5: Deploy Governance
        deployGovernance();

        // Step 6: Deploy Vault
        deployVault();

        // Step 7: Configure Protocol
        configureProtocol();

        // Step 8: Transfer Ownership
        transferOwnership();

        vm.stopBroadcast();

        console.log("\n=== Deployment Summary ===");
        logDeploymentAddresses();

        console.log("\n=== Post-Deployment Steps ===");
        logPostDeploymentInstructions();
    }

    function deployProtocolToken() internal {
        console.log("1. Deploying Protocol Token...");

        // Deploy implementation
        ProtocolToken implementation = new ProtocolToken();
        console.log("   Implementation:", address(implementation));

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(ProtocolToken.initialize.selector, admin)
        );
        console.log("   Proxy:", address(proxy));

        protoToken = ProtocolToken(address(proxy));

        // Mint initial supply
        protoToken.mint(admin, INITIAL_SUPPLY);
        console.log("   Initial supply minted:", INITIAL_SUPPLY / 1e18, "PROTO");
        console.log("   ✓ Protocol Token deployed\n");
    }

    function deployNFTMembership() internal {
        console.log("2. Deploying NFT Membership...");

        // Deploy implementation
        NFTMembership implementation = new NFTMembership();
        console.log("   Implementation:", address(implementation));

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(
                NFTMembership.initialize.selector,
                admin,
                address(protoToken)
            )
        );
        console.log("   Proxy:", address(proxy));

        nftMembership = NFTMembership(address(proxy));

        console.log("   Tier prices configured:");
        console.log("   - BRONZE:", nftMembership.tierPrices(NFTMembership.Tier.BRONZE) / 1e18, "PROTO");
        console.log("   - SILVER:", nftMembership.tierPrices(NFTMembership.Tier.SILVER) / 1e18, "PROTO");
        console.log("   - GOLD:", nftMembership.tierPrices(NFTMembership.Tier.GOLD) / 1e18, "PROTO");
        console.log("   - PLATINUM:", nftMembership.tierPrices(NFTMembership.Tier.PLATINUM) / 1e18, "PROTO");
        console.log("   ✓ NFT Membership deployed\n");
    }

    function deployOracle() internal {
        console.log("3. Deploying Price Oracle...");

        // Deploy implementation
        PriceOracle implementation = new PriceOracle();
        console.log("   Implementation:", address(implementation));

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(PriceOracle.initialize.selector, admin)
        );
        console.log("   Proxy:", address(proxy));

        oracle = PriceOracle(address(proxy));
        console.log("   ✓ Price Oracle deployed\n");
    }

    function deployTreasury() internal {
        console.log("4. Deploying Multi-sig Treasury...");

        // Deploy implementation
        MultiSigTreasury implementation = new MultiSigTreasury();
        console.log("   Implementation:", address(implementation));

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(
                MultiSigTreasury.initialize.selector,
                multiSigSigners,
                requiredSignatures
            )
        );
        console.log("   Proxy:", address(proxy));

        treasury = MultiSigTreasury(payable(address(proxy)));

        console.log("   Signers:");
        for (uint i = 0; i < multiSigSigners.length; i++) {
            console.log("   -", multiSigSigners[i]);
        }
        console.log("   Required confirmations:", requiredSignatures);
        console.log("   ✓ Multi-sig Treasury deployed\n");
    }

    function deployGovernance() internal {
        console.log("5. Deploying Governance...");

        // Deploy implementation
        Governance implementation = new Governance();
        console.log("   Implementation:", address(implementation));

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(
                Governance.initialize.selector,
                admin,
                address(protoToken),
                address(nftMembership)
            )
        );
        console.log("   Proxy:", address(proxy));

        governance = Governance(address(proxy));

        console.log("   Parameters:");
        console.log("   - Proposal threshold:", governance.proposalThreshold() / 1e18, "PROTO");
        console.log("   - Quorum:", governance.quorumPercentage(), "%");
        console.log("   - Voting delay:", governance.votingDelay(), "blocks");
        console.log("   - Voting period:", governance.votingPeriod(), "blocks (~7 days)");
        console.log("   - Timelock:", governance.timelockDelay() / 1 days, "days");
        console.log("   ✓ Governance deployed\n");
    }

    function deployVault() internal {
        console.log("6. Deploying DeFi Vault...");

        // Deploy implementation
        DeFiVault implementation = new DeFiVault();
        console.log("   Implementation:", address(implementation));

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(
                DeFiVault.initialize.selector,
                admin,
                IERC20(address(protoToken)), // Using PROTO as vault asset
                address(nftMembership),
                address(treasury)
            )
        );
        console.log("   Proxy:", address(proxy));

        vault = DeFiVault(address(proxy));

        console.log("   Fee structure:");
        console.log("   - Performance fee:", vault.performanceFee() / 100, "%");
        console.log("   - Management fee:", vault.managementFee() / 100, "%");
        console.log("   - Flash loan fee:", vault.flashLoanFee(), "bps");
        console.log("   ✓ DeFi Vault deployed\n");
    }

    function configureProtocol() internal {
        console.log("7. Configuring Protocol...");

        // Grant minter role to admin for initial distribution
        protoToken.grantRole(protoToken.MINTER_ROLE(), admin);

        // Grant necessary roles for vault
        vault.grantRole(vault.STRATEGIST_ROLE(), admin);

        // Setup oracle (example with mock feed for testing)
        // In production, replace with actual Chainlink price feeds
        // oracle.setPriceFeed(address(protoToken), CHAINLINK_FEED_ADDRESS, 3600);

        console.log("   ✓ Protocol configured\n");
    }

    function transferOwnership() internal {
        console.log("8. Transferring Ownership...");

        // In production, transfer admin roles to multi-sig treasury
        // For initial deployment, keeping admin for setup

        console.log("   Note: Admin roles retained for initial setup");
        console.log("   Transfer to multi-sig treasury after verification");
        console.log("   ✓ Ownership setup complete\n");
    }

    function logDeploymentAddresses() internal view {
        console.log("Protocol Token:", address(protoToken));
        console.log("NFT Membership:", address(nftMembership));
        console.log("Price Oracle:", address(oracle));
        console.log("Governance:", address(governance));
        console.log("DeFi Vault:", address(vault));
        console.log("Multi-sig Treasury:", address(treasury));
    }

    function logPostDeploymentInstructions() internal view {
        console.log("1. Verify all contracts on block explorer");
        console.log("2. Setup price feeds for oracle");
        console.log("3. Fund treasury with initial allocation");
        console.log("4. Create initial governance proposals");
        console.log("5. Distribute tokens according to tokenomics:");
        console.log("   - 40% Community Rewards (vesting)");
        console.log("   - 20% Team & Advisors (vesting)");
        console.log("   - 15% Treasury");
        console.log("   - 15% Liquidity Mining");
        console.log("   - 10% Initial DEX Offering");
        console.log("6. Transfer admin roles to multi-sig");
        console.log("7. Unpause vault when ready");
        console.log("8. Enable NFT minting");
        console.log("9. Activate governance");
        console.log("10. Announce protocol launch");
    }

    // Helper function for testing
    function makeAddr(string memory name) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(name)))));
    }
}

/**
 * @title DeployTestnet
 * @notice Simplified deployment for testnet with pre-funded accounts
 */
contract DeployTestnet is Script {
    function run() public {
        console.log("=== Testnet Deployment ===\n");

        // Use simpler setup for testnet
        DeployDeFiCapstone deployer = new DeployDeFiCapstone();
        deployer.setUp();
        deployer.run();

        console.log("\n=== Testnet Deployment Complete ===");
        console.log("Use these addresses to interact with the protocol on testnet");
    }
}

/**
 * @title UpgradeProtocol
 * @notice Script to upgrade protocol contracts via governance
 */
contract UpgradeProtocol is Script {
    function run() public {
        console.log("=== Protocol Upgrade ===\n");

        address protoTokenProxy = vm.envAddress("PROTO_TOKEN_PROXY");
        address admin = vm.envAddress("ADMIN_ADDRESS");

        vm.startBroadcast();

        // Deploy new implementation
        ProtocolToken newImplementation = new ProtocolToken();
        console.log("New implementation deployed:", address(newImplementation));

        // Upgrade through proxy (requires UPGRADER_ROLE)
        // In production, this should go through governance
        console.log("Upgrade must be executed by UPGRADER_ROLE");
        console.log("Consider creating governance proposal for upgrade");

        vm.stopBroadcast();
    }
}

/**
 * @title ConfigureOracle
 * @notice Script to configure oracle price feeds
 */
contract ConfigureOracle is Script {
    function run() public {
        address oracleAddress = vm.envAddress("ORACLE_ADDRESS");
        address priceFeedAddress = vm.envAddress("PRICE_FEED_ADDRESS");
        address assetAddress = vm.envAddress("ASSET_ADDRESS");

        vm.startBroadcast();

        PriceOracle oracle = PriceOracle(oracleAddress);

        // Configure price feed
        oracle.setPriceFeed(
            assetAddress,
            priceFeedAddress,
            3600 // 1 hour heartbeat
        );

        console.log("Oracle configured for asset:", assetAddress);
        console.log("Price feed:", priceFeedAddress);

        vm.stopBroadcast();
    }
}

/**
 * @title FundTreasury
 * @notice Script to fund treasury with initial allocation
 */
contract FundTreasury is Script {
    function run() public {
        address protoTokenAddress = vm.envAddress("PROTO_TOKEN_ADDRESS");
        address treasuryAddress = vm.envAddress("TREASURY_ADDRESS");
        uint256 treasuryAllocation = 150_000_000 * 1e18; // 15% of 1B

        vm.startBroadcast();

        ProtocolToken protoToken = ProtocolToken(protoTokenAddress);

        // Transfer to treasury
        protoToken.transfer(treasuryAddress, treasuryAllocation);

        console.log("Treasury funded with:", treasuryAllocation / 1e18, "PROTO");

        vm.stopBroadcast();
    }
}

/**
 * @title CreateGovernanceProposal
 * @notice Script to create a governance proposal
 */
contract CreateGovernanceProposal is Script {
    function run() public {
        address governanceAddress = vm.envAddress("GOVERNANCE_ADDRESS");
        address vaultAddress = vm.envAddress("VAULT_ADDRESS");

        vm.startBroadcast();

        Governance governance = Governance(governanceAddress);

        // Example: Proposal to update vault fees
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = vaultAddress;
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(
            DeFiVault.setFees.selector,
            500,  // 5% performance fee
            100,  // 1% management fee
            5     // 0.05% flash loan fee
        );

        uint256 proposalId = governance.propose(
            targets,
            values,
            calldatas,
            "Reduce protocol fees to increase competitiveness"
        );

        console.log("Proposal created with ID:", proposalId);

        vm.stopBroadcast();
    }
}
