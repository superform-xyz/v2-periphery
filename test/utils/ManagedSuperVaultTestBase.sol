// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { SuperGovernor } from "../../src/SuperGovernor.sol";
import { ManagedSuperVault } from "../../src/ManagedSuperVault/ManagedSuperVault.sol";
import { ManagedSuperVaultController } from "../../src/ManagedSuperVault/ManagedSuperVaultController.sol";
import { ManagedSuperVaultEscrow } from "../../src/ManagedSuperVault/ManagedSuperVaultEscrow.sol";
import { ManagedSuperVaultAggregator } from "../../src/ManagedSuperVault/ManagedSuperVaultAggregator.sol";
import { IManagedSuperVaultAggregator } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";
import { IManagedSuperVaultController } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultController.sol";
import { PeripheryHelpers } from "./PeripheryHelpers.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";

/// @notice Shared test harness for the ManagedSuperVault family
abstract contract ManagedSuperVaultTestBase is PeripheryHelpers {
    SuperGovernor internal superGovernor;
    ManagedSuperVaultAggregator internal aggregator;

    ManagedSuperVault internal vault;
    ManagedSuperVaultController internal controller;
    ManagedSuperVaultEscrow internal escrow;

    MockERC20 internal asset;

    // Accounts
    address internal sGovernor;
    address internal governor;
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

    bytes32 internal constant MANAGED_AGGREGATOR_KEY = keccak256("MANAGED_SUPER_VAULT_AGGREGATOR");
    bytes32 internal constant EVIDENCE_HASH = keccak256("nav-evidence");

    function setUp() public virtual {
        // Start at a realistic timestamp (the post-unpause skim timelock measures from 0 otherwise)
        vm.warp(30 days);

        sGovernor = _deployAccount(0x1, "SuperGovernor");
        governor = _deployAccount(0x2, "Governor");
        treasury = _deployAccount(0x3, "Treasury");
        manager = _deployAccount(0x4, "Manager");
        secondaryManager = _deployAccount(0x5, "SecondaryManager");
        attestor = _deployAccount(0x6, "Attestor");
        attestor2 = _deployAccount(0x7, "Attestor2");
        feeRecipient = _deployAccount(0x8, "FeeRecipient");
        user = _deployAccount(0x9, "User");
        user2 = _deployAccount(0xA, "User2");

        asset = new MockERC20("Asset", "ASSET", 18);

        superGovernor = new SuperGovernor(sGovernor, governor, governor, governor, governor, governor, treasury, false);

        // Deploy implementation contracts
        address vaultImpl = address(new ManagedSuperVault(address(superGovernor)));
        address controllerImpl = address(new ManagedSuperVaultController(address(superGovernor)));
        address escrowImpl = address(new ManagedSuperVaultEscrow());

        aggregator = new ManagedSuperVaultAggregator(address(superGovernor), vaultImpl, controllerImpl, escrowImpl);

        // Register the managed aggregator in the SuperGovernor address registry
        vm.prank(sGovernor);
        superGovernor.setAddress(MANAGED_AGGREGATOR_KEY, address(aggregator));

        // Create a default managed vault
        (address vault_, address controller_, address escrow_) = _createManagedVault(_defaultParams());
        vault = ManagedSuperVault(vault_);
        controller = ManagedSuperVaultController(payable(controller_));
        escrow = ManagedSuperVaultEscrow(escrow_);

        // Add secondary manager
        vm.prank(manager);
        aggregator.addSecondaryManager(controller_, secondaryManager);

        // Fund users
        asset.mint(user, 1_000_000e18);
        asset.mint(user2, 1_000_000e18);
    }

    /*//////////////////////////////////////////////////////////////
                            HELPERS
    //////////////////////////////////////////////////////////////*/

    function _defaultParams()
        internal
        view
        returns (IManagedSuperVaultAggregator.ManagedVaultCreationParams memory params)
    {
        address[] memory attestors = new address[](2);
        attestors[0] = attestor;
        attestors[1] = attestor2;

        params = IManagedSuperVaultAggregator.ManagedVaultCreationParams({
            asset: address(asset),
            name: "Managed Vault",
            symbol: "MV",
            mainManager: manager,
            secondaryManagers: new address[](0),
            minUpdateInterval: MIN_UPDATE_INTERVAL,
            maxStaleness: MAX_STALENESS,
            maxUpdateDeviationBps: 0, // default 50%
            depositPolicy: IManagedSuperVaultController.DepositPolicy({
                approvalMode: IManagedSuperVaultController.DepositApprovalMode.Open,
                depositsPaused: false,
                minDepositAssets: 0,
                maxDepositAssets: 0
            }),
            navConfig: IManagedSuperVaultController.NavAttestationConfig({ attestors: attestors, threshold: 1 }),
            feeConfig: IManagedSuperVaultController.FeeConfig({
                performanceFeeBps: 1000, managementFeeBps: 0, recipient: feeRecipient
            }),
            metadataURI: "ipfs://managed-vault-metadata"
        });
    }

    function _createManagedVault(IManagedSuperVaultAggregator.ManagedVaultCreationParams memory params)
        internal
        returns (address vault_, address controller_, address escrow_)
    {
        vm.prank(manager);
        return aggregator.createManagedVault(params);
    }

    /// @notice Propose and attest a NAV update so it finalizes at `newPPS`
    /// @dev The NAV lifecycle lives on the aggregator, keyed by controller
    function _updateNAV(uint256 newPPS) internal {
        // Respect the min update interval
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);

        vm.prank(manager);
        uint256 proposalId =
            aggregator.proposeNAVUpdate(address(controller), newPPS, block.timestamp, EVIDENCE_HASH, "ipfs://evidence");

        vm.prank(attestor);
        aggregator.attestNAVUpdate(address(controller), proposalId);
    }

    /// @notice Full async deposit round trip: request -> manager fulfill -> claim
    function _depositRoundTrip(address depositor, uint256 assets) internal returns (uint256 shares) {
        vm.startPrank(depositor);
        asset.approve(address(vault), assets);
        vault.requestDeposit(assets, depositor, depositor);
        vm.stopPrank();

        address[] memory depositors = new address[](1);
        depositors[0] = depositor;
        vm.prank(manager);
        controller.fulfillDepositRequests(depositors);

        uint256 claimable = controller.claimableDepositRequest(depositor);
        vm.prank(depositor);
        shares = vault.deposit(claimable, depositor, depositor);
    }

    /// @notice Full async redeem round trip: request -> manager fulfill -> claim assets
    function _redeemRoundTrip(address redeemer, uint256 shares) internal returns (uint256 assetsOut) {
        vm.prank(redeemer);
        vault.requestRedeem(shares, redeemer, redeemer);

        (, uint256 theoreticalAssets,) = controller.previewExactRedeem(redeemer);

        address[] memory controllers = new address[](1);
        controllers[0] = redeemer;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = theoreticalAssets;

        vm.prank(manager);
        controller.fulfillRedeemRequests(controllers, amounts);

        assetsOut = vault.maxWithdraw(redeemer);
        vm.prank(redeemer);
        vault.withdraw(assetsOut, redeemer, redeemer);
    }
}
