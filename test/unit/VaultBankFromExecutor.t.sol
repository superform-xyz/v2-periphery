// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

// external
import { ExecutionLib } from "modulekit/accounts/erc7579/lib/ExecutionLib.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

// Superform
import { ISuperExecutor } from "@superform-v2-core/src/interfaces/ISuperExecutor.sol";
import { ISuperLedger } from "@superform-v2-core/src/interfaces/accounting/ISuperLedger.sol";
import { ISuperValidator } from "@superform-v2-core/src/interfaces/ISuperValidator.sol";
import { SuperExecutor } from "@superform-v2-core/src/executors/SuperExecutor.sol";
import { SuperValidatorBase } from "@superform-v2-core/src/validators/SuperValidatorBase.sol";

import { MODULE_TYPE_EXECUTOR, MODULE_TYPE_VALIDATOR } from "modulekit/accounts/kernel/types/Constants.sol";
import { PeripheryHelpers } from "../utils/PeripheryHelpers.sol";
import { InternalHelpers } from "@superform-v2-core/test/utils/InternalHelpers.sol";
import { MerkleTreeHelper } from "@superform-v2-core/test/utils/MerkleTreeHelper.sol";
import { SignatureHelper } from "@superform-v2-core/test/utils/SignatureHelper.sol";

import { RhinestoneModuleKit, ModuleKitHelpers, AccountInstance, UserOpData } from "modulekit/ModuleKit.sol";
import { ERC4626YieldSourceOracle } from "@superform-v2-core/src/accounting/oracles/ERC4626YieldSourceOracle.sol";
import { SuperLedgerConfiguration } from "@superform-v2-core/src/accounting/SuperLedgerConfiguration.sol";
import { ISuperLedgerConfiguration } from "@superform-v2-core/src/interfaces/accounting/ISuperLedgerConfiguration.sol";
import { ApproveERC20Hook } from "@superform-v2-core/src/hooks/tokens/erc20/ApproveERC20Hook.sol";
import { Deposit4626VaultHook } from "@superform-v2-core/src/hooks/vaults/4626/Deposit4626VaultHook.sol";
import { MintSuperPositionsHook } from "@superform-v2-core/src/hooks/vaults/vault-bank/MintSuperPositionsHook.sol";
import { SuperLedger } from "@superform-v2-core/src/accounting/SuperLedger.sol";
import { SuperValidator } from "@superform-v2-core/src/validators/SuperValidator.sol";
import { VaultBank } from "../../src/VaultBank/VaultBank.sol";
import { SuperGovernor } from "../../src/SuperGovernor.sol";

contract VaultBankFromExecutor is
    PeripheryHelpers,
    RhinestoneModuleKit,
    InternalHelpers,
    SignatureHelper,
    MerkleTreeHelper
{
    using ModuleKitHelpers for *;
    using ExecutionLib for *;

    IERC4626 public vaultInstance;
    address public anotherYieldSourceAddress;
    address public yieldSourceAddress;
    address public yieldSourceOracle;
    address public underlying;
    ISuperExecutor public superExecutor;
    address ledgerConfig;
    ISuperLedger public ledger;
    SuperGovernor public superGovernor;
    VaultBank public vaultBank;

    address approveHook;
    address deposit4626Hook;
    address mintSuperPositionsHook;
    SuperValidator public validator;

    address public signer;
    uint256 public signerPrvKey;

    address feeRecipient;

    function setUp() public {
        vm.createSelectFork(vm.envString(ETHEREUM_RPC_URL_KEY), ETH_BLOCK);
        underlying = CHAIN_1_USDC;
        ledgerConfig = address(new SuperLedgerConfiguration());

        yieldSourceAddress = CHAIN_1_MORPHO_VAULT;
        anotherYieldSourceAddress = CHAIN_1_YEARN_VAULT;
        yieldSourceOracle = address(new ERC4626YieldSourceOracle(address(ledgerConfig)));
        vaultInstance = IERC4626(yieldSourceAddress);

        validator = new SuperValidator();
        vm.label(address(validator), "Validator source");

        (signer, signerPrvKey) = makeAddrAndKey("signer");

        superExecutor = ISuperExecutor(new SuperExecutor(address(ledgerConfig)));

        address[] memory allowedExecutors = new address[](1);
        allowedExecutors[0] = address(superExecutor);
        ledger = ISuperLedger(address(new SuperLedger(address(ledgerConfig), allowedExecutors)));

        feeRecipient = makeAddr("feeRecipient");
        ISuperLedgerConfiguration.YieldSourceOracleConfigArgs[] memory configs =
            new ISuperLedgerConfiguration.YieldSourceOracleConfigArgs[](1);
        configs[0] = ISuperLedgerConfiguration.YieldSourceOracleConfigArgs({
            yieldSourceOracle: yieldSourceOracle,
            feePercent: 100,
            feeRecipient: feeRecipient,
            ledger: address(ledger)
        });
        bytes32[] memory salts = new bytes32[](1);
        salts[0] = bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY));
        ISuperLedgerConfiguration(ledgerConfig).setYieldSourceOracles(salts, configs);

        approveHook = address(new ApproveERC20Hook());
        deposit4626Hook = address(new Deposit4626VaultHook());
        mintSuperPositionsHook = address(new MintSuperPositionsHook());

        superGovernor = new SuperGovernor(address(this), address(this), address(this), address(this), address(this), address(this));
        superGovernor.addExecutor(address(superExecutor));
        vaultBank = new VaultBank(address(superGovernor));
        superGovernor.addVaultBank(uint64(block.chainid), address(vaultBank));
        superGovernor.registerHook(address(approveHook), false);
        superGovernor.registerHook(address(deposit4626Hook), false);
        superGovernor.registerHook(address(mintSuperPositionsHook), false);
    }

    function test_ShouldExecuteAll_AndLockAssetsInVaultBank_Test2HookChaining(uint256 amount) external {
        AccountInstance memory testInstance = makeAccountInstance(keccak256(abi.encode("TEST")));
        address testAccount = testInstance.account;

        testInstance.installModule({ moduleTypeId: MODULE_TYPE_EXECUTOR, module: address(superExecutor), data: "" });
        testInstance.installModule({
            moduleTypeId: MODULE_TYPE_VALIDATOR,
            module: address(validator),
            data: abi.encode(signer)
        });

        amount = _bound(amount);

        superGovernor.addVaultBank(8453, address(vaultBank));

        _getTokens(underlying, testAccount, amount);
        _getTokens(CHAIN_1_DAI, testAccount, amount);

        address[] memory hooksAddresses = new address[](5);
        hooksAddresses[0] = address(approveHook);
        hooksAddresses[1] = address(deposit4626Hook);
        hooksAddresses[2] = address(mintSuperPositionsHook);
        hooksAddresses[3] = address(approveHook);
        hooksAddresses[4] = address(deposit4626Hook);

        bytes[] memory hooksData = new bytes[](5);
        hooksData[0] = _createApproveHookData(underlying, yieldSourceAddress, amount, false);
        hooksData[1] = _createDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            yieldSourceAddress,
            amount,
            false,
            address(vaultBank),
            8453
        );

        uint256 sharesPreviewed = vaultInstance.previewDeposit(amount);
        hooksData[2] = _createApproveAndLockVaultBankHookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            yieldSourceAddress,
            sharesPreviewed,
            false,
            address(vaultBank),
            8453
        );
        hooksData[3] = _createApproveHookData(CHAIN_1_DAI, anotherYieldSourceAddress, amount, false);
        hooksData[4] = _createDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            anotherYieldSourceAddress,
            amount,
            false,
            address(vaultBank),
            8453
        );

        ISuperExecutor.ExecutorEntry memory entry =
            ISuperExecutor.ExecutorEntry({ hooksAddresses: hooksAddresses, hooksData: hooksData });
        UserOpData memory userOpData =
            _getExecOpsWithValidator(testInstance, superExecutor, abi.encode(entry), address(validator));

        uint48 validUntil = uint48(block.timestamp + 100 days);
        bytes memory sigData = _createSourceData(validUntil, userOpData);
        userOpData.userOp.signature = sigData;
        executeOp(userOpData);

        uint256 accSharesAfter = vaultInstance.balanceOf(address(vaultBank));
        assertEq(accSharesAfter, sharesPreviewed);
    }

    function test_ShouldExecuteAll_AndLockAssetsInVaultBank_Test1ExistingShares(uint256 amount) external {
        AccountInstance memory testInstance = makeAccountInstance(keccak256(abi.encode("TEST")));
        address testAccount = testInstance.account;

        testInstance.installModule({ moduleTypeId: MODULE_TYPE_EXECUTOR, module: address(superExecutor), data: "" });
        testInstance.installModule({
            moduleTypeId: MODULE_TYPE_VALIDATOR,
            module: address(validator),
            data: abi.encode(signer)
        });

        amount = _bound(amount);

        superGovernor.addVaultBank(8453, address(vaultBank));

        address[] memory hooksAddresses = new address[](1);
        hooksAddresses[0] = address(mintSuperPositionsHook);

        bytes[] memory hooksData = new bytes[](1);
        _getTokens(yieldSourceAddress, testAccount, amount);
        hooksData[0] = _createApproveAndLockVaultBankHookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            yieldSourceAddress,
            amount,
            false,
            address(vaultBank),
            8453
        );

        ISuperExecutor.ExecutorEntry memory entry =
            ISuperExecutor.ExecutorEntry({ hooksAddresses: hooksAddresses, hooksData: hooksData });
        UserOpData memory userOpData =
            _getExecOpsWithValidator(testInstance, superExecutor, abi.encode(entry), address(validator));

        uint48 validUntil = uint48(block.timestamp + 100 days);
        bytes memory sigData = _createSourceData(validUntil, userOpData);
        userOpData.userOp.signature = sigData;
        executeOp(userOpData);

        uint256 accSharesAfter = vaultInstance.balanceOf(address(vaultBank));
        assertEq(accSharesAfter, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/
    function _createSourceData(
        uint48 validUntil,
        UserOpData memory userOpData
    )
        private
        view
        returns (bytes memory signatureData)
    {
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] =
            _createSourceValidatorLeaf(userOpData.userOpHash, validUntil, 0, new uint64[](0), address(validator));

        (bytes32[][] memory merkleProof, bytes32 merkleRoot) = _createValidatorMerkleTree(leaves);

        bytes memory signature =
            _createSignature(SuperValidatorBase(address(validator)).namespace(), merkleRoot, signer, signerPrvKey);

        uint64[] memory chainsWithDestExecutionNone = new uint64[](0);
        ISuperValidator.DstProof[] memory proofDst = new ISuperValidator.DstProof[](0);
        signatureData =
            abi.encode(chainsWithDestExecutionNone, validUntil, 0, merkleRoot, merkleProof[0], proofDst, signature);
    }
}
