// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// External dependencies
import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";
import {ActorManager} from "@recon/ActorManager.sol";
import {AssetManager} from "@recon/AssetManager.sol";
import {Utils} from "@recon/Utils.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {Test} from "forge-std/Test.sol";
import {MockERC20} from "@recon/MockERC20.sol";

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
import {MockSuperGovernor} from "test/recon/mocks/MockSuperGovernor.sol";
import {MockSuperVault} from "test/recon/mocks/MockSuperVault.sol";
import {MockSuperVaultStrategy} from "test/recon/mocks/MockSuperVaultStrategy.sol";
import {MockSuperVaultEscrow} from "test/recon/mocks/MockSuperVaultEscrow.sol";

contract HalmosTester is ActorManager, AssetManager, SymTest, Test {
    // Configuration constants
    uint8 internal constant DECIMALS = 18;
    address asset;

    // Core contracts
    MockSuperGovernor superGovernor;
    SuperVault superVault;
    UnsafeSuperVaultAggregator superVaultAggregator;
    SuperVaultEscrow superVaultEscrow;
    SuperVaultStrategy superVaultStrategy;

    // Implementation contracts for aggregator
    MockSuperVault vaultImpl;
    MockSuperVaultStrategy strategyImpl;
    MockSuperVaultEscrow escrowImpl;

    /// === Setup === ///
    /// This contains all calls to be performed in the tester constructor, both for Echidna and Foundry
    function setUp() public virtual {
        // 1. Add additional actors
        _addActor(address(0x100)); // Actor 1
        _addActor(address(0x200)); // Actor 2

        // 2. Create assets using AssetManager
        _newAsset(DECIMALS); // Deploy token with 18 decimals

        // 3. Deploy SuperGovernor first (required by other contracts
        superGovernor = new MockSuperGovernor();

        // 4. Deploy implementation contracts for the aggregator
        vaultImpl = new MockSuperVault();
        strategyImpl = new MockSuperVaultStrategy();
        escrowImpl = new MockSuperVaultEscrow();

        // 5. Deploy SuperVaultAggregator with implementation contracts
        // NOTE: can't be mocked because it deploys the SuperVaultStrategy
        superVaultAggregator = new UnsafeSuperVaultAggregator(
            address(superGovernor),
            address(vaultImpl),
            address(strategyImpl),
            address(escrowImpl)
        );

        // 6. Create a vault trio using the aggregator
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
                    recipient: address(this)
                })
            });

        (
            address vaultAddr,
            address strategyAddr,
            address escrowAddr
        ) = superVaultAggregator.createVault(params);

        // 7. Store the deployed contracts
        superVault = SuperVault(vaultAddr);
        superVaultStrategy = SuperVaultStrategy(payable(strategyAddr));
        superVaultEscrow = SuperVaultEscrow(escrowAddr);

        svm.enableSymbolicStorage(address(this));
        svm.enableSymbolicStorage(address(_getAsset()));
        svm.enableSymbolicStorage(address(superGovernor));
        svm.enableSymbolicStorage(address(superVaultAggregator));
        svm.enableSymbolicStorage(address(superVault));
        svm.enableSymbolicStorage(address(superVaultStrategy));
        svm.enableSymbolicStorage(address(superVaultEscrow));
    }

    function _callSuperVaultStrategy(uint256 arrayLength) internal {
        // we only care about fulfilling redemption requests and determining if it's ever possible to reach a state where user fulfillments can make the strategy insolvent

        address[] memory controllers = new address[](arrayLength);
        address[] memory hooks = new address[](arrayLength);
        bytes[] memory hookCalldata = new bytes[](arrayLength);
        uint256[] memory expectedAssetsOrSharesOut = new uint256[](arrayLength);
        bytes32[][] memory globalProofs = new bytes32[][](arrayLength);
        bytes32[][] memory strategyProofs = new bytes32[][](arrayLength);

        for (uint256 i; i < arrayLength; i++) {
            controllers[i] = svm.createAddress("controller");
            hooks[i] = svm.createAddress("hook");

            // Create fixed-size bytes to avoid symbolic size issues
            bytes memory data = new bytes(32);
            bytes32 dataContent = svm.createBytes32("hookData");
            assembly {
                mstore(add(data, 0x20), dataContent)
            }
            hookCalldata[i] = data;

            expectedAssetsOrSharesOut[i] = svm.createUint256("expectedOut");

            // Initialize inner arrays for proofs
            globalProofs[i] = new bytes32[](1);
            strategyProofs[i] = new bytes32[](1);

            // Populate the proof arrays
            globalProofs[i][0] = svm.createBytes32("globalProof");
            strategyProofs[i][0] = svm.createBytes32("strategyProof");
        }

        ISuperVaultStrategy.FulfillArgs memory fulfillArgs = ISuperVaultStrategy
            .FulfillArgs({
                controllers: controllers,
                hooks: hooks,
                hookCalldata: hookCalldata,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: globalProofs,
                strategyProofs: strategyProofs
            });

        bytes memory args = abi.encode(fulfillArgs);

        (bool success, ) = address(superVaultStrategy).call(
            abi.encodePacked(
                superVaultStrategy.fulfillRedeemRequests.selector,
                args
            )
        );
        vm.assume(success);
    }

    function check_strategySolvency(uint256 arrayLength) public {
        vm.assume(arrayLength > 0);
        vm.assume(arrayLength <= 10); // Cap array length up to 10

        // make the call to fulfillRedeemRequests
        _callSuperVaultStrategy(arrayLength);

        address[] memory actors = _getActors();
        uint256 summedMaxWithdraw;
        for (uint256 i; i < actors.length; i++) {
            summedMaxWithdraw += superVault.maxWithdraw(actors[i]);
        }
        uint256 strategyAssetBalance = MockERC20(superVault.asset()).balanceOf(
            address(superVaultStrategy)
        );
        assert(strategyAssetBalance >= summedMaxWithdraw);
    }
}
