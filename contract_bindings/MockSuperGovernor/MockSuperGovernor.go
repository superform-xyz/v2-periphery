// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package MockSuperGovernor

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// MockSuperGovernorISuperGovernorGasInfo is an auto generated low-level Go binding around an user-defined struct.
type MockSuperGovernorISuperGovernorGasInfo struct {
	BaseGasBatch             *big.Int
	GasIncreasePerEntryBatch *big.Int
}

// MockSuperGovernorMetaData contains all meta data concerning the MockSuperGovernor contract.
var MockSuperGovernorMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"BANK_MANAGER\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"BANK_MANAGER_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ECDSAPPSORACLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"GAS_MANAGER_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"GOVERNOR_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"GUARDIAN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUP\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_ASSET_FACTORY\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_BANK\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_GOVERNOR_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_ORACLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_VAULT_AGGREGATOR\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"TREASURY\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"UP\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"VAULT_BANK\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addExecutor\",\"inputs\":[{\"name\":\"executor\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addICCToWhitelist\",\"inputs\":[{\"name\":\"icc\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addRelayer\",\"inputs\":[{\"name\":\"relayer\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addSuperformManager\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addValidator\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addVaultBank\",\"inputs\":[{\"name\":\"chainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"vaultBank\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"batchSetOracleUptimeFeed\",\"inputs\":[{\"name\":\"dataOracles_\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"uptimeOracles_\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"gracePeriods_\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"changeHooksRootUpdateTimelock\",\"inputs\":[{\"name\":\"newTimelock\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"changePrimaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newManager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeActivePPSOracleChange\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeAddIncentiveTokens\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeFeeUpdate\",\"inputs\":[{\"name\":\"feeType\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeMinStalenessChange\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeRemoveIncentiveTokens\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeSuperBankHookMerkleRootUpdate\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeUpkeepClaim\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeUpkeepPaymentsChange\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeVaultBankHookMerkleRootUpdate\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"freezeManagerTakeover\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getActivePPSOracle\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAddress\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAllSuperformManagers\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getExecutors\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getFee\",\"inputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getGasInfo\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structMockSuperGovernor.ISuperGovernor_GasInfo\",\"components\":[{\"name\":\"baseGasBatch\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"gasIncreasePerEntryBatch\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getManagersPaginated\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMinStaleness\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getPPSOracleQuorum\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedActivePPSOracle\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedMinStaleness\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedSuperBankHookMerkleRoot\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedUpkeepPaymentsStatus\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedVaultBankHookMerkleRoot\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProtectedKeepers\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProtectedKeepersCount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProver\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRegisteredFulfillRequestsHooks\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRegisteredHooks\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRelayers\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSuperBankHookMerkleRoot\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSuperformManagersCount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getUpkeepCostPerBatchUpdate\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidators\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getVaultBank\",\"inputs\":[{\"name\":\"\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getVaultBankHookMerkleRoot\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isActivePPSOracle\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isExecutor\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isFulfillRequestsHookRegistered\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isGuardian\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isHookRegistered\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isManagerTakeoverFrozen\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isProtectedKeeper\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isRelayer\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isSuperformManager\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isUpkeepPaymentsEnabled\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isValidator\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isWhitelistedIncentiveToken\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proposeActivePPSOracle\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeAddIncentiveTokens\",\"inputs\":[{\"name\":\"tokens\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeFee\",\"inputs\":[{\"name\":\"feeType\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeGlobalHooksRoot\",\"inputs\":[{\"name\":\"newRoot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeMinStaleness\",\"inputs\":[{\"name\":\"newMinStaleness\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeRemoveIncentiveTokens\",\"inputs\":[{\"name\":\"tokens\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeSuperBankHookMerkleRoot\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"proposedRoot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeUpkeepPaymentsChange\",\"inputs\":[{\"name\":\"enabled\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeVaultBankHookMerkleRoot\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"proposedRoot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"queueOracleProviderRemoval\",\"inputs\":[{\"name\":\"providers\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"queueOracleUpdate\",\"inputs\":[{\"name\":\"bases_\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"quotes_\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"providers_\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"},{\"name\":\"feeds_\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"registerHook\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"isFulfillRequestsHook\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"registerProtectedKeeper\",\"inputs\":[{\"name\":\"keeper\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeExecutor\",\"inputs\":[{\"name\":\"executor\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeICCFromWhitelist\",\"inputs\":[{\"name\":\"icc\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeRelayer\",\"inputs\":[{\"name\":\"relayer\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeSuperformManager\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeValidator\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"callerConfirmation\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setActivePPSOracle\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setAddress\",\"inputs\":[{\"name\":\"key\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"value\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setBANK_MANAGERReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setBANK_MANAGER_ROLEReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setDEFAULT_ADMIN_ROLEReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setECDSAPPSORACLEReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGAS_MANAGER_ROLEReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGOVERNOR_ROLEReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGUARDIAN_ROLEReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGasInfo\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"baseGasBatch\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"gasIncreasePerEntryBatch\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetActivePPSOracleReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetAddressReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetAllSuperformManagersReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetExecutorsReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetFeeReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetGasInfoReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"tuple\",\"internalType\":\"structMockSuperGovernor.ISuperGovernor_GasInfo\",\"components\":[{\"name\":\"baseGasBatch\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"gasIncreasePerEntryBatch\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetManagersPaginatedReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"_value1\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetMinStalenessReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetPPSOracleQuorumReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetProposedActivePPSOracleReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_value1\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetProposedMinStalenessReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_value1\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetProposedSuperBankHookMerkleRootReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"_value1\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetProposedUpkeepPaymentsStatusReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"_value1\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetProposedVaultBankHookMerkleRootReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"_value1\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetProtectedKeepersCountReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetProtectedKeepersReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetProverReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetRegisteredFulfillRequestsHooksReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetRegisteredHooksReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetRelayersReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetRoleAdminReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetSuperBankHookMerkleRootReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetSuperformManagersCountReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetUpkeepCostPerBatchUpdateReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetValidatorsReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetVaultBankHookMerkleRootReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGetVaultBankReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGlobalHooksRootVetoStatus\",\"inputs\":[{\"name\":\"vetoed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setHasRoleReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setIsActivePPSOracleReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setIsExecutorReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setIsFulfillRequestsHookRegisteredReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setIsGuardianReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setIsHookRegisteredReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setIsManagerTakeoverFrozenReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setIsProtectedKeeperReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setIsRelayerReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setIsSuperformManagerReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setIsUpkeepPaymentsEnabledReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setIsValidatorReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setIsWhitelistedIncentiveTokenReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setOracleFeedMaxStaleness\",\"inputs\":[{\"name\":\"feed\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newMaxStaleness\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setOracleFeedMaxStalenessBatch\",\"inputs\":[{\"name\":\"feeds_\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"newMaxStalenessList_\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setOracleMaxStaleness\",\"inputs\":[{\"name\":\"newMaxStaleness\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setPPSOracleQuorum\",\"inputs\":[{\"name\":\"quorum\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setProver\",\"inputs\":[{\"name\":\"prover\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSUPER_ASSET_FACTORYReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSUPER_BANKReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSUPER_GOVERNOR_ROLEReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSUPER_ORACLEReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSUPER_VAULT_AGGREGATORReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSUPReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setStrategyHooksRootVetoStatus\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"vetoed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSuperAssetManager\",\"inputs\":[{\"name\":\"superAsset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"superAssetManager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSupportsInterfaceReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setTREASURYReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setUPReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setVAULT_BANKReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"unregisterHook\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"unregisterProtectedKeeper\",\"inputs\":[{\"name\":\"keeper\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"ActivePPSOracleChanged\",\"inputs\":[{\"name\":\"oldOracle\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"newOracle\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ActivePPSOracleProposed\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ActivePPSOracleSet\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AddressSet\",\"inputs\":[{\"name\":\"key\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"value\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ExecutorAdded\",\"inputs\":[{\"name\":\"executor\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ExecutorRemoved\",\"inputs\":[{\"name\":\"executor\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FeeProposed\",\"inputs\":[{\"name\":\"feeType\",\"type\":\"uint8\",\"indexed\":false,\"internalType\":\"uint8\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FeeUpdated\",\"inputs\":[{\"name\":\"feeType\",\"type\":\"uint8\",\"indexed\":false,\"internalType\":\"uint8\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FulfillRequestsHookRegistered\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FulfillRequestsHookUnregistered\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"GasInfoSet\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"baseGasBatch\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"gasIncreasePerEntryBatch\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"HookApproved\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"HookRemoved\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ManagerTakeoversFrozen\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MinStalenesChanged\",\"inputs\":[{\"name\":\"newMinStaleness\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MinStalenesProposed\",\"inputs\":[{\"name\":\"newMinStaleness\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSOracleQuorumUpdated\",\"inputs\":[{\"name\":\"quorum\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ProtectedKeeperRegistered\",\"inputs\":[{\"name\":\"keeper\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ProtectedKeeperUnregistered\",\"inputs\":[{\"name\":\"keeper\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ProverSet\",\"inputs\":[{\"name\":\"prover\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RelayerAdded\",\"inputs\":[{\"name\":\"relayer\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RelayerRemoved\",\"inputs\":[{\"name\":\"relayer\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RevenueShareUpdated\",\"inputs\":[{\"name\":\"share\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SuperBankHookMerkleRootProposed\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"newRoot\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SuperBankHookMerkleRootUpdated\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"newRoot\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SuperformManagerAdded\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SuperformManagerRemoved\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepPaymentsChangeProposed\",\"inputs\":[{\"name\":\"enabled\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepPaymentsChanged\",\"inputs\":[{\"name\":\"enabled\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorAdded\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorRemoved\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"VaultBankAddressAdded\",\"inputs\":[{\"name\":\"chainId\",\"type\":\"uint64\",\"indexed\":false,\"internalType\":\"uint64\"},{\"name\":\"vaultBank\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"VaultBankHookMerkleRootProposed\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"newRoot\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"VaultBankHookMerkleRootUpdated\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"newRoot\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WhitelistedIncentiveTokensAdded\",\"inputs\":[{\"name\":\"tokens\",\"type\":\"address[]\",\"indexed\":false,\"internalType\":\"address[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WhitelistedIncentiveTokensProposed\",\"inputs\":[{\"name\":\"tokens\",\"type\":\"address[]\",\"indexed\":false,\"internalType\":\"address[]\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WhitelistedIncentiveTokensRemoved\",\"inputs\":[{\"name\":\"tokens\",\"type\":\"address[]\",\"indexed\":false,\"internalType\":\"address[]\"}],\"anonymous\":false}]",
}

// MockSuperGovernorABI is the input ABI used to generate the binding from.
// Deprecated: Use MockSuperGovernorMetaData.ABI instead.
var MockSuperGovernorABI = MockSuperGovernorMetaData.ABI

// MockSuperGovernor is an auto generated Go binding around an Ethereum contract.
type MockSuperGovernor struct {
	MockSuperGovernorCaller     // Read-only binding to the contract
	MockSuperGovernorTransactor // Write-only binding to the contract
	MockSuperGovernorFilterer   // Log filterer for contract events
}

// MockSuperGovernorCaller is an auto generated read-only Go binding around an Ethereum contract.
type MockSuperGovernorCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockSuperGovernorTransactor is an auto generated write-only Go binding around an Ethereum contract.
type MockSuperGovernorTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockSuperGovernorFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type MockSuperGovernorFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockSuperGovernorSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type MockSuperGovernorSession struct {
	Contract     *MockSuperGovernor // Generic contract binding to set the session for
	CallOpts     bind.CallOpts      // Call options to use throughout this session
	TransactOpts bind.TransactOpts  // Transaction auth options to use throughout this session
}

// MockSuperGovernorCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type MockSuperGovernorCallerSession struct {
	Contract *MockSuperGovernorCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts            // Call options to use throughout this session
}

// MockSuperGovernorTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type MockSuperGovernorTransactorSession struct {
	Contract     *MockSuperGovernorTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts            // Transaction auth options to use throughout this session
}

// MockSuperGovernorRaw is an auto generated low-level Go binding around an Ethereum contract.
type MockSuperGovernorRaw struct {
	Contract *MockSuperGovernor // Generic contract binding to access the raw methods on
}

// MockSuperGovernorCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type MockSuperGovernorCallerRaw struct {
	Contract *MockSuperGovernorCaller // Generic read-only contract binding to access the raw methods on
}

// MockSuperGovernorTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type MockSuperGovernorTransactorRaw struct {
	Contract *MockSuperGovernorTransactor // Generic write-only contract binding to access the raw methods on
}

// NewMockSuperGovernor creates a new instance of MockSuperGovernor, bound to a specific deployed contract.
func NewMockSuperGovernor(address common.Address, backend bind.ContractBackend) (*MockSuperGovernor, error) {
	contract, err := bindMockSuperGovernor(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernor{MockSuperGovernorCaller: MockSuperGovernorCaller{contract: contract}, MockSuperGovernorTransactor: MockSuperGovernorTransactor{contract: contract}, MockSuperGovernorFilterer: MockSuperGovernorFilterer{contract: contract}}, nil
}

// NewMockSuperGovernorCaller creates a new read-only instance of MockSuperGovernor, bound to a specific deployed contract.
func NewMockSuperGovernorCaller(address common.Address, caller bind.ContractCaller) (*MockSuperGovernorCaller, error) {
	contract, err := bindMockSuperGovernor(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorCaller{contract: contract}, nil
}

// NewMockSuperGovernorTransactor creates a new write-only instance of MockSuperGovernor, bound to a specific deployed contract.
func NewMockSuperGovernorTransactor(address common.Address, transactor bind.ContractTransactor) (*MockSuperGovernorTransactor, error) {
	contract, err := bindMockSuperGovernor(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorTransactor{contract: contract}, nil
}

// NewMockSuperGovernorFilterer creates a new log filterer instance of MockSuperGovernor, bound to a specific deployed contract.
func NewMockSuperGovernorFilterer(address common.Address, filterer bind.ContractFilterer) (*MockSuperGovernorFilterer, error) {
	contract, err := bindMockSuperGovernor(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorFilterer{contract: contract}, nil
}

// bindMockSuperGovernor binds a generic wrapper to an already deployed contract.
func bindMockSuperGovernor(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := MockSuperGovernorMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MockSuperGovernor *MockSuperGovernorRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MockSuperGovernor.Contract.MockSuperGovernorCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MockSuperGovernor *MockSuperGovernorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.MockSuperGovernorTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MockSuperGovernor *MockSuperGovernorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.MockSuperGovernorTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MockSuperGovernor *MockSuperGovernorCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MockSuperGovernor.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MockSuperGovernor *MockSuperGovernorTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MockSuperGovernor *MockSuperGovernorTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.contract.Transact(opts, method, params...)
}

// BANKMANAGER is a free data retrieval call binding the contract method 0x67e21123.
//
// Solidity: function BANK_MANAGER() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) BANKMANAGER(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "BANK_MANAGER")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// BANKMANAGER is a free data retrieval call binding the contract method 0x67e21123.
//
// Solidity: function BANK_MANAGER() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) BANKMANAGER() ([32]byte, error) {
	return _MockSuperGovernor.Contract.BANKMANAGER(&_MockSuperGovernor.CallOpts)
}

// BANKMANAGER is a free data retrieval call binding the contract method 0x67e21123.
//
// Solidity: function BANK_MANAGER() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) BANKMANAGER() ([32]byte, error) {
	return _MockSuperGovernor.Contract.BANKMANAGER(&_MockSuperGovernor.CallOpts)
}

// BANKMANAGERROLE is a free data retrieval call binding the contract method 0xf2157052.
//
// Solidity: function BANK_MANAGER_ROLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) BANKMANAGERROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "BANK_MANAGER_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// BANKMANAGERROLE is a free data retrieval call binding the contract method 0xf2157052.
//
// Solidity: function BANK_MANAGER_ROLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) BANKMANAGERROLE() ([32]byte, error) {
	return _MockSuperGovernor.Contract.BANKMANAGERROLE(&_MockSuperGovernor.CallOpts)
}

// BANKMANAGERROLE is a free data retrieval call binding the contract method 0xf2157052.
//
// Solidity: function BANK_MANAGER_ROLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) BANKMANAGERROLE() ([32]byte, error) {
	return _MockSuperGovernor.Contract.BANKMANAGERROLE(&_MockSuperGovernor.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) DEFAULTADMINROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "DEFAULT_ADMIN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _MockSuperGovernor.Contract.DEFAULTADMINROLE(&_MockSuperGovernor.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _MockSuperGovernor.Contract.DEFAULTADMINROLE(&_MockSuperGovernor.CallOpts)
}

// ECDSAPPSORACLE is a free data retrieval call binding the contract method 0xffdb5200.
//
// Solidity: function ECDSAPPSORACLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) ECDSAPPSORACLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "ECDSAPPSORACLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// ECDSAPPSORACLE is a free data retrieval call binding the contract method 0xffdb5200.
//
// Solidity: function ECDSAPPSORACLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) ECDSAPPSORACLE() ([32]byte, error) {
	return _MockSuperGovernor.Contract.ECDSAPPSORACLE(&_MockSuperGovernor.CallOpts)
}

// ECDSAPPSORACLE is a free data retrieval call binding the contract method 0xffdb5200.
//
// Solidity: function ECDSAPPSORACLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) ECDSAPPSORACLE() ([32]byte, error) {
	return _MockSuperGovernor.Contract.ECDSAPPSORACLE(&_MockSuperGovernor.CallOpts)
}

// GASMANAGERROLE is a free data retrieval call binding the contract method 0x42436beb.
//
// Solidity: function GAS_MANAGER_ROLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) GASMANAGERROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "GAS_MANAGER_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GASMANAGERROLE is a free data retrieval call binding the contract method 0x42436beb.
//
// Solidity: function GAS_MANAGER_ROLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) GASMANAGERROLE() ([32]byte, error) {
	return _MockSuperGovernor.Contract.GASMANAGERROLE(&_MockSuperGovernor.CallOpts)
}

// GASMANAGERROLE is a free data retrieval call binding the contract method 0x42436beb.
//
// Solidity: function GAS_MANAGER_ROLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GASMANAGERROLE() ([32]byte, error) {
	return _MockSuperGovernor.Contract.GASMANAGERROLE(&_MockSuperGovernor.CallOpts)
}

// GOVERNORROLE is a free data retrieval call binding the contract method 0xccc57490.
//
// Solidity: function GOVERNOR_ROLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) GOVERNORROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "GOVERNOR_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GOVERNORROLE is a free data retrieval call binding the contract method 0xccc57490.
//
// Solidity: function GOVERNOR_ROLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) GOVERNORROLE() ([32]byte, error) {
	return _MockSuperGovernor.Contract.GOVERNORROLE(&_MockSuperGovernor.CallOpts)
}

// GOVERNORROLE is a free data retrieval call binding the contract method 0xccc57490.
//
// Solidity: function GOVERNOR_ROLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GOVERNORROLE() ([32]byte, error) {
	return _MockSuperGovernor.Contract.GOVERNORROLE(&_MockSuperGovernor.CallOpts)
}

// GUARDIANROLE is a free data retrieval call binding the contract method 0x24ea54f4.
//
// Solidity: function GUARDIAN_ROLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) GUARDIANROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "GUARDIAN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GUARDIANROLE is a free data retrieval call binding the contract method 0x24ea54f4.
//
// Solidity: function GUARDIAN_ROLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) GUARDIANROLE() ([32]byte, error) {
	return _MockSuperGovernor.Contract.GUARDIANROLE(&_MockSuperGovernor.CallOpts)
}

// GUARDIANROLE is a free data retrieval call binding the contract method 0x24ea54f4.
//
// Solidity: function GUARDIAN_ROLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GUARDIANROLE() ([32]byte, error) {
	return _MockSuperGovernor.Contract.GUARDIANROLE(&_MockSuperGovernor.CallOpts)
}

// SUP is a free data retrieval call binding the contract method 0x95c0bf69.
//
// Solidity: function SUP() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) SUP(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "SUP")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SUP is a free data retrieval call binding the contract method 0x95c0bf69.
//
// Solidity: function SUP() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) SUP() ([32]byte, error) {
	return _MockSuperGovernor.Contract.SUP(&_MockSuperGovernor.CallOpts)
}

// SUP is a free data retrieval call binding the contract method 0x95c0bf69.
//
// Solidity: function SUP() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) SUP() ([32]byte, error) {
	return _MockSuperGovernor.Contract.SUP(&_MockSuperGovernor.CallOpts)
}

// SUPERASSETFACTORY is a free data retrieval call binding the contract method 0xec63a694.
//
// Solidity: function SUPER_ASSET_FACTORY() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) SUPERASSETFACTORY(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "SUPER_ASSET_FACTORY")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SUPERASSETFACTORY is a free data retrieval call binding the contract method 0xec63a694.
//
// Solidity: function SUPER_ASSET_FACTORY() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) SUPERASSETFACTORY() ([32]byte, error) {
	return _MockSuperGovernor.Contract.SUPERASSETFACTORY(&_MockSuperGovernor.CallOpts)
}

// SUPERASSETFACTORY is a free data retrieval call binding the contract method 0xec63a694.
//
// Solidity: function SUPER_ASSET_FACTORY() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) SUPERASSETFACTORY() ([32]byte, error) {
	return _MockSuperGovernor.Contract.SUPERASSETFACTORY(&_MockSuperGovernor.CallOpts)
}

// SUPERBANK is a free data retrieval call binding the contract method 0x6f2140c1.
//
// Solidity: function SUPER_BANK() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) SUPERBANK(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "SUPER_BANK")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SUPERBANK is a free data retrieval call binding the contract method 0x6f2140c1.
//
// Solidity: function SUPER_BANK() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) SUPERBANK() ([32]byte, error) {
	return _MockSuperGovernor.Contract.SUPERBANK(&_MockSuperGovernor.CallOpts)
}

// SUPERBANK is a free data retrieval call binding the contract method 0x6f2140c1.
//
// Solidity: function SUPER_BANK() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) SUPERBANK() ([32]byte, error) {
	return _MockSuperGovernor.Contract.SUPERBANK(&_MockSuperGovernor.CallOpts)
}

// SUPERGOVERNORROLE is a free data retrieval call binding the contract method 0xec45ad53.
//
// Solidity: function SUPER_GOVERNOR_ROLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) SUPERGOVERNORROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "SUPER_GOVERNOR_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SUPERGOVERNORROLE is a free data retrieval call binding the contract method 0xec45ad53.
//
// Solidity: function SUPER_GOVERNOR_ROLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) SUPERGOVERNORROLE() ([32]byte, error) {
	return _MockSuperGovernor.Contract.SUPERGOVERNORROLE(&_MockSuperGovernor.CallOpts)
}

// SUPERGOVERNORROLE is a free data retrieval call binding the contract method 0xec45ad53.
//
// Solidity: function SUPER_GOVERNOR_ROLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) SUPERGOVERNORROLE() ([32]byte, error) {
	return _MockSuperGovernor.Contract.SUPERGOVERNORROLE(&_MockSuperGovernor.CallOpts)
}

// SUPERORACLE is a free data retrieval call binding the contract method 0x90d4a56d.
//
// Solidity: function SUPER_ORACLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) SUPERORACLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "SUPER_ORACLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SUPERORACLE is a free data retrieval call binding the contract method 0x90d4a56d.
//
// Solidity: function SUPER_ORACLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) SUPERORACLE() ([32]byte, error) {
	return _MockSuperGovernor.Contract.SUPERORACLE(&_MockSuperGovernor.CallOpts)
}

// SUPERORACLE is a free data retrieval call binding the contract method 0x90d4a56d.
//
// Solidity: function SUPER_ORACLE() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) SUPERORACLE() ([32]byte, error) {
	return _MockSuperGovernor.Contract.SUPERORACLE(&_MockSuperGovernor.CallOpts)
}

// SUPERVAULTAGGREGATOR is a free data retrieval call binding the contract method 0xc9838819.
//
// Solidity: function SUPER_VAULT_AGGREGATOR() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) SUPERVAULTAGGREGATOR(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "SUPER_VAULT_AGGREGATOR")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SUPERVAULTAGGREGATOR is a free data retrieval call binding the contract method 0xc9838819.
//
// Solidity: function SUPER_VAULT_AGGREGATOR() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) SUPERVAULTAGGREGATOR() ([32]byte, error) {
	return _MockSuperGovernor.Contract.SUPERVAULTAGGREGATOR(&_MockSuperGovernor.CallOpts)
}

// SUPERVAULTAGGREGATOR is a free data retrieval call binding the contract method 0xc9838819.
//
// Solidity: function SUPER_VAULT_AGGREGATOR() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) SUPERVAULTAGGREGATOR() ([32]byte, error) {
	return _MockSuperGovernor.Contract.SUPERVAULTAGGREGATOR(&_MockSuperGovernor.CallOpts)
}

// TREASURY is a free data retrieval call binding the contract method 0x2d2c5565.
//
// Solidity: function TREASURY() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) TREASURY(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "TREASURY")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// TREASURY is a free data retrieval call binding the contract method 0x2d2c5565.
//
// Solidity: function TREASURY() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) TREASURY() ([32]byte, error) {
	return _MockSuperGovernor.Contract.TREASURY(&_MockSuperGovernor.CallOpts)
}

// TREASURY is a free data retrieval call binding the contract method 0x2d2c5565.
//
// Solidity: function TREASURY() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) TREASURY() ([32]byte, error) {
	return _MockSuperGovernor.Contract.TREASURY(&_MockSuperGovernor.CallOpts)
}

// UP is a free data retrieval call binding the contract method 0x24f4ec51.
//
// Solidity: function UP() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) UP(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "UP")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// UP is a free data retrieval call binding the contract method 0x24f4ec51.
//
// Solidity: function UP() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) UP() ([32]byte, error) {
	return _MockSuperGovernor.Contract.UP(&_MockSuperGovernor.CallOpts)
}

// UP is a free data retrieval call binding the contract method 0x24f4ec51.
//
// Solidity: function UP() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) UP() ([32]byte, error) {
	return _MockSuperGovernor.Contract.UP(&_MockSuperGovernor.CallOpts)
}

// VAULTBANK is a free data retrieval call binding the contract method 0x39e0739e.
//
// Solidity: function VAULT_BANK() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) VAULTBANK(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "VAULT_BANK")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// VAULTBANK is a free data retrieval call binding the contract method 0x39e0739e.
//
// Solidity: function VAULT_BANK() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) VAULTBANK() ([32]byte, error) {
	return _MockSuperGovernor.Contract.VAULTBANK(&_MockSuperGovernor.CallOpts)
}

// VAULTBANK is a free data retrieval call binding the contract method 0x39e0739e.
//
// Solidity: function VAULT_BANK() view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) VAULTBANK() ([32]byte, error) {
	return _MockSuperGovernor.Contract.VAULTBANK(&_MockSuperGovernor.CallOpts)
}

// GetActivePPSOracle is a free data retrieval call binding the contract method 0x275f0f2b.
//
// Solidity: function getActivePPSOracle() view returns(address)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetActivePPSOracle(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getActivePPSOracle")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetActivePPSOracle is a free data retrieval call binding the contract method 0x275f0f2b.
//
// Solidity: function getActivePPSOracle() view returns(address)
func (_MockSuperGovernor *MockSuperGovernorSession) GetActivePPSOracle() (common.Address, error) {
	return _MockSuperGovernor.Contract.GetActivePPSOracle(&_MockSuperGovernor.CallOpts)
}

// GetActivePPSOracle is a free data retrieval call binding the contract method 0x275f0f2b.
//
// Solidity: function getActivePPSOracle() view returns(address)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetActivePPSOracle() (common.Address, error) {
	return _MockSuperGovernor.Contract.GetActivePPSOracle(&_MockSuperGovernor.CallOpts)
}

// GetAddress is a free data retrieval call binding the contract method 0x21f8a721.
//
// Solidity: function getAddress(bytes32 ) view returns(address)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetAddress(opts *bind.CallOpts, arg0 [32]byte) (common.Address, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getAddress", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetAddress is a free data retrieval call binding the contract method 0x21f8a721.
//
// Solidity: function getAddress(bytes32 ) view returns(address)
func (_MockSuperGovernor *MockSuperGovernorSession) GetAddress(arg0 [32]byte) (common.Address, error) {
	return _MockSuperGovernor.Contract.GetAddress(&_MockSuperGovernor.CallOpts, arg0)
}

// GetAddress is a free data retrieval call binding the contract method 0x21f8a721.
//
// Solidity: function getAddress(bytes32 ) view returns(address)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetAddress(arg0 [32]byte) (common.Address, error) {
	return _MockSuperGovernor.Contract.GetAddress(&_MockSuperGovernor.CallOpts, arg0)
}

// GetAllSuperformManagers is a free data retrieval call binding the contract method 0xa1d1ab43.
//
// Solidity: function getAllSuperformManagers() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorCaller) GetAllSuperformManagers(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getAllSuperformManagers")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetAllSuperformManagers is a free data retrieval call binding the contract method 0xa1d1ab43.
//
// Solidity: function getAllSuperformManagers() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorSession) GetAllSuperformManagers() ([]common.Address, error) {
	return _MockSuperGovernor.Contract.GetAllSuperformManagers(&_MockSuperGovernor.CallOpts)
}

// GetAllSuperformManagers is a free data retrieval call binding the contract method 0xa1d1ab43.
//
// Solidity: function getAllSuperformManagers() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetAllSuperformManagers() ([]common.Address, error) {
	return _MockSuperGovernor.Contract.GetAllSuperformManagers(&_MockSuperGovernor.CallOpts)
}

// GetExecutors is a free data retrieval call binding the contract method 0xef09e78f.
//
// Solidity: function getExecutors() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorCaller) GetExecutors(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getExecutors")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetExecutors is a free data retrieval call binding the contract method 0xef09e78f.
//
// Solidity: function getExecutors() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorSession) GetExecutors() ([]common.Address, error) {
	return _MockSuperGovernor.Contract.GetExecutors(&_MockSuperGovernor.CallOpts)
}

// GetExecutors is a free data retrieval call binding the contract method 0xef09e78f.
//
// Solidity: function getExecutors() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetExecutors() ([]common.Address, error) {
	return _MockSuperGovernor.Contract.GetExecutors(&_MockSuperGovernor.CallOpts)
}

// GetFee is a free data retrieval call binding the contract method 0x083132c4.
//
// Solidity: function getFee(uint8 ) view returns(uint256)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetFee(opts *bind.CallOpts, arg0 uint8) (*big.Int, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getFee", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetFee is a free data retrieval call binding the contract method 0x083132c4.
//
// Solidity: function getFee(uint8 ) view returns(uint256)
func (_MockSuperGovernor *MockSuperGovernorSession) GetFee(arg0 uint8) (*big.Int, error) {
	return _MockSuperGovernor.Contract.GetFee(&_MockSuperGovernor.CallOpts, arg0)
}

// GetFee is a free data retrieval call binding the contract method 0x083132c4.
//
// Solidity: function getFee(uint8 ) view returns(uint256)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetFee(arg0 uint8) (*big.Int, error) {
	return _MockSuperGovernor.Contract.GetFee(&_MockSuperGovernor.CallOpts, arg0)
}

// GetGasInfo is a free data retrieval call binding the contract method 0xf5f81403.
//
// Solidity: function getGasInfo(address ) view returns((uint256,uint256))
func (_MockSuperGovernor *MockSuperGovernorCaller) GetGasInfo(opts *bind.CallOpts, arg0 common.Address) (MockSuperGovernorISuperGovernorGasInfo, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getGasInfo", arg0)

	if err != nil {
		return *new(MockSuperGovernorISuperGovernorGasInfo), err
	}

	out0 := *abi.ConvertType(out[0], new(MockSuperGovernorISuperGovernorGasInfo)).(*MockSuperGovernorISuperGovernorGasInfo)

	return out0, err

}

// GetGasInfo is a free data retrieval call binding the contract method 0xf5f81403.
//
// Solidity: function getGasInfo(address ) view returns((uint256,uint256))
func (_MockSuperGovernor *MockSuperGovernorSession) GetGasInfo(arg0 common.Address) (MockSuperGovernorISuperGovernorGasInfo, error) {
	return _MockSuperGovernor.Contract.GetGasInfo(&_MockSuperGovernor.CallOpts, arg0)
}

// GetGasInfo is a free data retrieval call binding the contract method 0xf5f81403.
//
// Solidity: function getGasInfo(address ) view returns((uint256,uint256))
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetGasInfo(arg0 common.Address) (MockSuperGovernorISuperGovernorGasInfo, error) {
	return _MockSuperGovernor.Contract.GetGasInfo(&_MockSuperGovernor.CallOpts, arg0)
}

// GetManagersPaginated is a free data retrieval call binding the contract method 0xbe5edae5.
//
// Solidity: function getManagersPaginated(uint256 , uint256 ) view returns(address[], uint256)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetManagersPaginated(opts *bind.CallOpts, arg0 *big.Int, arg1 *big.Int) ([]common.Address, *big.Int, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getManagersPaginated", arg0, arg1)

	if err != nil {
		return *new([]common.Address), *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)
	out1 := *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return out0, out1, err

}

// GetManagersPaginated is a free data retrieval call binding the contract method 0xbe5edae5.
//
// Solidity: function getManagersPaginated(uint256 , uint256 ) view returns(address[], uint256)
func (_MockSuperGovernor *MockSuperGovernorSession) GetManagersPaginated(arg0 *big.Int, arg1 *big.Int) ([]common.Address, *big.Int, error) {
	return _MockSuperGovernor.Contract.GetManagersPaginated(&_MockSuperGovernor.CallOpts, arg0, arg1)
}

// GetManagersPaginated is a free data retrieval call binding the contract method 0xbe5edae5.
//
// Solidity: function getManagersPaginated(uint256 , uint256 ) view returns(address[], uint256)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetManagersPaginated(arg0 *big.Int, arg1 *big.Int) ([]common.Address, *big.Int, error) {
	return _MockSuperGovernor.Contract.GetManagersPaginated(&_MockSuperGovernor.CallOpts, arg0, arg1)
}

// GetMinStaleness is a free data retrieval call binding the contract method 0x29f05976.
//
// Solidity: function getMinStaleness() view returns(uint256)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetMinStaleness(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getMinStaleness")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetMinStaleness is a free data retrieval call binding the contract method 0x29f05976.
//
// Solidity: function getMinStaleness() view returns(uint256)
func (_MockSuperGovernor *MockSuperGovernorSession) GetMinStaleness() (*big.Int, error) {
	return _MockSuperGovernor.Contract.GetMinStaleness(&_MockSuperGovernor.CallOpts)
}

// GetMinStaleness is a free data retrieval call binding the contract method 0x29f05976.
//
// Solidity: function getMinStaleness() view returns(uint256)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetMinStaleness() (*big.Int, error) {
	return _MockSuperGovernor.Contract.GetMinStaleness(&_MockSuperGovernor.CallOpts)
}

// GetPPSOracleQuorum is a free data retrieval call binding the contract method 0xdf6aaf96.
//
// Solidity: function getPPSOracleQuorum() view returns(uint256)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetPPSOracleQuorum(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getPPSOracleQuorum")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetPPSOracleQuorum is a free data retrieval call binding the contract method 0xdf6aaf96.
//
// Solidity: function getPPSOracleQuorum() view returns(uint256)
func (_MockSuperGovernor *MockSuperGovernorSession) GetPPSOracleQuorum() (*big.Int, error) {
	return _MockSuperGovernor.Contract.GetPPSOracleQuorum(&_MockSuperGovernor.CallOpts)
}

// GetPPSOracleQuorum is a free data retrieval call binding the contract method 0xdf6aaf96.
//
// Solidity: function getPPSOracleQuorum() view returns(uint256)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetPPSOracleQuorum() (*big.Int, error) {
	return _MockSuperGovernor.Contract.GetPPSOracleQuorum(&_MockSuperGovernor.CallOpts)
}

// GetProposedActivePPSOracle is a free data retrieval call binding the contract method 0xa86ed388.
//
// Solidity: function getProposedActivePPSOracle() view returns(address, uint256)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetProposedActivePPSOracle(opts *bind.CallOpts) (common.Address, *big.Int, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getProposedActivePPSOracle")

	if err != nil {
		return *new(common.Address), *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	out1 := *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return out0, out1, err

}

// GetProposedActivePPSOracle is a free data retrieval call binding the contract method 0xa86ed388.
//
// Solidity: function getProposedActivePPSOracle() view returns(address, uint256)
func (_MockSuperGovernor *MockSuperGovernorSession) GetProposedActivePPSOracle() (common.Address, *big.Int, error) {
	return _MockSuperGovernor.Contract.GetProposedActivePPSOracle(&_MockSuperGovernor.CallOpts)
}

// GetProposedActivePPSOracle is a free data retrieval call binding the contract method 0xa86ed388.
//
// Solidity: function getProposedActivePPSOracle() view returns(address, uint256)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetProposedActivePPSOracle() (common.Address, *big.Int, error) {
	return _MockSuperGovernor.Contract.GetProposedActivePPSOracle(&_MockSuperGovernor.CallOpts)
}

// GetProposedMinStaleness is a free data retrieval call binding the contract method 0xe8422432.
//
// Solidity: function getProposedMinStaleness() view returns(uint256, uint256)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetProposedMinStaleness(opts *bind.CallOpts) (*big.Int, *big.Int, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getProposedMinStaleness")

	if err != nil {
		return *new(*big.Int), *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	out1 := *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return out0, out1, err

}

// GetProposedMinStaleness is a free data retrieval call binding the contract method 0xe8422432.
//
// Solidity: function getProposedMinStaleness() view returns(uint256, uint256)
func (_MockSuperGovernor *MockSuperGovernorSession) GetProposedMinStaleness() (*big.Int, *big.Int, error) {
	return _MockSuperGovernor.Contract.GetProposedMinStaleness(&_MockSuperGovernor.CallOpts)
}

// GetProposedMinStaleness is a free data retrieval call binding the contract method 0xe8422432.
//
// Solidity: function getProposedMinStaleness() view returns(uint256, uint256)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetProposedMinStaleness() (*big.Int, *big.Int, error) {
	return _MockSuperGovernor.Contract.GetProposedMinStaleness(&_MockSuperGovernor.CallOpts)
}

// GetProposedSuperBankHookMerkleRoot is a free data retrieval call binding the contract method 0x43844de6.
//
// Solidity: function getProposedSuperBankHookMerkleRoot(address ) view returns(bytes32, uint256)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetProposedSuperBankHookMerkleRoot(opts *bind.CallOpts, arg0 common.Address) ([32]byte, *big.Int, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getProposedSuperBankHookMerkleRoot", arg0)

	if err != nil {
		return *new([32]byte), *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)
	out1 := *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return out0, out1, err

}

// GetProposedSuperBankHookMerkleRoot is a free data retrieval call binding the contract method 0x43844de6.
//
// Solidity: function getProposedSuperBankHookMerkleRoot(address ) view returns(bytes32, uint256)
func (_MockSuperGovernor *MockSuperGovernorSession) GetProposedSuperBankHookMerkleRoot(arg0 common.Address) ([32]byte, *big.Int, error) {
	return _MockSuperGovernor.Contract.GetProposedSuperBankHookMerkleRoot(&_MockSuperGovernor.CallOpts, arg0)
}

// GetProposedSuperBankHookMerkleRoot is a free data retrieval call binding the contract method 0x43844de6.
//
// Solidity: function getProposedSuperBankHookMerkleRoot(address ) view returns(bytes32, uint256)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetProposedSuperBankHookMerkleRoot(arg0 common.Address) ([32]byte, *big.Int, error) {
	return _MockSuperGovernor.Contract.GetProposedSuperBankHookMerkleRoot(&_MockSuperGovernor.CallOpts, arg0)
}

// GetProposedUpkeepPaymentsStatus is a free data retrieval call binding the contract method 0x57b8b13d.
//
// Solidity: function getProposedUpkeepPaymentsStatus() view returns(bool, uint256)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetProposedUpkeepPaymentsStatus(opts *bind.CallOpts) (bool, *big.Int, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getProposedUpkeepPaymentsStatus")

	if err != nil {
		return *new(bool), *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)
	out1 := *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return out0, out1, err

}

// GetProposedUpkeepPaymentsStatus is a free data retrieval call binding the contract method 0x57b8b13d.
//
// Solidity: function getProposedUpkeepPaymentsStatus() view returns(bool, uint256)
func (_MockSuperGovernor *MockSuperGovernorSession) GetProposedUpkeepPaymentsStatus() (bool, *big.Int, error) {
	return _MockSuperGovernor.Contract.GetProposedUpkeepPaymentsStatus(&_MockSuperGovernor.CallOpts)
}

// GetProposedUpkeepPaymentsStatus is a free data retrieval call binding the contract method 0x57b8b13d.
//
// Solidity: function getProposedUpkeepPaymentsStatus() view returns(bool, uint256)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetProposedUpkeepPaymentsStatus() (bool, *big.Int, error) {
	return _MockSuperGovernor.Contract.GetProposedUpkeepPaymentsStatus(&_MockSuperGovernor.CallOpts)
}

// GetProposedVaultBankHookMerkleRoot is a free data retrieval call binding the contract method 0xf7536506.
//
// Solidity: function getProposedVaultBankHookMerkleRoot(address ) view returns(bytes32, uint256)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetProposedVaultBankHookMerkleRoot(opts *bind.CallOpts, arg0 common.Address) ([32]byte, *big.Int, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getProposedVaultBankHookMerkleRoot", arg0)

	if err != nil {
		return *new([32]byte), *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)
	out1 := *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return out0, out1, err

}

// GetProposedVaultBankHookMerkleRoot is a free data retrieval call binding the contract method 0xf7536506.
//
// Solidity: function getProposedVaultBankHookMerkleRoot(address ) view returns(bytes32, uint256)
func (_MockSuperGovernor *MockSuperGovernorSession) GetProposedVaultBankHookMerkleRoot(arg0 common.Address) ([32]byte, *big.Int, error) {
	return _MockSuperGovernor.Contract.GetProposedVaultBankHookMerkleRoot(&_MockSuperGovernor.CallOpts, arg0)
}

// GetProposedVaultBankHookMerkleRoot is a free data retrieval call binding the contract method 0xf7536506.
//
// Solidity: function getProposedVaultBankHookMerkleRoot(address ) view returns(bytes32, uint256)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetProposedVaultBankHookMerkleRoot(arg0 common.Address) ([32]byte, *big.Int, error) {
	return _MockSuperGovernor.Contract.GetProposedVaultBankHookMerkleRoot(&_MockSuperGovernor.CallOpts, arg0)
}

// GetProtectedKeepers is a free data retrieval call binding the contract method 0x84570ebf.
//
// Solidity: function getProtectedKeepers() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorCaller) GetProtectedKeepers(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getProtectedKeepers")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetProtectedKeepers is a free data retrieval call binding the contract method 0x84570ebf.
//
// Solidity: function getProtectedKeepers() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorSession) GetProtectedKeepers() ([]common.Address, error) {
	return _MockSuperGovernor.Contract.GetProtectedKeepers(&_MockSuperGovernor.CallOpts)
}

// GetProtectedKeepers is a free data retrieval call binding the contract method 0x84570ebf.
//
// Solidity: function getProtectedKeepers() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetProtectedKeepers() ([]common.Address, error) {
	return _MockSuperGovernor.Contract.GetProtectedKeepers(&_MockSuperGovernor.CallOpts)
}

// GetProtectedKeepersCount is a free data retrieval call binding the contract method 0xb1c0374d.
//
// Solidity: function getProtectedKeepersCount() view returns(uint256)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetProtectedKeepersCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getProtectedKeepersCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetProtectedKeepersCount is a free data retrieval call binding the contract method 0xb1c0374d.
//
// Solidity: function getProtectedKeepersCount() view returns(uint256)
func (_MockSuperGovernor *MockSuperGovernorSession) GetProtectedKeepersCount() (*big.Int, error) {
	return _MockSuperGovernor.Contract.GetProtectedKeepersCount(&_MockSuperGovernor.CallOpts)
}

// GetProtectedKeepersCount is a free data retrieval call binding the contract method 0xb1c0374d.
//
// Solidity: function getProtectedKeepersCount() view returns(uint256)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetProtectedKeepersCount() (*big.Int, error) {
	return _MockSuperGovernor.Contract.GetProtectedKeepersCount(&_MockSuperGovernor.CallOpts)
}

// GetProver is a free data retrieval call binding the contract method 0xf9a83be7.
//
// Solidity: function getProver() view returns(address)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetProver(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getProver")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetProver is a free data retrieval call binding the contract method 0xf9a83be7.
//
// Solidity: function getProver() view returns(address)
func (_MockSuperGovernor *MockSuperGovernorSession) GetProver() (common.Address, error) {
	return _MockSuperGovernor.Contract.GetProver(&_MockSuperGovernor.CallOpts)
}

// GetProver is a free data retrieval call binding the contract method 0xf9a83be7.
//
// Solidity: function getProver() view returns(address)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetProver() (common.Address, error) {
	return _MockSuperGovernor.Contract.GetProver(&_MockSuperGovernor.CallOpts)
}

// GetRegisteredFulfillRequestsHooks is a free data retrieval call binding the contract method 0x046c7418.
//
// Solidity: function getRegisteredFulfillRequestsHooks() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorCaller) GetRegisteredFulfillRequestsHooks(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getRegisteredFulfillRequestsHooks")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetRegisteredFulfillRequestsHooks is a free data retrieval call binding the contract method 0x046c7418.
//
// Solidity: function getRegisteredFulfillRequestsHooks() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorSession) GetRegisteredFulfillRequestsHooks() ([]common.Address, error) {
	return _MockSuperGovernor.Contract.GetRegisteredFulfillRequestsHooks(&_MockSuperGovernor.CallOpts)
}

// GetRegisteredFulfillRequestsHooks is a free data retrieval call binding the contract method 0x046c7418.
//
// Solidity: function getRegisteredFulfillRequestsHooks() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetRegisteredFulfillRequestsHooks() ([]common.Address, error) {
	return _MockSuperGovernor.Contract.GetRegisteredFulfillRequestsHooks(&_MockSuperGovernor.CallOpts)
}

// GetRegisteredHooks is a free data retrieval call binding the contract method 0x841b0175.
//
// Solidity: function getRegisteredHooks() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorCaller) GetRegisteredHooks(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getRegisteredHooks")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetRegisteredHooks is a free data retrieval call binding the contract method 0x841b0175.
//
// Solidity: function getRegisteredHooks() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorSession) GetRegisteredHooks() ([]common.Address, error) {
	return _MockSuperGovernor.Contract.GetRegisteredHooks(&_MockSuperGovernor.CallOpts)
}

// GetRegisteredHooks is a free data retrieval call binding the contract method 0x841b0175.
//
// Solidity: function getRegisteredHooks() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetRegisteredHooks() ([]common.Address, error) {
	return _MockSuperGovernor.Contract.GetRegisteredHooks(&_MockSuperGovernor.CallOpts)
}

// GetRelayers is a free data retrieval call binding the contract method 0x179ff4b2.
//
// Solidity: function getRelayers() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorCaller) GetRelayers(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getRelayers")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetRelayers is a free data retrieval call binding the contract method 0x179ff4b2.
//
// Solidity: function getRelayers() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorSession) GetRelayers() ([]common.Address, error) {
	return _MockSuperGovernor.Contract.GetRelayers(&_MockSuperGovernor.CallOpts)
}

// GetRelayers is a free data retrieval call binding the contract method 0x179ff4b2.
//
// Solidity: function getRelayers() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetRelayers() ([]common.Address, error) {
	return _MockSuperGovernor.Contract.GetRelayers(&_MockSuperGovernor.CallOpts)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 ) view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetRoleAdmin(opts *bind.CallOpts, arg0 [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getRoleAdmin", arg0)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 ) view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) GetRoleAdmin(arg0 [32]byte) ([32]byte, error) {
	return _MockSuperGovernor.Contract.GetRoleAdmin(&_MockSuperGovernor.CallOpts, arg0)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 ) view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetRoleAdmin(arg0 [32]byte) ([32]byte, error) {
	return _MockSuperGovernor.Contract.GetRoleAdmin(&_MockSuperGovernor.CallOpts, arg0)
}

// GetSuperBankHookMerkleRoot is a free data retrieval call binding the contract method 0xf43526f4.
//
// Solidity: function getSuperBankHookMerkleRoot(address ) view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetSuperBankHookMerkleRoot(opts *bind.CallOpts, arg0 common.Address) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getSuperBankHookMerkleRoot", arg0)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetSuperBankHookMerkleRoot is a free data retrieval call binding the contract method 0xf43526f4.
//
// Solidity: function getSuperBankHookMerkleRoot(address ) view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) GetSuperBankHookMerkleRoot(arg0 common.Address) ([32]byte, error) {
	return _MockSuperGovernor.Contract.GetSuperBankHookMerkleRoot(&_MockSuperGovernor.CallOpts, arg0)
}

// GetSuperBankHookMerkleRoot is a free data retrieval call binding the contract method 0xf43526f4.
//
// Solidity: function getSuperBankHookMerkleRoot(address ) view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetSuperBankHookMerkleRoot(arg0 common.Address) ([32]byte, error) {
	return _MockSuperGovernor.Contract.GetSuperBankHookMerkleRoot(&_MockSuperGovernor.CallOpts, arg0)
}

// GetSuperformManagersCount is a free data retrieval call binding the contract method 0xcc8bb5e4.
//
// Solidity: function getSuperformManagersCount() view returns(uint256)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetSuperformManagersCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getSuperformManagersCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetSuperformManagersCount is a free data retrieval call binding the contract method 0xcc8bb5e4.
//
// Solidity: function getSuperformManagersCount() view returns(uint256)
func (_MockSuperGovernor *MockSuperGovernorSession) GetSuperformManagersCount() (*big.Int, error) {
	return _MockSuperGovernor.Contract.GetSuperformManagersCount(&_MockSuperGovernor.CallOpts)
}

// GetSuperformManagersCount is a free data retrieval call binding the contract method 0xcc8bb5e4.
//
// Solidity: function getSuperformManagersCount() view returns(uint256)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetSuperformManagersCount() (*big.Int, error) {
	return _MockSuperGovernor.Contract.GetSuperformManagersCount(&_MockSuperGovernor.CallOpts)
}

// GetUpkeepCostPerBatchUpdate is a free data retrieval call binding the contract method 0xc2c2748a.
//
// Solidity: function getUpkeepCostPerBatchUpdate(address , uint256 ) view returns(uint256)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetUpkeepCostPerBatchUpdate(opts *bind.CallOpts, arg0 common.Address, arg1 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getUpkeepCostPerBatchUpdate", arg0, arg1)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetUpkeepCostPerBatchUpdate is a free data retrieval call binding the contract method 0xc2c2748a.
//
// Solidity: function getUpkeepCostPerBatchUpdate(address , uint256 ) view returns(uint256)
func (_MockSuperGovernor *MockSuperGovernorSession) GetUpkeepCostPerBatchUpdate(arg0 common.Address, arg1 *big.Int) (*big.Int, error) {
	return _MockSuperGovernor.Contract.GetUpkeepCostPerBatchUpdate(&_MockSuperGovernor.CallOpts, arg0, arg1)
}

// GetUpkeepCostPerBatchUpdate is a free data retrieval call binding the contract method 0xc2c2748a.
//
// Solidity: function getUpkeepCostPerBatchUpdate(address , uint256 ) view returns(uint256)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetUpkeepCostPerBatchUpdate(arg0 common.Address, arg1 *big.Int) (*big.Int, error) {
	return _MockSuperGovernor.Contract.GetUpkeepCostPerBatchUpdate(&_MockSuperGovernor.CallOpts, arg0, arg1)
}

// GetValidators is a free data retrieval call binding the contract method 0xb7ab4db5.
//
// Solidity: function getValidators() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorCaller) GetValidators(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getValidators")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetValidators is a free data retrieval call binding the contract method 0xb7ab4db5.
//
// Solidity: function getValidators() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorSession) GetValidators() ([]common.Address, error) {
	return _MockSuperGovernor.Contract.GetValidators(&_MockSuperGovernor.CallOpts)
}

// GetValidators is a free data retrieval call binding the contract method 0xb7ab4db5.
//
// Solidity: function getValidators() view returns(address[])
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetValidators() ([]common.Address, error) {
	return _MockSuperGovernor.Contract.GetValidators(&_MockSuperGovernor.CallOpts)
}

// GetVaultBank is a free data retrieval call binding the contract method 0x3e099f30.
//
// Solidity: function getVaultBank(uint64 ) view returns(address)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetVaultBank(opts *bind.CallOpts, arg0 uint64) (common.Address, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getVaultBank", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetVaultBank is a free data retrieval call binding the contract method 0x3e099f30.
//
// Solidity: function getVaultBank(uint64 ) view returns(address)
func (_MockSuperGovernor *MockSuperGovernorSession) GetVaultBank(arg0 uint64) (common.Address, error) {
	return _MockSuperGovernor.Contract.GetVaultBank(&_MockSuperGovernor.CallOpts, arg0)
}

// GetVaultBank is a free data retrieval call binding the contract method 0x3e099f30.
//
// Solidity: function getVaultBank(uint64 ) view returns(address)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetVaultBank(arg0 uint64) (common.Address, error) {
	return _MockSuperGovernor.Contract.GetVaultBank(&_MockSuperGovernor.CallOpts, arg0)
}

// GetVaultBankHookMerkleRoot is a free data retrieval call binding the contract method 0xdfebb1c2.
//
// Solidity: function getVaultBankHookMerkleRoot(address ) view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCaller) GetVaultBankHookMerkleRoot(opts *bind.CallOpts, arg0 common.Address) ([32]byte, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "getVaultBankHookMerkleRoot", arg0)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetVaultBankHookMerkleRoot is a free data retrieval call binding the contract method 0xdfebb1c2.
//
// Solidity: function getVaultBankHookMerkleRoot(address ) view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorSession) GetVaultBankHookMerkleRoot(arg0 common.Address) ([32]byte, error) {
	return _MockSuperGovernor.Contract.GetVaultBankHookMerkleRoot(&_MockSuperGovernor.CallOpts, arg0)
}

// GetVaultBankHookMerkleRoot is a free data retrieval call binding the contract method 0xdfebb1c2.
//
// Solidity: function getVaultBankHookMerkleRoot(address ) view returns(bytes32)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) GetVaultBankHookMerkleRoot(arg0 common.Address) ([32]byte, error) {
	return _MockSuperGovernor.Contract.GetVaultBankHookMerkleRoot(&_MockSuperGovernor.CallOpts, arg0)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 , address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCaller) HasRole(opts *bind.CallOpts, arg0 [32]byte, arg1 common.Address) (bool, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "hasRole", arg0, arg1)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 , address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorSession) HasRole(arg0 [32]byte, arg1 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.HasRole(&_MockSuperGovernor.CallOpts, arg0, arg1)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 , address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) HasRole(arg0 [32]byte, arg1 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.HasRole(&_MockSuperGovernor.CallOpts, arg0, arg1)
}

// IsActivePPSOracle is a free data retrieval call binding the contract method 0xfd6f0fc2.
//
// Solidity: function isActivePPSOracle(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCaller) IsActivePPSOracle(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "isActivePPSOracle", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsActivePPSOracle is a free data retrieval call binding the contract method 0xfd6f0fc2.
//
// Solidity: function isActivePPSOracle(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorSession) IsActivePPSOracle(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsActivePPSOracle(&_MockSuperGovernor.CallOpts, arg0)
}

// IsActivePPSOracle is a free data retrieval call binding the contract method 0xfd6f0fc2.
//
// Solidity: function isActivePPSOracle(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) IsActivePPSOracle(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsActivePPSOracle(&_MockSuperGovernor.CallOpts, arg0)
}

// IsExecutor is a free data retrieval call binding the contract method 0xdebfda30.
//
// Solidity: function isExecutor(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCaller) IsExecutor(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "isExecutor", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsExecutor is a free data retrieval call binding the contract method 0xdebfda30.
//
// Solidity: function isExecutor(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorSession) IsExecutor(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsExecutor(&_MockSuperGovernor.CallOpts, arg0)
}

// IsExecutor is a free data retrieval call binding the contract method 0xdebfda30.
//
// Solidity: function isExecutor(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) IsExecutor(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsExecutor(&_MockSuperGovernor.CallOpts, arg0)
}

// IsFulfillRequestsHookRegistered is a free data retrieval call binding the contract method 0x7d3e649e.
//
// Solidity: function isFulfillRequestsHookRegistered(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCaller) IsFulfillRequestsHookRegistered(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "isFulfillRequestsHookRegistered", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsFulfillRequestsHookRegistered is a free data retrieval call binding the contract method 0x7d3e649e.
//
// Solidity: function isFulfillRequestsHookRegistered(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorSession) IsFulfillRequestsHookRegistered(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsFulfillRequestsHookRegistered(&_MockSuperGovernor.CallOpts, arg0)
}

// IsFulfillRequestsHookRegistered is a free data retrieval call binding the contract method 0x7d3e649e.
//
// Solidity: function isFulfillRequestsHookRegistered(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) IsFulfillRequestsHookRegistered(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsFulfillRequestsHookRegistered(&_MockSuperGovernor.CallOpts, arg0)
}

// IsGuardian is a free data retrieval call binding the contract method 0x0c68ba21.
//
// Solidity: function isGuardian(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCaller) IsGuardian(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "isGuardian", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsGuardian is a free data retrieval call binding the contract method 0x0c68ba21.
//
// Solidity: function isGuardian(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorSession) IsGuardian(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsGuardian(&_MockSuperGovernor.CallOpts, arg0)
}

// IsGuardian is a free data retrieval call binding the contract method 0x0c68ba21.
//
// Solidity: function isGuardian(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) IsGuardian(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsGuardian(&_MockSuperGovernor.CallOpts, arg0)
}

// IsHookRegistered is a free data retrieval call binding the contract method 0x0cbad00c.
//
// Solidity: function isHookRegistered(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCaller) IsHookRegistered(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "isHookRegistered", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsHookRegistered is a free data retrieval call binding the contract method 0x0cbad00c.
//
// Solidity: function isHookRegistered(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorSession) IsHookRegistered(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsHookRegistered(&_MockSuperGovernor.CallOpts, arg0)
}

// IsHookRegistered is a free data retrieval call binding the contract method 0x0cbad00c.
//
// Solidity: function isHookRegistered(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) IsHookRegistered(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsHookRegistered(&_MockSuperGovernor.CallOpts, arg0)
}

// IsManagerTakeoverFrozen is a free data retrieval call binding the contract method 0x5721145f.
//
// Solidity: function isManagerTakeoverFrozen() view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCaller) IsManagerTakeoverFrozen(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "isManagerTakeoverFrozen")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsManagerTakeoverFrozen is a free data retrieval call binding the contract method 0x5721145f.
//
// Solidity: function isManagerTakeoverFrozen() view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorSession) IsManagerTakeoverFrozen() (bool, error) {
	return _MockSuperGovernor.Contract.IsManagerTakeoverFrozen(&_MockSuperGovernor.CallOpts)
}

// IsManagerTakeoverFrozen is a free data retrieval call binding the contract method 0x5721145f.
//
// Solidity: function isManagerTakeoverFrozen() view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) IsManagerTakeoverFrozen() (bool, error) {
	return _MockSuperGovernor.Contract.IsManagerTakeoverFrozen(&_MockSuperGovernor.CallOpts)
}

// IsProtectedKeeper is a free data retrieval call binding the contract method 0x1e1c3d38.
//
// Solidity: function isProtectedKeeper(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCaller) IsProtectedKeeper(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "isProtectedKeeper", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsProtectedKeeper is a free data retrieval call binding the contract method 0x1e1c3d38.
//
// Solidity: function isProtectedKeeper(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorSession) IsProtectedKeeper(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsProtectedKeeper(&_MockSuperGovernor.CallOpts, arg0)
}

// IsProtectedKeeper is a free data retrieval call binding the contract method 0x1e1c3d38.
//
// Solidity: function isProtectedKeeper(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) IsProtectedKeeper(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsProtectedKeeper(&_MockSuperGovernor.CallOpts, arg0)
}

// IsRelayer is a free data retrieval call binding the contract method 0x541d5548.
//
// Solidity: function isRelayer(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCaller) IsRelayer(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "isRelayer", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsRelayer is a free data retrieval call binding the contract method 0x541d5548.
//
// Solidity: function isRelayer(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorSession) IsRelayer(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsRelayer(&_MockSuperGovernor.CallOpts, arg0)
}

// IsRelayer is a free data retrieval call binding the contract method 0x541d5548.
//
// Solidity: function isRelayer(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) IsRelayer(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsRelayer(&_MockSuperGovernor.CallOpts, arg0)
}

// IsSuperformManager is a free data retrieval call binding the contract method 0xae4d256e.
//
// Solidity: function isSuperformManager(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCaller) IsSuperformManager(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "isSuperformManager", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsSuperformManager is a free data retrieval call binding the contract method 0xae4d256e.
//
// Solidity: function isSuperformManager(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorSession) IsSuperformManager(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsSuperformManager(&_MockSuperGovernor.CallOpts, arg0)
}

// IsSuperformManager is a free data retrieval call binding the contract method 0xae4d256e.
//
// Solidity: function isSuperformManager(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) IsSuperformManager(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsSuperformManager(&_MockSuperGovernor.CallOpts, arg0)
}

// IsUpkeepPaymentsEnabled is a free data retrieval call binding the contract method 0x3ef15059.
//
// Solidity: function isUpkeepPaymentsEnabled() view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCaller) IsUpkeepPaymentsEnabled(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "isUpkeepPaymentsEnabled")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsUpkeepPaymentsEnabled is a free data retrieval call binding the contract method 0x3ef15059.
//
// Solidity: function isUpkeepPaymentsEnabled() view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorSession) IsUpkeepPaymentsEnabled() (bool, error) {
	return _MockSuperGovernor.Contract.IsUpkeepPaymentsEnabled(&_MockSuperGovernor.CallOpts)
}

// IsUpkeepPaymentsEnabled is a free data retrieval call binding the contract method 0x3ef15059.
//
// Solidity: function isUpkeepPaymentsEnabled() view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) IsUpkeepPaymentsEnabled() (bool, error) {
	return _MockSuperGovernor.Contract.IsUpkeepPaymentsEnabled(&_MockSuperGovernor.CallOpts)
}

// IsValidator is a free data retrieval call binding the contract method 0xfacd743b.
//
// Solidity: function isValidator(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCaller) IsValidator(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "isValidator", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsValidator is a free data retrieval call binding the contract method 0xfacd743b.
//
// Solidity: function isValidator(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorSession) IsValidator(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsValidator(&_MockSuperGovernor.CallOpts, arg0)
}

// IsValidator is a free data retrieval call binding the contract method 0xfacd743b.
//
// Solidity: function isValidator(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) IsValidator(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsValidator(&_MockSuperGovernor.CallOpts, arg0)
}

// IsWhitelistedIncentiveToken is a free data retrieval call binding the contract method 0x7045af80.
//
// Solidity: function isWhitelistedIncentiveToken(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCaller) IsWhitelistedIncentiveToken(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "isWhitelistedIncentiveToken", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsWhitelistedIncentiveToken is a free data retrieval call binding the contract method 0x7045af80.
//
// Solidity: function isWhitelistedIncentiveToken(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorSession) IsWhitelistedIncentiveToken(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsWhitelistedIncentiveToken(&_MockSuperGovernor.CallOpts, arg0)
}

// IsWhitelistedIncentiveToken is a free data retrieval call binding the contract method 0x7045af80.
//
// Solidity: function isWhitelistedIncentiveToken(address ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) IsWhitelistedIncentiveToken(arg0 common.Address) (bool, error) {
	return _MockSuperGovernor.Contract.IsWhitelistedIncentiveToken(&_MockSuperGovernor.CallOpts, arg0)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCaller) SupportsInterface(opts *bind.CallOpts, arg0 [4]byte) (bool, error) {
	var out []interface{}
	err := _MockSuperGovernor.contract.Call(opts, &out, "supportsInterface", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorSession) SupportsInterface(arg0 [4]byte) (bool, error) {
	return _MockSuperGovernor.Contract.SupportsInterface(&_MockSuperGovernor.CallOpts, arg0)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 ) view returns(bool)
func (_MockSuperGovernor *MockSuperGovernorCallerSession) SupportsInterface(arg0 [4]byte) (bool, error) {
	return _MockSuperGovernor.Contract.SupportsInterface(&_MockSuperGovernor.CallOpts, arg0)
}

// AddExecutor is a paid mutator transaction binding the contract method 0x1f5a0bbe.
//
// Solidity: function addExecutor(address executor) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) AddExecutor(opts *bind.TransactOpts, executor common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "addExecutor", executor)
}

// AddExecutor is a paid mutator transaction binding the contract method 0x1f5a0bbe.
//
// Solidity: function addExecutor(address executor) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) AddExecutor(executor common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.AddExecutor(&_MockSuperGovernor.TransactOpts, executor)
}

// AddExecutor is a paid mutator transaction binding the contract method 0x1f5a0bbe.
//
// Solidity: function addExecutor(address executor) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) AddExecutor(executor common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.AddExecutor(&_MockSuperGovernor.TransactOpts, executor)
}

// AddICCToWhitelist is a paid mutator transaction binding the contract method 0xd070909e.
//
// Solidity: function addICCToWhitelist(address icc) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) AddICCToWhitelist(opts *bind.TransactOpts, icc common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "addICCToWhitelist", icc)
}

// AddICCToWhitelist is a paid mutator transaction binding the contract method 0xd070909e.
//
// Solidity: function addICCToWhitelist(address icc) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) AddICCToWhitelist(icc common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.AddICCToWhitelist(&_MockSuperGovernor.TransactOpts, icc)
}

// AddICCToWhitelist is a paid mutator transaction binding the contract method 0xd070909e.
//
// Solidity: function addICCToWhitelist(address icc) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) AddICCToWhitelist(icc common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.AddICCToWhitelist(&_MockSuperGovernor.TransactOpts, icc)
}

// AddRelayer is a paid mutator transaction binding the contract method 0xdd39f00d.
//
// Solidity: function addRelayer(address relayer) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) AddRelayer(opts *bind.TransactOpts, relayer common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "addRelayer", relayer)
}

// AddRelayer is a paid mutator transaction binding the contract method 0xdd39f00d.
//
// Solidity: function addRelayer(address relayer) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) AddRelayer(relayer common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.AddRelayer(&_MockSuperGovernor.TransactOpts, relayer)
}

// AddRelayer is a paid mutator transaction binding the contract method 0xdd39f00d.
//
// Solidity: function addRelayer(address relayer) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) AddRelayer(relayer common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.AddRelayer(&_MockSuperGovernor.TransactOpts, relayer)
}

// AddSuperformManager is a paid mutator transaction binding the contract method 0xb291fdf3.
//
// Solidity: function addSuperformManager(address manager) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) AddSuperformManager(opts *bind.TransactOpts, manager common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "addSuperformManager", manager)
}

// AddSuperformManager is a paid mutator transaction binding the contract method 0xb291fdf3.
//
// Solidity: function addSuperformManager(address manager) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) AddSuperformManager(manager common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.AddSuperformManager(&_MockSuperGovernor.TransactOpts, manager)
}

// AddSuperformManager is a paid mutator transaction binding the contract method 0xb291fdf3.
//
// Solidity: function addSuperformManager(address manager) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) AddSuperformManager(manager common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.AddSuperformManager(&_MockSuperGovernor.TransactOpts, manager)
}

// AddValidator is a paid mutator transaction binding the contract method 0x4d238c8e.
//
// Solidity: function addValidator(address validator) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) AddValidator(opts *bind.TransactOpts, validator common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "addValidator", validator)
}

// AddValidator is a paid mutator transaction binding the contract method 0x4d238c8e.
//
// Solidity: function addValidator(address validator) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) AddValidator(validator common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.AddValidator(&_MockSuperGovernor.TransactOpts, validator)
}

// AddValidator is a paid mutator transaction binding the contract method 0x4d238c8e.
//
// Solidity: function addValidator(address validator) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) AddValidator(validator common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.AddValidator(&_MockSuperGovernor.TransactOpts, validator)
}

// AddVaultBank is a paid mutator transaction binding the contract method 0xbecbf729.
//
// Solidity: function addVaultBank(uint64 chainId, address vaultBank) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) AddVaultBank(opts *bind.TransactOpts, chainId uint64, vaultBank common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "addVaultBank", chainId, vaultBank)
}

// AddVaultBank is a paid mutator transaction binding the contract method 0xbecbf729.
//
// Solidity: function addVaultBank(uint64 chainId, address vaultBank) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) AddVaultBank(chainId uint64, vaultBank common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.AddVaultBank(&_MockSuperGovernor.TransactOpts, chainId, vaultBank)
}

// AddVaultBank is a paid mutator transaction binding the contract method 0xbecbf729.
//
// Solidity: function addVaultBank(uint64 chainId, address vaultBank) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) AddVaultBank(chainId uint64, vaultBank common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.AddVaultBank(&_MockSuperGovernor.TransactOpts, chainId, vaultBank)
}

// BatchSetOracleUptimeFeed is a paid mutator transaction binding the contract method 0x52ad8b00.
//
// Solidity: function batchSetOracleUptimeFeed(address[] dataOracles_, address[] uptimeOracles_, uint256[] gracePeriods_) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) BatchSetOracleUptimeFeed(opts *bind.TransactOpts, dataOracles_ []common.Address, uptimeOracles_ []common.Address, gracePeriods_ []*big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "batchSetOracleUptimeFeed", dataOracles_, uptimeOracles_, gracePeriods_)
}

// BatchSetOracleUptimeFeed is a paid mutator transaction binding the contract method 0x52ad8b00.
//
// Solidity: function batchSetOracleUptimeFeed(address[] dataOracles_, address[] uptimeOracles_, uint256[] gracePeriods_) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) BatchSetOracleUptimeFeed(dataOracles_ []common.Address, uptimeOracles_ []common.Address, gracePeriods_ []*big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.BatchSetOracleUptimeFeed(&_MockSuperGovernor.TransactOpts, dataOracles_, uptimeOracles_, gracePeriods_)
}

// BatchSetOracleUptimeFeed is a paid mutator transaction binding the contract method 0x52ad8b00.
//
// Solidity: function batchSetOracleUptimeFeed(address[] dataOracles_, address[] uptimeOracles_, uint256[] gracePeriods_) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) BatchSetOracleUptimeFeed(dataOracles_ []common.Address, uptimeOracles_ []common.Address, gracePeriods_ []*big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.BatchSetOracleUptimeFeed(&_MockSuperGovernor.TransactOpts, dataOracles_, uptimeOracles_, gracePeriods_)
}

// ChangeHooksRootUpdateTimelock is a paid mutator transaction binding the contract method 0x9649933b.
//
// Solidity: function changeHooksRootUpdateTimelock(uint256 newTimelock) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ChangeHooksRootUpdateTimelock(opts *bind.TransactOpts, newTimelock *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "changeHooksRootUpdateTimelock", newTimelock)
}

// ChangeHooksRootUpdateTimelock is a paid mutator transaction binding the contract method 0x9649933b.
//
// Solidity: function changeHooksRootUpdateTimelock(uint256 newTimelock) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ChangeHooksRootUpdateTimelock(newTimelock *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ChangeHooksRootUpdateTimelock(&_MockSuperGovernor.TransactOpts, newTimelock)
}

// ChangeHooksRootUpdateTimelock is a paid mutator transaction binding the contract method 0x9649933b.
//
// Solidity: function changeHooksRootUpdateTimelock(uint256 newTimelock) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ChangeHooksRootUpdateTimelock(newTimelock *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ChangeHooksRootUpdateTimelock(&_MockSuperGovernor.TransactOpts, newTimelock)
}

// ChangePrimaryManager is a paid mutator transaction binding the contract method 0x906811e0.
//
// Solidity: function changePrimaryManager(address strategy, address newManager) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ChangePrimaryManager(opts *bind.TransactOpts, strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "changePrimaryManager", strategy, newManager)
}

// ChangePrimaryManager is a paid mutator transaction binding the contract method 0x906811e0.
//
// Solidity: function changePrimaryManager(address strategy, address newManager) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ChangePrimaryManager(strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ChangePrimaryManager(&_MockSuperGovernor.TransactOpts, strategy, newManager)
}

// ChangePrimaryManager is a paid mutator transaction binding the contract method 0x906811e0.
//
// Solidity: function changePrimaryManager(address strategy, address newManager) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ChangePrimaryManager(strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ChangePrimaryManager(&_MockSuperGovernor.TransactOpts, strategy, newManager)
}

// ExecuteActivePPSOracleChange is a paid mutator transaction binding the contract method 0xf1031b4e.
//
// Solidity: function executeActivePPSOracleChange() returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ExecuteActivePPSOracleChange(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "executeActivePPSOracleChange")
}

// ExecuteActivePPSOracleChange is a paid mutator transaction binding the contract method 0xf1031b4e.
//
// Solidity: function executeActivePPSOracleChange() returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ExecuteActivePPSOracleChange() (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ExecuteActivePPSOracleChange(&_MockSuperGovernor.TransactOpts)
}

// ExecuteActivePPSOracleChange is a paid mutator transaction binding the contract method 0xf1031b4e.
//
// Solidity: function executeActivePPSOracleChange() returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ExecuteActivePPSOracleChange() (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ExecuteActivePPSOracleChange(&_MockSuperGovernor.TransactOpts)
}

// ExecuteAddIncentiveTokens is a paid mutator transaction binding the contract method 0xe5cc7970.
//
// Solidity: function executeAddIncentiveTokens() returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ExecuteAddIncentiveTokens(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "executeAddIncentiveTokens")
}

// ExecuteAddIncentiveTokens is a paid mutator transaction binding the contract method 0xe5cc7970.
//
// Solidity: function executeAddIncentiveTokens() returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ExecuteAddIncentiveTokens() (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ExecuteAddIncentiveTokens(&_MockSuperGovernor.TransactOpts)
}

// ExecuteAddIncentiveTokens is a paid mutator transaction binding the contract method 0xe5cc7970.
//
// Solidity: function executeAddIncentiveTokens() returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ExecuteAddIncentiveTokens() (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ExecuteAddIncentiveTokens(&_MockSuperGovernor.TransactOpts)
}

// ExecuteFeeUpdate is a paid mutator transaction binding the contract method 0x365d6bf3.
//
// Solidity: function executeFeeUpdate(uint8 feeType) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ExecuteFeeUpdate(opts *bind.TransactOpts, feeType uint8) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "executeFeeUpdate", feeType)
}

// ExecuteFeeUpdate is a paid mutator transaction binding the contract method 0x365d6bf3.
//
// Solidity: function executeFeeUpdate(uint8 feeType) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ExecuteFeeUpdate(feeType uint8) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ExecuteFeeUpdate(&_MockSuperGovernor.TransactOpts, feeType)
}

// ExecuteFeeUpdate is a paid mutator transaction binding the contract method 0x365d6bf3.
//
// Solidity: function executeFeeUpdate(uint8 feeType) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ExecuteFeeUpdate(feeType uint8) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ExecuteFeeUpdate(&_MockSuperGovernor.TransactOpts, feeType)
}

// ExecuteMinStalenessChange is a paid mutator transaction binding the contract method 0x4fb917f3.
//
// Solidity: function executeMinStalenessChange() returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ExecuteMinStalenessChange(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "executeMinStalenessChange")
}

// ExecuteMinStalenessChange is a paid mutator transaction binding the contract method 0x4fb917f3.
//
// Solidity: function executeMinStalenessChange() returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ExecuteMinStalenessChange() (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ExecuteMinStalenessChange(&_MockSuperGovernor.TransactOpts)
}

// ExecuteMinStalenessChange is a paid mutator transaction binding the contract method 0x4fb917f3.
//
// Solidity: function executeMinStalenessChange() returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ExecuteMinStalenessChange() (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ExecuteMinStalenessChange(&_MockSuperGovernor.TransactOpts)
}

// ExecuteRemoveIncentiveTokens is a paid mutator transaction binding the contract method 0xdc972801.
//
// Solidity: function executeRemoveIncentiveTokens() returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ExecuteRemoveIncentiveTokens(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "executeRemoveIncentiveTokens")
}

// ExecuteRemoveIncentiveTokens is a paid mutator transaction binding the contract method 0xdc972801.
//
// Solidity: function executeRemoveIncentiveTokens() returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ExecuteRemoveIncentiveTokens() (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ExecuteRemoveIncentiveTokens(&_MockSuperGovernor.TransactOpts)
}

// ExecuteRemoveIncentiveTokens is a paid mutator transaction binding the contract method 0xdc972801.
//
// Solidity: function executeRemoveIncentiveTokens() returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ExecuteRemoveIncentiveTokens() (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ExecuteRemoveIncentiveTokens(&_MockSuperGovernor.TransactOpts)
}

// ExecuteSuperBankHookMerkleRootUpdate is a paid mutator transaction binding the contract method 0x290c49a1.
//
// Solidity: function executeSuperBankHookMerkleRootUpdate(address hook) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ExecuteSuperBankHookMerkleRootUpdate(opts *bind.TransactOpts, hook common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "executeSuperBankHookMerkleRootUpdate", hook)
}

// ExecuteSuperBankHookMerkleRootUpdate is a paid mutator transaction binding the contract method 0x290c49a1.
//
// Solidity: function executeSuperBankHookMerkleRootUpdate(address hook) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ExecuteSuperBankHookMerkleRootUpdate(hook common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ExecuteSuperBankHookMerkleRootUpdate(&_MockSuperGovernor.TransactOpts, hook)
}

// ExecuteSuperBankHookMerkleRootUpdate is a paid mutator transaction binding the contract method 0x290c49a1.
//
// Solidity: function executeSuperBankHookMerkleRootUpdate(address hook) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ExecuteSuperBankHookMerkleRootUpdate(hook common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ExecuteSuperBankHookMerkleRootUpdate(&_MockSuperGovernor.TransactOpts, hook)
}

// ExecuteUpkeepClaim is a paid mutator transaction binding the contract method 0x3202ac23.
//
// Solidity: function executeUpkeepClaim(uint256 amount) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ExecuteUpkeepClaim(opts *bind.TransactOpts, amount *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "executeUpkeepClaim", amount)
}

// ExecuteUpkeepClaim is a paid mutator transaction binding the contract method 0x3202ac23.
//
// Solidity: function executeUpkeepClaim(uint256 amount) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ExecuteUpkeepClaim(amount *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ExecuteUpkeepClaim(&_MockSuperGovernor.TransactOpts, amount)
}

// ExecuteUpkeepClaim is a paid mutator transaction binding the contract method 0x3202ac23.
//
// Solidity: function executeUpkeepClaim(uint256 amount) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ExecuteUpkeepClaim(amount *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ExecuteUpkeepClaim(&_MockSuperGovernor.TransactOpts, amount)
}

// ExecuteUpkeepPaymentsChange is a paid mutator transaction binding the contract method 0xecc3d967.
//
// Solidity: function executeUpkeepPaymentsChange() returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ExecuteUpkeepPaymentsChange(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "executeUpkeepPaymentsChange")
}

// ExecuteUpkeepPaymentsChange is a paid mutator transaction binding the contract method 0xecc3d967.
//
// Solidity: function executeUpkeepPaymentsChange() returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ExecuteUpkeepPaymentsChange() (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ExecuteUpkeepPaymentsChange(&_MockSuperGovernor.TransactOpts)
}

// ExecuteUpkeepPaymentsChange is a paid mutator transaction binding the contract method 0xecc3d967.
//
// Solidity: function executeUpkeepPaymentsChange() returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ExecuteUpkeepPaymentsChange() (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ExecuteUpkeepPaymentsChange(&_MockSuperGovernor.TransactOpts)
}

// ExecuteVaultBankHookMerkleRootUpdate is a paid mutator transaction binding the contract method 0x1de73a40.
//
// Solidity: function executeVaultBankHookMerkleRootUpdate(address hook) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ExecuteVaultBankHookMerkleRootUpdate(opts *bind.TransactOpts, hook common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "executeVaultBankHookMerkleRootUpdate", hook)
}

// ExecuteVaultBankHookMerkleRootUpdate is a paid mutator transaction binding the contract method 0x1de73a40.
//
// Solidity: function executeVaultBankHookMerkleRootUpdate(address hook) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ExecuteVaultBankHookMerkleRootUpdate(hook common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ExecuteVaultBankHookMerkleRootUpdate(&_MockSuperGovernor.TransactOpts, hook)
}

// ExecuteVaultBankHookMerkleRootUpdate is a paid mutator transaction binding the contract method 0x1de73a40.
//
// Solidity: function executeVaultBankHookMerkleRootUpdate(address hook) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ExecuteVaultBankHookMerkleRootUpdate(hook common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ExecuteVaultBankHookMerkleRootUpdate(&_MockSuperGovernor.TransactOpts, hook)
}

// FreezeManagerTakeover is a paid mutator transaction binding the contract method 0xca774c12.
//
// Solidity: function freezeManagerTakeover() returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) FreezeManagerTakeover(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "freezeManagerTakeover")
}

// FreezeManagerTakeover is a paid mutator transaction binding the contract method 0xca774c12.
//
// Solidity: function freezeManagerTakeover() returns()
func (_MockSuperGovernor *MockSuperGovernorSession) FreezeManagerTakeover() (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.FreezeManagerTakeover(&_MockSuperGovernor.TransactOpts)
}

// FreezeManagerTakeover is a paid mutator transaction binding the contract method 0xca774c12.
//
// Solidity: function freezeManagerTakeover() returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) FreezeManagerTakeover() (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.FreezeManagerTakeover(&_MockSuperGovernor.TransactOpts)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.GrantRole(&_MockSuperGovernor.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.GrantRole(&_MockSuperGovernor.TransactOpts, role, account)
}

// ProposeActivePPSOracle is a paid mutator transaction binding the contract method 0x1551c6c0.
//
// Solidity: function proposeActivePPSOracle(address oracle) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ProposeActivePPSOracle(opts *bind.TransactOpts, oracle common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "proposeActivePPSOracle", oracle)
}

// ProposeActivePPSOracle is a paid mutator transaction binding the contract method 0x1551c6c0.
//
// Solidity: function proposeActivePPSOracle(address oracle) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ProposeActivePPSOracle(oracle common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ProposeActivePPSOracle(&_MockSuperGovernor.TransactOpts, oracle)
}

// ProposeActivePPSOracle is a paid mutator transaction binding the contract method 0x1551c6c0.
//
// Solidity: function proposeActivePPSOracle(address oracle) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ProposeActivePPSOracle(oracle common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ProposeActivePPSOracle(&_MockSuperGovernor.TransactOpts, oracle)
}

// ProposeAddIncentiveTokens is a paid mutator transaction binding the contract method 0x51597672.
//
// Solidity: function proposeAddIncentiveTokens(address[] tokens) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ProposeAddIncentiveTokens(opts *bind.TransactOpts, tokens []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "proposeAddIncentiveTokens", tokens)
}

// ProposeAddIncentiveTokens is a paid mutator transaction binding the contract method 0x51597672.
//
// Solidity: function proposeAddIncentiveTokens(address[] tokens) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ProposeAddIncentiveTokens(tokens []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ProposeAddIncentiveTokens(&_MockSuperGovernor.TransactOpts, tokens)
}

// ProposeAddIncentiveTokens is a paid mutator transaction binding the contract method 0x51597672.
//
// Solidity: function proposeAddIncentiveTokens(address[] tokens) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ProposeAddIncentiveTokens(tokens []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ProposeAddIncentiveTokens(&_MockSuperGovernor.TransactOpts, tokens)
}

// ProposeFee is a paid mutator transaction binding the contract method 0x022e38cf.
//
// Solidity: function proposeFee(uint8 feeType, uint256 value) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ProposeFee(opts *bind.TransactOpts, feeType uint8, value *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "proposeFee", feeType, value)
}

// ProposeFee is a paid mutator transaction binding the contract method 0x022e38cf.
//
// Solidity: function proposeFee(uint8 feeType, uint256 value) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ProposeFee(feeType uint8, value *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ProposeFee(&_MockSuperGovernor.TransactOpts, feeType, value)
}

// ProposeFee is a paid mutator transaction binding the contract method 0x022e38cf.
//
// Solidity: function proposeFee(uint8 feeType, uint256 value) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ProposeFee(feeType uint8, value *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ProposeFee(&_MockSuperGovernor.TransactOpts, feeType, value)
}

// ProposeGlobalHooksRoot is a paid mutator transaction binding the contract method 0xb0e5173b.
//
// Solidity: function proposeGlobalHooksRoot(bytes32 newRoot) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ProposeGlobalHooksRoot(opts *bind.TransactOpts, newRoot [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "proposeGlobalHooksRoot", newRoot)
}

// ProposeGlobalHooksRoot is a paid mutator transaction binding the contract method 0xb0e5173b.
//
// Solidity: function proposeGlobalHooksRoot(bytes32 newRoot) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ProposeGlobalHooksRoot(newRoot [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ProposeGlobalHooksRoot(&_MockSuperGovernor.TransactOpts, newRoot)
}

// ProposeGlobalHooksRoot is a paid mutator transaction binding the contract method 0xb0e5173b.
//
// Solidity: function proposeGlobalHooksRoot(bytes32 newRoot) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ProposeGlobalHooksRoot(newRoot [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ProposeGlobalHooksRoot(&_MockSuperGovernor.TransactOpts, newRoot)
}

// ProposeMinStaleness is a paid mutator transaction binding the contract method 0xc0c10943.
//
// Solidity: function proposeMinStaleness(uint256 newMinStaleness) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ProposeMinStaleness(opts *bind.TransactOpts, newMinStaleness *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "proposeMinStaleness", newMinStaleness)
}

// ProposeMinStaleness is a paid mutator transaction binding the contract method 0xc0c10943.
//
// Solidity: function proposeMinStaleness(uint256 newMinStaleness) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ProposeMinStaleness(newMinStaleness *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ProposeMinStaleness(&_MockSuperGovernor.TransactOpts, newMinStaleness)
}

// ProposeMinStaleness is a paid mutator transaction binding the contract method 0xc0c10943.
//
// Solidity: function proposeMinStaleness(uint256 newMinStaleness) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ProposeMinStaleness(newMinStaleness *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ProposeMinStaleness(&_MockSuperGovernor.TransactOpts, newMinStaleness)
}

// ProposeRemoveIncentiveTokens is a paid mutator transaction binding the contract method 0xcb53603e.
//
// Solidity: function proposeRemoveIncentiveTokens(address[] tokens) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ProposeRemoveIncentiveTokens(opts *bind.TransactOpts, tokens []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "proposeRemoveIncentiveTokens", tokens)
}

// ProposeRemoveIncentiveTokens is a paid mutator transaction binding the contract method 0xcb53603e.
//
// Solidity: function proposeRemoveIncentiveTokens(address[] tokens) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ProposeRemoveIncentiveTokens(tokens []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ProposeRemoveIncentiveTokens(&_MockSuperGovernor.TransactOpts, tokens)
}

// ProposeRemoveIncentiveTokens is a paid mutator transaction binding the contract method 0xcb53603e.
//
// Solidity: function proposeRemoveIncentiveTokens(address[] tokens) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ProposeRemoveIncentiveTokens(tokens []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ProposeRemoveIncentiveTokens(&_MockSuperGovernor.TransactOpts, tokens)
}

// ProposeSuperBankHookMerkleRoot is a paid mutator transaction binding the contract method 0x5e46e8b9.
//
// Solidity: function proposeSuperBankHookMerkleRoot(address hook, bytes32 proposedRoot) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ProposeSuperBankHookMerkleRoot(opts *bind.TransactOpts, hook common.Address, proposedRoot [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "proposeSuperBankHookMerkleRoot", hook, proposedRoot)
}

// ProposeSuperBankHookMerkleRoot is a paid mutator transaction binding the contract method 0x5e46e8b9.
//
// Solidity: function proposeSuperBankHookMerkleRoot(address hook, bytes32 proposedRoot) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ProposeSuperBankHookMerkleRoot(hook common.Address, proposedRoot [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ProposeSuperBankHookMerkleRoot(&_MockSuperGovernor.TransactOpts, hook, proposedRoot)
}

// ProposeSuperBankHookMerkleRoot is a paid mutator transaction binding the contract method 0x5e46e8b9.
//
// Solidity: function proposeSuperBankHookMerkleRoot(address hook, bytes32 proposedRoot) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ProposeSuperBankHookMerkleRoot(hook common.Address, proposedRoot [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ProposeSuperBankHookMerkleRoot(&_MockSuperGovernor.TransactOpts, hook, proposedRoot)
}

// ProposeUpkeepPaymentsChange is a paid mutator transaction binding the contract method 0x778f8a93.
//
// Solidity: function proposeUpkeepPaymentsChange(bool enabled) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ProposeUpkeepPaymentsChange(opts *bind.TransactOpts, enabled bool) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "proposeUpkeepPaymentsChange", enabled)
}

// ProposeUpkeepPaymentsChange is a paid mutator transaction binding the contract method 0x778f8a93.
//
// Solidity: function proposeUpkeepPaymentsChange(bool enabled) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ProposeUpkeepPaymentsChange(enabled bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ProposeUpkeepPaymentsChange(&_MockSuperGovernor.TransactOpts, enabled)
}

// ProposeUpkeepPaymentsChange is a paid mutator transaction binding the contract method 0x778f8a93.
//
// Solidity: function proposeUpkeepPaymentsChange(bool enabled) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ProposeUpkeepPaymentsChange(enabled bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ProposeUpkeepPaymentsChange(&_MockSuperGovernor.TransactOpts, enabled)
}

// ProposeVaultBankHookMerkleRoot is a paid mutator transaction binding the contract method 0xba96fb67.
//
// Solidity: function proposeVaultBankHookMerkleRoot(address hook, bytes32 proposedRoot) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) ProposeVaultBankHookMerkleRoot(opts *bind.TransactOpts, hook common.Address, proposedRoot [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "proposeVaultBankHookMerkleRoot", hook, proposedRoot)
}

// ProposeVaultBankHookMerkleRoot is a paid mutator transaction binding the contract method 0xba96fb67.
//
// Solidity: function proposeVaultBankHookMerkleRoot(address hook, bytes32 proposedRoot) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) ProposeVaultBankHookMerkleRoot(hook common.Address, proposedRoot [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ProposeVaultBankHookMerkleRoot(&_MockSuperGovernor.TransactOpts, hook, proposedRoot)
}

// ProposeVaultBankHookMerkleRoot is a paid mutator transaction binding the contract method 0xba96fb67.
//
// Solidity: function proposeVaultBankHookMerkleRoot(address hook, bytes32 proposedRoot) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) ProposeVaultBankHookMerkleRoot(hook common.Address, proposedRoot [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.ProposeVaultBankHookMerkleRoot(&_MockSuperGovernor.TransactOpts, hook, proposedRoot)
}

// QueueOracleProviderRemoval is a paid mutator transaction binding the contract method 0x6490305f.
//
// Solidity: function queueOracleProviderRemoval(bytes32[] providers) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) QueueOracleProviderRemoval(opts *bind.TransactOpts, providers [][32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "queueOracleProviderRemoval", providers)
}

// QueueOracleProviderRemoval is a paid mutator transaction binding the contract method 0x6490305f.
//
// Solidity: function queueOracleProviderRemoval(bytes32[] providers) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) QueueOracleProviderRemoval(providers [][32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.QueueOracleProviderRemoval(&_MockSuperGovernor.TransactOpts, providers)
}

// QueueOracleProviderRemoval is a paid mutator transaction binding the contract method 0x6490305f.
//
// Solidity: function queueOracleProviderRemoval(bytes32[] providers) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) QueueOracleProviderRemoval(providers [][32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.QueueOracleProviderRemoval(&_MockSuperGovernor.TransactOpts, providers)
}

// QueueOracleUpdate is a paid mutator transaction binding the contract method 0xba1f073c.
//
// Solidity: function queueOracleUpdate(address[] bases_, address[] quotes_, bytes32[] providers_, address[] feeds_) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) QueueOracleUpdate(opts *bind.TransactOpts, bases_ []common.Address, quotes_ []common.Address, providers_ [][32]byte, feeds_ []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "queueOracleUpdate", bases_, quotes_, providers_, feeds_)
}

// QueueOracleUpdate is a paid mutator transaction binding the contract method 0xba1f073c.
//
// Solidity: function queueOracleUpdate(address[] bases_, address[] quotes_, bytes32[] providers_, address[] feeds_) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) QueueOracleUpdate(bases_ []common.Address, quotes_ []common.Address, providers_ [][32]byte, feeds_ []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.QueueOracleUpdate(&_MockSuperGovernor.TransactOpts, bases_, quotes_, providers_, feeds_)
}

// QueueOracleUpdate is a paid mutator transaction binding the contract method 0xba1f073c.
//
// Solidity: function queueOracleUpdate(address[] bases_, address[] quotes_, bytes32[] providers_, address[] feeds_) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) QueueOracleUpdate(bases_ []common.Address, quotes_ []common.Address, providers_ [][32]byte, feeds_ []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.QueueOracleUpdate(&_MockSuperGovernor.TransactOpts, bases_, quotes_, providers_, feeds_)
}

// RegisterHook is a paid mutator transaction binding the contract method 0x8481643b.
//
// Solidity: function registerHook(address hook, bool isFulfillRequestsHook) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) RegisterHook(opts *bind.TransactOpts, hook common.Address, isFulfillRequestsHook bool) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "registerHook", hook, isFulfillRequestsHook)
}

// RegisterHook is a paid mutator transaction binding the contract method 0x8481643b.
//
// Solidity: function registerHook(address hook, bool isFulfillRequestsHook) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) RegisterHook(hook common.Address, isFulfillRequestsHook bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.RegisterHook(&_MockSuperGovernor.TransactOpts, hook, isFulfillRequestsHook)
}

// RegisterHook is a paid mutator transaction binding the contract method 0x8481643b.
//
// Solidity: function registerHook(address hook, bool isFulfillRequestsHook) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) RegisterHook(hook common.Address, isFulfillRequestsHook bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.RegisterHook(&_MockSuperGovernor.TransactOpts, hook, isFulfillRequestsHook)
}

// RegisterProtectedKeeper is a paid mutator transaction binding the contract method 0x50151492.
//
// Solidity: function registerProtectedKeeper(address keeper) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) RegisterProtectedKeeper(opts *bind.TransactOpts, keeper common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "registerProtectedKeeper", keeper)
}

// RegisterProtectedKeeper is a paid mutator transaction binding the contract method 0x50151492.
//
// Solidity: function registerProtectedKeeper(address keeper) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) RegisterProtectedKeeper(keeper common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.RegisterProtectedKeeper(&_MockSuperGovernor.TransactOpts, keeper)
}

// RegisterProtectedKeeper is a paid mutator transaction binding the contract method 0x50151492.
//
// Solidity: function registerProtectedKeeper(address keeper) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) RegisterProtectedKeeper(keeper common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.RegisterProtectedKeeper(&_MockSuperGovernor.TransactOpts, keeper)
}

// RemoveExecutor is a paid mutator transaction binding the contract method 0x24788429.
//
// Solidity: function removeExecutor(address executor) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) RemoveExecutor(opts *bind.TransactOpts, executor common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "removeExecutor", executor)
}

// RemoveExecutor is a paid mutator transaction binding the contract method 0x24788429.
//
// Solidity: function removeExecutor(address executor) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) RemoveExecutor(executor common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.RemoveExecutor(&_MockSuperGovernor.TransactOpts, executor)
}

// RemoveExecutor is a paid mutator transaction binding the contract method 0x24788429.
//
// Solidity: function removeExecutor(address executor) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) RemoveExecutor(executor common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.RemoveExecutor(&_MockSuperGovernor.TransactOpts, executor)
}

// RemoveICCFromWhitelist is a paid mutator transaction binding the contract method 0x256b71a0.
//
// Solidity: function removeICCFromWhitelist(address icc) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) RemoveICCFromWhitelist(opts *bind.TransactOpts, icc common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "removeICCFromWhitelist", icc)
}

// RemoveICCFromWhitelist is a paid mutator transaction binding the contract method 0x256b71a0.
//
// Solidity: function removeICCFromWhitelist(address icc) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) RemoveICCFromWhitelist(icc common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.RemoveICCFromWhitelist(&_MockSuperGovernor.TransactOpts, icc)
}

// RemoveICCFromWhitelist is a paid mutator transaction binding the contract method 0x256b71a0.
//
// Solidity: function removeICCFromWhitelist(address icc) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) RemoveICCFromWhitelist(icc common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.RemoveICCFromWhitelist(&_MockSuperGovernor.TransactOpts, icc)
}

// RemoveRelayer is a paid mutator transaction binding the contract method 0x60f0a5ac.
//
// Solidity: function removeRelayer(address relayer) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) RemoveRelayer(opts *bind.TransactOpts, relayer common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "removeRelayer", relayer)
}

// RemoveRelayer is a paid mutator transaction binding the contract method 0x60f0a5ac.
//
// Solidity: function removeRelayer(address relayer) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) RemoveRelayer(relayer common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.RemoveRelayer(&_MockSuperGovernor.TransactOpts, relayer)
}

// RemoveRelayer is a paid mutator transaction binding the contract method 0x60f0a5ac.
//
// Solidity: function removeRelayer(address relayer) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) RemoveRelayer(relayer common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.RemoveRelayer(&_MockSuperGovernor.TransactOpts, relayer)
}

// RemoveSuperformManager is a paid mutator transaction binding the contract method 0x1c70d542.
//
// Solidity: function removeSuperformManager(address manager) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) RemoveSuperformManager(opts *bind.TransactOpts, manager common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "removeSuperformManager", manager)
}

// RemoveSuperformManager is a paid mutator transaction binding the contract method 0x1c70d542.
//
// Solidity: function removeSuperformManager(address manager) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) RemoveSuperformManager(manager common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.RemoveSuperformManager(&_MockSuperGovernor.TransactOpts, manager)
}

// RemoveSuperformManager is a paid mutator transaction binding the contract method 0x1c70d542.
//
// Solidity: function removeSuperformManager(address manager) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) RemoveSuperformManager(manager common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.RemoveSuperformManager(&_MockSuperGovernor.TransactOpts, manager)
}

// RemoveValidator is a paid mutator transaction binding the contract method 0x40a141ff.
//
// Solidity: function removeValidator(address validator) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) RemoveValidator(opts *bind.TransactOpts, validator common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "removeValidator", validator)
}

// RemoveValidator is a paid mutator transaction binding the contract method 0x40a141ff.
//
// Solidity: function removeValidator(address validator) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) RemoveValidator(validator common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.RemoveValidator(&_MockSuperGovernor.TransactOpts, validator)
}

// RemoveValidator is a paid mutator transaction binding the contract method 0x40a141ff.
//
// Solidity: function removeValidator(address validator) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) RemoveValidator(validator common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.RemoveValidator(&_MockSuperGovernor.TransactOpts, validator)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "renounceRole", role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.RenounceRole(&_MockSuperGovernor.TransactOpts, role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.RenounceRole(&_MockSuperGovernor.TransactOpts, role, callerConfirmation)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.RevokeRole(&_MockSuperGovernor.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.RevokeRole(&_MockSuperGovernor.TransactOpts, role, account)
}

// SetActivePPSOracle is a paid mutator transaction binding the contract method 0xf9525fb7.
//
// Solidity: function setActivePPSOracle(address oracle) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetActivePPSOracle(opts *bind.TransactOpts, oracle common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setActivePPSOracle", oracle)
}

// SetActivePPSOracle is a paid mutator transaction binding the contract method 0xf9525fb7.
//
// Solidity: function setActivePPSOracle(address oracle) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetActivePPSOracle(oracle common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetActivePPSOracle(&_MockSuperGovernor.TransactOpts, oracle)
}

// SetActivePPSOracle is a paid mutator transaction binding the contract method 0xf9525fb7.
//
// Solidity: function setActivePPSOracle(address oracle) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetActivePPSOracle(oracle common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetActivePPSOracle(&_MockSuperGovernor.TransactOpts, oracle)
}

// SetAddress is a paid mutator transaction binding the contract method 0xca446dd9.
//
// Solidity: function setAddress(bytes32 key, address value) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetAddress(opts *bind.TransactOpts, key [32]byte, value common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setAddress", key, value)
}

// SetAddress is a paid mutator transaction binding the contract method 0xca446dd9.
//
// Solidity: function setAddress(bytes32 key, address value) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetAddress(key [32]byte, value common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetAddress(&_MockSuperGovernor.TransactOpts, key, value)
}

// SetAddress is a paid mutator transaction binding the contract method 0xca446dd9.
//
// Solidity: function setAddress(bytes32 key, address value) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetAddress(key [32]byte, value common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetAddress(&_MockSuperGovernor.TransactOpts, key, value)
}

// SetBANKMANAGERReturn is a paid mutator transaction binding the contract method 0x50baae90.
//
// Solidity: function setBANK_MANAGERReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetBANKMANAGERReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setBANK_MANAGERReturn", _value0)
}

// SetBANKMANAGERReturn is a paid mutator transaction binding the contract method 0x50baae90.
//
// Solidity: function setBANK_MANAGERReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetBANKMANAGERReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetBANKMANAGERReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetBANKMANAGERReturn is a paid mutator transaction binding the contract method 0x50baae90.
//
// Solidity: function setBANK_MANAGERReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetBANKMANAGERReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetBANKMANAGERReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetBANKMANAGERROLEReturn is a paid mutator transaction binding the contract method 0xf47b9deb.
//
// Solidity: function setBANK_MANAGER_ROLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetBANKMANAGERROLEReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setBANK_MANAGER_ROLEReturn", _value0)
}

// SetBANKMANAGERROLEReturn is a paid mutator transaction binding the contract method 0xf47b9deb.
//
// Solidity: function setBANK_MANAGER_ROLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetBANKMANAGERROLEReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetBANKMANAGERROLEReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetBANKMANAGERROLEReturn is a paid mutator transaction binding the contract method 0xf47b9deb.
//
// Solidity: function setBANK_MANAGER_ROLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetBANKMANAGERROLEReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetBANKMANAGERROLEReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetDEFAULTADMINROLEReturn is a paid mutator transaction binding the contract method 0x2fbbe0ae.
//
// Solidity: function setDEFAULT_ADMIN_ROLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetDEFAULTADMINROLEReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setDEFAULT_ADMIN_ROLEReturn", _value0)
}

// SetDEFAULTADMINROLEReturn is a paid mutator transaction binding the contract method 0x2fbbe0ae.
//
// Solidity: function setDEFAULT_ADMIN_ROLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetDEFAULTADMINROLEReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetDEFAULTADMINROLEReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetDEFAULTADMINROLEReturn is a paid mutator transaction binding the contract method 0x2fbbe0ae.
//
// Solidity: function setDEFAULT_ADMIN_ROLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetDEFAULTADMINROLEReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetDEFAULTADMINROLEReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetECDSAPPSORACLEReturn is a paid mutator transaction binding the contract method 0x961491b6.
//
// Solidity: function setECDSAPPSORACLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetECDSAPPSORACLEReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setECDSAPPSORACLEReturn", _value0)
}

// SetECDSAPPSORACLEReturn is a paid mutator transaction binding the contract method 0x961491b6.
//
// Solidity: function setECDSAPPSORACLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetECDSAPPSORACLEReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetECDSAPPSORACLEReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetECDSAPPSORACLEReturn is a paid mutator transaction binding the contract method 0x961491b6.
//
// Solidity: function setECDSAPPSORACLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetECDSAPPSORACLEReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetECDSAPPSORACLEReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGASMANAGERROLEReturn is a paid mutator transaction binding the contract method 0x121939ea.
//
// Solidity: function setGAS_MANAGER_ROLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGASMANAGERROLEReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGAS_MANAGER_ROLEReturn", _value0)
}

// SetGASMANAGERROLEReturn is a paid mutator transaction binding the contract method 0x121939ea.
//
// Solidity: function setGAS_MANAGER_ROLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGASMANAGERROLEReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGASMANAGERROLEReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGASMANAGERROLEReturn is a paid mutator transaction binding the contract method 0x121939ea.
//
// Solidity: function setGAS_MANAGER_ROLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGASMANAGERROLEReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGASMANAGERROLEReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGOVERNORROLEReturn is a paid mutator transaction binding the contract method 0x3a364595.
//
// Solidity: function setGOVERNOR_ROLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGOVERNORROLEReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGOVERNOR_ROLEReturn", _value0)
}

// SetGOVERNORROLEReturn is a paid mutator transaction binding the contract method 0x3a364595.
//
// Solidity: function setGOVERNOR_ROLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGOVERNORROLEReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGOVERNORROLEReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGOVERNORROLEReturn is a paid mutator transaction binding the contract method 0x3a364595.
//
// Solidity: function setGOVERNOR_ROLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGOVERNORROLEReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGOVERNORROLEReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGUARDIANROLEReturn is a paid mutator transaction binding the contract method 0xd021c2e6.
//
// Solidity: function setGUARDIAN_ROLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGUARDIANROLEReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGUARDIAN_ROLEReturn", _value0)
}

// SetGUARDIANROLEReturn is a paid mutator transaction binding the contract method 0xd021c2e6.
//
// Solidity: function setGUARDIAN_ROLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGUARDIANROLEReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGUARDIANROLEReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGUARDIANROLEReturn is a paid mutator transaction binding the contract method 0xd021c2e6.
//
// Solidity: function setGUARDIAN_ROLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGUARDIANROLEReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGUARDIANROLEReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGasInfo is a paid mutator transaction binding the contract method 0x6c6e61a4.
//
// Solidity: function setGasInfo(address oracle, uint256 baseGasBatch, uint256 gasIncreasePerEntryBatch) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGasInfo(opts *bind.TransactOpts, oracle common.Address, baseGasBatch *big.Int, gasIncreasePerEntryBatch *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGasInfo", oracle, baseGasBatch, gasIncreasePerEntryBatch)
}

// SetGasInfo is a paid mutator transaction binding the contract method 0x6c6e61a4.
//
// Solidity: function setGasInfo(address oracle, uint256 baseGasBatch, uint256 gasIncreasePerEntryBatch) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGasInfo(oracle common.Address, baseGasBatch *big.Int, gasIncreasePerEntryBatch *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGasInfo(&_MockSuperGovernor.TransactOpts, oracle, baseGasBatch, gasIncreasePerEntryBatch)
}

// SetGasInfo is a paid mutator transaction binding the contract method 0x6c6e61a4.
//
// Solidity: function setGasInfo(address oracle, uint256 baseGasBatch, uint256 gasIncreasePerEntryBatch) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGasInfo(oracle common.Address, baseGasBatch *big.Int, gasIncreasePerEntryBatch *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGasInfo(&_MockSuperGovernor.TransactOpts, oracle, baseGasBatch, gasIncreasePerEntryBatch)
}

// SetGetActivePPSOracleReturn is a paid mutator transaction binding the contract method 0x41f5bc89.
//
// Solidity: function setGetActivePPSOracleReturn(address _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetActivePPSOracleReturn(opts *bind.TransactOpts, _value0 common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetActivePPSOracleReturn", _value0)
}

// SetGetActivePPSOracleReturn is a paid mutator transaction binding the contract method 0x41f5bc89.
//
// Solidity: function setGetActivePPSOracleReturn(address _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetActivePPSOracleReturn(_value0 common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetActivePPSOracleReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetActivePPSOracleReturn is a paid mutator transaction binding the contract method 0x41f5bc89.
//
// Solidity: function setGetActivePPSOracleReturn(address _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetActivePPSOracleReturn(_value0 common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetActivePPSOracleReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetAddressReturn is a paid mutator transaction binding the contract method 0x5701fabe.
//
// Solidity: function setGetAddressReturn(address _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetAddressReturn(opts *bind.TransactOpts, _value0 common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetAddressReturn", _value0)
}

// SetGetAddressReturn is a paid mutator transaction binding the contract method 0x5701fabe.
//
// Solidity: function setGetAddressReturn(address _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetAddressReturn(_value0 common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetAddressReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetAddressReturn is a paid mutator transaction binding the contract method 0x5701fabe.
//
// Solidity: function setGetAddressReturn(address _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetAddressReturn(_value0 common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetAddressReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetAllSuperformManagersReturn is a paid mutator transaction binding the contract method 0x37880f07.
//
// Solidity: function setGetAllSuperformManagersReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetAllSuperformManagersReturn(opts *bind.TransactOpts, _value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetAllSuperformManagersReturn", _value0)
}

// SetGetAllSuperformManagersReturn is a paid mutator transaction binding the contract method 0x37880f07.
//
// Solidity: function setGetAllSuperformManagersReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetAllSuperformManagersReturn(_value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetAllSuperformManagersReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetAllSuperformManagersReturn is a paid mutator transaction binding the contract method 0x37880f07.
//
// Solidity: function setGetAllSuperformManagersReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetAllSuperformManagersReturn(_value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetAllSuperformManagersReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetExecutorsReturn is a paid mutator transaction binding the contract method 0x88739a93.
//
// Solidity: function setGetExecutorsReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetExecutorsReturn(opts *bind.TransactOpts, _value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetExecutorsReturn", _value0)
}

// SetGetExecutorsReturn is a paid mutator transaction binding the contract method 0x88739a93.
//
// Solidity: function setGetExecutorsReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetExecutorsReturn(_value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetExecutorsReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetExecutorsReturn is a paid mutator transaction binding the contract method 0x88739a93.
//
// Solidity: function setGetExecutorsReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetExecutorsReturn(_value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetExecutorsReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetFeeReturn is a paid mutator transaction binding the contract method 0x9dad932d.
//
// Solidity: function setGetFeeReturn(uint256 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetFeeReturn(opts *bind.TransactOpts, _value0 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetFeeReturn", _value0)
}

// SetGetFeeReturn is a paid mutator transaction binding the contract method 0x9dad932d.
//
// Solidity: function setGetFeeReturn(uint256 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetFeeReturn(_value0 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetFeeReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetFeeReturn is a paid mutator transaction binding the contract method 0x9dad932d.
//
// Solidity: function setGetFeeReturn(uint256 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetFeeReturn(_value0 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetFeeReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetGasInfoReturn is a paid mutator transaction binding the contract method 0xf8609366.
//
// Solidity: function setGetGasInfoReturn((uint256,uint256) _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetGasInfoReturn(opts *bind.TransactOpts, _value0 MockSuperGovernorISuperGovernorGasInfo) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetGasInfoReturn", _value0)
}

// SetGetGasInfoReturn is a paid mutator transaction binding the contract method 0xf8609366.
//
// Solidity: function setGetGasInfoReturn((uint256,uint256) _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetGasInfoReturn(_value0 MockSuperGovernorISuperGovernorGasInfo) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetGasInfoReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetGasInfoReturn is a paid mutator transaction binding the contract method 0xf8609366.
//
// Solidity: function setGetGasInfoReturn((uint256,uint256) _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetGasInfoReturn(_value0 MockSuperGovernorISuperGovernorGasInfo) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetGasInfoReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetManagersPaginatedReturn is a paid mutator transaction binding the contract method 0x05f5933c.
//
// Solidity: function setGetManagersPaginatedReturn(address[] _value0, uint256 _value1) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetManagersPaginatedReturn(opts *bind.TransactOpts, _value0 []common.Address, _value1 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetManagersPaginatedReturn", _value0, _value1)
}

// SetGetManagersPaginatedReturn is a paid mutator transaction binding the contract method 0x05f5933c.
//
// Solidity: function setGetManagersPaginatedReturn(address[] _value0, uint256 _value1) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetManagersPaginatedReturn(_value0 []common.Address, _value1 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetManagersPaginatedReturn(&_MockSuperGovernor.TransactOpts, _value0, _value1)
}

// SetGetManagersPaginatedReturn is a paid mutator transaction binding the contract method 0x05f5933c.
//
// Solidity: function setGetManagersPaginatedReturn(address[] _value0, uint256 _value1) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetManagersPaginatedReturn(_value0 []common.Address, _value1 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetManagersPaginatedReturn(&_MockSuperGovernor.TransactOpts, _value0, _value1)
}

// SetGetMinStalenessReturn is a paid mutator transaction binding the contract method 0xc91ff5ed.
//
// Solidity: function setGetMinStalenessReturn(uint256 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetMinStalenessReturn(opts *bind.TransactOpts, _value0 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetMinStalenessReturn", _value0)
}

// SetGetMinStalenessReturn is a paid mutator transaction binding the contract method 0xc91ff5ed.
//
// Solidity: function setGetMinStalenessReturn(uint256 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetMinStalenessReturn(_value0 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetMinStalenessReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetMinStalenessReturn is a paid mutator transaction binding the contract method 0xc91ff5ed.
//
// Solidity: function setGetMinStalenessReturn(uint256 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetMinStalenessReturn(_value0 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetMinStalenessReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetPPSOracleQuorumReturn is a paid mutator transaction binding the contract method 0xae26a5a0.
//
// Solidity: function setGetPPSOracleQuorumReturn(uint256 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetPPSOracleQuorumReturn(opts *bind.TransactOpts, _value0 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetPPSOracleQuorumReturn", _value0)
}

// SetGetPPSOracleQuorumReturn is a paid mutator transaction binding the contract method 0xae26a5a0.
//
// Solidity: function setGetPPSOracleQuorumReturn(uint256 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetPPSOracleQuorumReturn(_value0 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetPPSOracleQuorumReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetPPSOracleQuorumReturn is a paid mutator transaction binding the contract method 0xae26a5a0.
//
// Solidity: function setGetPPSOracleQuorumReturn(uint256 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetPPSOracleQuorumReturn(_value0 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetPPSOracleQuorumReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetProposedActivePPSOracleReturn is a paid mutator transaction binding the contract method 0xc40ba40c.
//
// Solidity: function setGetProposedActivePPSOracleReturn(address _value0, uint256 _value1) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetProposedActivePPSOracleReturn(opts *bind.TransactOpts, _value0 common.Address, _value1 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetProposedActivePPSOracleReturn", _value0, _value1)
}

// SetGetProposedActivePPSOracleReturn is a paid mutator transaction binding the contract method 0xc40ba40c.
//
// Solidity: function setGetProposedActivePPSOracleReturn(address _value0, uint256 _value1) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetProposedActivePPSOracleReturn(_value0 common.Address, _value1 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetProposedActivePPSOracleReturn(&_MockSuperGovernor.TransactOpts, _value0, _value1)
}

// SetGetProposedActivePPSOracleReturn is a paid mutator transaction binding the contract method 0xc40ba40c.
//
// Solidity: function setGetProposedActivePPSOracleReturn(address _value0, uint256 _value1) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetProposedActivePPSOracleReturn(_value0 common.Address, _value1 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetProposedActivePPSOracleReturn(&_MockSuperGovernor.TransactOpts, _value0, _value1)
}

// SetGetProposedMinStalenessReturn is a paid mutator transaction binding the contract method 0x08e943c7.
//
// Solidity: function setGetProposedMinStalenessReturn(uint256 _value0, uint256 _value1) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetProposedMinStalenessReturn(opts *bind.TransactOpts, _value0 *big.Int, _value1 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetProposedMinStalenessReturn", _value0, _value1)
}

// SetGetProposedMinStalenessReturn is a paid mutator transaction binding the contract method 0x08e943c7.
//
// Solidity: function setGetProposedMinStalenessReturn(uint256 _value0, uint256 _value1) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetProposedMinStalenessReturn(_value0 *big.Int, _value1 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetProposedMinStalenessReturn(&_MockSuperGovernor.TransactOpts, _value0, _value1)
}

// SetGetProposedMinStalenessReturn is a paid mutator transaction binding the contract method 0x08e943c7.
//
// Solidity: function setGetProposedMinStalenessReturn(uint256 _value0, uint256 _value1) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetProposedMinStalenessReturn(_value0 *big.Int, _value1 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetProposedMinStalenessReturn(&_MockSuperGovernor.TransactOpts, _value0, _value1)
}

// SetGetProposedSuperBankHookMerkleRootReturn is a paid mutator transaction binding the contract method 0xe0890ae6.
//
// Solidity: function setGetProposedSuperBankHookMerkleRootReturn(bytes32 _value0, uint256 _value1) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetProposedSuperBankHookMerkleRootReturn(opts *bind.TransactOpts, _value0 [32]byte, _value1 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetProposedSuperBankHookMerkleRootReturn", _value0, _value1)
}

// SetGetProposedSuperBankHookMerkleRootReturn is a paid mutator transaction binding the contract method 0xe0890ae6.
//
// Solidity: function setGetProposedSuperBankHookMerkleRootReturn(bytes32 _value0, uint256 _value1) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetProposedSuperBankHookMerkleRootReturn(_value0 [32]byte, _value1 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetProposedSuperBankHookMerkleRootReturn(&_MockSuperGovernor.TransactOpts, _value0, _value1)
}

// SetGetProposedSuperBankHookMerkleRootReturn is a paid mutator transaction binding the contract method 0xe0890ae6.
//
// Solidity: function setGetProposedSuperBankHookMerkleRootReturn(bytes32 _value0, uint256 _value1) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetProposedSuperBankHookMerkleRootReturn(_value0 [32]byte, _value1 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetProposedSuperBankHookMerkleRootReturn(&_MockSuperGovernor.TransactOpts, _value0, _value1)
}

// SetGetProposedUpkeepPaymentsStatusReturn is a paid mutator transaction binding the contract method 0x0f644834.
//
// Solidity: function setGetProposedUpkeepPaymentsStatusReturn(bool _value0, uint256 _value1) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetProposedUpkeepPaymentsStatusReturn(opts *bind.TransactOpts, _value0 bool, _value1 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetProposedUpkeepPaymentsStatusReturn", _value0, _value1)
}

// SetGetProposedUpkeepPaymentsStatusReturn is a paid mutator transaction binding the contract method 0x0f644834.
//
// Solidity: function setGetProposedUpkeepPaymentsStatusReturn(bool _value0, uint256 _value1) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetProposedUpkeepPaymentsStatusReturn(_value0 bool, _value1 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetProposedUpkeepPaymentsStatusReturn(&_MockSuperGovernor.TransactOpts, _value0, _value1)
}

// SetGetProposedUpkeepPaymentsStatusReturn is a paid mutator transaction binding the contract method 0x0f644834.
//
// Solidity: function setGetProposedUpkeepPaymentsStatusReturn(bool _value0, uint256 _value1) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetProposedUpkeepPaymentsStatusReturn(_value0 bool, _value1 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetProposedUpkeepPaymentsStatusReturn(&_MockSuperGovernor.TransactOpts, _value0, _value1)
}

// SetGetProposedVaultBankHookMerkleRootReturn is a paid mutator transaction binding the contract method 0xa995de0d.
//
// Solidity: function setGetProposedVaultBankHookMerkleRootReturn(bytes32 _value0, uint256 _value1) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetProposedVaultBankHookMerkleRootReturn(opts *bind.TransactOpts, _value0 [32]byte, _value1 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetProposedVaultBankHookMerkleRootReturn", _value0, _value1)
}

// SetGetProposedVaultBankHookMerkleRootReturn is a paid mutator transaction binding the contract method 0xa995de0d.
//
// Solidity: function setGetProposedVaultBankHookMerkleRootReturn(bytes32 _value0, uint256 _value1) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetProposedVaultBankHookMerkleRootReturn(_value0 [32]byte, _value1 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetProposedVaultBankHookMerkleRootReturn(&_MockSuperGovernor.TransactOpts, _value0, _value1)
}

// SetGetProposedVaultBankHookMerkleRootReturn is a paid mutator transaction binding the contract method 0xa995de0d.
//
// Solidity: function setGetProposedVaultBankHookMerkleRootReturn(bytes32 _value0, uint256 _value1) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetProposedVaultBankHookMerkleRootReturn(_value0 [32]byte, _value1 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetProposedVaultBankHookMerkleRootReturn(&_MockSuperGovernor.TransactOpts, _value0, _value1)
}

// SetGetProtectedKeepersCountReturn is a paid mutator transaction binding the contract method 0xcaf01e9f.
//
// Solidity: function setGetProtectedKeepersCountReturn(uint256 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetProtectedKeepersCountReturn(opts *bind.TransactOpts, _value0 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetProtectedKeepersCountReturn", _value0)
}

// SetGetProtectedKeepersCountReturn is a paid mutator transaction binding the contract method 0xcaf01e9f.
//
// Solidity: function setGetProtectedKeepersCountReturn(uint256 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetProtectedKeepersCountReturn(_value0 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetProtectedKeepersCountReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetProtectedKeepersCountReturn is a paid mutator transaction binding the contract method 0xcaf01e9f.
//
// Solidity: function setGetProtectedKeepersCountReturn(uint256 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetProtectedKeepersCountReturn(_value0 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetProtectedKeepersCountReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetProtectedKeepersReturn is a paid mutator transaction binding the contract method 0x7d321e26.
//
// Solidity: function setGetProtectedKeepersReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetProtectedKeepersReturn(opts *bind.TransactOpts, _value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetProtectedKeepersReturn", _value0)
}

// SetGetProtectedKeepersReturn is a paid mutator transaction binding the contract method 0x7d321e26.
//
// Solidity: function setGetProtectedKeepersReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetProtectedKeepersReturn(_value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetProtectedKeepersReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetProtectedKeepersReturn is a paid mutator transaction binding the contract method 0x7d321e26.
//
// Solidity: function setGetProtectedKeepersReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetProtectedKeepersReturn(_value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetProtectedKeepersReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetProverReturn is a paid mutator transaction binding the contract method 0x9b6dbe57.
//
// Solidity: function setGetProverReturn(address _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetProverReturn(opts *bind.TransactOpts, _value0 common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetProverReturn", _value0)
}

// SetGetProverReturn is a paid mutator transaction binding the contract method 0x9b6dbe57.
//
// Solidity: function setGetProverReturn(address _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetProverReturn(_value0 common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetProverReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetProverReturn is a paid mutator transaction binding the contract method 0x9b6dbe57.
//
// Solidity: function setGetProverReturn(address _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetProverReturn(_value0 common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetProverReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetRegisteredFulfillRequestsHooksReturn is a paid mutator transaction binding the contract method 0x31d01b31.
//
// Solidity: function setGetRegisteredFulfillRequestsHooksReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetRegisteredFulfillRequestsHooksReturn(opts *bind.TransactOpts, _value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetRegisteredFulfillRequestsHooksReturn", _value0)
}

// SetGetRegisteredFulfillRequestsHooksReturn is a paid mutator transaction binding the contract method 0x31d01b31.
//
// Solidity: function setGetRegisteredFulfillRequestsHooksReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetRegisteredFulfillRequestsHooksReturn(_value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetRegisteredFulfillRequestsHooksReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetRegisteredFulfillRequestsHooksReturn is a paid mutator transaction binding the contract method 0x31d01b31.
//
// Solidity: function setGetRegisteredFulfillRequestsHooksReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetRegisteredFulfillRequestsHooksReturn(_value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetRegisteredFulfillRequestsHooksReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetRegisteredHooksReturn is a paid mutator transaction binding the contract method 0xe9e20a50.
//
// Solidity: function setGetRegisteredHooksReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetRegisteredHooksReturn(opts *bind.TransactOpts, _value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetRegisteredHooksReturn", _value0)
}

// SetGetRegisteredHooksReturn is a paid mutator transaction binding the contract method 0xe9e20a50.
//
// Solidity: function setGetRegisteredHooksReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetRegisteredHooksReturn(_value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetRegisteredHooksReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetRegisteredHooksReturn is a paid mutator transaction binding the contract method 0xe9e20a50.
//
// Solidity: function setGetRegisteredHooksReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetRegisteredHooksReturn(_value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetRegisteredHooksReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetRelayersReturn is a paid mutator transaction binding the contract method 0xb58d9a73.
//
// Solidity: function setGetRelayersReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetRelayersReturn(opts *bind.TransactOpts, _value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetRelayersReturn", _value0)
}

// SetGetRelayersReturn is a paid mutator transaction binding the contract method 0xb58d9a73.
//
// Solidity: function setGetRelayersReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetRelayersReturn(_value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetRelayersReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetRelayersReturn is a paid mutator transaction binding the contract method 0xb58d9a73.
//
// Solidity: function setGetRelayersReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetRelayersReturn(_value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetRelayersReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetRoleAdminReturn is a paid mutator transaction binding the contract method 0x7581d416.
//
// Solidity: function setGetRoleAdminReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetRoleAdminReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetRoleAdminReturn", _value0)
}

// SetGetRoleAdminReturn is a paid mutator transaction binding the contract method 0x7581d416.
//
// Solidity: function setGetRoleAdminReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetRoleAdminReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetRoleAdminReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetRoleAdminReturn is a paid mutator transaction binding the contract method 0x7581d416.
//
// Solidity: function setGetRoleAdminReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetRoleAdminReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetRoleAdminReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetSuperBankHookMerkleRootReturn is a paid mutator transaction binding the contract method 0x5eb0137e.
//
// Solidity: function setGetSuperBankHookMerkleRootReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetSuperBankHookMerkleRootReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetSuperBankHookMerkleRootReturn", _value0)
}

// SetGetSuperBankHookMerkleRootReturn is a paid mutator transaction binding the contract method 0x5eb0137e.
//
// Solidity: function setGetSuperBankHookMerkleRootReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetSuperBankHookMerkleRootReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetSuperBankHookMerkleRootReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetSuperBankHookMerkleRootReturn is a paid mutator transaction binding the contract method 0x5eb0137e.
//
// Solidity: function setGetSuperBankHookMerkleRootReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetSuperBankHookMerkleRootReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetSuperBankHookMerkleRootReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetSuperformManagersCountReturn is a paid mutator transaction binding the contract method 0xd72d3764.
//
// Solidity: function setGetSuperformManagersCountReturn(uint256 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetSuperformManagersCountReturn(opts *bind.TransactOpts, _value0 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetSuperformManagersCountReturn", _value0)
}

// SetGetSuperformManagersCountReturn is a paid mutator transaction binding the contract method 0xd72d3764.
//
// Solidity: function setGetSuperformManagersCountReturn(uint256 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetSuperformManagersCountReturn(_value0 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetSuperformManagersCountReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetSuperformManagersCountReturn is a paid mutator transaction binding the contract method 0xd72d3764.
//
// Solidity: function setGetSuperformManagersCountReturn(uint256 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetSuperformManagersCountReturn(_value0 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetSuperformManagersCountReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetUpkeepCostPerBatchUpdateReturn is a paid mutator transaction binding the contract method 0xeae0cb1c.
//
// Solidity: function setGetUpkeepCostPerBatchUpdateReturn(uint256 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetUpkeepCostPerBatchUpdateReturn(opts *bind.TransactOpts, _value0 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetUpkeepCostPerBatchUpdateReturn", _value0)
}

// SetGetUpkeepCostPerBatchUpdateReturn is a paid mutator transaction binding the contract method 0xeae0cb1c.
//
// Solidity: function setGetUpkeepCostPerBatchUpdateReturn(uint256 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetUpkeepCostPerBatchUpdateReturn(_value0 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetUpkeepCostPerBatchUpdateReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetUpkeepCostPerBatchUpdateReturn is a paid mutator transaction binding the contract method 0xeae0cb1c.
//
// Solidity: function setGetUpkeepCostPerBatchUpdateReturn(uint256 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetUpkeepCostPerBatchUpdateReturn(_value0 *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetUpkeepCostPerBatchUpdateReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetValidatorsReturn is a paid mutator transaction binding the contract method 0x5d094355.
//
// Solidity: function setGetValidatorsReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetValidatorsReturn(opts *bind.TransactOpts, _value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetValidatorsReturn", _value0)
}

// SetGetValidatorsReturn is a paid mutator transaction binding the contract method 0x5d094355.
//
// Solidity: function setGetValidatorsReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetValidatorsReturn(_value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetValidatorsReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetValidatorsReturn is a paid mutator transaction binding the contract method 0x5d094355.
//
// Solidity: function setGetValidatorsReturn(address[] _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetValidatorsReturn(_value0 []common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetValidatorsReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetVaultBankHookMerkleRootReturn is a paid mutator transaction binding the contract method 0x3bb0d6e3.
//
// Solidity: function setGetVaultBankHookMerkleRootReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetVaultBankHookMerkleRootReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetVaultBankHookMerkleRootReturn", _value0)
}

// SetGetVaultBankHookMerkleRootReturn is a paid mutator transaction binding the contract method 0x3bb0d6e3.
//
// Solidity: function setGetVaultBankHookMerkleRootReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetVaultBankHookMerkleRootReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetVaultBankHookMerkleRootReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetVaultBankHookMerkleRootReturn is a paid mutator transaction binding the contract method 0x3bb0d6e3.
//
// Solidity: function setGetVaultBankHookMerkleRootReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetVaultBankHookMerkleRootReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetVaultBankHookMerkleRootReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetVaultBankReturn is a paid mutator transaction binding the contract method 0x1ad663d9.
//
// Solidity: function setGetVaultBankReturn(address _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGetVaultBankReturn(opts *bind.TransactOpts, _value0 common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGetVaultBankReturn", _value0)
}

// SetGetVaultBankReturn is a paid mutator transaction binding the contract method 0x1ad663d9.
//
// Solidity: function setGetVaultBankReturn(address _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGetVaultBankReturn(_value0 common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetVaultBankReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGetVaultBankReturn is a paid mutator transaction binding the contract method 0x1ad663d9.
//
// Solidity: function setGetVaultBankReturn(address _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGetVaultBankReturn(_value0 common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGetVaultBankReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetGlobalHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xd5f3cd86.
//
// Solidity: function setGlobalHooksRootVetoStatus(bool vetoed) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetGlobalHooksRootVetoStatus(opts *bind.TransactOpts, vetoed bool) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setGlobalHooksRootVetoStatus", vetoed)
}

// SetGlobalHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xd5f3cd86.
//
// Solidity: function setGlobalHooksRootVetoStatus(bool vetoed) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetGlobalHooksRootVetoStatus(vetoed bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGlobalHooksRootVetoStatus(&_MockSuperGovernor.TransactOpts, vetoed)
}

// SetGlobalHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xd5f3cd86.
//
// Solidity: function setGlobalHooksRootVetoStatus(bool vetoed) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetGlobalHooksRootVetoStatus(vetoed bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetGlobalHooksRootVetoStatus(&_MockSuperGovernor.TransactOpts, vetoed)
}

// SetHasRoleReturn is a paid mutator transaction binding the contract method 0x9de3a269.
//
// Solidity: function setHasRoleReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetHasRoleReturn(opts *bind.TransactOpts, _value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setHasRoleReturn", _value0)
}

// SetHasRoleReturn is a paid mutator transaction binding the contract method 0x9de3a269.
//
// Solidity: function setHasRoleReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetHasRoleReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetHasRoleReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetHasRoleReturn is a paid mutator transaction binding the contract method 0x9de3a269.
//
// Solidity: function setHasRoleReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetHasRoleReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetHasRoleReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsActivePPSOracleReturn is a paid mutator transaction binding the contract method 0xda6203bb.
//
// Solidity: function setIsActivePPSOracleReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetIsActivePPSOracleReturn(opts *bind.TransactOpts, _value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setIsActivePPSOracleReturn", _value0)
}

// SetIsActivePPSOracleReturn is a paid mutator transaction binding the contract method 0xda6203bb.
//
// Solidity: function setIsActivePPSOracleReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetIsActivePPSOracleReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsActivePPSOracleReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsActivePPSOracleReturn is a paid mutator transaction binding the contract method 0xda6203bb.
//
// Solidity: function setIsActivePPSOracleReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetIsActivePPSOracleReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsActivePPSOracleReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsExecutorReturn is a paid mutator transaction binding the contract method 0x83d4eb98.
//
// Solidity: function setIsExecutorReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetIsExecutorReturn(opts *bind.TransactOpts, _value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setIsExecutorReturn", _value0)
}

// SetIsExecutorReturn is a paid mutator transaction binding the contract method 0x83d4eb98.
//
// Solidity: function setIsExecutorReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetIsExecutorReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsExecutorReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsExecutorReturn is a paid mutator transaction binding the contract method 0x83d4eb98.
//
// Solidity: function setIsExecutorReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetIsExecutorReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsExecutorReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsFulfillRequestsHookRegisteredReturn is a paid mutator transaction binding the contract method 0x0fc847b7.
//
// Solidity: function setIsFulfillRequestsHookRegisteredReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetIsFulfillRequestsHookRegisteredReturn(opts *bind.TransactOpts, _value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setIsFulfillRequestsHookRegisteredReturn", _value0)
}

// SetIsFulfillRequestsHookRegisteredReturn is a paid mutator transaction binding the contract method 0x0fc847b7.
//
// Solidity: function setIsFulfillRequestsHookRegisteredReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetIsFulfillRequestsHookRegisteredReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsFulfillRequestsHookRegisteredReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsFulfillRequestsHookRegisteredReturn is a paid mutator transaction binding the contract method 0x0fc847b7.
//
// Solidity: function setIsFulfillRequestsHookRegisteredReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetIsFulfillRequestsHookRegisteredReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsFulfillRequestsHookRegisteredReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsGuardianReturn is a paid mutator transaction binding the contract method 0x6a7e83bb.
//
// Solidity: function setIsGuardianReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetIsGuardianReturn(opts *bind.TransactOpts, _value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setIsGuardianReturn", _value0)
}

// SetIsGuardianReturn is a paid mutator transaction binding the contract method 0x6a7e83bb.
//
// Solidity: function setIsGuardianReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetIsGuardianReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsGuardianReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsGuardianReturn is a paid mutator transaction binding the contract method 0x6a7e83bb.
//
// Solidity: function setIsGuardianReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetIsGuardianReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsGuardianReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsHookRegisteredReturn is a paid mutator transaction binding the contract method 0xb3d8ffe4.
//
// Solidity: function setIsHookRegisteredReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetIsHookRegisteredReturn(opts *bind.TransactOpts, _value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setIsHookRegisteredReturn", _value0)
}

// SetIsHookRegisteredReturn is a paid mutator transaction binding the contract method 0xb3d8ffe4.
//
// Solidity: function setIsHookRegisteredReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetIsHookRegisteredReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsHookRegisteredReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsHookRegisteredReturn is a paid mutator transaction binding the contract method 0xb3d8ffe4.
//
// Solidity: function setIsHookRegisteredReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetIsHookRegisteredReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsHookRegisteredReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsManagerTakeoverFrozenReturn is a paid mutator transaction binding the contract method 0x7fa54e7d.
//
// Solidity: function setIsManagerTakeoverFrozenReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetIsManagerTakeoverFrozenReturn(opts *bind.TransactOpts, _value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setIsManagerTakeoverFrozenReturn", _value0)
}

// SetIsManagerTakeoverFrozenReturn is a paid mutator transaction binding the contract method 0x7fa54e7d.
//
// Solidity: function setIsManagerTakeoverFrozenReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetIsManagerTakeoverFrozenReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsManagerTakeoverFrozenReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsManagerTakeoverFrozenReturn is a paid mutator transaction binding the contract method 0x7fa54e7d.
//
// Solidity: function setIsManagerTakeoverFrozenReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetIsManagerTakeoverFrozenReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsManagerTakeoverFrozenReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsProtectedKeeperReturn is a paid mutator transaction binding the contract method 0xf978d6d7.
//
// Solidity: function setIsProtectedKeeperReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetIsProtectedKeeperReturn(opts *bind.TransactOpts, _value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setIsProtectedKeeperReturn", _value0)
}

// SetIsProtectedKeeperReturn is a paid mutator transaction binding the contract method 0xf978d6d7.
//
// Solidity: function setIsProtectedKeeperReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetIsProtectedKeeperReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsProtectedKeeperReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsProtectedKeeperReturn is a paid mutator transaction binding the contract method 0xf978d6d7.
//
// Solidity: function setIsProtectedKeeperReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetIsProtectedKeeperReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsProtectedKeeperReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsRelayerReturn is a paid mutator transaction binding the contract method 0xec2d9380.
//
// Solidity: function setIsRelayerReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetIsRelayerReturn(opts *bind.TransactOpts, _value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setIsRelayerReturn", _value0)
}

// SetIsRelayerReturn is a paid mutator transaction binding the contract method 0xec2d9380.
//
// Solidity: function setIsRelayerReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetIsRelayerReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsRelayerReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsRelayerReturn is a paid mutator transaction binding the contract method 0xec2d9380.
//
// Solidity: function setIsRelayerReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetIsRelayerReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsRelayerReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsSuperformManagerReturn is a paid mutator transaction binding the contract method 0x5bbe8bdc.
//
// Solidity: function setIsSuperformManagerReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetIsSuperformManagerReturn(opts *bind.TransactOpts, _value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setIsSuperformManagerReturn", _value0)
}

// SetIsSuperformManagerReturn is a paid mutator transaction binding the contract method 0x5bbe8bdc.
//
// Solidity: function setIsSuperformManagerReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetIsSuperformManagerReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsSuperformManagerReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsSuperformManagerReturn is a paid mutator transaction binding the contract method 0x5bbe8bdc.
//
// Solidity: function setIsSuperformManagerReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetIsSuperformManagerReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsSuperformManagerReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsUpkeepPaymentsEnabledReturn is a paid mutator transaction binding the contract method 0x5b24c4af.
//
// Solidity: function setIsUpkeepPaymentsEnabledReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetIsUpkeepPaymentsEnabledReturn(opts *bind.TransactOpts, _value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setIsUpkeepPaymentsEnabledReturn", _value0)
}

// SetIsUpkeepPaymentsEnabledReturn is a paid mutator transaction binding the contract method 0x5b24c4af.
//
// Solidity: function setIsUpkeepPaymentsEnabledReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetIsUpkeepPaymentsEnabledReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsUpkeepPaymentsEnabledReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsUpkeepPaymentsEnabledReturn is a paid mutator transaction binding the contract method 0x5b24c4af.
//
// Solidity: function setIsUpkeepPaymentsEnabledReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetIsUpkeepPaymentsEnabledReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsUpkeepPaymentsEnabledReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsValidatorReturn is a paid mutator transaction binding the contract method 0x840a94bb.
//
// Solidity: function setIsValidatorReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetIsValidatorReturn(opts *bind.TransactOpts, _value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setIsValidatorReturn", _value0)
}

// SetIsValidatorReturn is a paid mutator transaction binding the contract method 0x840a94bb.
//
// Solidity: function setIsValidatorReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetIsValidatorReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsValidatorReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsValidatorReturn is a paid mutator transaction binding the contract method 0x840a94bb.
//
// Solidity: function setIsValidatorReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetIsValidatorReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsValidatorReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsWhitelistedIncentiveTokenReturn is a paid mutator transaction binding the contract method 0x5bb5fdac.
//
// Solidity: function setIsWhitelistedIncentiveTokenReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetIsWhitelistedIncentiveTokenReturn(opts *bind.TransactOpts, _value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setIsWhitelistedIncentiveTokenReturn", _value0)
}

// SetIsWhitelistedIncentiveTokenReturn is a paid mutator transaction binding the contract method 0x5bb5fdac.
//
// Solidity: function setIsWhitelistedIncentiveTokenReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetIsWhitelistedIncentiveTokenReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsWhitelistedIncentiveTokenReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetIsWhitelistedIncentiveTokenReturn is a paid mutator transaction binding the contract method 0x5bb5fdac.
//
// Solidity: function setIsWhitelistedIncentiveTokenReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetIsWhitelistedIncentiveTokenReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetIsWhitelistedIncentiveTokenReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetOracleFeedMaxStaleness is a paid mutator transaction binding the contract method 0x17a79fa6.
//
// Solidity: function setOracleFeedMaxStaleness(address feed, uint256 newMaxStaleness) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetOracleFeedMaxStaleness(opts *bind.TransactOpts, feed common.Address, newMaxStaleness *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setOracleFeedMaxStaleness", feed, newMaxStaleness)
}

// SetOracleFeedMaxStaleness is a paid mutator transaction binding the contract method 0x17a79fa6.
//
// Solidity: function setOracleFeedMaxStaleness(address feed, uint256 newMaxStaleness) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetOracleFeedMaxStaleness(feed common.Address, newMaxStaleness *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetOracleFeedMaxStaleness(&_MockSuperGovernor.TransactOpts, feed, newMaxStaleness)
}

// SetOracleFeedMaxStaleness is a paid mutator transaction binding the contract method 0x17a79fa6.
//
// Solidity: function setOracleFeedMaxStaleness(address feed, uint256 newMaxStaleness) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetOracleFeedMaxStaleness(feed common.Address, newMaxStaleness *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetOracleFeedMaxStaleness(&_MockSuperGovernor.TransactOpts, feed, newMaxStaleness)
}

// SetOracleFeedMaxStalenessBatch is a paid mutator transaction binding the contract method 0x3fa9fe64.
//
// Solidity: function setOracleFeedMaxStalenessBatch(address[] feeds_, uint256[] newMaxStalenessList_) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetOracleFeedMaxStalenessBatch(opts *bind.TransactOpts, feeds_ []common.Address, newMaxStalenessList_ []*big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setOracleFeedMaxStalenessBatch", feeds_, newMaxStalenessList_)
}

// SetOracleFeedMaxStalenessBatch is a paid mutator transaction binding the contract method 0x3fa9fe64.
//
// Solidity: function setOracleFeedMaxStalenessBatch(address[] feeds_, uint256[] newMaxStalenessList_) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetOracleFeedMaxStalenessBatch(feeds_ []common.Address, newMaxStalenessList_ []*big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetOracleFeedMaxStalenessBatch(&_MockSuperGovernor.TransactOpts, feeds_, newMaxStalenessList_)
}

// SetOracleFeedMaxStalenessBatch is a paid mutator transaction binding the contract method 0x3fa9fe64.
//
// Solidity: function setOracleFeedMaxStalenessBatch(address[] feeds_, uint256[] newMaxStalenessList_) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetOracleFeedMaxStalenessBatch(feeds_ []common.Address, newMaxStalenessList_ []*big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetOracleFeedMaxStalenessBatch(&_MockSuperGovernor.TransactOpts, feeds_, newMaxStalenessList_)
}

// SetOracleMaxStaleness is a paid mutator transaction binding the contract method 0x324341ed.
//
// Solidity: function setOracleMaxStaleness(uint256 newMaxStaleness) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetOracleMaxStaleness(opts *bind.TransactOpts, newMaxStaleness *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setOracleMaxStaleness", newMaxStaleness)
}

// SetOracleMaxStaleness is a paid mutator transaction binding the contract method 0x324341ed.
//
// Solidity: function setOracleMaxStaleness(uint256 newMaxStaleness) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetOracleMaxStaleness(newMaxStaleness *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetOracleMaxStaleness(&_MockSuperGovernor.TransactOpts, newMaxStaleness)
}

// SetOracleMaxStaleness is a paid mutator transaction binding the contract method 0x324341ed.
//
// Solidity: function setOracleMaxStaleness(uint256 newMaxStaleness) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetOracleMaxStaleness(newMaxStaleness *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetOracleMaxStaleness(&_MockSuperGovernor.TransactOpts, newMaxStaleness)
}

// SetPPSOracleQuorum is a paid mutator transaction binding the contract method 0x52da1de3.
//
// Solidity: function setPPSOracleQuorum(uint256 quorum) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetPPSOracleQuorum(opts *bind.TransactOpts, quorum *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setPPSOracleQuorum", quorum)
}

// SetPPSOracleQuorum is a paid mutator transaction binding the contract method 0x52da1de3.
//
// Solidity: function setPPSOracleQuorum(uint256 quorum) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetPPSOracleQuorum(quorum *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetPPSOracleQuorum(&_MockSuperGovernor.TransactOpts, quorum)
}

// SetPPSOracleQuorum is a paid mutator transaction binding the contract method 0x52da1de3.
//
// Solidity: function setPPSOracleQuorum(uint256 quorum) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetPPSOracleQuorum(quorum *big.Int) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetPPSOracleQuorum(&_MockSuperGovernor.TransactOpts, quorum)
}

// SetProver is a paid mutator transaction binding the contract method 0xcbda2992.
//
// Solidity: function setProver(address prover) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetProver(opts *bind.TransactOpts, prover common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setProver", prover)
}

// SetProver is a paid mutator transaction binding the contract method 0xcbda2992.
//
// Solidity: function setProver(address prover) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetProver(prover common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetProver(&_MockSuperGovernor.TransactOpts, prover)
}

// SetProver is a paid mutator transaction binding the contract method 0xcbda2992.
//
// Solidity: function setProver(address prover) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetProver(prover common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetProver(&_MockSuperGovernor.TransactOpts, prover)
}

// SetSUPERASSETFACTORYReturn is a paid mutator transaction binding the contract method 0x87cf0956.
//
// Solidity: function setSUPER_ASSET_FACTORYReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetSUPERASSETFACTORYReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setSUPER_ASSET_FACTORYReturn", _value0)
}

// SetSUPERASSETFACTORYReturn is a paid mutator transaction binding the contract method 0x87cf0956.
//
// Solidity: function setSUPER_ASSET_FACTORYReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetSUPERASSETFACTORYReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetSUPERASSETFACTORYReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetSUPERASSETFACTORYReturn is a paid mutator transaction binding the contract method 0x87cf0956.
//
// Solidity: function setSUPER_ASSET_FACTORYReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetSUPERASSETFACTORYReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetSUPERASSETFACTORYReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetSUPERBANKReturn is a paid mutator transaction binding the contract method 0xa4e68489.
//
// Solidity: function setSUPER_BANKReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetSUPERBANKReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setSUPER_BANKReturn", _value0)
}

// SetSUPERBANKReturn is a paid mutator transaction binding the contract method 0xa4e68489.
//
// Solidity: function setSUPER_BANKReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetSUPERBANKReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetSUPERBANKReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetSUPERBANKReturn is a paid mutator transaction binding the contract method 0xa4e68489.
//
// Solidity: function setSUPER_BANKReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetSUPERBANKReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetSUPERBANKReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetSUPERGOVERNORROLEReturn is a paid mutator transaction binding the contract method 0xd993b8e7.
//
// Solidity: function setSUPER_GOVERNOR_ROLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetSUPERGOVERNORROLEReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setSUPER_GOVERNOR_ROLEReturn", _value0)
}

// SetSUPERGOVERNORROLEReturn is a paid mutator transaction binding the contract method 0xd993b8e7.
//
// Solidity: function setSUPER_GOVERNOR_ROLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetSUPERGOVERNORROLEReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetSUPERGOVERNORROLEReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetSUPERGOVERNORROLEReturn is a paid mutator transaction binding the contract method 0xd993b8e7.
//
// Solidity: function setSUPER_GOVERNOR_ROLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetSUPERGOVERNORROLEReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetSUPERGOVERNORROLEReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetSUPERORACLEReturn is a paid mutator transaction binding the contract method 0x2a7fe70b.
//
// Solidity: function setSUPER_ORACLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetSUPERORACLEReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setSUPER_ORACLEReturn", _value0)
}

// SetSUPERORACLEReturn is a paid mutator transaction binding the contract method 0x2a7fe70b.
//
// Solidity: function setSUPER_ORACLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetSUPERORACLEReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetSUPERORACLEReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetSUPERORACLEReturn is a paid mutator transaction binding the contract method 0x2a7fe70b.
//
// Solidity: function setSUPER_ORACLEReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetSUPERORACLEReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetSUPERORACLEReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetSUPERVAULTAGGREGATORReturn is a paid mutator transaction binding the contract method 0xce285c34.
//
// Solidity: function setSUPER_VAULT_AGGREGATORReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetSUPERVAULTAGGREGATORReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setSUPER_VAULT_AGGREGATORReturn", _value0)
}

// SetSUPERVAULTAGGREGATORReturn is a paid mutator transaction binding the contract method 0xce285c34.
//
// Solidity: function setSUPER_VAULT_AGGREGATORReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetSUPERVAULTAGGREGATORReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetSUPERVAULTAGGREGATORReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetSUPERVAULTAGGREGATORReturn is a paid mutator transaction binding the contract method 0xce285c34.
//
// Solidity: function setSUPER_VAULT_AGGREGATORReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetSUPERVAULTAGGREGATORReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetSUPERVAULTAGGREGATORReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetSUPReturn is a paid mutator transaction binding the contract method 0xfb552128.
//
// Solidity: function setSUPReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetSUPReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setSUPReturn", _value0)
}

// SetSUPReturn is a paid mutator transaction binding the contract method 0xfb552128.
//
// Solidity: function setSUPReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetSUPReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetSUPReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetSUPReturn is a paid mutator transaction binding the contract method 0xfb552128.
//
// Solidity: function setSUPReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetSUPReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetSUPReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetStrategyHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xf5297a47.
//
// Solidity: function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetStrategyHooksRootVetoStatus(opts *bind.TransactOpts, strategy common.Address, vetoed bool) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setStrategyHooksRootVetoStatus", strategy, vetoed)
}

// SetStrategyHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xf5297a47.
//
// Solidity: function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetStrategyHooksRootVetoStatus(strategy common.Address, vetoed bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetStrategyHooksRootVetoStatus(&_MockSuperGovernor.TransactOpts, strategy, vetoed)
}

// SetStrategyHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xf5297a47.
//
// Solidity: function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetStrategyHooksRootVetoStatus(strategy common.Address, vetoed bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetStrategyHooksRootVetoStatus(&_MockSuperGovernor.TransactOpts, strategy, vetoed)
}

// SetSuperAssetManager is a paid mutator transaction binding the contract method 0xe778f632.
//
// Solidity: function setSuperAssetManager(address superAsset, address superAssetManager) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetSuperAssetManager(opts *bind.TransactOpts, superAsset common.Address, superAssetManager common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setSuperAssetManager", superAsset, superAssetManager)
}

// SetSuperAssetManager is a paid mutator transaction binding the contract method 0xe778f632.
//
// Solidity: function setSuperAssetManager(address superAsset, address superAssetManager) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetSuperAssetManager(superAsset common.Address, superAssetManager common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetSuperAssetManager(&_MockSuperGovernor.TransactOpts, superAsset, superAssetManager)
}

// SetSuperAssetManager is a paid mutator transaction binding the contract method 0xe778f632.
//
// Solidity: function setSuperAssetManager(address superAsset, address superAssetManager) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetSuperAssetManager(superAsset common.Address, superAssetManager common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetSuperAssetManager(&_MockSuperGovernor.TransactOpts, superAsset, superAssetManager)
}

// SetSupportsInterfaceReturn is a paid mutator transaction binding the contract method 0xe1ed1366.
//
// Solidity: function setSupportsInterfaceReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetSupportsInterfaceReturn(opts *bind.TransactOpts, _value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setSupportsInterfaceReturn", _value0)
}

// SetSupportsInterfaceReturn is a paid mutator transaction binding the contract method 0xe1ed1366.
//
// Solidity: function setSupportsInterfaceReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetSupportsInterfaceReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetSupportsInterfaceReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetSupportsInterfaceReturn is a paid mutator transaction binding the contract method 0xe1ed1366.
//
// Solidity: function setSupportsInterfaceReturn(bool _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetSupportsInterfaceReturn(_value0 bool) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetSupportsInterfaceReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetTREASURYReturn is a paid mutator transaction binding the contract method 0x5218f8bb.
//
// Solidity: function setTREASURYReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetTREASURYReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setTREASURYReturn", _value0)
}

// SetTREASURYReturn is a paid mutator transaction binding the contract method 0x5218f8bb.
//
// Solidity: function setTREASURYReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetTREASURYReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetTREASURYReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetTREASURYReturn is a paid mutator transaction binding the contract method 0x5218f8bb.
//
// Solidity: function setTREASURYReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetTREASURYReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetTREASURYReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetUPReturn is a paid mutator transaction binding the contract method 0x0b10ce61.
//
// Solidity: function setUPReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetUPReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setUPReturn", _value0)
}

// SetUPReturn is a paid mutator transaction binding the contract method 0x0b10ce61.
//
// Solidity: function setUPReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetUPReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetUPReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetUPReturn is a paid mutator transaction binding the contract method 0x0b10ce61.
//
// Solidity: function setUPReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetUPReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetUPReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetVAULTBANKReturn is a paid mutator transaction binding the contract method 0xa30da33f.
//
// Solidity: function setVAULT_BANKReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) SetVAULTBANKReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "setVAULT_BANKReturn", _value0)
}

// SetVAULTBANKReturn is a paid mutator transaction binding the contract method 0xa30da33f.
//
// Solidity: function setVAULT_BANKReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) SetVAULTBANKReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetVAULTBANKReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// SetVAULTBANKReturn is a paid mutator transaction binding the contract method 0xa30da33f.
//
// Solidity: function setVAULT_BANKReturn(bytes32 _value0) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) SetVAULTBANKReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.SetVAULTBANKReturn(&_MockSuperGovernor.TransactOpts, _value0)
}

// UnregisterHook is a paid mutator transaction binding the contract method 0xf76f48cb.
//
// Solidity: function unregisterHook(address hook) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) UnregisterHook(opts *bind.TransactOpts, hook common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "unregisterHook", hook)
}

// UnregisterHook is a paid mutator transaction binding the contract method 0xf76f48cb.
//
// Solidity: function unregisterHook(address hook) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) UnregisterHook(hook common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.UnregisterHook(&_MockSuperGovernor.TransactOpts, hook)
}

// UnregisterHook is a paid mutator transaction binding the contract method 0xf76f48cb.
//
// Solidity: function unregisterHook(address hook) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) UnregisterHook(hook common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.UnregisterHook(&_MockSuperGovernor.TransactOpts, hook)
}

// UnregisterProtectedKeeper is a paid mutator transaction binding the contract method 0xa390ad1e.
//
// Solidity: function unregisterProtectedKeeper(address keeper) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactor) UnregisterProtectedKeeper(opts *bind.TransactOpts, keeper common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.contract.Transact(opts, "unregisterProtectedKeeper", keeper)
}

// UnregisterProtectedKeeper is a paid mutator transaction binding the contract method 0xa390ad1e.
//
// Solidity: function unregisterProtectedKeeper(address keeper) returns()
func (_MockSuperGovernor *MockSuperGovernorSession) UnregisterProtectedKeeper(keeper common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.UnregisterProtectedKeeper(&_MockSuperGovernor.TransactOpts, keeper)
}

// UnregisterProtectedKeeper is a paid mutator transaction binding the contract method 0xa390ad1e.
//
// Solidity: function unregisterProtectedKeeper(address keeper) returns()
func (_MockSuperGovernor *MockSuperGovernorTransactorSession) UnregisterProtectedKeeper(keeper common.Address) (*types.Transaction, error) {
	return _MockSuperGovernor.Contract.UnregisterProtectedKeeper(&_MockSuperGovernor.TransactOpts, keeper)
}

// MockSuperGovernorActivePPSOracleChangedIterator is returned from FilterActivePPSOracleChanged and is used to iterate over the raw logs and unpacked data for ActivePPSOracleChanged events raised by the MockSuperGovernor contract.
type MockSuperGovernorActivePPSOracleChangedIterator struct {
	Event *MockSuperGovernorActivePPSOracleChanged // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorActivePPSOracleChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorActivePPSOracleChanged)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorActivePPSOracleChanged)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorActivePPSOracleChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorActivePPSOracleChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorActivePPSOracleChanged represents a ActivePPSOracleChanged event raised by the MockSuperGovernor contract.
type MockSuperGovernorActivePPSOracleChanged struct {
	OldOracle common.Address
	NewOracle common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterActivePPSOracleChanged is a free log retrieval operation binding the contract event 0x6f32d4a08b9b9b8ee365ed09addde1536e0cc6a14a46e120923bafef349131e4.
//
// Solidity: event ActivePPSOracleChanged(address oldOracle, address newOracle)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterActivePPSOracleChanged(opts *bind.FilterOpts) (*MockSuperGovernorActivePPSOracleChangedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "ActivePPSOracleChanged")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorActivePPSOracleChangedIterator{contract: _MockSuperGovernor.contract, event: "ActivePPSOracleChanged", logs: logs, sub: sub}, nil
}

// WatchActivePPSOracleChanged is a free log subscription operation binding the contract event 0x6f32d4a08b9b9b8ee365ed09addde1536e0cc6a14a46e120923bafef349131e4.
//
// Solidity: event ActivePPSOracleChanged(address oldOracle, address newOracle)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchActivePPSOracleChanged(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorActivePPSOracleChanged) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "ActivePPSOracleChanged")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorActivePPSOracleChanged)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "ActivePPSOracleChanged", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseActivePPSOracleChanged is a log parse operation binding the contract event 0x6f32d4a08b9b9b8ee365ed09addde1536e0cc6a14a46e120923bafef349131e4.
//
// Solidity: event ActivePPSOracleChanged(address oldOracle, address newOracle)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseActivePPSOracleChanged(log types.Log) (*MockSuperGovernorActivePPSOracleChanged, error) {
	event := new(MockSuperGovernorActivePPSOracleChanged)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "ActivePPSOracleChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorActivePPSOracleProposedIterator is returned from FilterActivePPSOracleProposed and is used to iterate over the raw logs and unpacked data for ActivePPSOracleProposed events raised by the MockSuperGovernor contract.
type MockSuperGovernorActivePPSOracleProposedIterator struct {
	Event *MockSuperGovernorActivePPSOracleProposed // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorActivePPSOracleProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorActivePPSOracleProposed)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorActivePPSOracleProposed)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorActivePPSOracleProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorActivePPSOracleProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorActivePPSOracleProposed represents a ActivePPSOracleProposed event raised by the MockSuperGovernor contract.
type MockSuperGovernorActivePPSOracleProposed struct {
	Oracle        common.Address
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterActivePPSOracleProposed is a free log retrieval operation binding the contract event 0x0081013d01b2d41dec72c3449ec25ce9dda2847a6e11ad584836ab3589efe675.
//
// Solidity: event ActivePPSOracleProposed(address oracle, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterActivePPSOracleProposed(opts *bind.FilterOpts) (*MockSuperGovernorActivePPSOracleProposedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "ActivePPSOracleProposed")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorActivePPSOracleProposedIterator{contract: _MockSuperGovernor.contract, event: "ActivePPSOracleProposed", logs: logs, sub: sub}, nil
}

// WatchActivePPSOracleProposed is a free log subscription operation binding the contract event 0x0081013d01b2d41dec72c3449ec25ce9dda2847a6e11ad584836ab3589efe675.
//
// Solidity: event ActivePPSOracleProposed(address oracle, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchActivePPSOracleProposed(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorActivePPSOracleProposed) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "ActivePPSOracleProposed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorActivePPSOracleProposed)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "ActivePPSOracleProposed", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseActivePPSOracleProposed is a log parse operation binding the contract event 0x0081013d01b2d41dec72c3449ec25ce9dda2847a6e11ad584836ab3589efe675.
//
// Solidity: event ActivePPSOracleProposed(address oracle, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseActivePPSOracleProposed(log types.Log) (*MockSuperGovernorActivePPSOracleProposed, error) {
	event := new(MockSuperGovernorActivePPSOracleProposed)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "ActivePPSOracleProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorActivePPSOracleSetIterator is returned from FilterActivePPSOracleSet and is used to iterate over the raw logs and unpacked data for ActivePPSOracleSet events raised by the MockSuperGovernor contract.
type MockSuperGovernorActivePPSOracleSetIterator struct {
	Event *MockSuperGovernorActivePPSOracleSet // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorActivePPSOracleSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorActivePPSOracleSet)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorActivePPSOracleSet)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorActivePPSOracleSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorActivePPSOracleSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorActivePPSOracleSet represents a ActivePPSOracleSet event raised by the MockSuperGovernor contract.
type MockSuperGovernorActivePPSOracleSet struct {
	Oracle common.Address
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterActivePPSOracleSet is a free log retrieval operation binding the contract event 0x4f8ebeedbe3d26fd9e31b446c8da12464fc23cd6ce8c45510c211175190d62fa.
//
// Solidity: event ActivePPSOracleSet(address oracle)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterActivePPSOracleSet(opts *bind.FilterOpts) (*MockSuperGovernorActivePPSOracleSetIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "ActivePPSOracleSet")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorActivePPSOracleSetIterator{contract: _MockSuperGovernor.contract, event: "ActivePPSOracleSet", logs: logs, sub: sub}, nil
}

// WatchActivePPSOracleSet is a free log subscription operation binding the contract event 0x4f8ebeedbe3d26fd9e31b446c8da12464fc23cd6ce8c45510c211175190d62fa.
//
// Solidity: event ActivePPSOracleSet(address oracle)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchActivePPSOracleSet(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorActivePPSOracleSet) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "ActivePPSOracleSet")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorActivePPSOracleSet)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "ActivePPSOracleSet", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseActivePPSOracleSet is a log parse operation binding the contract event 0x4f8ebeedbe3d26fd9e31b446c8da12464fc23cd6ce8c45510c211175190d62fa.
//
// Solidity: event ActivePPSOracleSet(address oracle)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseActivePPSOracleSet(log types.Log) (*MockSuperGovernorActivePPSOracleSet, error) {
	event := new(MockSuperGovernorActivePPSOracleSet)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "ActivePPSOracleSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorAddressSetIterator is returned from FilterAddressSet and is used to iterate over the raw logs and unpacked data for AddressSet events raised by the MockSuperGovernor contract.
type MockSuperGovernorAddressSetIterator struct {
	Event *MockSuperGovernorAddressSet // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorAddressSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorAddressSet)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorAddressSet)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorAddressSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorAddressSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorAddressSet represents a AddressSet event raised by the MockSuperGovernor contract.
type MockSuperGovernorAddressSet struct {
	Key   [32]byte
	Value common.Address
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterAddressSet is a free log retrieval operation binding the contract event 0xb37614c7d254ea8d16eb81fa11dddaeb266aa8ba4917980859c7740aff30c691.
//
// Solidity: event AddressSet(bytes32 key, address value)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterAddressSet(opts *bind.FilterOpts) (*MockSuperGovernorAddressSetIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "AddressSet")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorAddressSetIterator{contract: _MockSuperGovernor.contract, event: "AddressSet", logs: logs, sub: sub}, nil
}

// WatchAddressSet is a free log subscription operation binding the contract event 0xb37614c7d254ea8d16eb81fa11dddaeb266aa8ba4917980859c7740aff30c691.
//
// Solidity: event AddressSet(bytes32 key, address value)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchAddressSet(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorAddressSet) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "AddressSet")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorAddressSet)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "AddressSet", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseAddressSet is a log parse operation binding the contract event 0xb37614c7d254ea8d16eb81fa11dddaeb266aa8ba4917980859c7740aff30c691.
//
// Solidity: event AddressSet(bytes32 key, address value)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseAddressSet(log types.Log) (*MockSuperGovernorAddressSet, error) {
	event := new(MockSuperGovernorAddressSet)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "AddressSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorExecutorAddedIterator is returned from FilterExecutorAdded and is used to iterate over the raw logs and unpacked data for ExecutorAdded events raised by the MockSuperGovernor contract.
type MockSuperGovernorExecutorAddedIterator struct {
	Event *MockSuperGovernorExecutorAdded // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorExecutorAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorExecutorAdded)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorExecutorAdded)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorExecutorAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorExecutorAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorExecutorAdded represents a ExecutorAdded event raised by the MockSuperGovernor contract.
type MockSuperGovernorExecutorAdded struct {
	Executor common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterExecutorAdded is a free log retrieval operation binding the contract event 0xae5b7c3b000f575c241001dc9bcb3d8778376889353b07121115574eceff78c5.
//
// Solidity: event ExecutorAdded(address executor)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterExecutorAdded(opts *bind.FilterOpts) (*MockSuperGovernorExecutorAddedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "ExecutorAdded")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorExecutorAddedIterator{contract: _MockSuperGovernor.contract, event: "ExecutorAdded", logs: logs, sub: sub}, nil
}

// WatchExecutorAdded is a free log subscription operation binding the contract event 0xae5b7c3b000f575c241001dc9bcb3d8778376889353b07121115574eceff78c5.
//
// Solidity: event ExecutorAdded(address executor)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchExecutorAdded(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorExecutorAdded) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "ExecutorAdded")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorExecutorAdded)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "ExecutorAdded", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseExecutorAdded is a log parse operation binding the contract event 0xae5b7c3b000f575c241001dc9bcb3d8778376889353b07121115574eceff78c5.
//
// Solidity: event ExecutorAdded(address executor)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseExecutorAdded(log types.Log) (*MockSuperGovernorExecutorAdded, error) {
	event := new(MockSuperGovernorExecutorAdded)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "ExecutorAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorExecutorRemovedIterator is returned from FilterExecutorRemoved and is used to iterate over the raw logs and unpacked data for ExecutorRemoved events raised by the MockSuperGovernor contract.
type MockSuperGovernorExecutorRemovedIterator struct {
	Event *MockSuperGovernorExecutorRemoved // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorExecutorRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorExecutorRemoved)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorExecutorRemoved)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorExecutorRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorExecutorRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorExecutorRemoved represents a ExecutorRemoved event raised by the MockSuperGovernor contract.
type MockSuperGovernorExecutorRemoved struct {
	Executor common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterExecutorRemoved is a free log retrieval operation binding the contract event 0x4a2cf608bfb427f53279ec7f0eadf48913b9346ccefc3af138dbdec14ea0907d.
//
// Solidity: event ExecutorRemoved(address executor)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterExecutorRemoved(opts *bind.FilterOpts) (*MockSuperGovernorExecutorRemovedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "ExecutorRemoved")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorExecutorRemovedIterator{contract: _MockSuperGovernor.contract, event: "ExecutorRemoved", logs: logs, sub: sub}, nil
}

// WatchExecutorRemoved is a free log subscription operation binding the contract event 0x4a2cf608bfb427f53279ec7f0eadf48913b9346ccefc3af138dbdec14ea0907d.
//
// Solidity: event ExecutorRemoved(address executor)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchExecutorRemoved(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorExecutorRemoved) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "ExecutorRemoved")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorExecutorRemoved)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "ExecutorRemoved", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseExecutorRemoved is a log parse operation binding the contract event 0x4a2cf608bfb427f53279ec7f0eadf48913b9346ccefc3af138dbdec14ea0907d.
//
// Solidity: event ExecutorRemoved(address executor)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseExecutorRemoved(log types.Log) (*MockSuperGovernorExecutorRemoved, error) {
	event := new(MockSuperGovernorExecutorRemoved)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "ExecutorRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorFeeProposedIterator is returned from FilterFeeProposed and is used to iterate over the raw logs and unpacked data for FeeProposed events raised by the MockSuperGovernor contract.
type MockSuperGovernorFeeProposedIterator struct {
	Event *MockSuperGovernorFeeProposed // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorFeeProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorFeeProposed)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorFeeProposed)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorFeeProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorFeeProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorFeeProposed represents a FeeProposed event raised by the MockSuperGovernor contract.
type MockSuperGovernorFeeProposed struct {
	FeeType       uint8
	Value         *big.Int
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterFeeProposed is a free log retrieval operation binding the contract event 0x79548367f12987b3f5043ed1f421f89ebc84ab67cdaa9ee1e4d2a9e76b58ba0b.
//
// Solidity: event FeeProposed(uint8 feeType, uint256 value, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterFeeProposed(opts *bind.FilterOpts) (*MockSuperGovernorFeeProposedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "FeeProposed")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorFeeProposedIterator{contract: _MockSuperGovernor.contract, event: "FeeProposed", logs: logs, sub: sub}, nil
}

// WatchFeeProposed is a free log subscription operation binding the contract event 0x79548367f12987b3f5043ed1f421f89ebc84ab67cdaa9ee1e4d2a9e76b58ba0b.
//
// Solidity: event FeeProposed(uint8 feeType, uint256 value, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchFeeProposed(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorFeeProposed) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "FeeProposed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorFeeProposed)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "FeeProposed", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseFeeProposed is a log parse operation binding the contract event 0x79548367f12987b3f5043ed1f421f89ebc84ab67cdaa9ee1e4d2a9e76b58ba0b.
//
// Solidity: event FeeProposed(uint8 feeType, uint256 value, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseFeeProposed(log types.Log) (*MockSuperGovernorFeeProposed, error) {
	event := new(MockSuperGovernorFeeProposed)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "FeeProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorFeeUpdatedIterator is returned from FilterFeeUpdated and is used to iterate over the raw logs and unpacked data for FeeUpdated events raised by the MockSuperGovernor contract.
type MockSuperGovernorFeeUpdatedIterator struct {
	Event *MockSuperGovernorFeeUpdated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorFeeUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorFeeUpdated)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorFeeUpdated)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorFeeUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorFeeUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorFeeUpdated represents a FeeUpdated event raised by the MockSuperGovernor contract.
type MockSuperGovernorFeeUpdated struct {
	FeeType uint8
	Value   *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterFeeUpdated is a free log retrieval operation binding the contract event 0x53b82d85cd75c3f353186408e2e619ae5f01c371100dc061ee0423d12acb7508.
//
// Solidity: event FeeUpdated(uint8 feeType, uint256 value)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterFeeUpdated(opts *bind.FilterOpts) (*MockSuperGovernorFeeUpdatedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "FeeUpdated")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorFeeUpdatedIterator{contract: _MockSuperGovernor.contract, event: "FeeUpdated", logs: logs, sub: sub}, nil
}

// WatchFeeUpdated is a free log subscription operation binding the contract event 0x53b82d85cd75c3f353186408e2e619ae5f01c371100dc061ee0423d12acb7508.
//
// Solidity: event FeeUpdated(uint8 feeType, uint256 value)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchFeeUpdated(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorFeeUpdated) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "FeeUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorFeeUpdated)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "FeeUpdated", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseFeeUpdated is a log parse operation binding the contract event 0x53b82d85cd75c3f353186408e2e619ae5f01c371100dc061ee0423d12acb7508.
//
// Solidity: event FeeUpdated(uint8 feeType, uint256 value)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseFeeUpdated(log types.Log) (*MockSuperGovernorFeeUpdated, error) {
	event := new(MockSuperGovernorFeeUpdated)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "FeeUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorFulfillRequestsHookRegisteredIterator is returned from FilterFulfillRequestsHookRegistered and is used to iterate over the raw logs and unpacked data for FulfillRequestsHookRegistered events raised by the MockSuperGovernor contract.
type MockSuperGovernorFulfillRequestsHookRegisteredIterator struct {
	Event *MockSuperGovernorFulfillRequestsHookRegistered // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorFulfillRequestsHookRegisteredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorFulfillRequestsHookRegistered)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorFulfillRequestsHookRegistered)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorFulfillRequestsHookRegisteredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorFulfillRequestsHookRegisteredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorFulfillRequestsHookRegistered represents a FulfillRequestsHookRegistered event raised by the MockSuperGovernor contract.
type MockSuperGovernorFulfillRequestsHookRegistered struct {
	Hook common.Address
	Raw  types.Log // Blockchain specific contextual infos
}

// FilterFulfillRequestsHookRegistered is a free log retrieval operation binding the contract event 0x11764f0d0c3db8483b5aa057c1f5266bac770010886dc97e83bec7f34f315807.
//
// Solidity: event FulfillRequestsHookRegistered(address hook)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterFulfillRequestsHookRegistered(opts *bind.FilterOpts) (*MockSuperGovernorFulfillRequestsHookRegisteredIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "FulfillRequestsHookRegistered")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorFulfillRequestsHookRegisteredIterator{contract: _MockSuperGovernor.contract, event: "FulfillRequestsHookRegistered", logs: logs, sub: sub}, nil
}

// WatchFulfillRequestsHookRegistered is a free log subscription operation binding the contract event 0x11764f0d0c3db8483b5aa057c1f5266bac770010886dc97e83bec7f34f315807.
//
// Solidity: event FulfillRequestsHookRegistered(address hook)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchFulfillRequestsHookRegistered(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorFulfillRequestsHookRegistered) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "FulfillRequestsHookRegistered")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorFulfillRequestsHookRegistered)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "FulfillRequestsHookRegistered", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseFulfillRequestsHookRegistered is a log parse operation binding the contract event 0x11764f0d0c3db8483b5aa057c1f5266bac770010886dc97e83bec7f34f315807.
//
// Solidity: event FulfillRequestsHookRegistered(address hook)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseFulfillRequestsHookRegistered(log types.Log) (*MockSuperGovernorFulfillRequestsHookRegistered, error) {
	event := new(MockSuperGovernorFulfillRequestsHookRegistered)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "FulfillRequestsHookRegistered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorFulfillRequestsHookUnregisteredIterator is returned from FilterFulfillRequestsHookUnregistered and is used to iterate over the raw logs and unpacked data for FulfillRequestsHookUnregistered events raised by the MockSuperGovernor contract.
type MockSuperGovernorFulfillRequestsHookUnregisteredIterator struct {
	Event *MockSuperGovernorFulfillRequestsHookUnregistered // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorFulfillRequestsHookUnregisteredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorFulfillRequestsHookUnregistered)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorFulfillRequestsHookUnregistered)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorFulfillRequestsHookUnregisteredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorFulfillRequestsHookUnregisteredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorFulfillRequestsHookUnregistered represents a FulfillRequestsHookUnregistered event raised by the MockSuperGovernor contract.
type MockSuperGovernorFulfillRequestsHookUnregistered struct {
	Hook common.Address
	Raw  types.Log // Blockchain specific contextual infos
}

// FilterFulfillRequestsHookUnregistered is a free log retrieval operation binding the contract event 0x305fc42e276ebac0666dd3b0dbe7bd4014ce8a289b4078026176e821c4b5ef1d.
//
// Solidity: event FulfillRequestsHookUnregistered(address hook)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterFulfillRequestsHookUnregistered(opts *bind.FilterOpts) (*MockSuperGovernorFulfillRequestsHookUnregisteredIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "FulfillRequestsHookUnregistered")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorFulfillRequestsHookUnregisteredIterator{contract: _MockSuperGovernor.contract, event: "FulfillRequestsHookUnregistered", logs: logs, sub: sub}, nil
}

// WatchFulfillRequestsHookUnregistered is a free log subscription operation binding the contract event 0x305fc42e276ebac0666dd3b0dbe7bd4014ce8a289b4078026176e821c4b5ef1d.
//
// Solidity: event FulfillRequestsHookUnregistered(address hook)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchFulfillRequestsHookUnregistered(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorFulfillRequestsHookUnregistered) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "FulfillRequestsHookUnregistered")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorFulfillRequestsHookUnregistered)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "FulfillRequestsHookUnregistered", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseFulfillRequestsHookUnregistered is a log parse operation binding the contract event 0x305fc42e276ebac0666dd3b0dbe7bd4014ce8a289b4078026176e821c4b5ef1d.
//
// Solidity: event FulfillRequestsHookUnregistered(address hook)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseFulfillRequestsHookUnregistered(log types.Log) (*MockSuperGovernorFulfillRequestsHookUnregistered, error) {
	event := new(MockSuperGovernorFulfillRequestsHookUnregistered)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "FulfillRequestsHookUnregistered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorGasInfoSetIterator is returned from FilterGasInfoSet and is used to iterate over the raw logs and unpacked data for GasInfoSet events raised by the MockSuperGovernor contract.
type MockSuperGovernorGasInfoSetIterator struct {
	Event *MockSuperGovernorGasInfoSet // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorGasInfoSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorGasInfoSet)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorGasInfoSet)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorGasInfoSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorGasInfoSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorGasInfoSet represents a GasInfoSet event raised by the MockSuperGovernor contract.
type MockSuperGovernorGasInfoSet struct {
	Oracle                   common.Address
	BaseGasBatch             *big.Int
	GasIncreasePerEntryBatch *big.Int
	Raw                      types.Log // Blockchain specific contextual infos
}

// FilterGasInfoSet is a free log retrieval operation binding the contract event 0x474ae60cfd5deb72036951ff96f6a845f0a809827d202ac2f1757683c00bb7a9.
//
// Solidity: event GasInfoSet(address oracle, uint256 baseGasBatch, uint256 gasIncreasePerEntryBatch)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterGasInfoSet(opts *bind.FilterOpts) (*MockSuperGovernorGasInfoSetIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "GasInfoSet")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorGasInfoSetIterator{contract: _MockSuperGovernor.contract, event: "GasInfoSet", logs: logs, sub: sub}, nil
}

// WatchGasInfoSet is a free log subscription operation binding the contract event 0x474ae60cfd5deb72036951ff96f6a845f0a809827d202ac2f1757683c00bb7a9.
//
// Solidity: event GasInfoSet(address oracle, uint256 baseGasBatch, uint256 gasIncreasePerEntryBatch)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchGasInfoSet(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorGasInfoSet) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "GasInfoSet")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorGasInfoSet)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "GasInfoSet", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseGasInfoSet is a log parse operation binding the contract event 0x474ae60cfd5deb72036951ff96f6a845f0a809827d202ac2f1757683c00bb7a9.
//
// Solidity: event GasInfoSet(address oracle, uint256 baseGasBatch, uint256 gasIncreasePerEntryBatch)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseGasInfoSet(log types.Log) (*MockSuperGovernorGasInfoSet, error) {
	event := new(MockSuperGovernorGasInfoSet)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "GasInfoSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorHookApprovedIterator is returned from FilterHookApproved and is used to iterate over the raw logs and unpacked data for HookApproved events raised by the MockSuperGovernor contract.
type MockSuperGovernorHookApprovedIterator struct {
	Event *MockSuperGovernorHookApproved // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorHookApprovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorHookApproved)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorHookApproved)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorHookApprovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorHookApprovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorHookApproved represents a HookApproved event raised by the MockSuperGovernor contract.
type MockSuperGovernorHookApproved struct {
	Hook common.Address
	Raw  types.Log // Blockchain specific contextual infos
}

// FilterHookApproved is a free log retrieval operation binding the contract event 0x6b2d5736790b4cdb325004b8784c7b94dc55a32af9d82d1f6ceb5bd8c7c8573e.
//
// Solidity: event HookApproved(address hook)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterHookApproved(opts *bind.FilterOpts) (*MockSuperGovernorHookApprovedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "HookApproved")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorHookApprovedIterator{contract: _MockSuperGovernor.contract, event: "HookApproved", logs: logs, sub: sub}, nil
}

// WatchHookApproved is a free log subscription operation binding the contract event 0x6b2d5736790b4cdb325004b8784c7b94dc55a32af9d82d1f6ceb5bd8c7c8573e.
//
// Solidity: event HookApproved(address hook)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchHookApproved(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorHookApproved) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "HookApproved")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorHookApproved)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "HookApproved", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseHookApproved is a log parse operation binding the contract event 0x6b2d5736790b4cdb325004b8784c7b94dc55a32af9d82d1f6ceb5bd8c7c8573e.
//
// Solidity: event HookApproved(address hook)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseHookApproved(log types.Log) (*MockSuperGovernorHookApproved, error) {
	event := new(MockSuperGovernorHookApproved)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "HookApproved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorHookRemovedIterator is returned from FilterHookRemoved and is used to iterate over the raw logs and unpacked data for HookRemoved events raised by the MockSuperGovernor contract.
type MockSuperGovernorHookRemovedIterator struct {
	Event *MockSuperGovernorHookRemoved // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorHookRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorHookRemoved)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorHookRemoved)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorHookRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorHookRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorHookRemoved represents a HookRemoved event raised by the MockSuperGovernor contract.
type MockSuperGovernorHookRemoved struct {
	Hook common.Address
	Raw  types.Log // Blockchain specific contextual infos
}

// FilterHookRemoved is a free log retrieval operation binding the contract event 0x47d0871e905ac6550f54ba266e0d90d2dc8ed67a957c064ca3438eddf4e3fd89.
//
// Solidity: event HookRemoved(address hook)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterHookRemoved(opts *bind.FilterOpts) (*MockSuperGovernorHookRemovedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "HookRemoved")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorHookRemovedIterator{contract: _MockSuperGovernor.contract, event: "HookRemoved", logs: logs, sub: sub}, nil
}

// WatchHookRemoved is a free log subscription operation binding the contract event 0x47d0871e905ac6550f54ba266e0d90d2dc8ed67a957c064ca3438eddf4e3fd89.
//
// Solidity: event HookRemoved(address hook)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchHookRemoved(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorHookRemoved) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "HookRemoved")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorHookRemoved)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "HookRemoved", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseHookRemoved is a log parse operation binding the contract event 0x47d0871e905ac6550f54ba266e0d90d2dc8ed67a957c064ca3438eddf4e3fd89.
//
// Solidity: event HookRemoved(address hook)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseHookRemoved(log types.Log) (*MockSuperGovernorHookRemoved, error) {
	event := new(MockSuperGovernorHookRemoved)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "HookRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorManagerTakeoversFrozenIterator is returned from FilterManagerTakeoversFrozen and is used to iterate over the raw logs and unpacked data for ManagerTakeoversFrozen events raised by the MockSuperGovernor contract.
type MockSuperGovernorManagerTakeoversFrozenIterator struct {
	Event *MockSuperGovernorManagerTakeoversFrozen // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorManagerTakeoversFrozenIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorManagerTakeoversFrozen)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorManagerTakeoversFrozen)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorManagerTakeoversFrozenIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorManagerTakeoversFrozenIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorManagerTakeoversFrozen represents a ManagerTakeoversFrozen event raised by the MockSuperGovernor contract.
type MockSuperGovernorManagerTakeoversFrozen struct {
	Raw types.Log // Blockchain specific contextual infos
}

// FilterManagerTakeoversFrozen is a free log retrieval operation binding the contract event 0x0cfbf370e135d688f4de1107bfa980d42fe9e0884277d500e4a5262e207df76d.
//
// Solidity: event ManagerTakeoversFrozen()
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterManagerTakeoversFrozen(opts *bind.FilterOpts) (*MockSuperGovernorManagerTakeoversFrozenIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "ManagerTakeoversFrozen")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorManagerTakeoversFrozenIterator{contract: _MockSuperGovernor.contract, event: "ManagerTakeoversFrozen", logs: logs, sub: sub}, nil
}

// WatchManagerTakeoversFrozen is a free log subscription operation binding the contract event 0x0cfbf370e135d688f4de1107bfa980d42fe9e0884277d500e4a5262e207df76d.
//
// Solidity: event ManagerTakeoversFrozen()
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchManagerTakeoversFrozen(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorManagerTakeoversFrozen) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "ManagerTakeoversFrozen")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorManagerTakeoversFrozen)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "ManagerTakeoversFrozen", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseManagerTakeoversFrozen is a log parse operation binding the contract event 0x0cfbf370e135d688f4de1107bfa980d42fe9e0884277d500e4a5262e207df76d.
//
// Solidity: event ManagerTakeoversFrozen()
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseManagerTakeoversFrozen(log types.Log) (*MockSuperGovernorManagerTakeoversFrozen, error) {
	event := new(MockSuperGovernorManagerTakeoversFrozen)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "ManagerTakeoversFrozen", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorMinStalenesChangedIterator is returned from FilterMinStalenesChanged and is used to iterate over the raw logs and unpacked data for MinStalenesChanged events raised by the MockSuperGovernor contract.
type MockSuperGovernorMinStalenesChangedIterator struct {
	Event *MockSuperGovernorMinStalenesChanged // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorMinStalenesChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorMinStalenesChanged)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorMinStalenesChanged)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorMinStalenesChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorMinStalenesChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorMinStalenesChanged represents a MinStalenesChanged event raised by the MockSuperGovernor contract.
type MockSuperGovernorMinStalenesChanged struct {
	NewMinStaleness *big.Int
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterMinStalenesChanged is a free log retrieval operation binding the contract event 0x5ef721aefae68d3af172090ad589f1eb72736af265747458daf734c5c60d7daa.
//
// Solidity: event MinStalenesChanged(uint256 newMinStaleness)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterMinStalenesChanged(opts *bind.FilterOpts) (*MockSuperGovernorMinStalenesChangedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "MinStalenesChanged")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorMinStalenesChangedIterator{contract: _MockSuperGovernor.contract, event: "MinStalenesChanged", logs: logs, sub: sub}, nil
}

// WatchMinStalenesChanged is a free log subscription operation binding the contract event 0x5ef721aefae68d3af172090ad589f1eb72736af265747458daf734c5c60d7daa.
//
// Solidity: event MinStalenesChanged(uint256 newMinStaleness)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchMinStalenesChanged(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorMinStalenesChanged) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "MinStalenesChanged")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorMinStalenesChanged)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "MinStalenesChanged", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseMinStalenesChanged is a log parse operation binding the contract event 0x5ef721aefae68d3af172090ad589f1eb72736af265747458daf734c5c60d7daa.
//
// Solidity: event MinStalenesChanged(uint256 newMinStaleness)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseMinStalenesChanged(log types.Log) (*MockSuperGovernorMinStalenesChanged, error) {
	event := new(MockSuperGovernorMinStalenesChanged)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "MinStalenesChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorMinStalenesProposedIterator is returned from FilterMinStalenesProposed and is used to iterate over the raw logs and unpacked data for MinStalenesProposed events raised by the MockSuperGovernor contract.
type MockSuperGovernorMinStalenesProposedIterator struct {
	Event *MockSuperGovernorMinStalenesProposed // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorMinStalenesProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorMinStalenesProposed)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorMinStalenesProposed)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorMinStalenesProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorMinStalenesProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorMinStalenesProposed represents a MinStalenesProposed event raised by the MockSuperGovernor contract.
type MockSuperGovernorMinStalenesProposed struct {
	NewMinStaleness *big.Int
	EffectiveTime   *big.Int
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterMinStalenesProposed is a free log retrieval operation binding the contract event 0xae30e7c9277d9f36ab2ab07d353aa93dcc567106b5d571ebead929f12ebcd7ad.
//
// Solidity: event MinStalenesProposed(uint256 newMinStaleness, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterMinStalenesProposed(opts *bind.FilterOpts) (*MockSuperGovernorMinStalenesProposedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "MinStalenesProposed")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorMinStalenesProposedIterator{contract: _MockSuperGovernor.contract, event: "MinStalenesProposed", logs: logs, sub: sub}, nil
}

// WatchMinStalenesProposed is a free log subscription operation binding the contract event 0xae30e7c9277d9f36ab2ab07d353aa93dcc567106b5d571ebead929f12ebcd7ad.
//
// Solidity: event MinStalenesProposed(uint256 newMinStaleness, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchMinStalenesProposed(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorMinStalenesProposed) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "MinStalenesProposed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorMinStalenesProposed)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "MinStalenesProposed", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseMinStalenesProposed is a log parse operation binding the contract event 0xae30e7c9277d9f36ab2ab07d353aa93dcc567106b5d571ebead929f12ebcd7ad.
//
// Solidity: event MinStalenesProposed(uint256 newMinStaleness, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseMinStalenesProposed(log types.Log) (*MockSuperGovernorMinStalenesProposed, error) {
	event := new(MockSuperGovernorMinStalenesProposed)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "MinStalenesProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorPPSOracleQuorumUpdatedIterator is returned from FilterPPSOracleQuorumUpdated and is used to iterate over the raw logs and unpacked data for PPSOracleQuorumUpdated events raised by the MockSuperGovernor contract.
type MockSuperGovernorPPSOracleQuorumUpdatedIterator struct {
	Event *MockSuperGovernorPPSOracleQuorumUpdated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorPPSOracleQuorumUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorPPSOracleQuorumUpdated)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorPPSOracleQuorumUpdated)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorPPSOracleQuorumUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorPPSOracleQuorumUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorPPSOracleQuorumUpdated represents a PPSOracleQuorumUpdated event raised by the MockSuperGovernor contract.
type MockSuperGovernorPPSOracleQuorumUpdated struct {
	Quorum *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterPPSOracleQuorumUpdated is a free log retrieval operation binding the contract event 0xf957b69cfa930a437fa0211ed212fe9b40bfbf99f4e5734d9d6068834d33a928.
//
// Solidity: event PPSOracleQuorumUpdated(uint256 quorum)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterPPSOracleQuorumUpdated(opts *bind.FilterOpts) (*MockSuperGovernorPPSOracleQuorumUpdatedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "PPSOracleQuorumUpdated")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorPPSOracleQuorumUpdatedIterator{contract: _MockSuperGovernor.contract, event: "PPSOracleQuorumUpdated", logs: logs, sub: sub}, nil
}

// WatchPPSOracleQuorumUpdated is a free log subscription operation binding the contract event 0xf957b69cfa930a437fa0211ed212fe9b40bfbf99f4e5734d9d6068834d33a928.
//
// Solidity: event PPSOracleQuorumUpdated(uint256 quorum)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchPPSOracleQuorumUpdated(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorPPSOracleQuorumUpdated) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "PPSOracleQuorumUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorPPSOracleQuorumUpdated)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "PPSOracleQuorumUpdated", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParsePPSOracleQuorumUpdated is a log parse operation binding the contract event 0xf957b69cfa930a437fa0211ed212fe9b40bfbf99f4e5734d9d6068834d33a928.
//
// Solidity: event PPSOracleQuorumUpdated(uint256 quorum)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParsePPSOracleQuorumUpdated(log types.Log) (*MockSuperGovernorPPSOracleQuorumUpdated, error) {
	event := new(MockSuperGovernorPPSOracleQuorumUpdated)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "PPSOracleQuorumUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorProtectedKeeperRegisteredIterator is returned from FilterProtectedKeeperRegistered and is used to iterate over the raw logs and unpacked data for ProtectedKeeperRegistered events raised by the MockSuperGovernor contract.
type MockSuperGovernorProtectedKeeperRegisteredIterator struct {
	Event *MockSuperGovernorProtectedKeeperRegistered // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorProtectedKeeperRegisteredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorProtectedKeeperRegistered)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorProtectedKeeperRegistered)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorProtectedKeeperRegisteredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorProtectedKeeperRegisteredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorProtectedKeeperRegistered represents a ProtectedKeeperRegistered event raised by the MockSuperGovernor contract.
type MockSuperGovernorProtectedKeeperRegistered struct {
	Keeper common.Address
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterProtectedKeeperRegistered is a free log retrieval operation binding the contract event 0x5a17551f8f59aacc175aed9daecc2461b2161d1ca643c75612710502de9d57b1.
//
// Solidity: event ProtectedKeeperRegistered(address keeper)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterProtectedKeeperRegistered(opts *bind.FilterOpts) (*MockSuperGovernorProtectedKeeperRegisteredIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "ProtectedKeeperRegistered")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorProtectedKeeperRegisteredIterator{contract: _MockSuperGovernor.contract, event: "ProtectedKeeperRegistered", logs: logs, sub: sub}, nil
}

// WatchProtectedKeeperRegistered is a free log subscription operation binding the contract event 0x5a17551f8f59aacc175aed9daecc2461b2161d1ca643c75612710502de9d57b1.
//
// Solidity: event ProtectedKeeperRegistered(address keeper)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchProtectedKeeperRegistered(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorProtectedKeeperRegistered) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "ProtectedKeeperRegistered")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorProtectedKeeperRegistered)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "ProtectedKeeperRegistered", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseProtectedKeeperRegistered is a log parse operation binding the contract event 0x5a17551f8f59aacc175aed9daecc2461b2161d1ca643c75612710502de9d57b1.
//
// Solidity: event ProtectedKeeperRegistered(address keeper)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseProtectedKeeperRegistered(log types.Log) (*MockSuperGovernorProtectedKeeperRegistered, error) {
	event := new(MockSuperGovernorProtectedKeeperRegistered)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "ProtectedKeeperRegistered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorProtectedKeeperUnregisteredIterator is returned from FilterProtectedKeeperUnregistered and is used to iterate over the raw logs and unpacked data for ProtectedKeeperUnregistered events raised by the MockSuperGovernor contract.
type MockSuperGovernorProtectedKeeperUnregisteredIterator struct {
	Event *MockSuperGovernorProtectedKeeperUnregistered // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorProtectedKeeperUnregisteredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorProtectedKeeperUnregistered)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorProtectedKeeperUnregistered)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorProtectedKeeperUnregisteredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorProtectedKeeperUnregisteredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorProtectedKeeperUnregistered represents a ProtectedKeeperUnregistered event raised by the MockSuperGovernor contract.
type MockSuperGovernorProtectedKeeperUnregistered struct {
	Keeper common.Address
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterProtectedKeeperUnregistered is a free log retrieval operation binding the contract event 0xd5f663a5782ccd5e7465e8419aa75f38fdc175262978753ee490757f48d7318b.
//
// Solidity: event ProtectedKeeperUnregistered(address keeper)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterProtectedKeeperUnregistered(opts *bind.FilterOpts) (*MockSuperGovernorProtectedKeeperUnregisteredIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "ProtectedKeeperUnregistered")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorProtectedKeeperUnregisteredIterator{contract: _MockSuperGovernor.contract, event: "ProtectedKeeperUnregistered", logs: logs, sub: sub}, nil
}

// WatchProtectedKeeperUnregistered is a free log subscription operation binding the contract event 0xd5f663a5782ccd5e7465e8419aa75f38fdc175262978753ee490757f48d7318b.
//
// Solidity: event ProtectedKeeperUnregistered(address keeper)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchProtectedKeeperUnregistered(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorProtectedKeeperUnregistered) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "ProtectedKeeperUnregistered")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorProtectedKeeperUnregistered)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "ProtectedKeeperUnregistered", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseProtectedKeeperUnregistered is a log parse operation binding the contract event 0xd5f663a5782ccd5e7465e8419aa75f38fdc175262978753ee490757f48d7318b.
//
// Solidity: event ProtectedKeeperUnregistered(address keeper)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseProtectedKeeperUnregistered(log types.Log) (*MockSuperGovernorProtectedKeeperUnregistered, error) {
	event := new(MockSuperGovernorProtectedKeeperUnregistered)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "ProtectedKeeperUnregistered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorProverSetIterator is returned from FilterProverSet and is used to iterate over the raw logs and unpacked data for ProverSet events raised by the MockSuperGovernor contract.
type MockSuperGovernorProverSetIterator struct {
	Event *MockSuperGovernorProverSet // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorProverSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorProverSet)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorProverSet)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorProverSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorProverSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorProverSet represents a ProverSet event raised by the MockSuperGovernor contract.
type MockSuperGovernorProverSet struct {
	Prover common.Address
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterProverSet is a free log retrieval operation binding the contract event 0xc881e48d34a3dc6ca8b8ab38320d54f4972a7ade617113524dc2c2bf44984c8a.
//
// Solidity: event ProverSet(address prover)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterProverSet(opts *bind.FilterOpts) (*MockSuperGovernorProverSetIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "ProverSet")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorProverSetIterator{contract: _MockSuperGovernor.contract, event: "ProverSet", logs: logs, sub: sub}, nil
}

// WatchProverSet is a free log subscription operation binding the contract event 0xc881e48d34a3dc6ca8b8ab38320d54f4972a7ade617113524dc2c2bf44984c8a.
//
// Solidity: event ProverSet(address prover)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchProverSet(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorProverSet) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "ProverSet")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorProverSet)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "ProverSet", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseProverSet is a log parse operation binding the contract event 0xc881e48d34a3dc6ca8b8ab38320d54f4972a7ade617113524dc2c2bf44984c8a.
//
// Solidity: event ProverSet(address prover)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseProverSet(log types.Log) (*MockSuperGovernorProverSet, error) {
	event := new(MockSuperGovernorProverSet)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "ProverSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorRelayerAddedIterator is returned from FilterRelayerAdded and is used to iterate over the raw logs and unpacked data for RelayerAdded events raised by the MockSuperGovernor contract.
type MockSuperGovernorRelayerAddedIterator struct {
	Event *MockSuperGovernorRelayerAdded // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorRelayerAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorRelayerAdded)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorRelayerAdded)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorRelayerAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorRelayerAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorRelayerAdded represents a RelayerAdded event raised by the MockSuperGovernor contract.
type MockSuperGovernorRelayerAdded struct {
	Relayer common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRelayerAdded is a free log retrieval operation binding the contract event 0x03580ee9f53a62b7cb409a2cb56f9be87747dd15017afc5cef6eef321e4fb2c5.
//
// Solidity: event RelayerAdded(address relayer)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterRelayerAdded(opts *bind.FilterOpts) (*MockSuperGovernorRelayerAddedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "RelayerAdded")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorRelayerAddedIterator{contract: _MockSuperGovernor.contract, event: "RelayerAdded", logs: logs, sub: sub}, nil
}

// WatchRelayerAdded is a free log subscription operation binding the contract event 0x03580ee9f53a62b7cb409a2cb56f9be87747dd15017afc5cef6eef321e4fb2c5.
//
// Solidity: event RelayerAdded(address relayer)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchRelayerAdded(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorRelayerAdded) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "RelayerAdded")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorRelayerAdded)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "RelayerAdded", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRelayerAdded is a log parse operation binding the contract event 0x03580ee9f53a62b7cb409a2cb56f9be87747dd15017afc5cef6eef321e4fb2c5.
//
// Solidity: event RelayerAdded(address relayer)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseRelayerAdded(log types.Log) (*MockSuperGovernorRelayerAdded, error) {
	event := new(MockSuperGovernorRelayerAdded)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "RelayerAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorRelayerRemovedIterator is returned from FilterRelayerRemoved and is used to iterate over the raw logs and unpacked data for RelayerRemoved events raised by the MockSuperGovernor contract.
type MockSuperGovernorRelayerRemovedIterator struct {
	Event *MockSuperGovernorRelayerRemoved // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorRelayerRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorRelayerRemoved)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorRelayerRemoved)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorRelayerRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorRelayerRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorRelayerRemoved represents a RelayerRemoved event raised by the MockSuperGovernor contract.
type MockSuperGovernorRelayerRemoved struct {
	Relayer common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRelayerRemoved is a free log retrieval operation binding the contract event 0x10e1f7ce9fd7d1b90a66d13a2ab3cb8dd7f29f3f8d520b143b063ccfbab6906b.
//
// Solidity: event RelayerRemoved(address relayer)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterRelayerRemoved(opts *bind.FilterOpts) (*MockSuperGovernorRelayerRemovedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "RelayerRemoved")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorRelayerRemovedIterator{contract: _MockSuperGovernor.contract, event: "RelayerRemoved", logs: logs, sub: sub}, nil
}

// WatchRelayerRemoved is a free log subscription operation binding the contract event 0x10e1f7ce9fd7d1b90a66d13a2ab3cb8dd7f29f3f8d520b143b063ccfbab6906b.
//
// Solidity: event RelayerRemoved(address relayer)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchRelayerRemoved(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorRelayerRemoved) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "RelayerRemoved")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorRelayerRemoved)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "RelayerRemoved", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRelayerRemoved is a log parse operation binding the contract event 0x10e1f7ce9fd7d1b90a66d13a2ab3cb8dd7f29f3f8d520b143b063ccfbab6906b.
//
// Solidity: event RelayerRemoved(address relayer)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseRelayerRemoved(log types.Log) (*MockSuperGovernorRelayerRemoved, error) {
	event := new(MockSuperGovernorRelayerRemoved)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "RelayerRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorRevenueShareUpdatedIterator is returned from FilterRevenueShareUpdated and is used to iterate over the raw logs and unpacked data for RevenueShareUpdated events raised by the MockSuperGovernor contract.
type MockSuperGovernorRevenueShareUpdatedIterator struct {
	Event *MockSuperGovernorRevenueShareUpdated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorRevenueShareUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorRevenueShareUpdated)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorRevenueShareUpdated)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorRevenueShareUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorRevenueShareUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorRevenueShareUpdated represents a RevenueShareUpdated event raised by the MockSuperGovernor contract.
type MockSuperGovernorRevenueShareUpdated struct {
	Share *big.Int
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterRevenueShareUpdated is a free log retrieval operation binding the contract event 0x343a3cad72a9e3a0fe71e8417402226b647587dfd1713f79f85413ed27df7f7b.
//
// Solidity: event RevenueShareUpdated(uint256 share)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterRevenueShareUpdated(opts *bind.FilterOpts) (*MockSuperGovernorRevenueShareUpdatedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "RevenueShareUpdated")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorRevenueShareUpdatedIterator{contract: _MockSuperGovernor.contract, event: "RevenueShareUpdated", logs: logs, sub: sub}, nil
}

// WatchRevenueShareUpdated is a free log subscription operation binding the contract event 0x343a3cad72a9e3a0fe71e8417402226b647587dfd1713f79f85413ed27df7f7b.
//
// Solidity: event RevenueShareUpdated(uint256 share)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchRevenueShareUpdated(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorRevenueShareUpdated) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "RevenueShareUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorRevenueShareUpdated)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "RevenueShareUpdated", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRevenueShareUpdated is a log parse operation binding the contract event 0x343a3cad72a9e3a0fe71e8417402226b647587dfd1713f79f85413ed27df7f7b.
//
// Solidity: event RevenueShareUpdated(uint256 share)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseRevenueShareUpdated(log types.Log) (*MockSuperGovernorRevenueShareUpdated, error) {
	event := new(MockSuperGovernorRevenueShareUpdated)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "RevenueShareUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorRoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the MockSuperGovernor contract.
type MockSuperGovernorRoleAdminChangedIterator struct {
	Event *MockSuperGovernorRoleAdminChanged // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorRoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorRoleAdminChanged)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorRoleAdminChanged)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorRoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorRoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorRoleAdminChanged represents a RoleAdminChanged event raised by the MockSuperGovernor contract.
type MockSuperGovernorRoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 role, bytes32 previousAdminRole, bytes32 newAdminRole)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterRoleAdminChanged(opts *bind.FilterOpts) (*MockSuperGovernorRoleAdminChangedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "RoleAdminChanged")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorRoleAdminChangedIterator{contract: _MockSuperGovernor.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 role, bytes32 previousAdminRole, bytes32 newAdminRole)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorRoleAdminChanged) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "RoleAdminChanged")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorRoleAdminChanged)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRoleAdminChanged is a log parse operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 role, bytes32 previousAdminRole, bytes32 newAdminRole)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseRoleAdminChanged(log types.Log) (*MockSuperGovernorRoleAdminChanged, error) {
	event := new(MockSuperGovernorRoleAdminChanged)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorRoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the MockSuperGovernor contract.
type MockSuperGovernorRoleGrantedIterator struct {
	Event *MockSuperGovernorRoleGranted // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorRoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorRoleGranted)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorRoleGranted)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorRoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorRoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorRoleGranted represents a RoleGranted event raised by the MockSuperGovernor contract.
type MockSuperGovernorRoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 role, address account, address sender)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterRoleGranted(opts *bind.FilterOpts) (*MockSuperGovernorRoleGrantedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "RoleGranted")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorRoleGrantedIterator{contract: _MockSuperGovernor.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 role, address account, address sender)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorRoleGranted) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "RoleGranted")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorRoleGranted)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "RoleGranted", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRoleGranted is a log parse operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 role, address account, address sender)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseRoleGranted(log types.Log) (*MockSuperGovernorRoleGranted, error) {
	event := new(MockSuperGovernorRoleGranted)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorRoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the MockSuperGovernor contract.
type MockSuperGovernorRoleRevokedIterator struct {
	Event *MockSuperGovernorRoleRevoked // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorRoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorRoleRevoked)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorRoleRevoked)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorRoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorRoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorRoleRevoked represents a RoleRevoked event raised by the MockSuperGovernor contract.
type MockSuperGovernorRoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 role, address account, address sender)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterRoleRevoked(opts *bind.FilterOpts) (*MockSuperGovernorRoleRevokedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "RoleRevoked")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorRoleRevokedIterator{contract: _MockSuperGovernor.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 role, address account, address sender)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorRoleRevoked) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "RoleRevoked")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorRoleRevoked)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRoleRevoked is a log parse operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 role, address account, address sender)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseRoleRevoked(log types.Log) (*MockSuperGovernorRoleRevoked, error) {
	event := new(MockSuperGovernorRoleRevoked)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorSuperBankHookMerkleRootProposedIterator is returned from FilterSuperBankHookMerkleRootProposed and is used to iterate over the raw logs and unpacked data for SuperBankHookMerkleRootProposed events raised by the MockSuperGovernor contract.
type MockSuperGovernorSuperBankHookMerkleRootProposedIterator struct {
	Event *MockSuperGovernorSuperBankHookMerkleRootProposed // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorSuperBankHookMerkleRootProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorSuperBankHookMerkleRootProposed)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorSuperBankHookMerkleRootProposed)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorSuperBankHookMerkleRootProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorSuperBankHookMerkleRootProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorSuperBankHookMerkleRootProposed represents a SuperBankHookMerkleRootProposed event raised by the MockSuperGovernor contract.
type MockSuperGovernorSuperBankHookMerkleRootProposed struct {
	Hook          common.Address
	NewRoot       [32]byte
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterSuperBankHookMerkleRootProposed is a free log retrieval operation binding the contract event 0x2f45381bbf8fc39bccf5516ecef3bec5e43aed86711ddaa35c12ab2d6073fd36.
//
// Solidity: event SuperBankHookMerkleRootProposed(address hook, bytes32 newRoot, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterSuperBankHookMerkleRootProposed(opts *bind.FilterOpts) (*MockSuperGovernorSuperBankHookMerkleRootProposedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "SuperBankHookMerkleRootProposed")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorSuperBankHookMerkleRootProposedIterator{contract: _MockSuperGovernor.contract, event: "SuperBankHookMerkleRootProposed", logs: logs, sub: sub}, nil
}

// WatchSuperBankHookMerkleRootProposed is a free log subscription operation binding the contract event 0x2f45381bbf8fc39bccf5516ecef3bec5e43aed86711ddaa35c12ab2d6073fd36.
//
// Solidity: event SuperBankHookMerkleRootProposed(address hook, bytes32 newRoot, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchSuperBankHookMerkleRootProposed(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorSuperBankHookMerkleRootProposed) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "SuperBankHookMerkleRootProposed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorSuperBankHookMerkleRootProposed)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "SuperBankHookMerkleRootProposed", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseSuperBankHookMerkleRootProposed is a log parse operation binding the contract event 0x2f45381bbf8fc39bccf5516ecef3bec5e43aed86711ddaa35c12ab2d6073fd36.
//
// Solidity: event SuperBankHookMerkleRootProposed(address hook, bytes32 newRoot, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseSuperBankHookMerkleRootProposed(log types.Log) (*MockSuperGovernorSuperBankHookMerkleRootProposed, error) {
	event := new(MockSuperGovernorSuperBankHookMerkleRootProposed)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "SuperBankHookMerkleRootProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorSuperBankHookMerkleRootUpdatedIterator is returned from FilterSuperBankHookMerkleRootUpdated and is used to iterate over the raw logs and unpacked data for SuperBankHookMerkleRootUpdated events raised by the MockSuperGovernor contract.
type MockSuperGovernorSuperBankHookMerkleRootUpdatedIterator struct {
	Event *MockSuperGovernorSuperBankHookMerkleRootUpdated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorSuperBankHookMerkleRootUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorSuperBankHookMerkleRootUpdated)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorSuperBankHookMerkleRootUpdated)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorSuperBankHookMerkleRootUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorSuperBankHookMerkleRootUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorSuperBankHookMerkleRootUpdated represents a SuperBankHookMerkleRootUpdated event raised by the MockSuperGovernor contract.
type MockSuperGovernorSuperBankHookMerkleRootUpdated struct {
	Hook    common.Address
	NewRoot [32]byte
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterSuperBankHookMerkleRootUpdated is a free log retrieval operation binding the contract event 0xac299fc62dbe9994754db34d3374ec4eb38e185895e08b5bbffa75e98bf2a53f.
//
// Solidity: event SuperBankHookMerkleRootUpdated(address hook, bytes32 newRoot)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterSuperBankHookMerkleRootUpdated(opts *bind.FilterOpts) (*MockSuperGovernorSuperBankHookMerkleRootUpdatedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "SuperBankHookMerkleRootUpdated")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorSuperBankHookMerkleRootUpdatedIterator{contract: _MockSuperGovernor.contract, event: "SuperBankHookMerkleRootUpdated", logs: logs, sub: sub}, nil
}

// WatchSuperBankHookMerkleRootUpdated is a free log subscription operation binding the contract event 0xac299fc62dbe9994754db34d3374ec4eb38e185895e08b5bbffa75e98bf2a53f.
//
// Solidity: event SuperBankHookMerkleRootUpdated(address hook, bytes32 newRoot)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchSuperBankHookMerkleRootUpdated(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorSuperBankHookMerkleRootUpdated) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "SuperBankHookMerkleRootUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorSuperBankHookMerkleRootUpdated)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "SuperBankHookMerkleRootUpdated", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseSuperBankHookMerkleRootUpdated is a log parse operation binding the contract event 0xac299fc62dbe9994754db34d3374ec4eb38e185895e08b5bbffa75e98bf2a53f.
//
// Solidity: event SuperBankHookMerkleRootUpdated(address hook, bytes32 newRoot)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseSuperBankHookMerkleRootUpdated(log types.Log) (*MockSuperGovernorSuperBankHookMerkleRootUpdated, error) {
	event := new(MockSuperGovernorSuperBankHookMerkleRootUpdated)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "SuperBankHookMerkleRootUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorSuperformManagerAddedIterator is returned from FilterSuperformManagerAdded and is used to iterate over the raw logs and unpacked data for SuperformManagerAdded events raised by the MockSuperGovernor contract.
type MockSuperGovernorSuperformManagerAddedIterator struct {
	Event *MockSuperGovernorSuperformManagerAdded // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorSuperformManagerAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorSuperformManagerAdded)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorSuperformManagerAdded)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorSuperformManagerAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorSuperformManagerAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorSuperformManagerAdded represents a SuperformManagerAdded event raised by the MockSuperGovernor contract.
type MockSuperGovernorSuperformManagerAdded struct {
	Manager common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterSuperformManagerAdded is a free log retrieval operation binding the contract event 0x12c16151d1e0db8865cc79e38b297dcc5b372789b7efc7cc4460df4e3a4afbd6.
//
// Solidity: event SuperformManagerAdded(address manager)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterSuperformManagerAdded(opts *bind.FilterOpts) (*MockSuperGovernorSuperformManagerAddedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "SuperformManagerAdded")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorSuperformManagerAddedIterator{contract: _MockSuperGovernor.contract, event: "SuperformManagerAdded", logs: logs, sub: sub}, nil
}

// WatchSuperformManagerAdded is a free log subscription operation binding the contract event 0x12c16151d1e0db8865cc79e38b297dcc5b372789b7efc7cc4460df4e3a4afbd6.
//
// Solidity: event SuperformManagerAdded(address manager)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchSuperformManagerAdded(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorSuperformManagerAdded) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "SuperformManagerAdded")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorSuperformManagerAdded)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "SuperformManagerAdded", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseSuperformManagerAdded is a log parse operation binding the contract event 0x12c16151d1e0db8865cc79e38b297dcc5b372789b7efc7cc4460df4e3a4afbd6.
//
// Solidity: event SuperformManagerAdded(address manager)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseSuperformManagerAdded(log types.Log) (*MockSuperGovernorSuperformManagerAdded, error) {
	event := new(MockSuperGovernorSuperformManagerAdded)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "SuperformManagerAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorSuperformManagerRemovedIterator is returned from FilterSuperformManagerRemoved and is used to iterate over the raw logs and unpacked data for SuperformManagerRemoved events raised by the MockSuperGovernor contract.
type MockSuperGovernorSuperformManagerRemovedIterator struct {
	Event *MockSuperGovernorSuperformManagerRemoved // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorSuperformManagerRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorSuperformManagerRemoved)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorSuperformManagerRemoved)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorSuperformManagerRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorSuperformManagerRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorSuperformManagerRemoved represents a SuperformManagerRemoved event raised by the MockSuperGovernor contract.
type MockSuperGovernorSuperformManagerRemoved struct {
	Manager common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterSuperformManagerRemoved is a free log retrieval operation binding the contract event 0x9ea6376bcd095bc346ab7f5c534391c1a6ba1bb5153caf5e068742acd4f55162.
//
// Solidity: event SuperformManagerRemoved(address manager)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterSuperformManagerRemoved(opts *bind.FilterOpts) (*MockSuperGovernorSuperformManagerRemovedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "SuperformManagerRemoved")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorSuperformManagerRemovedIterator{contract: _MockSuperGovernor.contract, event: "SuperformManagerRemoved", logs: logs, sub: sub}, nil
}

// WatchSuperformManagerRemoved is a free log subscription operation binding the contract event 0x9ea6376bcd095bc346ab7f5c534391c1a6ba1bb5153caf5e068742acd4f55162.
//
// Solidity: event SuperformManagerRemoved(address manager)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchSuperformManagerRemoved(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorSuperformManagerRemoved) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "SuperformManagerRemoved")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorSuperformManagerRemoved)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "SuperformManagerRemoved", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseSuperformManagerRemoved is a log parse operation binding the contract event 0x9ea6376bcd095bc346ab7f5c534391c1a6ba1bb5153caf5e068742acd4f55162.
//
// Solidity: event SuperformManagerRemoved(address manager)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseSuperformManagerRemoved(log types.Log) (*MockSuperGovernorSuperformManagerRemoved, error) {
	event := new(MockSuperGovernorSuperformManagerRemoved)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "SuperformManagerRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorUpkeepPaymentsChangeProposedIterator is returned from FilterUpkeepPaymentsChangeProposed and is used to iterate over the raw logs and unpacked data for UpkeepPaymentsChangeProposed events raised by the MockSuperGovernor contract.
type MockSuperGovernorUpkeepPaymentsChangeProposedIterator struct {
	Event *MockSuperGovernorUpkeepPaymentsChangeProposed // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorUpkeepPaymentsChangeProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorUpkeepPaymentsChangeProposed)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorUpkeepPaymentsChangeProposed)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorUpkeepPaymentsChangeProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorUpkeepPaymentsChangeProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorUpkeepPaymentsChangeProposed represents a UpkeepPaymentsChangeProposed event raised by the MockSuperGovernor contract.
type MockSuperGovernorUpkeepPaymentsChangeProposed struct {
	Enabled       bool
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterUpkeepPaymentsChangeProposed is a free log retrieval operation binding the contract event 0x3ccaf2442d2b29874fd84ceba9675d97d4dde7d521be650f67faab29a9afb10a.
//
// Solidity: event UpkeepPaymentsChangeProposed(bool enabled, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterUpkeepPaymentsChangeProposed(opts *bind.FilterOpts) (*MockSuperGovernorUpkeepPaymentsChangeProposedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "UpkeepPaymentsChangeProposed")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorUpkeepPaymentsChangeProposedIterator{contract: _MockSuperGovernor.contract, event: "UpkeepPaymentsChangeProposed", logs: logs, sub: sub}, nil
}

// WatchUpkeepPaymentsChangeProposed is a free log subscription operation binding the contract event 0x3ccaf2442d2b29874fd84ceba9675d97d4dde7d521be650f67faab29a9afb10a.
//
// Solidity: event UpkeepPaymentsChangeProposed(bool enabled, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchUpkeepPaymentsChangeProposed(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorUpkeepPaymentsChangeProposed) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "UpkeepPaymentsChangeProposed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorUpkeepPaymentsChangeProposed)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "UpkeepPaymentsChangeProposed", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseUpkeepPaymentsChangeProposed is a log parse operation binding the contract event 0x3ccaf2442d2b29874fd84ceba9675d97d4dde7d521be650f67faab29a9afb10a.
//
// Solidity: event UpkeepPaymentsChangeProposed(bool enabled, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseUpkeepPaymentsChangeProposed(log types.Log) (*MockSuperGovernorUpkeepPaymentsChangeProposed, error) {
	event := new(MockSuperGovernorUpkeepPaymentsChangeProposed)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "UpkeepPaymentsChangeProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorUpkeepPaymentsChangedIterator is returned from FilterUpkeepPaymentsChanged and is used to iterate over the raw logs and unpacked data for UpkeepPaymentsChanged events raised by the MockSuperGovernor contract.
type MockSuperGovernorUpkeepPaymentsChangedIterator struct {
	Event *MockSuperGovernorUpkeepPaymentsChanged // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorUpkeepPaymentsChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorUpkeepPaymentsChanged)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorUpkeepPaymentsChanged)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorUpkeepPaymentsChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorUpkeepPaymentsChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorUpkeepPaymentsChanged represents a UpkeepPaymentsChanged event raised by the MockSuperGovernor contract.
type MockSuperGovernorUpkeepPaymentsChanged struct {
	Enabled bool
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterUpkeepPaymentsChanged is a free log retrieval operation binding the contract event 0x434397fd19989030741a6dd038e45b209af876fb83cafbd750fc5ad51be91ce9.
//
// Solidity: event UpkeepPaymentsChanged(bool enabled)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterUpkeepPaymentsChanged(opts *bind.FilterOpts) (*MockSuperGovernorUpkeepPaymentsChangedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "UpkeepPaymentsChanged")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorUpkeepPaymentsChangedIterator{contract: _MockSuperGovernor.contract, event: "UpkeepPaymentsChanged", logs: logs, sub: sub}, nil
}

// WatchUpkeepPaymentsChanged is a free log subscription operation binding the contract event 0x434397fd19989030741a6dd038e45b209af876fb83cafbd750fc5ad51be91ce9.
//
// Solidity: event UpkeepPaymentsChanged(bool enabled)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchUpkeepPaymentsChanged(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorUpkeepPaymentsChanged) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "UpkeepPaymentsChanged")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorUpkeepPaymentsChanged)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "UpkeepPaymentsChanged", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseUpkeepPaymentsChanged is a log parse operation binding the contract event 0x434397fd19989030741a6dd038e45b209af876fb83cafbd750fc5ad51be91ce9.
//
// Solidity: event UpkeepPaymentsChanged(bool enabled)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseUpkeepPaymentsChanged(log types.Log) (*MockSuperGovernorUpkeepPaymentsChanged, error) {
	event := new(MockSuperGovernorUpkeepPaymentsChanged)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "UpkeepPaymentsChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorValidatorAddedIterator is returned from FilterValidatorAdded and is used to iterate over the raw logs and unpacked data for ValidatorAdded events raised by the MockSuperGovernor contract.
type MockSuperGovernorValidatorAddedIterator struct {
	Event *MockSuperGovernorValidatorAdded // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorValidatorAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorValidatorAdded)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorValidatorAdded)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorValidatorAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorValidatorAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorValidatorAdded represents a ValidatorAdded event raised by the MockSuperGovernor contract.
type MockSuperGovernorValidatorAdded struct {
	Validator common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterValidatorAdded is a free log retrieval operation binding the contract event 0xe366c1c0452ed8eec96861e9e54141ebff23c9ec89fe27b996b45f5ec3884987.
//
// Solidity: event ValidatorAdded(address validator)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterValidatorAdded(opts *bind.FilterOpts) (*MockSuperGovernorValidatorAddedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "ValidatorAdded")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorValidatorAddedIterator{contract: _MockSuperGovernor.contract, event: "ValidatorAdded", logs: logs, sub: sub}, nil
}

// WatchValidatorAdded is a free log subscription operation binding the contract event 0xe366c1c0452ed8eec96861e9e54141ebff23c9ec89fe27b996b45f5ec3884987.
//
// Solidity: event ValidatorAdded(address validator)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchValidatorAdded(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorValidatorAdded) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "ValidatorAdded")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorValidatorAdded)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "ValidatorAdded", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseValidatorAdded is a log parse operation binding the contract event 0xe366c1c0452ed8eec96861e9e54141ebff23c9ec89fe27b996b45f5ec3884987.
//
// Solidity: event ValidatorAdded(address validator)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseValidatorAdded(log types.Log) (*MockSuperGovernorValidatorAdded, error) {
	event := new(MockSuperGovernorValidatorAdded)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "ValidatorAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorValidatorRemovedIterator is returned from FilterValidatorRemoved and is used to iterate over the raw logs and unpacked data for ValidatorRemoved events raised by the MockSuperGovernor contract.
type MockSuperGovernorValidatorRemovedIterator struct {
	Event *MockSuperGovernorValidatorRemoved // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorValidatorRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorValidatorRemoved)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorValidatorRemoved)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorValidatorRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorValidatorRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorValidatorRemoved represents a ValidatorRemoved event raised by the MockSuperGovernor contract.
type MockSuperGovernorValidatorRemoved struct {
	Validator common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterValidatorRemoved is a free log retrieval operation binding the contract event 0xe1434e25d6611e0db941968fdc97811c982ac1602e951637d206f5fdda9dd8f1.
//
// Solidity: event ValidatorRemoved(address validator)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterValidatorRemoved(opts *bind.FilterOpts) (*MockSuperGovernorValidatorRemovedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "ValidatorRemoved")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorValidatorRemovedIterator{contract: _MockSuperGovernor.contract, event: "ValidatorRemoved", logs: logs, sub: sub}, nil
}

// WatchValidatorRemoved is a free log subscription operation binding the contract event 0xe1434e25d6611e0db941968fdc97811c982ac1602e951637d206f5fdda9dd8f1.
//
// Solidity: event ValidatorRemoved(address validator)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchValidatorRemoved(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorValidatorRemoved) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "ValidatorRemoved")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorValidatorRemoved)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "ValidatorRemoved", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseValidatorRemoved is a log parse operation binding the contract event 0xe1434e25d6611e0db941968fdc97811c982ac1602e951637d206f5fdda9dd8f1.
//
// Solidity: event ValidatorRemoved(address validator)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseValidatorRemoved(log types.Log) (*MockSuperGovernorValidatorRemoved, error) {
	event := new(MockSuperGovernorValidatorRemoved)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "ValidatorRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorVaultBankAddressAddedIterator is returned from FilterVaultBankAddressAdded and is used to iterate over the raw logs and unpacked data for VaultBankAddressAdded events raised by the MockSuperGovernor contract.
type MockSuperGovernorVaultBankAddressAddedIterator struct {
	Event *MockSuperGovernorVaultBankAddressAdded // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorVaultBankAddressAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorVaultBankAddressAdded)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorVaultBankAddressAdded)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorVaultBankAddressAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorVaultBankAddressAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorVaultBankAddressAdded represents a VaultBankAddressAdded event raised by the MockSuperGovernor contract.
type MockSuperGovernorVaultBankAddressAdded struct {
	ChainId   uint64
	VaultBank common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterVaultBankAddressAdded is a free log retrieval operation binding the contract event 0x5cb45d0d54e4695b28909810784917d1e30ad097489dc83bfc62abac3097f169.
//
// Solidity: event VaultBankAddressAdded(uint64 chainId, address vaultBank)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterVaultBankAddressAdded(opts *bind.FilterOpts) (*MockSuperGovernorVaultBankAddressAddedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "VaultBankAddressAdded")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorVaultBankAddressAddedIterator{contract: _MockSuperGovernor.contract, event: "VaultBankAddressAdded", logs: logs, sub: sub}, nil
}

// WatchVaultBankAddressAdded is a free log subscription operation binding the contract event 0x5cb45d0d54e4695b28909810784917d1e30ad097489dc83bfc62abac3097f169.
//
// Solidity: event VaultBankAddressAdded(uint64 chainId, address vaultBank)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchVaultBankAddressAdded(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorVaultBankAddressAdded) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "VaultBankAddressAdded")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorVaultBankAddressAdded)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "VaultBankAddressAdded", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseVaultBankAddressAdded is a log parse operation binding the contract event 0x5cb45d0d54e4695b28909810784917d1e30ad097489dc83bfc62abac3097f169.
//
// Solidity: event VaultBankAddressAdded(uint64 chainId, address vaultBank)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseVaultBankAddressAdded(log types.Log) (*MockSuperGovernorVaultBankAddressAdded, error) {
	event := new(MockSuperGovernorVaultBankAddressAdded)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "VaultBankAddressAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorVaultBankHookMerkleRootProposedIterator is returned from FilterVaultBankHookMerkleRootProposed and is used to iterate over the raw logs and unpacked data for VaultBankHookMerkleRootProposed events raised by the MockSuperGovernor contract.
type MockSuperGovernorVaultBankHookMerkleRootProposedIterator struct {
	Event *MockSuperGovernorVaultBankHookMerkleRootProposed // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorVaultBankHookMerkleRootProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorVaultBankHookMerkleRootProposed)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorVaultBankHookMerkleRootProposed)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorVaultBankHookMerkleRootProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorVaultBankHookMerkleRootProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorVaultBankHookMerkleRootProposed represents a VaultBankHookMerkleRootProposed event raised by the MockSuperGovernor contract.
type MockSuperGovernorVaultBankHookMerkleRootProposed struct {
	Hook          common.Address
	NewRoot       [32]byte
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterVaultBankHookMerkleRootProposed is a free log retrieval operation binding the contract event 0xfed894aa6018dfdc5cdaaa43cc8ab59cadae93a82571bdcf49f5219065a366dd.
//
// Solidity: event VaultBankHookMerkleRootProposed(address hook, bytes32 newRoot, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterVaultBankHookMerkleRootProposed(opts *bind.FilterOpts) (*MockSuperGovernorVaultBankHookMerkleRootProposedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "VaultBankHookMerkleRootProposed")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorVaultBankHookMerkleRootProposedIterator{contract: _MockSuperGovernor.contract, event: "VaultBankHookMerkleRootProposed", logs: logs, sub: sub}, nil
}

// WatchVaultBankHookMerkleRootProposed is a free log subscription operation binding the contract event 0xfed894aa6018dfdc5cdaaa43cc8ab59cadae93a82571bdcf49f5219065a366dd.
//
// Solidity: event VaultBankHookMerkleRootProposed(address hook, bytes32 newRoot, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchVaultBankHookMerkleRootProposed(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorVaultBankHookMerkleRootProposed) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "VaultBankHookMerkleRootProposed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorVaultBankHookMerkleRootProposed)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "VaultBankHookMerkleRootProposed", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseVaultBankHookMerkleRootProposed is a log parse operation binding the contract event 0xfed894aa6018dfdc5cdaaa43cc8ab59cadae93a82571bdcf49f5219065a366dd.
//
// Solidity: event VaultBankHookMerkleRootProposed(address hook, bytes32 newRoot, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseVaultBankHookMerkleRootProposed(log types.Log) (*MockSuperGovernorVaultBankHookMerkleRootProposed, error) {
	event := new(MockSuperGovernorVaultBankHookMerkleRootProposed)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "VaultBankHookMerkleRootProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorVaultBankHookMerkleRootUpdatedIterator is returned from FilterVaultBankHookMerkleRootUpdated and is used to iterate over the raw logs and unpacked data for VaultBankHookMerkleRootUpdated events raised by the MockSuperGovernor contract.
type MockSuperGovernorVaultBankHookMerkleRootUpdatedIterator struct {
	Event *MockSuperGovernorVaultBankHookMerkleRootUpdated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorVaultBankHookMerkleRootUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorVaultBankHookMerkleRootUpdated)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorVaultBankHookMerkleRootUpdated)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorVaultBankHookMerkleRootUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorVaultBankHookMerkleRootUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorVaultBankHookMerkleRootUpdated represents a VaultBankHookMerkleRootUpdated event raised by the MockSuperGovernor contract.
type MockSuperGovernorVaultBankHookMerkleRootUpdated struct {
	Hook    common.Address
	NewRoot [32]byte
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterVaultBankHookMerkleRootUpdated is a free log retrieval operation binding the contract event 0x86b54825d63e1f082661065387182da51e6eb5a1ae1e63e1b0fd8a99aaf7e11f.
//
// Solidity: event VaultBankHookMerkleRootUpdated(address hook, bytes32 newRoot)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterVaultBankHookMerkleRootUpdated(opts *bind.FilterOpts) (*MockSuperGovernorVaultBankHookMerkleRootUpdatedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "VaultBankHookMerkleRootUpdated")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorVaultBankHookMerkleRootUpdatedIterator{contract: _MockSuperGovernor.contract, event: "VaultBankHookMerkleRootUpdated", logs: logs, sub: sub}, nil
}

// WatchVaultBankHookMerkleRootUpdated is a free log subscription operation binding the contract event 0x86b54825d63e1f082661065387182da51e6eb5a1ae1e63e1b0fd8a99aaf7e11f.
//
// Solidity: event VaultBankHookMerkleRootUpdated(address hook, bytes32 newRoot)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchVaultBankHookMerkleRootUpdated(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorVaultBankHookMerkleRootUpdated) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "VaultBankHookMerkleRootUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorVaultBankHookMerkleRootUpdated)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "VaultBankHookMerkleRootUpdated", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseVaultBankHookMerkleRootUpdated is a log parse operation binding the contract event 0x86b54825d63e1f082661065387182da51e6eb5a1ae1e63e1b0fd8a99aaf7e11f.
//
// Solidity: event VaultBankHookMerkleRootUpdated(address hook, bytes32 newRoot)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseVaultBankHookMerkleRootUpdated(log types.Log) (*MockSuperGovernorVaultBankHookMerkleRootUpdated, error) {
	event := new(MockSuperGovernorVaultBankHookMerkleRootUpdated)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "VaultBankHookMerkleRootUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorWhitelistedIncentiveTokensAddedIterator is returned from FilterWhitelistedIncentiveTokensAdded and is used to iterate over the raw logs and unpacked data for WhitelistedIncentiveTokensAdded events raised by the MockSuperGovernor contract.
type MockSuperGovernorWhitelistedIncentiveTokensAddedIterator struct {
	Event *MockSuperGovernorWhitelistedIncentiveTokensAdded // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorWhitelistedIncentiveTokensAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorWhitelistedIncentiveTokensAdded)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorWhitelistedIncentiveTokensAdded)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorWhitelistedIncentiveTokensAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorWhitelistedIncentiveTokensAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorWhitelistedIncentiveTokensAdded represents a WhitelistedIncentiveTokensAdded event raised by the MockSuperGovernor contract.
type MockSuperGovernorWhitelistedIncentiveTokensAdded struct {
	Tokens []common.Address
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterWhitelistedIncentiveTokensAdded is a free log retrieval operation binding the contract event 0xfcea9a0a0943a560b6065073054ea3e19aa43e137d7e753876775ad1179847c6.
//
// Solidity: event WhitelistedIncentiveTokensAdded(address[] tokens)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterWhitelistedIncentiveTokensAdded(opts *bind.FilterOpts) (*MockSuperGovernorWhitelistedIncentiveTokensAddedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "WhitelistedIncentiveTokensAdded")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorWhitelistedIncentiveTokensAddedIterator{contract: _MockSuperGovernor.contract, event: "WhitelistedIncentiveTokensAdded", logs: logs, sub: sub}, nil
}

// WatchWhitelistedIncentiveTokensAdded is a free log subscription operation binding the contract event 0xfcea9a0a0943a560b6065073054ea3e19aa43e137d7e753876775ad1179847c6.
//
// Solidity: event WhitelistedIncentiveTokensAdded(address[] tokens)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchWhitelistedIncentiveTokensAdded(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorWhitelistedIncentiveTokensAdded) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "WhitelistedIncentiveTokensAdded")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorWhitelistedIncentiveTokensAdded)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "WhitelistedIncentiveTokensAdded", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseWhitelistedIncentiveTokensAdded is a log parse operation binding the contract event 0xfcea9a0a0943a560b6065073054ea3e19aa43e137d7e753876775ad1179847c6.
//
// Solidity: event WhitelistedIncentiveTokensAdded(address[] tokens)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseWhitelistedIncentiveTokensAdded(log types.Log) (*MockSuperGovernorWhitelistedIncentiveTokensAdded, error) {
	event := new(MockSuperGovernorWhitelistedIncentiveTokensAdded)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "WhitelistedIncentiveTokensAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorWhitelistedIncentiveTokensProposedIterator is returned from FilterWhitelistedIncentiveTokensProposed and is used to iterate over the raw logs and unpacked data for WhitelistedIncentiveTokensProposed events raised by the MockSuperGovernor contract.
type MockSuperGovernorWhitelistedIncentiveTokensProposedIterator struct {
	Event *MockSuperGovernorWhitelistedIncentiveTokensProposed // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorWhitelistedIncentiveTokensProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorWhitelistedIncentiveTokensProposed)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorWhitelistedIncentiveTokensProposed)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorWhitelistedIncentiveTokensProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorWhitelistedIncentiveTokensProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorWhitelistedIncentiveTokensProposed represents a WhitelistedIncentiveTokensProposed event raised by the MockSuperGovernor contract.
type MockSuperGovernorWhitelistedIncentiveTokensProposed struct {
	Tokens        []common.Address
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterWhitelistedIncentiveTokensProposed is a free log retrieval operation binding the contract event 0xdc25fd6bdd21f8da9b5b76d30960d45120a708e1f91ae912871da0fc21454979.
//
// Solidity: event WhitelistedIncentiveTokensProposed(address[] tokens, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterWhitelistedIncentiveTokensProposed(opts *bind.FilterOpts) (*MockSuperGovernorWhitelistedIncentiveTokensProposedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "WhitelistedIncentiveTokensProposed")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorWhitelistedIncentiveTokensProposedIterator{contract: _MockSuperGovernor.contract, event: "WhitelistedIncentiveTokensProposed", logs: logs, sub: sub}, nil
}

// WatchWhitelistedIncentiveTokensProposed is a free log subscription operation binding the contract event 0xdc25fd6bdd21f8da9b5b76d30960d45120a708e1f91ae912871da0fc21454979.
//
// Solidity: event WhitelistedIncentiveTokensProposed(address[] tokens, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchWhitelistedIncentiveTokensProposed(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorWhitelistedIncentiveTokensProposed) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "WhitelistedIncentiveTokensProposed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorWhitelistedIncentiveTokensProposed)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "WhitelistedIncentiveTokensProposed", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseWhitelistedIncentiveTokensProposed is a log parse operation binding the contract event 0xdc25fd6bdd21f8da9b5b76d30960d45120a708e1f91ae912871da0fc21454979.
//
// Solidity: event WhitelistedIncentiveTokensProposed(address[] tokens, uint256 effectiveTime)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseWhitelistedIncentiveTokensProposed(log types.Log) (*MockSuperGovernorWhitelistedIncentiveTokensProposed, error) {
	event := new(MockSuperGovernorWhitelistedIncentiveTokensProposed)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "WhitelistedIncentiveTokensProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockSuperGovernorWhitelistedIncentiveTokensRemovedIterator is returned from FilterWhitelistedIncentiveTokensRemoved and is used to iterate over the raw logs and unpacked data for WhitelistedIncentiveTokensRemoved events raised by the MockSuperGovernor contract.
type MockSuperGovernorWhitelistedIncentiveTokensRemovedIterator struct {
	Event *MockSuperGovernorWhitelistedIncentiveTokensRemoved // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MockSuperGovernorWhitelistedIncentiveTokensRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockSuperGovernorWhitelistedIncentiveTokensRemoved)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MockSuperGovernorWhitelistedIncentiveTokensRemoved)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MockSuperGovernorWhitelistedIncentiveTokensRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockSuperGovernorWhitelistedIncentiveTokensRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockSuperGovernorWhitelistedIncentiveTokensRemoved represents a WhitelistedIncentiveTokensRemoved event raised by the MockSuperGovernor contract.
type MockSuperGovernorWhitelistedIncentiveTokensRemoved struct {
	Tokens []common.Address
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterWhitelistedIncentiveTokensRemoved is a free log retrieval operation binding the contract event 0x592ccb66164159ca890f72fc24cdab8c5fcfcfe35f7455b88e594060568ce011.
//
// Solidity: event WhitelistedIncentiveTokensRemoved(address[] tokens)
func (_MockSuperGovernor *MockSuperGovernorFilterer) FilterWhitelistedIncentiveTokensRemoved(opts *bind.FilterOpts) (*MockSuperGovernorWhitelistedIncentiveTokensRemovedIterator, error) {

	logs, sub, err := _MockSuperGovernor.contract.FilterLogs(opts, "WhitelistedIncentiveTokensRemoved")
	if err != nil {
		return nil, err
	}
	return &MockSuperGovernorWhitelistedIncentiveTokensRemovedIterator{contract: _MockSuperGovernor.contract, event: "WhitelistedIncentiveTokensRemoved", logs: logs, sub: sub}, nil
}

// WatchWhitelistedIncentiveTokensRemoved is a free log subscription operation binding the contract event 0x592ccb66164159ca890f72fc24cdab8c5fcfcfe35f7455b88e594060568ce011.
//
// Solidity: event WhitelistedIncentiveTokensRemoved(address[] tokens)
func (_MockSuperGovernor *MockSuperGovernorFilterer) WatchWhitelistedIncentiveTokensRemoved(opts *bind.WatchOpts, sink chan<- *MockSuperGovernorWhitelistedIncentiveTokensRemoved) (event.Subscription, error) {

	logs, sub, err := _MockSuperGovernor.contract.WatchLogs(opts, "WhitelistedIncentiveTokensRemoved")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockSuperGovernorWhitelistedIncentiveTokensRemoved)
				if err := _MockSuperGovernor.contract.UnpackLog(event, "WhitelistedIncentiveTokensRemoved", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseWhitelistedIncentiveTokensRemoved is a log parse operation binding the contract event 0x592ccb66164159ca890f72fc24cdab8c5fcfcfe35f7455b88e594060568ce011.
//
// Solidity: event WhitelistedIncentiveTokensRemoved(address[] tokens)
func (_MockSuperGovernor *MockSuperGovernorFilterer) ParseWhitelistedIncentiveTokensRemoved(log types.Log) (*MockSuperGovernorWhitelistedIncentiveTokensRemoved, error) {
	event := new(MockSuperGovernorWhitelistedIncentiveTokensRemoved)
	if err := _MockSuperGovernor.contract.UnpackLog(event, "WhitelistedIncentiveTokensRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
