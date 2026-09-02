// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { SuperGovernor } from "../../src/SuperGovernor.sol";
import { ManagedSuperVault } from "../../src/ManagedSuperVault/ManagedSuperVault.sol";
import { ManagedSuperVaultStrategy } from "../../src/ManagedSuperVault/ManagedSuperVaultStrategy.sol";
import { ManagedSuperVaultAggregator } from "../../src/ManagedSuperVault/ManagedSuperVaultAggregator.sol";
import { ManagedSuperVaultDepositQueue } from "../../src/ManagedSuperVault/ManagedSuperVaultDepositQueue.sol";
import { ManagedNAVOracle } from "../../src/ManagedSuperVault/ManagedNAVOracle.sol";
import { SuperVaultEscrow } from "../../src/SuperVault/SuperVaultEscrow.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { IManagedSuperVaultAggregator } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";
import { IManagedNAVOracle } from "../../src/interfaces/ManagedSuperVault/IManagedNAVOracle.sol";
import {
    IManagedSuperVaultDepositQueue
} from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultDepositQueue.sol";
import { PeripheryHelpers } from "./PeripheryHelpers.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";

/// @notice Shared test harness for the Managed SuperVault family (reuse architecture):
///         forked vault/strategy/aggregator + reused escrow impl + deposit queue + NAV oracle
abstract contract ManagedSuperVaultTestBase is PeripheryHelpers {
    SuperGovernor internal superGovernor;
    ManagedSuperVaultAggregator internal aggregator;
    ManagedNAVOracle internal navOracle;

    ManagedSuperVault internal vault;
    ManagedSuperVaultStrategy internal strategy;
    SuperVaultEscrow internal escrow;
    ManagedSuperVaultDepositQueue internal queue;

    MockERC20 internal asset;

    // Accounts
    address internal sGovernor;
    address internal governor;
    address internal guardian;
    address internal treasury;
    address internal manager;
    address internal secondaryManager;
    address internal attestor;
    address internal attestor2;
    address internal feeRecipient;
    address internal user;
    // user2 is inherited from v2-core test Helpers

    // Default vault parameters
    uint256 internal constant MIN_UPDATE_INTERVAL = 100;
    uint256 internal constant MAX_STALENESS = 1 days;
    uint256 internal constant INITIAL_PPS = 1e18; // 18-decimals asset

    bytes32 internal constant MANAGED_AGGREGATOR_KEY = keccak256("MANAGED_SUPER_VAULT_AGGREGATOR");
    bytes32 internal constant EVIDENCE_HASH = keccak256("nav-evidence");

    function setUp() public virtual {
        // Start at a realistic timestamp (the post-unpause skim timelock measures from 0 otherwise)
        vm.warp(30 days);

        sGovernor = _deployAccount(0x1, "SuperGovernor");
        governor = _deployAccount(0x2, "Governor");
        guardian = _deployAccount(0xB, "Guardian");
        treasury = _deployAccount(0x3, "Treasury");
        manager = _deployAccount(0x4, "Manager");
        secondaryManager = _deployAccount(0x5, "SecondaryManager");
        attestor = _deployAccount(0x6, "Attestor");
        attestor2 = _deployAccount(0x7, "Attestor2");
        feeRecipient = _deployAccount(0x8, "FeeRecipient");
        user = _deployAccount(0x9, "User");
        user2 = _deployAccount(0xA, "User2");

        asset = new MockERC20("Asset", "ASSET", 18);

        superGovernor =
            new SuperGovernor(sGovernor, governor, governor, governor, governor, guardian, treasury, false);

        // Deploy implementation contracts (escrow impl is REUSED from the main family)
        address vaultImpl = address(new ManagedSuperVault(address(superGovernor)));
        address strategyImpl = address(new ManagedSuperVaultStrategy(address(superGovernor)));
        address escrowImpl = address(new SuperVaultEscrow());
        address queueImpl = address(new ManagedSuperVaultDepositQueue());

        // Aggregator first (inert until the oracle is wired), then oracle, then one-time wiring
        aggregator =
            new ManagedSuperVaultAggregator(address(superGovernor), vaultImpl, strategyImpl, escrowImpl, queueImpl);
        navOracle = new ManagedNAVOracle(address(aggregator));
        vm.prank(sGovernor);
        aggregator.setInitialNavOracle(address(navOracle));

        // Register the managed aggregator in the SuperGovernor address registry (discovery-only:
        // managed clones store their aggregator at initialize)
        vm.prank(sGovernor);
        superGovernor.setAddress(MANAGED_AGGREGATOR_KEY, address(aggregator));

        // Create a default managed vault
        (address vault_, address strategy_, address escrow_, address queue_) = _createManagedVault(_defaultParams());
        vault = ManagedSuperVault(vault_);
        strategy = ManagedSuperVaultStrategy(payable(strategy_));
        escrow = SuperVaultEscrow(escrow_);
        queue = ManagedSuperVaultDepositQueue(queue_);

        // Add secondary manager
        vm.prank(manager);
        aggregator.addSecondaryManager(strategy_, secondaryManager);

        // Fund users
        asset.mint(user, 1_000_000e18);
        asset.mint(user2, 1_000_000e18);
    }

    /*//////////////////////////////////////////////////////////////
                            HELPERS
    //////////////////////////////////////////////////////////////*/

    function _defaultParams() internal view returns (IManagedSuperVaultAggregator.VaultCreationParams memory params) {
        address[] memory attestors = new address[](2);
        attestors[0] = attestor;
        attestors[1] = attestor2;

        params = IManagedSuperVaultAggregator.VaultCreationParams({
            asset: address(asset),
            name: "Managed Vault",
            symbol: "MV",
            mainManager: manager,
            secondaryManagers: new address[](0),
            minUpdateInterval: MIN_UPDATE_INTERVAL,
            maxStaleness: MAX_STALENESS,
            feeConfig: ISuperVaultStrategy.FeeConfig({
                performanceFeeBps: 1000, managementFeeBps: 0, recipient: feeRecipient
            }),
            depositPolicy: IManagedSuperVaultDepositQueue.DepositPolicy({
                approvalMode: IManagedSuperVaultDepositQueue.DepositApprovalMode.Open,
                depositsPaused: false,
                minDepositAssets: 0,
                maxDepositAssets: 0
            }),
            navConfig: IManagedNAVOracle.NavAttestationConfig({ attestors: attestors, threshold: 1 }),
            metadataURI: "ipfs://managed-vault-metadata"
        });
    }

    function _createManagedVault(IManagedSuperVaultAggregator.VaultCreationParams memory params)
        internal
        returns (address vault_, address strategy_, address escrow_, address queue_)
    {
        vm.prank(manager);
        return aggregator.createVault(params);
    }

    /// @notice Propose and attest a NAV update so it finalizes at `newPPS`
    /// @dev The attestation lifecycle lives on the NAV oracle, keyed by strategy; the aggregator's
    ///      _forwardPPS rails accept/reject the push
    function _pushNAV(uint256 newPPS) internal returns (uint256 proposalId) {
        // Respect the min update interval
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);

        vm.prank(manager);
        proposalId =
            navOracle.proposeNAVUpdate(address(strategy), newPPS, block.timestamp, EVIDENCE_HASH, "ipfs://evidence");

        vm.prank(attestor);
        navOracle.attestNAVUpdate(address(strategy), proposalId);
    }

    /// @notice Full async deposit round trip: queue request -> manager fulfill -> claim native shares
    function _requestFulfillClaim(address depositor, uint256 assets) internal returns (uint256 shares) {
        vm.startPrank(depositor);
        asset.approve(address(queue), assets);
        queue.requestDeposit(assets, depositor, depositor);
        vm.stopPrank();

        address[] memory depositors = new address[](1);
        depositors[0] = depositor;
        vm.prank(manager);
        queue.fulfillDepositRequests(depositors);

        uint256 claimable = queue.claimableDepositRequest(0, depositor);
        vm.prank(depositor);
        shares = queue.deposit(claimable, depositor, depositor);
    }

    /// @notice Full async redeem round trip through the NATIVE SuperVault redeem path:
    ///         request -> manager fulfill on the strategy -> claim assets from the vault
    function _redeemRoundTrip(address redeemer, uint256 shares) internal returns (uint256 assetsOut) {
        vm.prank(redeemer);
        vault.requestRedeem(shares, redeemer, redeemer);

        // Theoretical assets at the current stored PPS
        uint256 pps = strategy.getStoredPPS();
        uint256 theoreticalAssets = shares * pps / vault.PRECISION();

        address[] memory controllers = new address[](1);
        controllers[0] = redeemer;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = theoreticalAssets;

        vm.prank(manager);
        strategy.fulfillRedeemRequests(controllers, amounts);

        assetsOut = vault.maxWithdraw(redeemer);
        vm.prank(redeemer);
        vault.withdraw(assetsOut, redeemer, redeemer);
    }
}
