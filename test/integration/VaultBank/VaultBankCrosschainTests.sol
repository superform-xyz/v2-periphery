// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Tests
import { BaseTest } from "../../BaseTest.t.sol";

// Superform
import { ISuperExecutor } from "@superform-v2-core/src/interfaces/ISuperExecutor.sol";
import { IYieldSourceOracle } from "@superform-v2-core/src/interfaces/accounting/IYieldSourceOracle.sol";
import { AcrossV3Adapter } from "@superform-v2-core/src/adapters/AcrossV3Adapter.sol";
import { ISuperDestinationExecutor } from "@superform-v2-core/src/interfaces/ISuperDestinationExecutor.sol";
import { VaultBank } from "../../../src/VaultBank/VaultBank.sol";
import { SuperGovernor } from "../../../src/SuperGovernor.sol";

// External
import { UserOpData, AccountInstance, ModuleKitHelpers } from "modulekit/ModuleKit.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { IValidator } from "modulekit/accounts/common/interfaces/IERC7579Module.sol";
import { ExecutionLib } from "modulekit/accounts/erc7579/lib/ExecutionLib.sol";

contract VaultBankCrosschainTests is BaseTest {
    using ModuleKitHelpers for *;
    using ExecutionLib for *;

    address public underlyingETH_USDC;
    address public underlyingBase_USDC;

    address public accountBase;
    address public accountETH;

    AccountInstance public instanceOnBase;
    AccountInstance public instanceOnETH;

    ISuperExecutor public superExecutorOnETH;

    AcrossV3Adapter public acrossV3AdapterOnBase;

    ISuperDestinationExecutor public superTargetExecutorOnBase;

    IValidator public validatorOnBase;
    IValidator public sourceValidatorOnETH;

    VaultBank public vaultBank;
    SuperGovernor public superGovernor;

    IERC4626 public vaultInstanceMorphoEth;
    IERC4626 public vaultInstanceMorphoBase;

    address public yieldSourceMorphoUsdcAddressEth;
    address public yieldSourceMorphoUsdcAddressBase;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[ETH]);

        // Set up the underlying tokens
        underlyingBase_USDC = existingUnderlyingTokens[BASE][USDC_KEY];
        underlyingETH_USDC = existingUnderlyingTokens[ETH][USDC_KEY];

        // Set up the accounts
        accountBase = accountInstances[BASE].account;
        accountETH = accountInstances[ETH].account;

        instanceOnBase = accountInstances[BASE];
        instanceOnETH = accountInstances[ETH];

        // Set up the super executors
        superExecutorOnETH = ISuperExecutor(_getContract(ETH, SUPER_EXECUTOR_KEY));

        // Set up the super target executors
        superTargetExecutorOnBase = ISuperDestinationExecutor(_getContract(BASE, SUPER_DESTINATION_EXECUTOR_KEY));

        acrossV3AdapterOnBase = AcrossV3Adapter(_getContract(BASE, ACROSS_V3_ADAPTER_KEY));

        // Set up the validators
        validatorOnBase = IValidator(_getContract(BASE, SUPER_DESTINATION_VALIDATOR_KEY));
        sourceValidatorOnETH = IValidator(_getContract(ETH, SUPER_MERKLE_VALIDATOR_KEY));

        yieldSourceMorphoUsdcAddressEth = realVaultAddresses[ETH][ERC4626_VAULT_KEY][MORPHO_VAULT_KEY][USDC_KEY];
        vaultInstanceMorphoEth = IERC4626(yieldSourceMorphoUsdcAddressEth);
        vm.label(yieldSourceMorphoUsdcAddressEth, "YIELD_SOURCE_MORPHO_USDC_ETH");

        yieldSourceMorphoUsdcAddressBase =
            realVaultAddresses[BASE][ERC4626_VAULT_KEY][MORPHO_GAUNTLET_USDC_PRIME_KEY][USDC_KEY];
        vaultInstanceMorphoBase = IERC4626(yieldSourceMorphoUsdcAddressBase);
        vm.label(yieldSourceMorphoUsdcAddressBase, "YIELD_SOURCE_MORPHO_USDC_BASE");
    }

    function test_Bridge_Deposit4626_MintSP() public {
        // Use a fixed timestamp that's guaranteed to be after market lastUpdate times
        uint256 safeTimestamp = 1_740_570_000; // ~2.5 hours after the problematic lastUpdate timestamp
        SELECT_FORK_AND_WARP(ETH, safeTimestamp);

        uint256 amount = 1e3; // Reduced to 0.001 USDC to avoid overflow with very low liquidity BASE vault (~4 USDC
            // total)
        uint256 previewRedeemAmount =
            vaultInstanceMorphoEth.previewRedeem(vaultInstanceMorphoEth.previewDeposit(amount));

        uint256 previewLockAmount;
        // BASE IS DST
        SELECT_FORK_AND_WARP(BASE, safeTimestamp);

        superGovernor = new SuperGovernor(address(this), address(this), address(this), address(this), address(this), address(this));
        vaultBank = new VaultBank(address(superGovernor));
        superGovernor.addVaultBank(ETH, address(vaultBank));
        superGovernor.registerHook(_getHookAddress(BASE, MINT_SUPERPOSITIONS_HOOK_KEY), false);

        bytes memory targetExecutorMessage;
        TargetExecutorMessage memory messageData;
        address accountToUse;
        {
            // PREPARE DST DATA
            address[] memory dstHooksAddresses = new address[](3);
            dstHooksAddresses[0] = _getHookAddress(BASE, APPROVE_ERC20_HOOK_KEY);
            dstHooksAddresses[1] = _getHookAddress(BASE, DEPOSIT_4626_VAULT_HOOK_KEY);
            dstHooksAddresses[2] = _getHookAddress(BASE, MINT_SUPERPOSITIONS_HOOK_KEY);

            bytes[] memory dstHooksData = new bytes[](3);
            dstHooksData[0] = _createApproveHookData(
                underlyingBase_USDC, yieldSourceMorphoUsdcAddressBase, previewRedeemAmount, false
            );
            dstHooksData[1] = _createDeposit4626HookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
                yieldSourceMorphoUsdcAddressBase,
                previewRedeemAmount,
                false,
                address(0),
                0
            );
            previewLockAmount = vaultInstanceMorphoBase.previewDeposit(previewRedeemAmount);
            dstHooksData[2] = _createApproveAndLockVaultBankHookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
                yieldSourceMorphoUsdcAddressBase,
                previewLockAmount,
                false,
                address(vaultBank),
                ETH
            );

            messageData = TargetExecutorMessage({
                hooksAddresses: dstHooksAddresses,
                hooksData: dstHooksData,
                validator: address(validatorOnBase),
                signer: validatorSigners[BASE],
                signerPrivateKey: validatorSignerPrivateKeys[BASE],
                targetAdapter: address(acrossV3AdapterOnBase),
                targetExecutor: address(superTargetExecutorOnBase),
                nexusFactory: CHAIN_8453_NEXUS_FACTORY,
                nexusBootstrap: CHAIN_8453_NEXUS_BOOTSTRAP,
                chainId: uint64(BASE),
                amount: amount,
                account: accountBase,
                tokenSent: underlyingBase_USDC
            });

            (targetExecutorMessage, accountToUse) = _createTargetExecutorMessage(messageData, false);
        }

        // ETH is SRC
        SELECT_FORK_AND_WARP(ETH, safeTimestamp);

        address[] memory srcHooksAddresses = new address[](4);
        srcHooksAddresses[0] = _getHookAddress(ETH, APPROVE_ERC20_HOOK_KEY);
        srcHooksAddresses[1] = _getHookAddress(ETH, DEPOSIT_4626_VAULT_HOOK_KEY);
        srcHooksAddresses[2] = _getHookAddress(ETH, APPROVE_ERC20_HOOK_KEY);
        srcHooksAddresses[3] = _getHookAddress(ETH, ACROSS_SEND_FUNDS_AND_EXECUTE_ON_DST_HOOK_KEY);

        bytes[] memory srcHooksData = new bytes[](4);
        srcHooksData[0] = _createApproveHookData(underlyingETH_USDC, yieldSourceMorphoUsdcAddressEth, amount, false);
        srcHooksData[1] = _createDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            yieldSourceMorphoUsdcAddressEth,
            amount,
            false,
            address(0),
            0
        );
        srcHooksData[2] = _createApproveHookData(underlyingETH_USDC, SPOKE_POOL_V3_ADDRESSES[ETH], 0, true);

        srcHooksData[3] = _createAcrossV3ReceiveFundsAndExecuteHookData(
            existingUnderlyingTokens[ETH][USDC_KEY],
            existingUnderlyingTokens[BASE][USDC_KEY],
            previewRedeemAmount,
            previewRedeemAmount,
            BASE,
            true,
            targetExecutorMessage
        );

        ISuperExecutor.ExecutorEntry memory entry =
            ISuperExecutor.ExecutorEntry({ hooksAddresses: srcHooksAddresses, hooksData: srcHooksData });

        UserOpData memory srcUserOpData = _getExecOpsWithValidator(
            instanceOnETH, superExecutorOnETH, abi.encode(entry), address(sourceValidatorOnETH)
        );
        bytes memory signatureData = _createMerkleRootAndSignature(
            messageData, srcUserOpData.userOpHash, accountToUse, BASE, address(sourceValidatorOnETH)
        );
        srcUserOpData.userOp.signature = signatureData;

        _processAcrossV3Message(
            ProcessAcrossV3MessageParams({
                srcChainId: ETH,
                dstChainId: BASE,
                warpTimestamp: safeTimestamp,
                executionData: executeOp(srcUserOpData),
                relayerType: RELAYER_TYPE.ENOUGH_BALANCE,
                errorMessage: bytes4(0),
                errorReason: "",
                root: bytes32(0),
                account: accountBase,
                relayerGas: 0
            })
        );

        SELECT_FORK_AND_WARP(BASE, safeTimestamp + 10 days);
        uint256 accSharesAfter = IERC4626(yieldSourceMorphoUsdcAddressBase).balanceOf(address(vaultBank));
        assertEq(accSharesAfter, previewLockAmount);
    }

    function test_Bridge_MintSP() public {
        // Use a fixed timestamp that's guaranteed to be after market lastUpdate times
        uint256 safeTimestamp = 1_740_570_000; // ~2.5 hours after the problematic lastUpdate timestamp
        SELECT_FORK_AND_WARP(ETH, safeTimestamp);

        uint256 amount = 1e3; // Reduced to 0.001 USDC to avoid overflow with very low liquidity BASE vault (~4 USDC
            // total)
        uint256 previewRedeemAmount =
            vaultInstanceMorphoEth.previewRedeem(vaultInstanceMorphoEth.previewDeposit(amount));

        // BASE IS DST
        SELECT_FORK_AND_WARP(BASE, safeTimestamp);

        superGovernor = new SuperGovernor(address(this), address(this), address(this), address(this), address(this), address(this));
        vaultBank = new VaultBank(address(superGovernor));
        superGovernor.addVaultBank(ETH, address(vaultBank));
        superGovernor.registerHook(_getHookAddress(BASE, MINT_SUPERPOSITIONS_HOOK_KEY), false);

        bytes memory targetExecutorMessage;
        TargetExecutorMessage memory messageData;
        address accountToUse;
        {
            // PREPARE DST DATA
            address[] memory dstHooksAddresses = new address[](1);
            dstHooksAddresses[0] = _getHookAddress(BASE, MINT_SUPERPOSITIONS_HOOK_KEY);

            bytes[] memory dstHooksData = new bytes[](1);
            dstHooksData[0] = _createApproveAndLockVaultBankHookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
                CHAIN_8453_USDC,
                previewRedeemAmount,
                false,
                address(vaultBank),
                ETH
            );

            messageData = TargetExecutorMessage({
                hooksAddresses: dstHooksAddresses,
                hooksData: dstHooksData,
                validator: address(validatorOnBase),
                signer: validatorSigners[BASE],
                signerPrivateKey: validatorSignerPrivateKeys[BASE],
                targetAdapter: address(acrossV3AdapterOnBase),
                targetExecutor: address(superTargetExecutorOnBase),
                nexusFactory: CHAIN_8453_NEXUS_FACTORY,
                nexusBootstrap: CHAIN_8453_NEXUS_BOOTSTRAP,
                chainId: uint64(BASE),
                amount: amount,
                account: accountBase,
                tokenSent: underlyingBase_USDC
            });

            (targetExecutorMessage, accountToUse) = _createTargetExecutorMessage(messageData, false);
        }

        _getTokens(CHAIN_8453_USDC, accountToUse, amount);

        // ETH is SRC
        SELECT_FORK_AND_WARP(ETH, safeTimestamp);

        address[] memory srcHooksAddresses = new address[](4);
        srcHooksAddresses[0] = _getHookAddress(ETH, APPROVE_ERC20_HOOK_KEY);
        srcHooksAddresses[1] = _getHookAddress(ETH, DEPOSIT_4626_VAULT_HOOK_KEY);
        srcHooksAddresses[2] = _getHookAddress(ETH, APPROVE_ERC20_HOOK_KEY);
        srcHooksAddresses[3] = _getHookAddress(ETH, ACROSS_SEND_FUNDS_AND_EXECUTE_ON_DST_HOOK_KEY);

        bytes[] memory srcHooksData = new bytes[](4);
        srcHooksData[0] = _createApproveHookData(underlyingETH_USDC, yieldSourceMorphoUsdcAddressEth, amount, false);
        srcHooksData[1] = _createDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            yieldSourceMorphoUsdcAddressEth,
            amount,
            false,
            address(0),
            0
        );
        srcHooksData[2] = _createApproveHookData(underlyingETH_USDC, SPOKE_POOL_V3_ADDRESSES[ETH], 0, true);

        srcHooksData[3] = _createAcrossV3ReceiveFundsAndExecuteHookData(
            existingUnderlyingTokens[ETH][USDC_KEY],
            existingUnderlyingTokens[BASE][USDC_KEY],
            previewRedeemAmount,
            previewRedeemAmount,
            BASE,
            true,
            targetExecutorMessage
        );

        ISuperExecutor.ExecutorEntry memory entry =
            ISuperExecutor.ExecutorEntry({ hooksAddresses: srcHooksAddresses, hooksData: srcHooksData });

        UserOpData memory srcUserOpData = _getExecOpsWithValidator(
            instanceOnETH, superExecutorOnETH, abi.encode(entry), address(sourceValidatorOnETH)
        );
        bytes memory signatureData = _createMerkleRootAndSignature(
            messageData, srcUserOpData.userOpHash, accountToUse, BASE, address(sourceValidatorOnETH)
        );
        srcUserOpData.userOp.signature = signatureData;

        _processAcrossV3Message(
            ProcessAcrossV3MessageParams({
                srcChainId: ETH,
                dstChainId: BASE,
                warpTimestamp: safeTimestamp,
                executionData: executeOp(srcUserOpData),
                relayerType: RELAYER_TYPE.ENOUGH_BALANCE,
                errorMessage: bytes4(0),
                errorReason: "",
                root: bytes32(0),
                account: accountBase,
                relayerGas: 0
            })
        );

        SELECT_FORK_AND_WARP(BASE, safeTimestamp + 10 days);
        uint256 accSharesAfter = IERC4626(CHAIN_8453_USDC).balanceOf(address(vaultBank));
        assertEq(accSharesAfter, previewRedeemAmount);
    }
}
