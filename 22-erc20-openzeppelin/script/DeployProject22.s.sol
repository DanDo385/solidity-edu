// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/Project22Solution.sol";

/**
 * @title DeployProject22
 * @dev Deployment script for all OpenZeppelin ERC20 token examples
 *
 * Usage:
 *   forge script script/DeployProject22.s.sol:DeployProject22 --rpc-url <RPC_URL> --broadcast --verify
 *
 * For local testing:
 *   forge script script/DeployProject22.s.sol:DeployProject22 --fork-url http://localhost:8545 --broadcast
 */
contract DeployProject22 is Script {
    // Deployed contract addresses
    BasicTokenSolution public basicToken;
    BurnableTokenSolution public burnableToken;
    PausableTokenSolution public pausableToken;
    SnapshotTokenSolution public snapshotToken;
    GovernanceTokenSolution public governanceToken;
    CappedTokenSolution public cappedToken;
    FullFeaturedTokenSolution public fullFeaturedToken;
    CustomHookTokenSolution public customHookToken;
    VestingTokenSolution public vestingToken;
    RewardTokenSolution public rewardToken;

    function run() public {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying contracts with address:", deployer);
        console.log("Deployer balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy all token contracts
        deployAllTokens(deployer);

        vm.stopBroadcast();

        // Log deployment information
        logDeployments();
    }

    /**
     * @dev Deploy all token contracts
     */
    function deployAllTokens(address deployer) internal {
        console.log("\n=== Deploying Token Contracts ===\n");

        // 1. Basic Token
        console.log("Deploying BasicToken...");
        basicToken = new BasicTokenSolution();
        console.log("BasicToken deployed at:", address(basicToken));

        // 2. Burnable Token
        console.log("Deploying BurnableToken...");
        burnableToken = new BurnableTokenSolution();
        console.log("BurnableToken deployed at:", address(burnableToken));

        // 3. Pausable Token
        console.log("Deploying PausableToken...");
        pausableToken = new PausableTokenSolution();
        console.log("PausableToken deployed at:", address(pausableToken));

        // 4. Snapshot Token
        console.log("Deploying SnapshotToken...");
        snapshotToken = new SnapshotTokenSolution();
        console.log("SnapshotToken deployed at:", address(snapshotToken));

        // 5. Governance Token
        console.log("Deploying GovernanceToken...");
        governanceToken = new GovernanceTokenSolution();
        console.log("GovernanceToken deployed at:", address(governanceToken));

        // 6. Capped Token
        console.log("Deploying CappedToken...");
        cappedToken = new CappedTokenSolution();
        console.log("CappedToken deployed at:", address(cappedToken));

        // 7. Full Featured Token
        console.log("Deploying FullFeaturedToken...");
        fullFeaturedToken = new FullFeaturedTokenSolution();
        console.log("FullFeaturedToken deployed at:", address(fullFeaturedToken));

        // 8. Custom Hook Token (with treasury)
        console.log("Deploying CustomHookToken...");
        address treasury = deployer; // Use deployer as treasury for demo
        customHookToken = new CustomHookTokenSolution(treasury);
        console.log("CustomHookToken deployed at:", address(customHookToken));
        console.log("Treasury address:", treasury);

        // 9. Vesting Token
        console.log("Deploying VestingToken...");
        vestingToken = new VestingTokenSolution();
        console.log("VestingToken deployed at:", address(vestingToken));

        // 10. Reward Token
        console.log("Deploying RewardToken...");
        rewardToken = new RewardTokenSolution();
        console.log("RewardToken deployed at:", address(rewardToken));
    }

    /**
     * @dev Log deployment information and token details
     */
    function logDeployments() internal view {
        console.log("\n=== Deployment Summary ===\n");

        console.log("1. BasicToken:");
        console.log("   Address:", address(basicToken));
        console.log("   Name:", basicToken.name());
        console.log("   Symbol:", basicToken.symbol());
        console.log("   Total Supply:", basicToken.totalSupply());

        console.log("\n2. BurnableToken:");
        console.log("   Address:", address(burnableToken));
        console.log("   Name:", burnableToken.name());
        console.log("   Symbol:", burnableToken.symbol());

        console.log("\n3. PausableToken:");
        console.log("   Address:", address(pausableToken));
        console.log("   Name:", pausableToken.name());
        console.log("   Paused:", pausableToken.paused());

        console.log("\n4. SnapshotToken:");
        console.log("   Address:", address(snapshotToken));
        console.log("   Name:", snapshotToken.name());

        console.log("\n5. GovernanceToken:");
        console.log("   Address:", address(governanceToken));
        console.log("   Name:", governanceToken.name());

        console.log("\n6. CappedToken:");
        console.log("   Address:", address(cappedToken));
        console.log("   Name:", cappedToken.name());
        console.log("   Cap:", cappedToken.cap());
        console.log("   Current Supply:", cappedToken.totalSupply());

        console.log("\n7. FullFeaturedToken:");
        console.log("   Address:", address(fullFeaturedToken));
        console.log("   Name:", fullFeaturedToken.name());

        console.log("\n8. CustomHookToken:");
        console.log("   Address:", address(customHookToken));
        console.log("   Name:", customHookToken.name());
        console.log("   Treasury:", customHookToken.treasury());
        console.log("   Fee (bps):", customHookToken.FEE_BASIS_POINTS());

        console.log("\n9. VestingToken:");
        console.log("   Address:", address(vestingToken));
        console.log("   Name:", vestingToken.name());
        console.log("   Vesting Period:", vestingToken.VESTING_PERIOD(), "seconds");

        console.log("\n10. RewardToken:");
        console.log("   Address:", address(rewardToken));
        console.log("   Name:", rewardToken.name());

        console.log("\n=== Deployment Complete ===\n");
    }
}

/**
 * @title DeployBasicToken
 * @dev Deploy only BasicToken (for individual deployment)
 */
contract DeployBasicToken is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        BasicTokenSolution token = new BasicTokenSolution();

        vm.stopBroadcast();

        console.log("BasicToken deployed at:", address(token));
        console.log("Name:", token.name());
        console.log("Symbol:", token.symbol());
        console.log("Total Supply:", token.totalSupply());
    }
}

/**
 * @title DeployGovernanceToken
 * @dev Deploy GovernanceToken with delegation setup
 */
contract DeployGovernanceToken is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy governance token
        GovernanceTokenSolution token = new GovernanceTokenSolution();

        // Delegate voting power to self
        token.delegate(deployer);

        vm.stopBroadcast();

        console.log("GovernanceToken deployed at:", address(token));
        console.log("Deployer voting power:", token.getVotes(deployer));
    }
}

/**
 * @title DeployRewardToken
 * @dev Deploy RewardToken with initial setup
 */
contract DeployRewardToken is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy reward token
        RewardTokenSolution token = new RewardTokenSolution();

        // Create initial snapshot
        uint256 snapshotId = token.snapshot();

        vm.stopBroadcast();

        console.log("RewardToken deployed at:", address(token));
        console.log("Initial snapshot ID:", snapshotId);
    }
}

/**
 * @title DeployCustomHookToken
 * @dev Deploy CustomHookToken with treasury setup
 */
contract DeployCustomHookToken is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Get treasury address from environment or use deployer
        address treasury = vm.envOr("TREASURY_ADDRESS", deployer);

        vm.startBroadcast(deployerPrivateKey);

        CustomHookTokenSolution token = new CustomHookTokenSolution(treasury);

        vm.stopBroadcast();

        console.log("CustomHookToken deployed at:", address(token));
        console.log("Treasury address:", token.treasury());
        console.log("Fee (basis points):", token.FEE_BASIS_POINTS());
    }
}

/**
 * @title InteractWithTokens
 * @dev Example script showing token interactions
 */
contract InteractWithTokens is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Load deployed token addresses
        address basicTokenAddr = vm.envAddress("BASIC_TOKEN_ADDRESS");
        address governanceTokenAddr = vm.envAddress("GOVERNANCE_TOKEN_ADDRESS");
        address snapshotTokenAddr = vm.envAddress("SNAPSHOT_TOKEN_ADDRESS");

        BasicTokenSolution basicToken = BasicTokenSolution(basicTokenAddr);
        GovernanceTokenSolution govToken = GovernanceTokenSolution(governanceTokenAddr);
        SnapshotTokenSolution snapToken = SnapshotTokenSolution(snapshotTokenAddr);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Transfer basic tokens
        console.log("\n=== Basic Token Interaction ===");
        address recipient = makeAddr("recipient");
        basicToken.transfer(recipient, 1000e18);
        console.log("Transferred 1000 BASIC to:", recipient);
        console.log("Recipient balance:", basicToken.balanceOf(recipient));

        // 2. Delegate governance tokens
        console.log("\n=== Governance Token Interaction ===");
        govToken.delegate(deployer);
        console.log("Delegated voting power to self");
        console.log("Voting power:", govToken.getVotes(deployer));

        // 3. Create snapshot
        console.log("\n=== Snapshot Token Interaction ===");
        uint256 snapshotId = snapToken.snapshot();
        console.log("Created snapshot ID:", snapshotId);
        console.log("Balance at snapshot:", snapToken.balanceOfAt(deployer, snapshotId));

        vm.stopBroadcast();
    }
}

/**
 * @title TestRewardDistribution
 * @dev Test reward distribution functionality
 */
contract TestRewardDistribution is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy reward token
        RewardTokenSolution token = new RewardTokenSolution();

        // Create test recipients
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        // Distribute tokens
        token.transfer(alice, 250_000e18); // 25%
        token.transfer(bob, 250_000e18);   // 25%
        // Deployer keeps 50%

        // Create snapshot
        uint256 snapshotId = token.snapshot();
        console.log("Snapshot created:", snapshotId);

        // Add rewards (1 ETH)
        token.addRewards{value: 1 ether}(snapshotId);
        console.log("Added 1 ETH in rewards");

        // Check pending rewards
        console.log("\nPending rewards:");
        console.log("Deployer:", token.pendingRewards(deployer, snapshotId));
        console.log("Alice:", token.pendingRewards(alice, snapshotId));
        console.log("Bob:", token.pendingRewards(bob, snapshotId));

        vm.stopBroadcast();

        console.log("\nReward token deployed at:", address(token));
        console.log("Snapshot ID for testing:", snapshotId);
    }
}
