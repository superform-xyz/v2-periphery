// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// External dependencies
import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";
import {ActorManager} from "@recon/ActorManager.sol";
import {AssetManager} from "@recon/AssetManager.sol";
import {Utils} from "@recon/Utils.sol";
// ERC4626 Hooks
import {Deposit4626VaultHook} from "lib/v2-core/src/hooks/vaults/4626/Deposit4626VaultHook.sol";
import {ApproveAndDeposit4626VaultHook} from "lib/v2-core/src/hooks/vaults/4626/ApproveAndDeposit4626VaultHook.sol";
import {Redeem4626VaultHook} from "lib/v2-core/src/hooks/vaults/4626/Redeem4626VaultHook.sol";

// ERC5115 Hooks
import {Deposit5115VaultHook} from "lib/v2-core/src/hooks/vaults/5115/Deposit5115VaultHook.sol";
import {ApproveAndDeposit5115VaultHook} from "lib/v2-core/src/hooks/vaults/5115/ApproveAndDeposit5115VaultHook.sol";
import {Redeem5115VaultHook} from "lib/v2-core/src/hooks/vaults/5115/Redeem5115VaultHook.sol";

// ERC7540 Hooks
import {Deposit7540VaultHook} from "lib/v2-core/src/hooks/vaults/7540/Deposit7540VaultHook.sol";
import {Redeem7540VaultHook} from "lib/v2-core/src/hooks/vaults/7540/Redeem7540VaultHook.sol";
import {RequestDeposit7540VaultHook} from "lib/v2-core/src/hooks/vaults/7540/RequestDeposit7540VaultHook.sol";
import {RequestRedeem7540VaultHook} from "lib/v2-core/src/hooks/vaults/7540/RequestRedeem7540VaultHook.sol";
import {ApproveAndRequestDeposit7540VaultHook} from "lib/v2-core/src/hooks/vaults/7540/ApproveAndRequestDeposit7540VaultHook.sol";
import {CancelDepositRequest7540Hook} from "lib/v2-core/src/hooks/vaults/7540/CancelDepositRequest7540Hook.sol";
import {CancelRedeemRequest7540Hook} from "lib/v2-core/src/hooks/vaults/7540/CancelRedeemRequest7540Hook.sol";
import {ClaimCancelDepositRequest7540Hook} from "lib/v2-core/src/hooks/vaults/7540/ClaimCancelDepositRequest7540Hook.sol";
import {ClaimCancelRedeemRequest7540Hook} from "lib/v2-core/src/hooks/vaults/7540/ClaimCancelRedeemRequest7540Hook.sol";
import {Withdraw7540VaultHook} from "lib/v2-core/src/hooks/vaults/7540/Withdraw7540VaultHook.sol";

// Super Vault Hooks
import {CancelRedeemHook} from "lib/v2-core/src/hooks/vaults/super-vault/CancelRedeemHook.sol";
import {Withdraw7540VaultHook as SuperVaultWithdraw7540VaultHook} from "lib/v2-core/src/hooks/vaults/super-vault/Withdraw7540VaultHook.sol";

// Source dependencies
import "src/SuperVault/SuperVault.sol";
import "src/SuperVault/SuperVaultAggregator.sol";
import "src/SuperVault/SuperVaultEscrow.sol";
import "src/SuperVault/SuperVaultStrategy.sol";
import "src/SuperGovernor.sol";
import {ISuperVaultAggregator} from "src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import {ISuperVaultStrategy} from "src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import {MockYieldSourceOracle} from "test/mocks/MockYieldSourceOracle.sol";

// Test suite dependencies
import {YieldManager, YieldSourceType} from "test/recon/managers/YieldManager.sol";
import {MerkleTestHelper} from "test/recon/helpers/MerkleTestHelper.sol";
import {UnsafeSuperVaultAggregator} from "test/recon/helpers/UnsafeSuperVaultAggregator.sol";
import {MockERC4626YieldSourceOracle} from "test/recon/mocks/MockERC4626YieldSourceOracle.sol";
import {MockERC5115YieldSourceOracle} from "test/recon/mocks/MockERC5115YieldSourceOracle.sol";
import {MockERC7540YieldSourceOracle} from "test/recon/mocks/MockERC7540YieldSourceOracle.sol";
import {MockECDSAPPSOracle} from "test/recon/mocks/MockECDSAPPSOracle.sol";

abstract contract Setup is
    BaseSetup,
    ActorManager,
    AssetManager,
    YieldManager,
    Utils
{
    // Configuration constants
    uint8 internal constant DECIMALS = 18;
    address asset;
    address feeRecipient = address(0xbeef);

    // Core contracts
    SuperGovernor superGovernor;
    SuperVault superVault;
    UnsafeSuperVaultAggregator superVaultAggregator;
    SuperVaultEscrow superVaultEscrow;
    SuperVaultStrategy superVaultStrategy;

    // Implementation contracts for aggregator
    SuperVault vaultImpl;
    SuperVaultStrategy strategyImpl;
    SuperVaultEscrow escrowImpl;

    // Helpers
    MerkleTestHelper merkleHelper;

    // ERC4626 Hooks
    ApproveAndDeposit4626VaultHook approveAndDeposit4626Hook;
    Deposit4626VaultHook deposit4626Hook;
    Redeem4626VaultHook redeem4626Hook;

    // ERC5115 Hooks
    ApproveAndDeposit5115VaultHook approveAndDeposit5115Hook;
    Deposit5115VaultHook deposit5115Hook;
    Redeem5115VaultHook redeem5115Hook;

    // ERC7540 Hooks
    Deposit7540VaultHook deposit7540Hook;
    Redeem7540VaultHook redeem7540Hook;
    RequestDeposit7540VaultHook requestDeposit7540Hook;
    RequestRedeem7540VaultHook requestRedeem7540Hook;
    ApproveAndRequestDeposit7540VaultHook approveAndRequestDeposit7540Hook;
    CancelDepositRequest7540Hook cancelDepositRequest7540Hook;
    CancelRedeemRequest7540Hook cancelRedeemRequest7540Hook;
    ClaimCancelDepositRequest7540Hook claimCancelDepositRequest7540Hook;
    ClaimCancelRedeemRequest7540Hook claimCancelRedeemRequest7540Hook;
    Withdraw7540VaultHook withdraw7540Hook;

    // Super Vault Hooks
    CancelRedeemHook cancelRedeemHook;
    SuperVaultWithdraw7540VaultHook superVaultWithdraw7540Hook;

    // Mocks
    MockERC4626YieldSourceOracle erc4626YieldSourceOracle;
    MockERC5115YieldSourceOracle erc5115YieldSourceOracle;
    MockERC7540YieldSourceOracle erc7540YieldSourceOracle;
    MockECDSAPPSOracle ECDSAPPSOracle;

    // Yield sources for different standards
    address erc4626YieldSource;
    address erc5115YieldSource;
    address erc7540YieldSource;

    // Ghosts
    bool hasUpdatedPPS;
    int256 burnedMoreThanRequested;
    int256 burnedLessThanRequested;
    int256 previewMintSharesGreater; // setPreviewSharesGreater
    int256 previewDepositSharesGreater; // setPreviewSharesGreater
    int256 previewMintAssetsGreater; // setpreviewAssetsGreater
    int256 previewDepositAssetsGreater; // setpreviewAssetsGreater

    // Canaries
    bool executeHooksClampedSuccess;
    bool executeHooksSuccess;
    bool fulfillRedeemRequestsSuccess;
    bool hasDeployedNewVault;

    /// === MODIFIERS === ///
    /// Prank admin and actor

    modifier asAdmin() {
        vm.prank(address(this));
        _;
    }

    modifier asActor() {
        vm.prank(address(_getActor()));
        _;
    }

    /// Makes a handler have no side effects
    /// The fuzzer will call this anyway, and because it reverts it will be removed from shrinking
    /// Replace the "withGhosts" with "stateless" to make the code clean
    modifier stateless() {
        _;
        revert("stateless");
    }

    /// === Setup === ///
    /// This contains all calls to be performed in the tester constructor, both for Echidna and Foundry
    function setup() internal virtual override {
        // 1. Add additional actors
        _addActor(address(0x100)); // Actor 1
        _addActor(address(0x200)); // Actor 2

        // 2. Create assets using AssetManager
        _newAsset(DECIMALS); // Deploy token with 18 decimals
        _newAsset(DECIMALS); // UP token

        _switchAsset(0);

        // 3. Deploy all three types of yield sources using YieldManager
        // Deploy ERC4626 yield source (default)
        erc4626YieldSource = _newYieldSource(
            _getAsset(),
            YieldSourceType.ERC4626
        );

        // Deploy ERC5115 yield source
        erc5115YieldSource = _newYieldSource(
            _getAsset(),
            YieldSourceType.ERC5115
        );

        // Deploy ERC7540 yield source
        erc7540YieldSource = _newYieldSource(
            _getAsset(),
            YieldSourceType.ERC7540
        );

        // Set ERC4626 as the default active yield source
        _switchYieldSource(0); // Switch to first yield source in the array (ERC4626)

        // 4. Deploy SuperGovernor first (required by other contracts)
        superGovernor = new SuperGovernor(
            address(this), // superGovernor role
            address(this), // governor role
            address(this), // bankManager role
            address(this), // gasManager role
            feeRecipient, // treasury
            address(this) // prover
        );

        // 5. Deploy implementation contracts for the aggregator
        vaultImpl = new SuperVault(address(superGovernor));
        strategyImpl = new SuperVaultStrategy(address(superGovernor));
        escrowImpl = new SuperVaultEscrow();

        // 6. Deploy SuperVaultAggregator with implementation contracts
        superVaultAggregator = new UnsafeSuperVaultAggregator(
            address(superGovernor),
            address(vaultImpl),
            address(strategyImpl),
            address(escrowImpl)
        );

        // 7. Register the SuperVaultAggregator and UpToken address with SuperGovernor
        superGovernor.setAddress(
            superGovernor.SUPER_VAULT_AGGREGATOR(),
            address(superVaultAggregator)
        );

        address[] memory assets = _getAssets();
        superGovernor.setAddress(superGovernor.UP(), assets[1]); // the second deployed token in the AssetManager is the UPToken
        superGovernor.setAddress(superGovernor.SUPER_BANK(), address(this));

        // 8. Deploy Mocks and Oracles

        // Deploy specific oracles for each yield source type
        erc4626YieldSourceOracle = new MockERC4626YieldSourceOracle();
        erc5115YieldSourceOracle = new MockERC5115YieldSourceOracle();
        erc7540YieldSourceOracle = new MockERC7540YieldSourceOracle();
        ECDSAPPSOracle = new MockECDSAPPSOracle();

        // ECDSAPPSOracle setup
        superGovernor.setActivePPSOracle(address(ECDSAPPSOracle));
        ECDSAPPSOracle.setSUPER_GOVERNORReturn(address(superVaultAggregator));

        // Set valid assets for all oracles
        asset = _getAsset();
        erc4626YieldSourceOracle.setValidAsset(asset, true);
        erc5115YieldSourceOracle.setValidAsset(asset, true);
        erc7540YieldSourceOracle.setValidAsset(asset, true);

        // 9. Create a vault trio using the aggregator
        ISuperVaultAggregator.VaultCreationParams
            memory params = ISuperVaultAggregator.VaultCreationParams({
                asset: _getAsset(), // Use the token created by AssetManager
                name: "SuperVault",
                symbol: "SV",
                mainManager: address(this), // CONFIGURABLE: This parameter can be modified via target functions
                secondaryManagers: new address[](0), // CONFIGURABLE: This parameter can be modified via target functions
                minUpdateInterval: 5, // CONFIGURABLE: This parameter can be modified via target functions
                maxStaleness: 300, // CONFIGURABLE: This parameter can be modified via target functions
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000, // 10% performance fee
                    managementFeeBps: 100, // 1% management fee
                    recipient: feeRecipient
                })
            });

        (
            address vaultAddr,
            address strategyAddr,
            address escrowAddr
        ) = superVaultAggregator.createVault(params);

        // 10. Store the deployed contracts
        superVault = SuperVault(vaultAddr);
        superVaultStrategy = SuperVaultStrategy(payable(strategyAddr));
        superVaultEscrow = SuperVaultEscrow(escrowAddr);

        /// 11. Deploy all hook contracts and helper
        merkleHelper = new MerkleTestHelper();

        // Deploy ERC4626 Hooks
        approveAndDeposit4626Hook = new ApproveAndDeposit4626VaultHook();
        deposit4626Hook = new Deposit4626VaultHook();
        redeem4626Hook = new Redeem4626VaultHook();

        // Deploy ERC5115 Hooks
        approveAndDeposit5115Hook = new ApproveAndDeposit5115VaultHook();
        deposit5115Hook = new Deposit5115VaultHook();
        redeem5115Hook = new Redeem5115VaultHook();

        // Deploy ERC7540 Hooks
        deposit7540Hook = new Deposit7540VaultHook();
        redeem7540Hook = new Redeem7540VaultHook();
        requestDeposit7540Hook = new RequestDeposit7540VaultHook();
        requestRedeem7540Hook = new RequestRedeem7540VaultHook();
        approveAndRequestDeposit7540Hook = new ApproveAndRequestDeposit7540VaultHook();
        cancelDepositRequest7540Hook = new CancelDepositRequest7540Hook();
        cancelRedeemRequest7540Hook = new CancelRedeemRequest7540Hook();
        claimCancelDepositRequest7540Hook = new ClaimCancelDepositRequest7540Hook();
        claimCancelRedeemRequest7540Hook = new ClaimCancelRedeemRequest7540Hook();
        withdraw7540Hook = new Withdraw7540VaultHook();

        // Deploy Super Vault Hooks
        cancelRedeemHook = new CancelRedeemHook();
        superVaultWithdraw7540Hook = new SuperVaultWithdraw7540VaultHook();

        // Register all hooks with SuperGovernor
        // ERC4626 Hooks (deposit hooks are regular hooks, redeem hooks are fulfill request hooks)
        superGovernor.registerHook(address(approveAndDeposit4626Hook), false);
        superGovernor.registerHook(address(deposit4626Hook), false);
        superGovernor.registerHook(address(redeem4626Hook), true); // fulfill request hook

        // ERC5115 Hooks
        superGovernor.registerHook(address(approveAndDeposit5115Hook), false);
        superGovernor.registerHook(address(deposit5115Hook), false);
        superGovernor.registerHook(address(redeem5115Hook), true); // fulfill request hook

        // ERC7540 Hooks (deposit/request hooks are regular hooks, redeem/withdraw hooks are fulfill request hooks)
        superGovernor.registerHook(address(deposit7540Hook), false);
        superGovernor.registerHook(address(redeem7540Hook), true); // fulfill request hook
        superGovernor.registerHook(address(requestDeposit7540Hook), false);
        superGovernor.registerHook(address(requestRedeem7540Hook), false);
        superGovernor.registerHook(
            address(approveAndRequestDeposit7540Hook),
            false
        );
        superGovernor.registerHook(
            address(cancelDepositRequest7540Hook),
            false
        );
        superGovernor.registerHook(address(cancelRedeemRequest7540Hook), false);
        superGovernor.registerHook(
            address(claimCancelDepositRequest7540Hook),
            false
        );
        superGovernor.registerHook(
            address(claimCancelRedeemRequest7540Hook),
            false
        );
        superGovernor.registerHook(address(withdraw7540Hook), true); // fulfill request hook

        // Super Vault Hooks
        superGovernor.registerHook(address(cancelRedeemHook), false);
        superGovernor.registerHook(address(superVaultWithdraw7540Hook), true); // fulfill request hook

        // 12. Set up approval array for contracts that need token access
        address[] memory approvalArray = new address[](6);
        approvalArray[0] = address(superVault);
        approvalArray[1] = address(superVaultStrategy);
        approvalArray[2] = address(superVaultAggregator);
        approvalArray[3] = erc4626YieldSource;
        approvalArray[4] = erc5115YieldSource;
        approvalArray[5] = erc7540YieldSource;

        // 13. Finalize asset deployment (mints to actors and sets approvals)
        _finalizeAssetDeployment(_getActors(), approvalArray, type(uint88).max);
    }

    /// Get hook addresses for different yield source types

    function _getApproveAndDepositHookForType(
        YieldSourceType sourceType
    ) internal view returns (address) {
        if (sourceType == YieldSourceType.ERC4626) {
            return address(approveAndDeposit4626Hook);
        } else if (sourceType == YieldSourceType.ERC5115) {
            return address(approveAndDeposit5115Hook);
        } else if (sourceType == YieldSourceType.ERC7540) {
            return address(approveAndRequestDeposit7540Hook);
        }
        return address(0);
    }

    function _getRedeemHookForType(
        YieldSourceType sourceType
    ) internal view returns (address) {
        if (sourceType == YieldSourceType.ERC4626) {
            return address(redeem4626Hook);
        } else if (sourceType == YieldSourceType.ERC5115) {
            return address(redeem5115Hook);
        } else if (sourceType == YieldSourceType.ERC7540) {
            return address(redeem7540Hook);
        }
        return address(0);
    }

    /// Get oracle addresses for different yield source types

    function _getYieldSourceOracleForType(
        YieldSourceType sourceType
    ) internal view returns (address) {
        if (sourceType == YieldSourceType.ERC4626) {
            return address(erc4626YieldSourceOracle);
        } else if (sourceType == YieldSourceType.ERC5115) {
            return address(erc5115YieldSourceOracle);
        } else if (sourceType == YieldSourceType.ERC7540) {
            return address(erc7540YieldSourceOracle);
        }
    }

    /// @dev Helper function to determine yield source type from address
    function _getYieldSourceTypeFromAddress(
        address yieldSource
    ) internal view returns (YieldSourceType) {
        // Get all available yield sources from YieldManager
        address[] memory yieldSources = _getYieldSources();

        // Check which index matches the current yield source
        for (uint256 i = 0; i < yieldSources.length; i++) {
            if (yieldSources[i] == yieldSource) {
                // Return the corresponding type based on creation order:
                // Index 0: ERC4626, Index 1: ERC5115, Index 2: ERC7540
                if (i == 0) return YieldSourceType.ERC4626;
                if (i == 1) return YieldSourceType.ERC5115;
                if (i == 2) return YieldSourceType.ERC7540;
            }
        }

        // Default to ERC4626 if not found
        return YieldSourceType.ERC4626;
    }

    function _getERC4626YieldSourceOracle() internal view returns (address) {
        return address(erc4626YieldSourceOracle);
    }

    function _getERC5115YieldSourceOracle() internal view returns (address) {
        return address(erc5115YieldSourceOracle);
    }

    function _getERC7540YieldSourceOracle() internal view returns (address) {
        return address(erc7540YieldSourceOracle);
    }

    // Helpers
    function _getRandomActor(uint256 entropy) public view returns (address) {
        address[] memory actors = _getActors();

        return actors[entropy % actors.length];
    }
}
