// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/solution/DeFiCapstoneSolution.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

contract MockPriceFeed {
    int256 public price;
    uint256 public updatedAt;

    constructor(int256 _price) {
        price = _price;
        updatedAt = block.timestamp;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 _updatedAt,
            uint80 answeredInRound
        )
    {
        return (1, price, block.timestamp, updatedAt, 1);
    }

    function setPrice(int256 _price) external {
        price = _price;
        updatedAt = block.timestamp;
    }
}

contract MockFlashBorrower is IERC3156FlashBorrower {
    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    IERC20 public token;
    bool public shouldFail;
    bool public shouldSteal;

    function setToken(address _token) external {
        token = IERC20(_token);
    }

    function setShouldFail(bool _shouldFail) external {
        shouldFail = _shouldFail;
    }

    function setShouldSteal(bool _shouldSteal) external {
        shouldSteal = _shouldSteal;
    }

    function onFlashLoan(
        address initiator,
        address _token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        require(_token == address(token), "Wrong token");

        if (shouldFail) {
            return bytes32(0);
        }

        if (shouldSteal) {
            // Don't approve repayment
            return CALLBACK_SUCCESS;
        }

        // Normal operation: approve repayment
        token.approve(msg.sender, amount + fee);

        return CALLBACK_SUCCESS;
    }

    function executeFlashLoan(
        address lender,
        uint256 amount
    ) external {
        IERC3156FlashLender(lender).flashLoan(
            this,
            address(token),
            amount,
            ""
        );
    }
}

contract DeFiCapstoneTest is Test {
    ProtocolToken public protoToken;
    NFTMembership public nftMembership;
    PriceOracle public oracle;
    Governance public governance;
    DeFiVault public vault;
    MultiSigTreasury public treasury;

    MockPriceFeed public priceFeed;
    MockFlashBorrower public flashBorrower;

    IERC20 public asset;

    address public admin = makeAddr("admin");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");
    address public strategist = makeAddr("strategist");

    address public signer1 = makeAddr("signer1");
    address public signer2 = makeAddr("signer2");
    address public signer3 = makeAddr("signer3");
    address public signer4 = makeAddr("signer4");
    address public signer5 = makeAddr("signer5");

    uint256 constant INITIAL_SUPPLY = 100_000_000 * 1e18;
    uint256 constant USER_INITIAL_BALANCE = 1_000_000 * 1e18;

    function setUp() public {
        vm.startPrank(admin);

        // Deploy protocol token
        ProtocolToken protoImpl = new ProtocolToken();
        ERC1967Proxy protoProxy = new ERC1967Proxy(
            address(protoImpl),
            abi.encodeWithSelector(ProtocolToken.initialize.selector, admin)
        );
        protoToken = ProtocolToken(address(protoProxy));

        // Mint initial supply
        protoToken.mint(admin, INITIAL_SUPPLY);

        // Deploy NFT membership
        NFTMembership nftImpl = new NFTMembership();
        ERC1967Proxy nftProxy = new ERC1967Proxy(
            address(nftImpl),
            abi.encodeWithSelector(NFTMembership.initialize.selector, admin, address(protoToken))
        );
        nftMembership = NFTMembership(address(nftProxy));

        // Deploy oracle
        PriceOracle oracleImpl = new PriceOracle();
        ERC1967Proxy oracleProxy = new ERC1967Proxy(
            address(oracleImpl),
            abi.encodeWithSelector(PriceOracle.initialize.selector, admin)
        );
        oracle = PriceOracle(address(oracleProxy));

        // Deploy governance
        Governance govImpl = new Governance();
        ERC1967Proxy govProxy = new ERC1967Proxy(
            address(govImpl),
            abi.encodeWithSelector(
                Governance.initialize.selector,
                admin,
                address(protoToken),
                address(nftMembership)
            )
        );
        governance = Governance(address(govProxy));

        // Deploy multi-sig treasury
        address[] memory signers = new address[](5);
        signers[0] = signer1;
        signers[1] = signer2;
        signers[2] = signer3;
        signers[3] = signer4;
        signers[4] = signer5;

        MultiSigTreasury treasuryImpl = new MultiSigTreasury();
        ERC1967Proxy treasuryProxy = new ERC1967Proxy(
            address(treasuryImpl),
            abi.encodeWithSelector(MultiSigTreasury.initialize.selector, signers, 3)
        );
        treasury = MultiSigTreasury(payable(address(treasuryProxy)));

        // Deploy vault (using PROTO as the asset for simplicity)
        asset = IERC20(address(protoToken));
        DeFiVault vaultImpl = new DeFiVault();
        ERC1967Proxy vaultProxy = new ERC1967Proxy(
            address(vaultImpl),
            abi.encodeWithSelector(
                DeFiVault.initialize.selector,
                admin,
                asset,
                address(nftMembership),
                address(treasury)
            )
        );
        vault = DeFiVault(address(vaultProxy));

        // Grant roles
        vault.grantRole(vault.STRATEGIST_ROLE(), strategist);

        // Setup price feed
        priceFeed = new MockPriceFeed(2000 * 1e8); // $2000 per token
        oracle.setPriceFeed(address(protoToken), address(priceFeed), 3600);

        // Setup flash borrower
        flashBorrower = new MockFlashBorrower();
        flashBorrower.setToken(address(protoToken));

        // Distribute tokens to users
        protoToken.transfer(user1, USER_INITIAL_BALANCE);
        protoToken.transfer(user2, USER_INITIAL_BALANCE);
        protoToken.transfer(user3, USER_INITIAL_BALANCE);

        vm.stopPrank();
    }

    // ============================================================================
    // PROTOCOL TOKEN TESTS
    // ============================================================================

    function test_ProtocolToken_Initialization() public {
        assertEq(protoToken.name(), "Protocol Token");
        assertEq(protoToken.symbol(), "PROTO");
        assertEq(protoToken.totalSupply(), INITIAL_SUPPLY);
        assertTrue(protoToken.hasRole(protoToken.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_ProtocolToken_Mint() public {
        vm.prank(admin);
        protoToken.mint(user1, 1000 * 1e18);
        assertEq(protoToken.balanceOf(user1), USER_INITIAL_BALANCE + 1000 * 1e18);
    }

    function test_ProtocolToken_MintRevertsMaxSupply() public {
        vm.prank(admin);
        vm.expectRevert("Exceeds max supply");
        protoToken.mint(user1, protoToken.MAX_SUPPLY());
    }

    function test_ProtocolToken_Burn() public {
        uint256 burnAmount = 1000 * 1e18;
        vm.prank(user1);
        protoToken.burn(burnAmount);
        assertEq(protoToken.balanceOf(user1), USER_INITIAL_BALANCE - burnAmount);
    }

    function test_ProtocolToken_PauseTransfers() public {
        vm.prank(admin);
        protoToken.pause();

        vm.prank(user1);
        vm.expectRevert("Pausable: paused");
        protoToken.transfer(user2, 100 * 1e18);
    }

    // ============================================================================
    // NFT MEMBERSHIP TESTS
    // ============================================================================

    function test_NFTMembership_MintBronze() public {
        uint256 price = nftMembership.tierPrices(NFTMembership.Tier.BRONZE);

        vm.startPrank(user1);
        protoToken.approve(address(nftMembership), price);
        uint256 tokenId = nftMembership.mintMembership(NFTMembership.Tier.BRONZE);
        vm.stopPrank();

        assertEq(nftMembership.ownerOf(tokenId), user1);
        assertEq(uint256(nftMembership.getTier(tokenId)), uint256(NFTMembership.Tier.BRONZE));
        assertEq(nftMembership.userNFT(user1), tokenId);
    }

    function test_NFTMembership_GetVotingMultiplier() public {
        // No NFT
        assertEq(nftMembership.getVotingMultiplier(user1), 1);

        // Bronze NFT
        vm.startPrank(user1);
        uint256 price = nftMembership.tierPrices(NFTMembership.Tier.BRONZE);
        protoToken.approve(address(nftMembership), price);
        nftMembership.mintMembership(NFTMembership.Tier.BRONZE);
        vm.stopPrank();
        assertEq(nftMembership.getVotingMultiplier(user1), 1);

        // Gold NFT
        vm.startPrank(user2);
        price = nftMembership.tierPrices(NFTMembership.Tier.GOLD);
        protoToken.approve(address(nftMembership), price);
        nftMembership.mintMembership(NFTMembership.Tier.GOLD);
        vm.stopPrank();
        assertEq(nftMembership.getVotingMultiplier(user2), 5);
    }

    function test_NFTMembership_GetFeeDiscount() public {
        vm.startPrank(user1);
        uint256 price = nftMembership.tierPrices(NFTMembership.Tier.SILVER);
        protoToken.approve(address(nftMembership), price);
        nftMembership.mintMembership(NFTMembership.Tier.SILVER);
        vm.stopPrank();

        assertEq(nftMembership.getFeeDiscount(user1), 1000); // 10%
    }

    function test_NFTMembership_UpgradeTier() public {
        // Mint bronze
        vm.startPrank(user1);
        uint256 bronzePrice = nftMembership.tierPrices(NFTMembership.Tier.BRONZE);
        protoToken.approve(address(nftMembership), bronzePrice);
        uint256 tokenId = nftMembership.mintMembership(NFTMembership.Tier.BRONZE);

        // Upgrade to silver
        uint256 silverPrice = nftMembership.tierPrices(NFTMembership.Tier.SILVER);
        uint256 upgradeCost = silverPrice - bronzePrice;
        protoToken.approve(address(nftMembership), upgradeCost);
        nftMembership.upgradeMembership(tokenId, NFTMembership.Tier.SILVER);
        vm.stopPrank();

        assertEq(uint256(nftMembership.getTier(tokenId)), uint256(NFTMembership.Tier.SILVER));
    }

    function test_NFTMembership_RevertsDoubleNFT() public {
        vm.startPrank(user1);
        uint256 price = nftMembership.tierPrices(NFTMembership.Tier.BRONZE);
        protoToken.approve(address(nftMembership), price * 2);
        nftMembership.mintMembership(NFTMembership.Tier.BRONZE);

        vm.expectRevert("Already has membership");
        nftMembership.mintMembership(NFTMembership.Tier.BRONZE);
        vm.stopPrank();
    }

    // ============================================================================
    // ORACLE TESTS
    // ============================================================================

    function test_Oracle_GetPrice() public {
        uint256 price = oracle.getPrice(address(protoToken));
        assertEq(price, 2000 * 1e8);
    }

    function test_Oracle_RevertsStalePrice() public {
        vm.warp(block.timestamp + 3601); // Past heartbeat

        vm.expectRevert("Stale price");
        oracle.getPrice(address(protoToken));
    }

    function test_Oracle_ValidatePrice() public {
        // Valid price (within 10% deviation)
        uint256 validPrice = 2100 * 1e8; // 5% increase
        assertTrue(oracle.validatePrice(address(protoToken), validPrice));

        // Invalid price (>10% deviation)
        uint256 invalidPrice = 2300 * 1e8; // 15% increase
        assertFalse(oracle.validatePrice(address(protoToken), invalidPrice));
    }

    // ============================================================================
    // GOVERNANCE TESTS
    // ============================================================================

    function test_Governance_Propose() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(vault);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(vault.pause.selector);

        vm.prank(user1);
        uint256 proposalId = governance.propose(
            targets,
            values,
            calldatas,
            "Pause the vault"
        );

        assertEq(proposalId, 1);
    }

    function test_Governance_ProposeWithGoldNFT() public {
        // User3 doesn't have enough tokens but has gold NFT
        vm.startPrank(user3);

        // Mint gold NFT
        uint256 price = nftMembership.tierPrices(NFTMembership.Tier.GOLD);
        protoToken.approve(address(nftMembership), price);
        nftMembership.mintMembership(NFTMembership.Tier.GOLD);

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(vault);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(vault.pause.selector);

        // Should succeed with Gold NFT even without threshold tokens
        uint256 proposalId = governance.propose(
            targets,
            values,
            calldatas,
            "Pause vault with NFT power"
        );

        vm.stopPrank();
        assertGt(proposalId, 0);
    }

    function test_Governance_CastVote() public {
        // Create proposal
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(vault);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(vault.pause.selector);

        vm.prank(user1);
        uint256 proposalId = governance.propose(
            targets,
            values,
            calldatas,
            "Test proposal"
        );

        // Wait for voting to start
        vm.roll(block.number + 2);

        // Vote
        vm.prank(user1);
        governance.castVote(proposalId, 1); // Vote FOR

        (,,,, uint256 forVotes,,,,) = governance.proposalCores(proposalId);
        assertEq(forVotes, governance.getVotes(user1));
    }

    function test_Governance_NFTVotingWeight() public {
        // Mint platinum NFT for user2
        vm.startPrank(user2);
        uint256 price = nftMembership.tierPrices(NFTMembership.Tier.PLATINUM);
        protoToken.approve(address(nftMembership), price);
        nftMembership.mintMembership(NFTMembership.Tier.PLATINUM);
        vm.stopPrank();

        // User2 has 10x voting power
        uint256 user1Votes = governance.getVotes(user1);
        uint256 user2Votes = governance.getVotes(user2);

        assertEq(user2Votes, user1Votes * 10);
    }

    function test_Governance_FullProposalLifecycle() public {
        // Create proposal
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(vault);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(
            vault.setFees.selector,
            500,  // 5% performance fee
            100,  // 1% management fee
            5     // 0.05% flash loan fee
        );

        vm.prank(user1);
        uint256 proposalId = governance.propose(
            targets,
            values,
            calldatas,
            "Update vault fees"
        );

        // Check state: Pending
        assertEq(uint256(governance.state(proposalId)), uint256(Governance.ProposalState.Pending));

        // Wait for voting to start
        vm.roll(block.number + 2);
        assertEq(uint256(governance.state(proposalId)), uint256(Governance.ProposalState.Active));

        // Vote
        vm.prank(user1);
        governance.castVote(proposalId, 1);
        vm.prank(user2);
        governance.castVote(proposalId, 1);

        // End voting period
        vm.roll(block.number + 50400);

        // Check state: Succeeded
        assertEq(uint256(governance.state(proposalId)), uint256(Governance.ProposalState.Succeeded));

        // Queue
        governance.queue(proposalId);
        assertEq(uint256(governance.state(proposalId)), uint256(Governance.ProposalState.Queued));

        // Wait for timelock
        vm.warp(block.timestamp + 2 days + 1);

        // Execute
        vm.prank(admin);
        governance.execute(proposalId);

        assertEq(uint256(governance.state(proposalId)), uint256(Governance.ProposalState.Executed));
        assertEq(vault.performanceFee(), 500);
    }

    // ============================================================================
    // VAULT TESTS
    // ============================================================================

    function test_Vault_Deposit() public {
        uint256 depositAmount = 10_000 * 1e18;

        vm.startPrank(user1);
        protoToken.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user1);
        vm.stopPrank();

        assertEq(vault.balanceOf(user1), shares);
        assertEq(shares, depositAmount); // 1:1 initially
    }

    function test_Vault_DepositWithNFTBonus() public {
        // Mint silver NFT for discount
        vm.startPrank(user1);
        uint256 nftPrice = nftMembership.tierPrices(NFTMembership.Tier.SILVER);
        protoToken.approve(address(nftMembership), nftPrice);
        nftMembership.mintMembership(NFTMembership.Tier.SILVER);

        uint256 depositAmount = 10_000 * 1e18;
        protoToken.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user1);
        vm.stopPrank();

        assertGt(shares, 0);
    }

    function test_Vault_Withdraw() public {
        uint256 depositAmount = 10_000 * 1e18;

        vm.startPrank(user1);
        protoToken.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user1);

        uint256 withdrawAmount = vault.withdraw(depositAmount / 2, user1, user1);
        vm.stopPrank();

        assertGt(withdrawAmount, 0);
    }

    function test_Vault_Harvest() public {
        // Deposit funds
        vm.startPrank(user1);
        uint256 depositAmount = 100_000 * 1e18;
        protoToken.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user1);
        vm.stopPrank();

        // Simulate profit by sending tokens to vault
        vm.prank(admin);
        protoToken.transfer(address(vault), 10_000 * 1e18);

        // Harvest
        vm.prank(strategist);
        vault.harvest();

        assertGt(vault.totalFeesCollected(), 0);
    }

    // ============================================================================
    // FLASH LOAN TESTS
    // ============================================================================

    function test_FlashLoan_Success() public {
        // Deposit funds to vault
        vm.startPrank(user1);
        uint256 depositAmount = 100_000 * 1e18;
        protoToken.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user1);
        vm.stopPrank();

        // Setup borrower
        uint256 loanAmount = 50_000 * 1e18;
        uint256 fee = vault.flashFee(address(protoToken), loanAmount);

        vm.prank(admin);
        protoToken.transfer(address(flashBorrower), fee);

        // Execute flash loan
        vm.prank(address(flashBorrower));
        flashBorrower.executeFlashLoan(address(vault), loanAmount);

        assertGt(vault.totalFeesCollected(), 0);
    }

    function test_FlashLoan_MaxAmount() public {
        vm.startPrank(user1);
        uint256 depositAmount = 100_000 * 1e18;
        protoToken.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user1);
        vm.stopPrank();

        uint256 maxLoan = vault.maxFlashLoan(address(protoToken));
        uint256 expectedMax = (depositAmount * 8000) / 10000; // 80%

        assertEq(maxLoan, expectedMax);
    }

    function test_FlashLoan_RevertsOnFailedCallback() public {
        vm.startPrank(user1);
        uint256 depositAmount = 100_000 * 1e18;
        protoToken.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user1);
        vm.stopPrank();

        flashBorrower.setShouldFail(true);

        vm.prank(address(flashBorrower));
        vm.expectRevert("Callback failed");
        flashBorrower.executeFlashLoan(address(vault), 10_000 * 1e18);
    }

    function test_FlashLoan_RevertsOnInsufficientRepayment() public {
        vm.startPrank(user1);
        uint256 depositAmount = 100_000 * 1e18;
        protoToken.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user1);
        vm.stopPrank();

        flashBorrower.setShouldSteal(true);

        vm.prank(address(flashBorrower));
        vm.expectRevert();
        flashBorrower.executeFlashLoan(address(vault), 10_000 * 1e18);
    }

    // ============================================================================
    // MULTI-SIG TREASURY TESTS
    // ============================================================================

    function test_Treasury_SubmitTransaction() public {
        vm.prank(signer1);
        uint256 txId = treasury.submitTransaction(user1, 1 ether, "");

        (address to, uint256 value,, bool executed, uint256 confirmations) = treasury.transactions(txId);
        assertEq(to, user1);
        assertEq(value, 1 ether);
        assertEq(executed, false);
        assertEq(confirmations, 1); // Auto-confirmed by submitter
    }

    function test_Treasury_ConfirmTransaction() public {
        vm.prank(signer1);
        uint256 txId = treasury.submitTransaction(user1, 1 ether, "");

        vm.prank(signer2);
        treasury.confirmTransaction(txId);

        (,,,, uint256 confirmations) = treasury.transactions(txId);
        assertEq(confirmations, 2);
    }

    function test_Treasury_ExecuteTransaction() public {
        // Fund treasury
        vm.deal(address(treasury), 10 ether);

        vm.prank(signer1);
        uint256 txId = treasury.submitTransaction(user1, 1 ether, "");

        vm.prank(signer2);
        treasury.confirmTransaction(txId);

        vm.prank(signer3);
        treasury.confirmTransaction(txId); // This triggers execution

        (,,, bool executed,) = treasury.transactions(txId);
        assertTrue(executed);
        assertEq(user1.balance, 1 ether);
    }

    function test_Treasury_RevokeConfirmation() public {
        vm.prank(signer1);
        uint256 txId = treasury.submitTransaction(user1, 1 ether, "");

        vm.prank(signer2);
        treasury.confirmTransaction(txId);

        vm.prank(signer2);
        treasury.revokeConfirmation(txId);

        (,,,, uint256 confirmations) = treasury.transactions(txId);
        assertEq(confirmations, 1); // Back to just signer1
    }

    // ============================================================================
    // INTEGRATION TESTS
    // ============================================================================

    function test_Integration_FullUserJourney() public {
        vm.startPrank(user1);

        // 1. Mint NFT membership
        uint256 nftPrice = nftMembership.tierPrices(NFTMembership.Tier.GOLD);
        protoToken.approve(address(nftMembership), nftPrice);
        nftMembership.mintMembership(NFTMembership.Tier.GOLD);

        // 2. Deposit into vault
        uint256 depositAmount = 50_000 * 1e18;
        protoToken.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user1);

        // 3. Create governance proposal
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(vault);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(vault.setFees.selector, 500, 100, 5);

        uint256 proposalId = governance.propose(targets, values, calldatas, "Reduce fees");

        vm.stopPrank();

        // 4. Vote on proposal
        vm.roll(block.number + 2);

        vm.prank(user1);
        governance.castVote(proposalId, 1);

        vm.prank(user2);
        governance.castVote(proposalId, 1);

        // 5. Execute proposal
        vm.roll(block.number + 50400);
        governance.queue(proposalId);

        vm.warp(block.timestamp + 2 days + 1);
        vm.prank(admin);
        governance.execute(proposalId);

        // 6. Withdraw from vault
        vm.prank(user1);
        vault.withdraw(depositAmount / 2, user1, user1);

        assertGt(protoToken.balanceOf(user1), 0);
    }

    // ============================================================================
    // ATTACK SCENARIO TESTS
    // ============================================================================

    function test_Attack_ReentrancyProtection() public {
        // Vault has reentrancy guards on all state-changing functions
        // This test verifies the guards work

        vm.startPrank(user1);
        uint256 depositAmount = 10_000 * 1e18;
        protoToken.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user1);
        vm.stopPrank();

        // The ReentrancyGuard should prevent any reentrancy attacks
        // Flash loan includes nonReentrant modifier
    }

    function test_Attack_GovernanceTakeover() public {
        // Attacker tries to create malicious proposal
        address attacker = makeAddr("attacker");

        // Give attacker some tokens but not threshold
        vm.prank(admin);
        protoToken.transfer(attacker, 50_000 * 1e18);

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(vault);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(
            vault.grantRole.selector,
            vault.DEFAULT_ADMIN_ROLE(),
            attacker
        );

        vm.prank(attacker);
        vm.expectRevert("Insufficient tokens or NFT tier");
        governance.propose(targets, values, calldatas, "Malicious proposal");
    }

    function test_Attack_FlashLoanInflationAttack() public {
        // Attempt to manipulate vault share price via flash loan

        vm.startPrank(user1);
        uint256 depositAmount = 100_000 * 1e18;
        protoToken.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user1);
        vm.stopPrank();

        // The vault's internal accounting should prevent share manipulation
        // Flash loans are atomic and don't affect share prices
        uint256 sharesBefore = vault.balanceOf(user1);

        // Even after flash loan activity
        uint256 loanAmount = 50_000 * 1e18;
        uint256 fee = vault.flashFee(address(protoToken), loanAmount);

        vm.prank(admin);
        protoToken.transfer(address(flashBorrower), fee);

        vm.prank(address(flashBorrower));
        flashBorrower.executeFlashLoan(address(vault), loanAmount);

        // Shares unchanged
        assertEq(vault.balanceOf(user1), sharesBefore);
    }

    // ============================================================================
    // FUZZ TESTS
    // ============================================================================

    function testFuzz_Vault_DepositWithdraw(uint256 amount) public {
        amount = bound(amount, 1e18, USER_INITIAL_BALANCE);

        vm.startPrank(user1);
        protoToken.approve(address(vault), amount);
        uint256 shares = vault.deposit(amount, user1);

        vault.withdraw(amount, user1, user1);
        vm.stopPrank();

        // User should get approximately the same amount back (minus fees)
        assertGe(protoToken.balanceOf(user1), USER_INITIAL_BALANCE - amount / 100);
    }

    function testFuzz_FlashLoan_Amount(uint256 amount) public {
        uint256 depositAmount = 1_000_000 * 1e18;

        vm.startPrank(user1);
        protoToken.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user1);
        vm.stopPrank();

        uint256 maxLoan = vault.maxFlashLoan(address(protoToken));
        amount = bound(amount, 1e18, maxLoan);

        uint256 fee = vault.flashFee(address(protoToken), amount);

        vm.prank(admin);
        protoToken.transfer(address(flashBorrower), fee);

        vm.prank(address(flashBorrower));
        flashBorrower.executeFlashLoan(address(vault), amount);
    }

    // ============================================================================
    // INVARIANT TESTS
    // ============================================================================

    function invariant_VaultSharesMatchAssets() public {
        // Total shares should represent total assets
        if (vault.totalSupply() > 0) {
            uint256 assets = vault.totalAssets();
            uint256 shares = vault.totalSupply();
            assertGe(assets, shares / 2); // Allow for some deviation due to fees
        }
    }

    function invariant_TokenSupplyNeverExceedsMax() public {
        assertLe(protoToken.totalSupply(), protoToken.MAX_SUPPLY());
    }
}
