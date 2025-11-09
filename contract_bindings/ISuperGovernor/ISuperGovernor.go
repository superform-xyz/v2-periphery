// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package ISuperGovernor

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

// ISuperGovernorMetaData contains all meta data concerning the ISuperGovernor contract.
var ISuperGovernorMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"BANK_MANAGER_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ECDSAPPSORACLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"GAS_MANAGER_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"GOVERNOR_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"GUARDIAN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ORACLE_MANAGER_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUP\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_BANK\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_GOVERNOR_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_ORACLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_VAULT_AGGREGATOR\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"TREASURY\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"UP\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addExecutor\",\"inputs\":[{\"name\":\"executor\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addSuperformManager\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addValidator\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"batchSetEmergencyPrices\",\"inputs\":[{\"name\":\"tokens\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"prices\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"batchSetOracleUptimeFeed\",\"inputs\":[{\"name\":\"dataOracles\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"uptimeOracles\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"gracePeriods\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"changeHooksRootUpdateTimelock\",\"inputs\":[{\"name\":\"newTimelock\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"changePrimaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newManager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeActivePPSOracleChange\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeFeeUpdate\",\"inputs\":[{\"name\":\"feeType\",\"type\":\"uint8\",\"internalType\":\"enumFeeType\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeMinStalenesChange\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeOracleProviderRemoval\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeOracleUpdate\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeSuperBankHookMerkleRootUpdate\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeUpkeepClaim\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeUpkeepPaymentsChange\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"freezeManagerTakeover\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getActivePPSOracle\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAddress\",\"inputs\":[{\"name\":\"key\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAllSuperformManagers\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getExecutors\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getFee\",\"inputs\":[{\"name\":\"feeType\",\"type\":\"uint8\",\"internalType\":\"enumFeeType\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getGasInfo\",\"inputs\":[{\"name\":\"oracle_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getManagersPaginated\",\"inputs\":[{\"name\":\"cursor\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"limit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"chunkOfManagers\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"next\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMinStaleness\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getPPSOracleQuorum\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedActivePPSOracle\",\"inputs\":[],\"outputs\":[{\"name\":\"proposedOracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedMinStaleness\",\"inputs\":[],\"outputs\":[{\"name\":\"proposedMinStaleness\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedSuperBankHookMerkleRoot\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"proposedRoot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedUpkeepPaymentsStatus\",\"inputs\":[],\"outputs\":[{\"name\":\"enabled\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRegisteredHooks\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSuperBankHookMerkleRoot\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSuperformManagersCount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getUpkeepCostPerSingleUpdate\",\"inputs\":[{\"name\":\"oracle_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorAt\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorConfigVersion\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidators\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorsCount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isActivePPSOracle\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isExecutor\",\"inputs\":[{\"name\":\"executor\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isGuardian\",\"inputs\":[{\"name\":\"guardian\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isHookRegistered\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isManagerTakeoverFrozen\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isSuperformManager\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isUpkeepPaymentsEnabled\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isValidator\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proposeActivePPSOracle\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeFee\",\"inputs\":[{\"name\":\"feeType\",\"type\":\"uint8\",\"internalType\":\"enumFeeType\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeGlobalHooksRoot\",\"inputs\":[{\"name\":\"newRoot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeMinStaleness\",\"inputs\":[{\"name\":\"newMinStaleness\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeSuperBankHookMerkleRoot\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"proposedRoot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeUpkeepPaymentsChange\",\"inputs\":[{\"name\":\"enabled\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"queueOracleProviderRemoval\",\"inputs\":[{\"name\":\"providers\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"queueOracleUpdate\",\"inputs\":[{\"name\":\"bases\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"quotes\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"providers\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"},{\"name\":\"feeds\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"registerHook\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeExecutor\",\"inputs\":[{\"name\":\"executor\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeSuperformManager\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeValidator\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"callerConfirmation\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setActivePPSOracle\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setAddress\",\"inputs\":[{\"name\":\"key\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"value\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setEmergencyPrice\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"price\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGasInfo\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"gasIncreasePerEntryBatch\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGlobalHooksRootVetoStatus\",\"inputs\":[{\"name\":\"vetoed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setOracleFeedMaxStaleness\",\"inputs\":[{\"name\":\"feed\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newMaxStaleness\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setOracleFeedMaxStalenessBatch\",\"inputs\":[{\"name\":\"feeds\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"newMaxStalenessList\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setOracleMaxStaleness\",\"inputs\":[{\"name\":\"newMaxStaleness\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setPPSOracleQuorum\",\"inputs\":[{\"name\":\"quorum\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setStrategyHooksRootVetoStatus\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"vetoed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"slashStake\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"unregisterHook\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"ActivePPSOracleChanged\",\"inputs\":[{\"name\":\"oldOracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ActivePPSOracleProposed\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ActivePPSOracleSet\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AddressSet\",\"inputs\":[{\"name\":\"key\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"oldValue\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"value\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ExecutorAdded\",\"inputs\":[{\"name\":\"executor\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ExecutorRemoved\",\"inputs\":[{\"name\":\"executor\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FeeProposed\",\"inputs\":[{\"name\":\"feeType\",\"type\":\"uint8\",\"indexed\":true,\"internalType\":\"enumFeeType\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FeeUpdated\",\"inputs\":[{\"name\":\"feeType\",\"type\":\"uint8\",\"indexed\":true,\"internalType\":\"enumFeeType\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"GasInfoSet\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"gasIncreasePerEntryBatch\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"HookApproved\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"HookRemoved\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ManagerTakeoversFrozen\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MinStalenesChanged\",\"inputs\":[{\"name\":\"newMinStaleness\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MinStalenesProposed\",\"inputs\":[{\"name\":\"newMinStaleness\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSOracleQuorumUpdated\",\"inputs\":[{\"name\":\"quorum\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ProtectedKeeperRegistered\",\"inputs\":[{\"name\":\"keeper\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ProtectedKeeperUnregistered\",\"inputs\":[{\"name\":\"keeper\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RevenueShareUpdated\",\"inputs\":[{\"name\":\"share\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SuperBankHookMerkleRootProposed\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newRoot\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SuperBankHookMerkleRootUpdated\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newRoot\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SuperformManagerAdded\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SuperformManagerRemoved\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepPaymentsChangeProposed\",\"inputs\":[{\"name\":\"enabled\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepPaymentsChanged\",\"inputs\":[{\"name\":\"enabled\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorAdded\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"blockNumber\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorRemoved\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"blockNumber\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AccessControlBadConfirmation\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"neededRole\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"CONTRACT_ALREADY_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CONTRACT_NOT_FOUND\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"EXECUTOR_ALREADY_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"EXECUTOR_NOT_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"HOOK_ALREADY_APPROVED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"HOOK_NOT_APPROVED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_CHAIN_ID\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_FEE_VALUE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_GAS_INFO\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_QUORUM\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_REVENUE_SHARE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_TIMESTAMP\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"KEEPER_ALREADY_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"KEEPER_NOT_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MANAGER_ALREADY_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MANAGER_NOT_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MANAGER_TAKEOVERS_FROZEN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MAX_STALENESS_TOO_LOW\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MUST_USE_TIMELOCK_FOR_CHANGE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_ACTIVE_PPS_ORACLE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_PENDING_CHANGE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_PROPOSED_FEE\",\"inputs\":[{\"name\":\"feeType\",\"type\":\"uint8\",\"internalType\":\"enumFeeType\"}]},{\"type\":\"error\",\"name\":\"NO_PROPOSED_MERKLE_ROOT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_PROPOSED_MIN_STALENESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_PROPOSED_PPS_ORACLE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ONLY_GOVERNOR\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PRICE_NOT_FOUND\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"STALE_ORACLE_PRICE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SUPER_ORACLE_NOT_FOUND\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"TIMELOCK_NOT_EXPIRED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UP_NOT_FOUND\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"VALIDATOR_ALREADY_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"VALIDATOR_NOT_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_PROPOSED_MERKLE_ROOT\",\"inputs\":[]}]",
}

// ISuperGovernorABI is the input ABI used to generate the binding from.
// Deprecated: Use ISuperGovernorMetaData.ABI instead.
var ISuperGovernorABI = ISuperGovernorMetaData.ABI

// ISuperGovernor is an auto generated Go binding around an Ethereum contract.
type ISuperGovernor struct {
	ISuperGovernorCaller     // Read-only binding to the contract
	ISuperGovernorTransactor // Write-only binding to the contract
	ISuperGovernorFilterer   // Log filterer for contract events
}

// ISuperGovernorCaller is an auto generated read-only Go binding around an Ethereum contract.
type ISuperGovernorCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ISuperGovernorTransactor is an auto generated write-only Go binding around an Ethereum contract.
type ISuperGovernorTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ISuperGovernorFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type ISuperGovernorFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ISuperGovernorSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type ISuperGovernorSession struct {
	Contract     *ISuperGovernor   // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// ISuperGovernorCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type ISuperGovernorCallerSession struct {
	Contract *ISuperGovernorCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts         // Call options to use throughout this session
}

// ISuperGovernorTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type ISuperGovernorTransactorSession struct {
	Contract     *ISuperGovernorTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts         // Transaction auth options to use throughout this session
}

// ISuperGovernorRaw is an auto generated low-level Go binding around an Ethereum contract.
type ISuperGovernorRaw struct {
	Contract *ISuperGovernor // Generic contract binding to access the raw methods on
}

// ISuperGovernorCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type ISuperGovernorCallerRaw struct {
	Contract *ISuperGovernorCaller // Generic read-only contract binding to access the raw methods on
}

// ISuperGovernorTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type ISuperGovernorTransactorRaw struct {
	Contract *ISuperGovernorTransactor // Generic write-only contract binding to access the raw methods on
}

// NewISuperGovernor creates a new instance of ISuperGovernor, bound to a specific deployed contract.
func NewISuperGovernor(address common.Address, backend bind.ContractBackend) (*ISuperGovernor, error) {
	contract, err := bindISuperGovernor(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernor{ISuperGovernorCaller: ISuperGovernorCaller{contract: contract}, ISuperGovernorTransactor: ISuperGovernorTransactor{contract: contract}, ISuperGovernorFilterer: ISuperGovernorFilterer{contract: contract}}, nil
}

// NewISuperGovernorCaller creates a new read-only instance of ISuperGovernor, bound to a specific deployed contract.
func NewISuperGovernorCaller(address common.Address, caller bind.ContractCaller) (*ISuperGovernorCaller, error) {
	contract, err := bindISuperGovernor(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorCaller{contract: contract}, nil
}

// NewISuperGovernorTransactor creates a new write-only instance of ISuperGovernor, bound to a specific deployed contract.
func NewISuperGovernorTransactor(address common.Address, transactor bind.ContractTransactor) (*ISuperGovernorTransactor, error) {
	contract, err := bindISuperGovernor(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorTransactor{contract: contract}, nil
}

// NewISuperGovernorFilterer creates a new log filterer instance of ISuperGovernor, bound to a specific deployed contract.
func NewISuperGovernorFilterer(address common.Address, filterer bind.ContractFilterer) (*ISuperGovernorFilterer, error) {
	contract, err := bindISuperGovernor(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorFilterer{contract: contract}, nil
}

// bindISuperGovernor binds a generic wrapper to an already deployed contract.
func bindISuperGovernor(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := ISuperGovernorMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_ISuperGovernor *ISuperGovernorRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _ISuperGovernor.Contract.ISuperGovernorCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_ISuperGovernor *ISuperGovernorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ISuperGovernorTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_ISuperGovernor *ISuperGovernorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ISuperGovernorTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_ISuperGovernor *ISuperGovernorCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _ISuperGovernor.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_ISuperGovernor *ISuperGovernorTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_ISuperGovernor *ISuperGovernorTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.contract.Transact(opts, method, params...)
}

// BANKMANAGERROLE is a free data retrieval call binding the contract method 0xf2157052.
//
// Solidity: function BANK_MANAGER_ROLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCaller) BANKMANAGERROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "BANK_MANAGER_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// BANKMANAGERROLE is a free data retrieval call binding the contract method 0xf2157052.
//
// Solidity: function BANK_MANAGER_ROLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorSession) BANKMANAGERROLE() ([32]byte, error) {
	return _ISuperGovernor.Contract.BANKMANAGERROLE(&_ISuperGovernor.CallOpts)
}

// BANKMANAGERROLE is a free data retrieval call binding the contract method 0xf2157052.
//
// Solidity: function BANK_MANAGER_ROLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCallerSession) BANKMANAGERROLE() ([32]byte, error) {
	return _ISuperGovernor.Contract.BANKMANAGERROLE(&_ISuperGovernor.CallOpts)
}

// ECDSAPPSORACLE is a free data retrieval call binding the contract method 0xffdb5200.
//
// Solidity: function ECDSAPPSORACLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCaller) ECDSAPPSORACLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "ECDSAPPSORACLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// ECDSAPPSORACLE is a free data retrieval call binding the contract method 0xffdb5200.
//
// Solidity: function ECDSAPPSORACLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorSession) ECDSAPPSORACLE() ([32]byte, error) {
	return _ISuperGovernor.Contract.ECDSAPPSORACLE(&_ISuperGovernor.CallOpts)
}

// ECDSAPPSORACLE is a free data retrieval call binding the contract method 0xffdb5200.
//
// Solidity: function ECDSAPPSORACLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCallerSession) ECDSAPPSORACLE() ([32]byte, error) {
	return _ISuperGovernor.Contract.ECDSAPPSORACLE(&_ISuperGovernor.CallOpts)
}

// GASMANAGERROLE is a free data retrieval call binding the contract method 0x42436beb.
//
// Solidity: function GAS_MANAGER_ROLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCaller) GASMANAGERROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "GAS_MANAGER_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GASMANAGERROLE is a free data retrieval call binding the contract method 0x42436beb.
//
// Solidity: function GAS_MANAGER_ROLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorSession) GASMANAGERROLE() ([32]byte, error) {
	return _ISuperGovernor.Contract.GASMANAGERROLE(&_ISuperGovernor.CallOpts)
}

// GASMANAGERROLE is a free data retrieval call binding the contract method 0x42436beb.
//
// Solidity: function GAS_MANAGER_ROLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCallerSession) GASMANAGERROLE() ([32]byte, error) {
	return _ISuperGovernor.Contract.GASMANAGERROLE(&_ISuperGovernor.CallOpts)
}

// GOVERNORROLE is a free data retrieval call binding the contract method 0xccc57490.
//
// Solidity: function GOVERNOR_ROLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCaller) GOVERNORROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "GOVERNOR_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GOVERNORROLE is a free data retrieval call binding the contract method 0xccc57490.
//
// Solidity: function GOVERNOR_ROLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorSession) GOVERNORROLE() ([32]byte, error) {
	return _ISuperGovernor.Contract.GOVERNORROLE(&_ISuperGovernor.CallOpts)
}

// GOVERNORROLE is a free data retrieval call binding the contract method 0xccc57490.
//
// Solidity: function GOVERNOR_ROLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCallerSession) GOVERNORROLE() ([32]byte, error) {
	return _ISuperGovernor.Contract.GOVERNORROLE(&_ISuperGovernor.CallOpts)
}

// GUARDIANROLE is a free data retrieval call binding the contract method 0x24ea54f4.
//
// Solidity: function GUARDIAN_ROLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCaller) GUARDIANROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "GUARDIAN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GUARDIANROLE is a free data retrieval call binding the contract method 0x24ea54f4.
//
// Solidity: function GUARDIAN_ROLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorSession) GUARDIANROLE() ([32]byte, error) {
	return _ISuperGovernor.Contract.GUARDIANROLE(&_ISuperGovernor.CallOpts)
}

// GUARDIANROLE is a free data retrieval call binding the contract method 0x24ea54f4.
//
// Solidity: function GUARDIAN_ROLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCallerSession) GUARDIANROLE() ([32]byte, error) {
	return _ISuperGovernor.Contract.GUARDIANROLE(&_ISuperGovernor.CallOpts)
}

// ORACLEMANAGERROLE is a free data retrieval call binding the contract method 0xbfc69e1c.
//
// Solidity: function ORACLE_MANAGER_ROLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCaller) ORACLEMANAGERROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "ORACLE_MANAGER_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// ORACLEMANAGERROLE is a free data retrieval call binding the contract method 0xbfc69e1c.
//
// Solidity: function ORACLE_MANAGER_ROLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorSession) ORACLEMANAGERROLE() ([32]byte, error) {
	return _ISuperGovernor.Contract.ORACLEMANAGERROLE(&_ISuperGovernor.CallOpts)
}

// ORACLEMANAGERROLE is a free data retrieval call binding the contract method 0xbfc69e1c.
//
// Solidity: function ORACLE_MANAGER_ROLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCallerSession) ORACLEMANAGERROLE() ([32]byte, error) {
	return _ISuperGovernor.Contract.ORACLEMANAGERROLE(&_ISuperGovernor.CallOpts)
}

// SUP is a free data retrieval call binding the contract method 0x95c0bf69.
//
// Solidity: function SUP() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCaller) SUP(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "SUP")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SUP is a free data retrieval call binding the contract method 0x95c0bf69.
//
// Solidity: function SUP() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorSession) SUP() ([32]byte, error) {
	return _ISuperGovernor.Contract.SUP(&_ISuperGovernor.CallOpts)
}

// SUP is a free data retrieval call binding the contract method 0x95c0bf69.
//
// Solidity: function SUP() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCallerSession) SUP() ([32]byte, error) {
	return _ISuperGovernor.Contract.SUP(&_ISuperGovernor.CallOpts)
}

// SUPERBANK is a free data retrieval call binding the contract method 0x6f2140c1.
//
// Solidity: function SUPER_BANK() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCaller) SUPERBANK(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "SUPER_BANK")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SUPERBANK is a free data retrieval call binding the contract method 0x6f2140c1.
//
// Solidity: function SUPER_BANK() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorSession) SUPERBANK() ([32]byte, error) {
	return _ISuperGovernor.Contract.SUPERBANK(&_ISuperGovernor.CallOpts)
}

// SUPERBANK is a free data retrieval call binding the contract method 0x6f2140c1.
//
// Solidity: function SUPER_BANK() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCallerSession) SUPERBANK() ([32]byte, error) {
	return _ISuperGovernor.Contract.SUPERBANK(&_ISuperGovernor.CallOpts)
}

// SUPERGOVERNORROLE is a free data retrieval call binding the contract method 0xec45ad53.
//
// Solidity: function SUPER_GOVERNOR_ROLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCaller) SUPERGOVERNORROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "SUPER_GOVERNOR_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SUPERGOVERNORROLE is a free data retrieval call binding the contract method 0xec45ad53.
//
// Solidity: function SUPER_GOVERNOR_ROLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorSession) SUPERGOVERNORROLE() ([32]byte, error) {
	return _ISuperGovernor.Contract.SUPERGOVERNORROLE(&_ISuperGovernor.CallOpts)
}

// SUPERGOVERNORROLE is a free data retrieval call binding the contract method 0xec45ad53.
//
// Solidity: function SUPER_GOVERNOR_ROLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCallerSession) SUPERGOVERNORROLE() ([32]byte, error) {
	return _ISuperGovernor.Contract.SUPERGOVERNORROLE(&_ISuperGovernor.CallOpts)
}

// SUPERORACLE is a free data retrieval call binding the contract method 0x90d4a56d.
//
// Solidity: function SUPER_ORACLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCaller) SUPERORACLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "SUPER_ORACLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SUPERORACLE is a free data retrieval call binding the contract method 0x90d4a56d.
//
// Solidity: function SUPER_ORACLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorSession) SUPERORACLE() ([32]byte, error) {
	return _ISuperGovernor.Contract.SUPERORACLE(&_ISuperGovernor.CallOpts)
}

// SUPERORACLE is a free data retrieval call binding the contract method 0x90d4a56d.
//
// Solidity: function SUPER_ORACLE() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCallerSession) SUPERORACLE() ([32]byte, error) {
	return _ISuperGovernor.Contract.SUPERORACLE(&_ISuperGovernor.CallOpts)
}

// SUPERVAULTAGGREGATOR is a free data retrieval call binding the contract method 0xc9838819.
//
// Solidity: function SUPER_VAULT_AGGREGATOR() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCaller) SUPERVAULTAGGREGATOR(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "SUPER_VAULT_AGGREGATOR")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SUPERVAULTAGGREGATOR is a free data retrieval call binding the contract method 0xc9838819.
//
// Solidity: function SUPER_VAULT_AGGREGATOR() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorSession) SUPERVAULTAGGREGATOR() ([32]byte, error) {
	return _ISuperGovernor.Contract.SUPERVAULTAGGREGATOR(&_ISuperGovernor.CallOpts)
}

// SUPERVAULTAGGREGATOR is a free data retrieval call binding the contract method 0xc9838819.
//
// Solidity: function SUPER_VAULT_AGGREGATOR() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCallerSession) SUPERVAULTAGGREGATOR() ([32]byte, error) {
	return _ISuperGovernor.Contract.SUPERVAULTAGGREGATOR(&_ISuperGovernor.CallOpts)
}

// TREASURY is a free data retrieval call binding the contract method 0x2d2c5565.
//
// Solidity: function TREASURY() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCaller) TREASURY(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "TREASURY")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// TREASURY is a free data retrieval call binding the contract method 0x2d2c5565.
//
// Solidity: function TREASURY() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorSession) TREASURY() ([32]byte, error) {
	return _ISuperGovernor.Contract.TREASURY(&_ISuperGovernor.CallOpts)
}

// TREASURY is a free data retrieval call binding the contract method 0x2d2c5565.
//
// Solidity: function TREASURY() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCallerSession) TREASURY() ([32]byte, error) {
	return _ISuperGovernor.Contract.TREASURY(&_ISuperGovernor.CallOpts)
}

// UP is a free data retrieval call binding the contract method 0x24f4ec51.
//
// Solidity: function UP() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCaller) UP(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "UP")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// UP is a free data retrieval call binding the contract method 0x24f4ec51.
//
// Solidity: function UP() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorSession) UP() ([32]byte, error) {
	return _ISuperGovernor.Contract.UP(&_ISuperGovernor.CallOpts)
}

// UP is a free data retrieval call binding the contract method 0x24f4ec51.
//
// Solidity: function UP() view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCallerSession) UP() ([32]byte, error) {
	return _ISuperGovernor.Contract.UP(&_ISuperGovernor.CallOpts)
}

// GetActivePPSOracle is a free data retrieval call binding the contract method 0x275f0f2b.
//
// Solidity: function getActivePPSOracle() view returns(address)
func (_ISuperGovernor *ISuperGovernorCaller) GetActivePPSOracle(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getActivePPSOracle")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetActivePPSOracle is a free data retrieval call binding the contract method 0x275f0f2b.
//
// Solidity: function getActivePPSOracle() view returns(address)
func (_ISuperGovernor *ISuperGovernorSession) GetActivePPSOracle() (common.Address, error) {
	return _ISuperGovernor.Contract.GetActivePPSOracle(&_ISuperGovernor.CallOpts)
}

// GetActivePPSOracle is a free data retrieval call binding the contract method 0x275f0f2b.
//
// Solidity: function getActivePPSOracle() view returns(address)
func (_ISuperGovernor *ISuperGovernorCallerSession) GetActivePPSOracle() (common.Address, error) {
	return _ISuperGovernor.Contract.GetActivePPSOracle(&_ISuperGovernor.CallOpts)
}

// GetAddress is a free data retrieval call binding the contract method 0x21f8a721.
//
// Solidity: function getAddress(bytes32 key) view returns(address)
func (_ISuperGovernor *ISuperGovernorCaller) GetAddress(opts *bind.CallOpts, key [32]byte) (common.Address, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getAddress", key)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetAddress is a free data retrieval call binding the contract method 0x21f8a721.
//
// Solidity: function getAddress(bytes32 key) view returns(address)
func (_ISuperGovernor *ISuperGovernorSession) GetAddress(key [32]byte) (common.Address, error) {
	return _ISuperGovernor.Contract.GetAddress(&_ISuperGovernor.CallOpts, key)
}

// GetAddress is a free data retrieval call binding the contract method 0x21f8a721.
//
// Solidity: function getAddress(bytes32 key) view returns(address)
func (_ISuperGovernor *ISuperGovernorCallerSession) GetAddress(key [32]byte) (common.Address, error) {
	return _ISuperGovernor.Contract.GetAddress(&_ISuperGovernor.CallOpts, key)
}

// GetAllSuperformManagers is a free data retrieval call binding the contract method 0xa1d1ab43.
//
// Solidity: function getAllSuperformManagers() view returns(address[])
func (_ISuperGovernor *ISuperGovernorCaller) GetAllSuperformManagers(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getAllSuperformManagers")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetAllSuperformManagers is a free data retrieval call binding the contract method 0xa1d1ab43.
//
// Solidity: function getAllSuperformManagers() view returns(address[])
func (_ISuperGovernor *ISuperGovernorSession) GetAllSuperformManagers() ([]common.Address, error) {
	return _ISuperGovernor.Contract.GetAllSuperformManagers(&_ISuperGovernor.CallOpts)
}

// GetAllSuperformManagers is a free data retrieval call binding the contract method 0xa1d1ab43.
//
// Solidity: function getAllSuperformManagers() view returns(address[])
func (_ISuperGovernor *ISuperGovernorCallerSession) GetAllSuperformManagers() ([]common.Address, error) {
	return _ISuperGovernor.Contract.GetAllSuperformManagers(&_ISuperGovernor.CallOpts)
}

// GetExecutors is a free data retrieval call binding the contract method 0xef09e78f.
//
// Solidity: function getExecutors() view returns(address[])
func (_ISuperGovernor *ISuperGovernorCaller) GetExecutors(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getExecutors")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetExecutors is a free data retrieval call binding the contract method 0xef09e78f.
//
// Solidity: function getExecutors() view returns(address[])
func (_ISuperGovernor *ISuperGovernorSession) GetExecutors() ([]common.Address, error) {
	return _ISuperGovernor.Contract.GetExecutors(&_ISuperGovernor.CallOpts)
}

// GetExecutors is a free data retrieval call binding the contract method 0xef09e78f.
//
// Solidity: function getExecutors() view returns(address[])
func (_ISuperGovernor *ISuperGovernorCallerSession) GetExecutors() ([]common.Address, error) {
	return _ISuperGovernor.Contract.GetExecutors(&_ISuperGovernor.CallOpts)
}

// GetFee is a free data retrieval call binding the contract method 0x083132c4.
//
// Solidity: function getFee(uint8 feeType) view returns(uint256)
func (_ISuperGovernor *ISuperGovernorCaller) GetFee(opts *bind.CallOpts, feeType uint8) (*big.Int, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getFee", feeType)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetFee is a free data retrieval call binding the contract method 0x083132c4.
//
// Solidity: function getFee(uint8 feeType) view returns(uint256)
func (_ISuperGovernor *ISuperGovernorSession) GetFee(feeType uint8) (*big.Int, error) {
	return _ISuperGovernor.Contract.GetFee(&_ISuperGovernor.CallOpts, feeType)
}

// GetFee is a free data retrieval call binding the contract method 0x083132c4.
//
// Solidity: function getFee(uint8 feeType) view returns(uint256)
func (_ISuperGovernor *ISuperGovernorCallerSession) GetFee(feeType uint8) (*big.Int, error) {
	return _ISuperGovernor.Contract.GetFee(&_ISuperGovernor.CallOpts, feeType)
}

// GetGasInfo is a free data retrieval call binding the contract method 0xf5f81403.
//
// Solidity: function getGasInfo(address oracle_) view returns(uint256)
func (_ISuperGovernor *ISuperGovernorCaller) GetGasInfo(opts *bind.CallOpts, oracle_ common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getGasInfo", oracle_)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetGasInfo is a free data retrieval call binding the contract method 0xf5f81403.
//
// Solidity: function getGasInfo(address oracle_) view returns(uint256)
func (_ISuperGovernor *ISuperGovernorSession) GetGasInfo(oracle_ common.Address) (*big.Int, error) {
	return _ISuperGovernor.Contract.GetGasInfo(&_ISuperGovernor.CallOpts, oracle_)
}

// GetGasInfo is a free data retrieval call binding the contract method 0xf5f81403.
//
// Solidity: function getGasInfo(address oracle_) view returns(uint256)
func (_ISuperGovernor *ISuperGovernorCallerSession) GetGasInfo(oracle_ common.Address) (*big.Int, error) {
	return _ISuperGovernor.Contract.GetGasInfo(&_ISuperGovernor.CallOpts, oracle_)
}

// GetManagersPaginated is a free data retrieval call binding the contract method 0xbe5edae5.
//
// Solidity: function getManagersPaginated(uint256 cursor, uint256 limit) view returns(address[] chunkOfManagers, uint256 next)
func (_ISuperGovernor *ISuperGovernorCaller) GetManagersPaginated(opts *bind.CallOpts, cursor *big.Int, limit *big.Int) (struct {
	ChunkOfManagers []common.Address
	Next            *big.Int
}, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getManagersPaginated", cursor, limit)

	outstruct := new(struct {
		ChunkOfManagers []common.Address
		Next            *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.ChunkOfManagers = *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)
	outstruct.Next = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// GetManagersPaginated is a free data retrieval call binding the contract method 0xbe5edae5.
//
// Solidity: function getManagersPaginated(uint256 cursor, uint256 limit) view returns(address[] chunkOfManagers, uint256 next)
func (_ISuperGovernor *ISuperGovernorSession) GetManagersPaginated(cursor *big.Int, limit *big.Int) (struct {
	ChunkOfManagers []common.Address
	Next            *big.Int
}, error) {
	return _ISuperGovernor.Contract.GetManagersPaginated(&_ISuperGovernor.CallOpts, cursor, limit)
}

// GetManagersPaginated is a free data retrieval call binding the contract method 0xbe5edae5.
//
// Solidity: function getManagersPaginated(uint256 cursor, uint256 limit) view returns(address[] chunkOfManagers, uint256 next)
func (_ISuperGovernor *ISuperGovernorCallerSession) GetManagersPaginated(cursor *big.Int, limit *big.Int) (struct {
	ChunkOfManagers []common.Address
	Next            *big.Int
}, error) {
	return _ISuperGovernor.Contract.GetManagersPaginated(&_ISuperGovernor.CallOpts, cursor, limit)
}

// GetMinStaleness is a free data retrieval call binding the contract method 0x29f05976.
//
// Solidity: function getMinStaleness() view returns(uint256)
func (_ISuperGovernor *ISuperGovernorCaller) GetMinStaleness(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getMinStaleness")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetMinStaleness is a free data retrieval call binding the contract method 0x29f05976.
//
// Solidity: function getMinStaleness() view returns(uint256)
func (_ISuperGovernor *ISuperGovernorSession) GetMinStaleness() (*big.Int, error) {
	return _ISuperGovernor.Contract.GetMinStaleness(&_ISuperGovernor.CallOpts)
}

// GetMinStaleness is a free data retrieval call binding the contract method 0x29f05976.
//
// Solidity: function getMinStaleness() view returns(uint256)
func (_ISuperGovernor *ISuperGovernorCallerSession) GetMinStaleness() (*big.Int, error) {
	return _ISuperGovernor.Contract.GetMinStaleness(&_ISuperGovernor.CallOpts)
}

// GetPPSOracleQuorum is a free data retrieval call binding the contract method 0xdf6aaf96.
//
// Solidity: function getPPSOracleQuorum() view returns(uint256)
func (_ISuperGovernor *ISuperGovernorCaller) GetPPSOracleQuorum(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getPPSOracleQuorum")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetPPSOracleQuorum is a free data retrieval call binding the contract method 0xdf6aaf96.
//
// Solidity: function getPPSOracleQuorum() view returns(uint256)
func (_ISuperGovernor *ISuperGovernorSession) GetPPSOracleQuorum() (*big.Int, error) {
	return _ISuperGovernor.Contract.GetPPSOracleQuorum(&_ISuperGovernor.CallOpts)
}

// GetPPSOracleQuorum is a free data retrieval call binding the contract method 0xdf6aaf96.
//
// Solidity: function getPPSOracleQuorum() view returns(uint256)
func (_ISuperGovernor *ISuperGovernorCallerSession) GetPPSOracleQuorum() (*big.Int, error) {
	return _ISuperGovernor.Contract.GetPPSOracleQuorum(&_ISuperGovernor.CallOpts)
}

// GetProposedActivePPSOracle is a free data retrieval call binding the contract method 0xa86ed388.
//
// Solidity: function getProposedActivePPSOracle() view returns(address proposedOracle, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorCaller) GetProposedActivePPSOracle(opts *bind.CallOpts) (struct {
	ProposedOracle common.Address
	EffectiveTime  *big.Int
}, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getProposedActivePPSOracle")

	outstruct := new(struct {
		ProposedOracle common.Address
		EffectiveTime  *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.ProposedOracle = *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	outstruct.EffectiveTime = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// GetProposedActivePPSOracle is a free data retrieval call binding the contract method 0xa86ed388.
//
// Solidity: function getProposedActivePPSOracle() view returns(address proposedOracle, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorSession) GetProposedActivePPSOracle() (struct {
	ProposedOracle common.Address
	EffectiveTime  *big.Int
}, error) {
	return _ISuperGovernor.Contract.GetProposedActivePPSOracle(&_ISuperGovernor.CallOpts)
}

// GetProposedActivePPSOracle is a free data retrieval call binding the contract method 0xa86ed388.
//
// Solidity: function getProposedActivePPSOracle() view returns(address proposedOracle, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorCallerSession) GetProposedActivePPSOracle() (struct {
	ProposedOracle common.Address
	EffectiveTime  *big.Int
}, error) {
	return _ISuperGovernor.Contract.GetProposedActivePPSOracle(&_ISuperGovernor.CallOpts)
}

// GetProposedMinStaleness is a free data retrieval call binding the contract method 0xe8422432.
//
// Solidity: function getProposedMinStaleness() view returns(uint256 proposedMinStaleness, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorCaller) GetProposedMinStaleness(opts *bind.CallOpts) (struct {
	ProposedMinStaleness *big.Int
	EffectiveTime        *big.Int
}, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getProposedMinStaleness")

	outstruct := new(struct {
		ProposedMinStaleness *big.Int
		EffectiveTime        *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.ProposedMinStaleness = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.EffectiveTime = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// GetProposedMinStaleness is a free data retrieval call binding the contract method 0xe8422432.
//
// Solidity: function getProposedMinStaleness() view returns(uint256 proposedMinStaleness, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorSession) GetProposedMinStaleness() (struct {
	ProposedMinStaleness *big.Int
	EffectiveTime        *big.Int
}, error) {
	return _ISuperGovernor.Contract.GetProposedMinStaleness(&_ISuperGovernor.CallOpts)
}

// GetProposedMinStaleness is a free data retrieval call binding the contract method 0xe8422432.
//
// Solidity: function getProposedMinStaleness() view returns(uint256 proposedMinStaleness, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorCallerSession) GetProposedMinStaleness() (struct {
	ProposedMinStaleness *big.Int
	EffectiveTime        *big.Int
}, error) {
	return _ISuperGovernor.Contract.GetProposedMinStaleness(&_ISuperGovernor.CallOpts)
}

// GetProposedSuperBankHookMerkleRoot is a free data retrieval call binding the contract method 0x43844de6.
//
// Solidity: function getProposedSuperBankHookMerkleRoot(address hook) view returns(bytes32 proposedRoot, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorCaller) GetProposedSuperBankHookMerkleRoot(opts *bind.CallOpts, hook common.Address) (struct {
	ProposedRoot  [32]byte
	EffectiveTime *big.Int
}, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getProposedSuperBankHookMerkleRoot", hook)

	outstruct := new(struct {
		ProposedRoot  [32]byte
		EffectiveTime *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.ProposedRoot = *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)
	outstruct.EffectiveTime = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// GetProposedSuperBankHookMerkleRoot is a free data retrieval call binding the contract method 0x43844de6.
//
// Solidity: function getProposedSuperBankHookMerkleRoot(address hook) view returns(bytes32 proposedRoot, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorSession) GetProposedSuperBankHookMerkleRoot(hook common.Address) (struct {
	ProposedRoot  [32]byte
	EffectiveTime *big.Int
}, error) {
	return _ISuperGovernor.Contract.GetProposedSuperBankHookMerkleRoot(&_ISuperGovernor.CallOpts, hook)
}

// GetProposedSuperBankHookMerkleRoot is a free data retrieval call binding the contract method 0x43844de6.
//
// Solidity: function getProposedSuperBankHookMerkleRoot(address hook) view returns(bytes32 proposedRoot, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorCallerSession) GetProposedSuperBankHookMerkleRoot(hook common.Address) (struct {
	ProposedRoot  [32]byte
	EffectiveTime *big.Int
}, error) {
	return _ISuperGovernor.Contract.GetProposedSuperBankHookMerkleRoot(&_ISuperGovernor.CallOpts, hook)
}

// GetProposedUpkeepPaymentsStatus is a free data retrieval call binding the contract method 0x57b8b13d.
//
// Solidity: function getProposedUpkeepPaymentsStatus() view returns(bool enabled, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorCaller) GetProposedUpkeepPaymentsStatus(opts *bind.CallOpts) (struct {
	Enabled       bool
	EffectiveTime *big.Int
}, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getProposedUpkeepPaymentsStatus")

	outstruct := new(struct {
		Enabled       bool
		EffectiveTime *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Enabled = *abi.ConvertType(out[0], new(bool)).(*bool)
	outstruct.EffectiveTime = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// GetProposedUpkeepPaymentsStatus is a free data retrieval call binding the contract method 0x57b8b13d.
//
// Solidity: function getProposedUpkeepPaymentsStatus() view returns(bool enabled, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorSession) GetProposedUpkeepPaymentsStatus() (struct {
	Enabled       bool
	EffectiveTime *big.Int
}, error) {
	return _ISuperGovernor.Contract.GetProposedUpkeepPaymentsStatus(&_ISuperGovernor.CallOpts)
}

// GetProposedUpkeepPaymentsStatus is a free data retrieval call binding the contract method 0x57b8b13d.
//
// Solidity: function getProposedUpkeepPaymentsStatus() view returns(bool enabled, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorCallerSession) GetProposedUpkeepPaymentsStatus() (struct {
	Enabled       bool
	EffectiveTime *big.Int
}, error) {
	return _ISuperGovernor.Contract.GetProposedUpkeepPaymentsStatus(&_ISuperGovernor.CallOpts)
}

// GetRegisteredHooks is a free data retrieval call binding the contract method 0x841b0175.
//
// Solidity: function getRegisteredHooks() view returns(address[])
func (_ISuperGovernor *ISuperGovernorCaller) GetRegisteredHooks(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getRegisteredHooks")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetRegisteredHooks is a free data retrieval call binding the contract method 0x841b0175.
//
// Solidity: function getRegisteredHooks() view returns(address[])
func (_ISuperGovernor *ISuperGovernorSession) GetRegisteredHooks() ([]common.Address, error) {
	return _ISuperGovernor.Contract.GetRegisteredHooks(&_ISuperGovernor.CallOpts)
}

// GetRegisteredHooks is a free data retrieval call binding the contract method 0x841b0175.
//
// Solidity: function getRegisteredHooks() view returns(address[])
func (_ISuperGovernor *ISuperGovernorCallerSession) GetRegisteredHooks() ([]common.Address, error) {
	return _ISuperGovernor.Contract.GetRegisteredHooks(&_ISuperGovernor.CallOpts)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCaller) GetRoleAdmin(opts *bind.CallOpts, role [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getRoleAdmin", role)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _ISuperGovernor.Contract.GetRoleAdmin(&_ISuperGovernor.CallOpts, role)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCallerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _ISuperGovernor.Contract.GetRoleAdmin(&_ISuperGovernor.CallOpts, role)
}

// GetSuperBankHookMerkleRoot is a free data retrieval call binding the contract method 0xf43526f4.
//
// Solidity: function getSuperBankHookMerkleRoot(address hook) view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCaller) GetSuperBankHookMerkleRoot(opts *bind.CallOpts, hook common.Address) ([32]byte, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getSuperBankHookMerkleRoot", hook)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetSuperBankHookMerkleRoot is a free data retrieval call binding the contract method 0xf43526f4.
//
// Solidity: function getSuperBankHookMerkleRoot(address hook) view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorSession) GetSuperBankHookMerkleRoot(hook common.Address) ([32]byte, error) {
	return _ISuperGovernor.Contract.GetSuperBankHookMerkleRoot(&_ISuperGovernor.CallOpts, hook)
}

// GetSuperBankHookMerkleRoot is a free data retrieval call binding the contract method 0xf43526f4.
//
// Solidity: function getSuperBankHookMerkleRoot(address hook) view returns(bytes32)
func (_ISuperGovernor *ISuperGovernorCallerSession) GetSuperBankHookMerkleRoot(hook common.Address) ([32]byte, error) {
	return _ISuperGovernor.Contract.GetSuperBankHookMerkleRoot(&_ISuperGovernor.CallOpts, hook)
}

// GetSuperformManagersCount is a free data retrieval call binding the contract method 0xcc8bb5e4.
//
// Solidity: function getSuperformManagersCount() view returns(uint256)
func (_ISuperGovernor *ISuperGovernorCaller) GetSuperformManagersCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getSuperformManagersCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetSuperformManagersCount is a free data retrieval call binding the contract method 0xcc8bb5e4.
//
// Solidity: function getSuperformManagersCount() view returns(uint256)
func (_ISuperGovernor *ISuperGovernorSession) GetSuperformManagersCount() (*big.Int, error) {
	return _ISuperGovernor.Contract.GetSuperformManagersCount(&_ISuperGovernor.CallOpts)
}

// GetSuperformManagersCount is a free data retrieval call binding the contract method 0xcc8bb5e4.
//
// Solidity: function getSuperformManagersCount() view returns(uint256)
func (_ISuperGovernor *ISuperGovernorCallerSession) GetSuperformManagersCount() (*big.Int, error) {
	return _ISuperGovernor.Contract.GetSuperformManagersCount(&_ISuperGovernor.CallOpts)
}

// GetUpkeepCostPerSingleUpdate is a free data retrieval call binding the contract method 0x92f16278.
//
// Solidity: function getUpkeepCostPerSingleUpdate(address oracle_) view returns(uint256)
func (_ISuperGovernor *ISuperGovernorCaller) GetUpkeepCostPerSingleUpdate(opts *bind.CallOpts, oracle_ common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getUpkeepCostPerSingleUpdate", oracle_)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetUpkeepCostPerSingleUpdate is a free data retrieval call binding the contract method 0x92f16278.
//
// Solidity: function getUpkeepCostPerSingleUpdate(address oracle_) view returns(uint256)
func (_ISuperGovernor *ISuperGovernorSession) GetUpkeepCostPerSingleUpdate(oracle_ common.Address) (*big.Int, error) {
	return _ISuperGovernor.Contract.GetUpkeepCostPerSingleUpdate(&_ISuperGovernor.CallOpts, oracle_)
}

// GetUpkeepCostPerSingleUpdate is a free data retrieval call binding the contract method 0x92f16278.
//
// Solidity: function getUpkeepCostPerSingleUpdate(address oracle_) view returns(uint256)
func (_ISuperGovernor *ISuperGovernorCallerSession) GetUpkeepCostPerSingleUpdate(oracle_ common.Address) (*big.Int, error) {
	return _ISuperGovernor.Contract.GetUpkeepCostPerSingleUpdate(&_ISuperGovernor.CallOpts, oracle_)
}

// GetValidatorAt is a free data retrieval call binding the contract method 0x9a000e5b.
//
// Solidity: function getValidatorAt(uint256 index) view returns(address validator)
func (_ISuperGovernor *ISuperGovernorCaller) GetValidatorAt(opts *bind.CallOpts, index *big.Int) (common.Address, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getValidatorAt", index)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetValidatorAt is a free data retrieval call binding the contract method 0x9a000e5b.
//
// Solidity: function getValidatorAt(uint256 index) view returns(address validator)
func (_ISuperGovernor *ISuperGovernorSession) GetValidatorAt(index *big.Int) (common.Address, error) {
	return _ISuperGovernor.Contract.GetValidatorAt(&_ISuperGovernor.CallOpts, index)
}

// GetValidatorAt is a free data retrieval call binding the contract method 0x9a000e5b.
//
// Solidity: function getValidatorAt(uint256 index) view returns(address validator)
func (_ISuperGovernor *ISuperGovernorCallerSession) GetValidatorAt(index *big.Int) (common.Address, error) {
	return _ISuperGovernor.Contract.GetValidatorAt(&_ISuperGovernor.CallOpts, index)
}

// GetValidatorConfigVersion is a free data retrieval call binding the contract method 0x5bd68dbc.
//
// Solidity: function getValidatorConfigVersion() view returns(uint256)
func (_ISuperGovernor *ISuperGovernorCaller) GetValidatorConfigVersion(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getValidatorConfigVersion")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetValidatorConfigVersion is a free data retrieval call binding the contract method 0x5bd68dbc.
//
// Solidity: function getValidatorConfigVersion() view returns(uint256)
func (_ISuperGovernor *ISuperGovernorSession) GetValidatorConfigVersion() (*big.Int, error) {
	return _ISuperGovernor.Contract.GetValidatorConfigVersion(&_ISuperGovernor.CallOpts)
}

// GetValidatorConfigVersion is a free data retrieval call binding the contract method 0x5bd68dbc.
//
// Solidity: function getValidatorConfigVersion() view returns(uint256)
func (_ISuperGovernor *ISuperGovernorCallerSession) GetValidatorConfigVersion() (*big.Int, error) {
	return _ISuperGovernor.Contract.GetValidatorConfigVersion(&_ISuperGovernor.CallOpts)
}

// GetValidators is a free data retrieval call binding the contract method 0xb7ab4db5.
//
// Solidity: function getValidators() view returns(address[])
func (_ISuperGovernor *ISuperGovernorCaller) GetValidators(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getValidators")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetValidators is a free data retrieval call binding the contract method 0xb7ab4db5.
//
// Solidity: function getValidators() view returns(address[])
func (_ISuperGovernor *ISuperGovernorSession) GetValidators() ([]common.Address, error) {
	return _ISuperGovernor.Contract.GetValidators(&_ISuperGovernor.CallOpts)
}

// GetValidators is a free data retrieval call binding the contract method 0xb7ab4db5.
//
// Solidity: function getValidators() view returns(address[])
func (_ISuperGovernor *ISuperGovernorCallerSession) GetValidators() ([]common.Address, error) {
	return _ISuperGovernor.Contract.GetValidators(&_ISuperGovernor.CallOpts)
}

// GetValidatorsCount is a free data retrieval call binding the contract method 0x27498240.
//
// Solidity: function getValidatorsCount() view returns(uint256)
func (_ISuperGovernor *ISuperGovernorCaller) GetValidatorsCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "getValidatorsCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetValidatorsCount is a free data retrieval call binding the contract method 0x27498240.
//
// Solidity: function getValidatorsCount() view returns(uint256)
func (_ISuperGovernor *ISuperGovernorSession) GetValidatorsCount() (*big.Int, error) {
	return _ISuperGovernor.Contract.GetValidatorsCount(&_ISuperGovernor.CallOpts)
}

// GetValidatorsCount is a free data retrieval call binding the contract method 0x27498240.
//
// Solidity: function getValidatorsCount() view returns(uint256)
func (_ISuperGovernor *ISuperGovernorCallerSession) GetValidatorsCount() (*big.Int, error) {
	return _ISuperGovernor.Contract.GetValidatorsCount(&_ISuperGovernor.CallOpts)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_ISuperGovernor *ISuperGovernorCaller) HasRole(opts *bind.CallOpts, role [32]byte, account common.Address) (bool, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "hasRole", role, account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_ISuperGovernor *ISuperGovernorSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _ISuperGovernor.Contract.HasRole(&_ISuperGovernor.CallOpts, role, account)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_ISuperGovernor *ISuperGovernorCallerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _ISuperGovernor.Contract.HasRole(&_ISuperGovernor.CallOpts, role, account)
}

// IsActivePPSOracle is a free data retrieval call binding the contract method 0xfd6f0fc2.
//
// Solidity: function isActivePPSOracle(address oracle) view returns(bool)
func (_ISuperGovernor *ISuperGovernorCaller) IsActivePPSOracle(opts *bind.CallOpts, oracle common.Address) (bool, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "isActivePPSOracle", oracle)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsActivePPSOracle is a free data retrieval call binding the contract method 0xfd6f0fc2.
//
// Solidity: function isActivePPSOracle(address oracle) view returns(bool)
func (_ISuperGovernor *ISuperGovernorSession) IsActivePPSOracle(oracle common.Address) (bool, error) {
	return _ISuperGovernor.Contract.IsActivePPSOracle(&_ISuperGovernor.CallOpts, oracle)
}

// IsActivePPSOracle is a free data retrieval call binding the contract method 0xfd6f0fc2.
//
// Solidity: function isActivePPSOracle(address oracle) view returns(bool)
func (_ISuperGovernor *ISuperGovernorCallerSession) IsActivePPSOracle(oracle common.Address) (bool, error) {
	return _ISuperGovernor.Contract.IsActivePPSOracle(&_ISuperGovernor.CallOpts, oracle)
}

// IsExecutor is a free data retrieval call binding the contract method 0xdebfda30.
//
// Solidity: function isExecutor(address executor) view returns(bool)
func (_ISuperGovernor *ISuperGovernorCaller) IsExecutor(opts *bind.CallOpts, executor common.Address) (bool, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "isExecutor", executor)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsExecutor is a free data retrieval call binding the contract method 0xdebfda30.
//
// Solidity: function isExecutor(address executor) view returns(bool)
func (_ISuperGovernor *ISuperGovernorSession) IsExecutor(executor common.Address) (bool, error) {
	return _ISuperGovernor.Contract.IsExecutor(&_ISuperGovernor.CallOpts, executor)
}

// IsExecutor is a free data retrieval call binding the contract method 0xdebfda30.
//
// Solidity: function isExecutor(address executor) view returns(bool)
func (_ISuperGovernor *ISuperGovernorCallerSession) IsExecutor(executor common.Address) (bool, error) {
	return _ISuperGovernor.Contract.IsExecutor(&_ISuperGovernor.CallOpts, executor)
}

// IsGuardian is a free data retrieval call binding the contract method 0x0c68ba21.
//
// Solidity: function isGuardian(address guardian) view returns(bool)
func (_ISuperGovernor *ISuperGovernorCaller) IsGuardian(opts *bind.CallOpts, guardian common.Address) (bool, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "isGuardian", guardian)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsGuardian is a free data retrieval call binding the contract method 0x0c68ba21.
//
// Solidity: function isGuardian(address guardian) view returns(bool)
func (_ISuperGovernor *ISuperGovernorSession) IsGuardian(guardian common.Address) (bool, error) {
	return _ISuperGovernor.Contract.IsGuardian(&_ISuperGovernor.CallOpts, guardian)
}

// IsGuardian is a free data retrieval call binding the contract method 0x0c68ba21.
//
// Solidity: function isGuardian(address guardian) view returns(bool)
func (_ISuperGovernor *ISuperGovernorCallerSession) IsGuardian(guardian common.Address) (bool, error) {
	return _ISuperGovernor.Contract.IsGuardian(&_ISuperGovernor.CallOpts, guardian)
}

// IsHookRegistered is a free data retrieval call binding the contract method 0x0cbad00c.
//
// Solidity: function isHookRegistered(address hook) view returns(bool)
func (_ISuperGovernor *ISuperGovernorCaller) IsHookRegistered(opts *bind.CallOpts, hook common.Address) (bool, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "isHookRegistered", hook)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsHookRegistered is a free data retrieval call binding the contract method 0x0cbad00c.
//
// Solidity: function isHookRegistered(address hook) view returns(bool)
func (_ISuperGovernor *ISuperGovernorSession) IsHookRegistered(hook common.Address) (bool, error) {
	return _ISuperGovernor.Contract.IsHookRegistered(&_ISuperGovernor.CallOpts, hook)
}

// IsHookRegistered is a free data retrieval call binding the contract method 0x0cbad00c.
//
// Solidity: function isHookRegistered(address hook) view returns(bool)
func (_ISuperGovernor *ISuperGovernorCallerSession) IsHookRegistered(hook common.Address) (bool, error) {
	return _ISuperGovernor.Contract.IsHookRegistered(&_ISuperGovernor.CallOpts, hook)
}

// IsManagerTakeoverFrozen is a free data retrieval call binding the contract method 0x5721145f.
//
// Solidity: function isManagerTakeoverFrozen() view returns(bool)
func (_ISuperGovernor *ISuperGovernorCaller) IsManagerTakeoverFrozen(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "isManagerTakeoverFrozen")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsManagerTakeoverFrozen is a free data retrieval call binding the contract method 0x5721145f.
//
// Solidity: function isManagerTakeoverFrozen() view returns(bool)
func (_ISuperGovernor *ISuperGovernorSession) IsManagerTakeoverFrozen() (bool, error) {
	return _ISuperGovernor.Contract.IsManagerTakeoverFrozen(&_ISuperGovernor.CallOpts)
}

// IsManagerTakeoverFrozen is a free data retrieval call binding the contract method 0x5721145f.
//
// Solidity: function isManagerTakeoverFrozen() view returns(bool)
func (_ISuperGovernor *ISuperGovernorCallerSession) IsManagerTakeoverFrozen() (bool, error) {
	return _ISuperGovernor.Contract.IsManagerTakeoverFrozen(&_ISuperGovernor.CallOpts)
}

// IsSuperformManager is a free data retrieval call binding the contract method 0xae4d256e.
//
// Solidity: function isSuperformManager(address manager) view returns(bool)
func (_ISuperGovernor *ISuperGovernorCaller) IsSuperformManager(opts *bind.CallOpts, manager common.Address) (bool, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "isSuperformManager", manager)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsSuperformManager is a free data retrieval call binding the contract method 0xae4d256e.
//
// Solidity: function isSuperformManager(address manager) view returns(bool)
func (_ISuperGovernor *ISuperGovernorSession) IsSuperformManager(manager common.Address) (bool, error) {
	return _ISuperGovernor.Contract.IsSuperformManager(&_ISuperGovernor.CallOpts, manager)
}

// IsSuperformManager is a free data retrieval call binding the contract method 0xae4d256e.
//
// Solidity: function isSuperformManager(address manager) view returns(bool)
func (_ISuperGovernor *ISuperGovernorCallerSession) IsSuperformManager(manager common.Address) (bool, error) {
	return _ISuperGovernor.Contract.IsSuperformManager(&_ISuperGovernor.CallOpts, manager)
}

// IsUpkeepPaymentsEnabled is a free data retrieval call binding the contract method 0x3ef15059.
//
// Solidity: function isUpkeepPaymentsEnabled() view returns(bool)
func (_ISuperGovernor *ISuperGovernorCaller) IsUpkeepPaymentsEnabled(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "isUpkeepPaymentsEnabled")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsUpkeepPaymentsEnabled is a free data retrieval call binding the contract method 0x3ef15059.
//
// Solidity: function isUpkeepPaymentsEnabled() view returns(bool)
func (_ISuperGovernor *ISuperGovernorSession) IsUpkeepPaymentsEnabled() (bool, error) {
	return _ISuperGovernor.Contract.IsUpkeepPaymentsEnabled(&_ISuperGovernor.CallOpts)
}

// IsUpkeepPaymentsEnabled is a free data retrieval call binding the contract method 0x3ef15059.
//
// Solidity: function isUpkeepPaymentsEnabled() view returns(bool)
func (_ISuperGovernor *ISuperGovernorCallerSession) IsUpkeepPaymentsEnabled() (bool, error) {
	return _ISuperGovernor.Contract.IsUpkeepPaymentsEnabled(&_ISuperGovernor.CallOpts)
}

// IsValidator is a free data retrieval call binding the contract method 0xfacd743b.
//
// Solidity: function isValidator(address validator) view returns(bool)
func (_ISuperGovernor *ISuperGovernorCaller) IsValidator(opts *bind.CallOpts, validator common.Address) (bool, error) {
	var out []interface{}
	err := _ISuperGovernor.contract.Call(opts, &out, "isValidator", validator)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsValidator is a free data retrieval call binding the contract method 0xfacd743b.
//
// Solidity: function isValidator(address validator) view returns(bool)
func (_ISuperGovernor *ISuperGovernorSession) IsValidator(validator common.Address) (bool, error) {
	return _ISuperGovernor.Contract.IsValidator(&_ISuperGovernor.CallOpts, validator)
}

// IsValidator is a free data retrieval call binding the contract method 0xfacd743b.
//
// Solidity: function isValidator(address validator) view returns(bool)
func (_ISuperGovernor *ISuperGovernorCallerSession) IsValidator(validator common.Address) (bool, error) {
	return _ISuperGovernor.Contract.IsValidator(&_ISuperGovernor.CallOpts, validator)
}

// AddExecutor is a paid mutator transaction binding the contract method 0x1f5a0bbe.
//
// Solidity: function addExecutor(address executor) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) AddExecutor(opts *bind.TransactOpts, executor common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "addExecutor", executor)
}

// AddExecutor is a paid mutator transaction binding the contract method 0x1f5a0bbe.
//
// Solidity: function addExecutor(address executor) returns()
func (_ISuperGovernor *ISuperGovernorSession) AddExecutor(executor common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.AddExecutor(&_ISuperGovernor.TransactOpts, executor)
}

// AddExecutor is a paid mutator transaction binding the contract method 0x1f5a0bbe.
//
// Solidity: function addExecutor(address executor) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) AddExecutor(executor common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.AddExecutor(&_ISuperGovernor.TransactOpts, executor)
}

// AddSuperformManager is a paid mutator transaction binding the contract method 0xb291fdf3.
//
// Solidity: function addSuperformManager(address manager) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) AddSuperformManager(opts *bind.TransactOpts, manager common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "addSuperformManager", manager)
}

// AddSuperformManager is a paid mutator transaction binding the contract method 0xb291fdf3.
//
// Solidity: function addSuperformManager(address manager) returns()
func (_ISuperGovernor *ISuperGovernorSession) AddSuperformManager(manager common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.AddSuperformManager(&_ISuperGovernor.TransactOpts, manager)
}

// AddSuperformManager is a paid mutator transaction binding the contract method 0xb291fdf3.
//
// Solidity: function addSuperformManager(address manager) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) AddSuperformManager(manager common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.AddSuperformManager(&_ISuperGovernor.TransactOpts, manager)
}

// AddValidator is a paid mutator transaction binding the contract method 0x4d238c8e.
//
// Solidity: function addValidator(address validator) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) AddValidator(opts *bind.TransactOpts, validator common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "addValidator", validator)
}

// AddValidator is a paid mutator transaction binding the contract method 0x4d238c8e.
//
// Solidity: function addValidator(address validator) returns()
func (_ISuperGovernor *ISuperGovernorSession) AddValidator(validator common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.AddValidator(&_ISuperGovernor.TransactOpts, validator)
}

// AddValidator is a paid mutator transaction binding the contract method 0x4d238c8e.
//
// Solidity: function addValidator(address validator) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) AddValidator(validator common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.AddValidator(&_ISuperGovernor.TransactOpts, validator)
}

// BatchSetEmergencyPrices is a paid mutator transaction binding the contract method 0x00f1131f.
//
// Solidity: function batchSetEmergencyPrices(address[] tokens, uint256[] prices) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) BatchSetEmergencyPrices(opts *bind.TransactOpts, tokens []common.Address, prices []*big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "batchSetEmergencyPrices", tokens, prices)
}

// BatchSetEmergencyPrices is a paid mutator transaction binding the contract method 0x00f1131f.
//
// Solidity: function batchSetEmergencyPrices(address[] tokens, uint256[] prices) returns()
func (_ISuperGovernor *ISuperGovernorSession) BatchSetEmergencyPrices(tokens []common.Address, prices []*big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.BatchSetEmergencyPrices(&_ISuperGovernor.TransactOpts, tokens, prices)
}

// BatchSetEmergencyPrices is a paid mutator transaction binding the contract method 0x00f1131f.
//
// Solidity: function batchSetEmergencyPrices(address[] tokens, uint256[] prices) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) BatchSetEmergencyPrices(tokens []common.Address, prices []*big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.BatchSetEmergencyPrices(&_ISuperGovernor.TransactOpts, tokens, prices)
}

// BatchSetOracleUptimeFeed is a paid mutator transaction binding the contract method 0x52ad8b00.
//
// Solidity: function batchSetOracleUptimeFeed(address[] dataOracles, address[] uptimeOracles, uint256[] gracePeriods) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) BatchSetOracleUptimeFeed(opts *bind.TransactOpts, dataOracles []common.Address, uptimeOracles []common.Address, gracePeriods []*big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "batchSetOracleUptimeFeed", dataOracles, uptimeOracles, gracePeriods)
}

// BatchSetOracleUptimeFeed is a paid mutator transaction binding the contract method 0x52ad8b00.
//
// Solidity: function batchSetOracleUptimeFeed(address[] dataOracles, address[] uptimeOracles, uint256[] gracePeriods) returns()
func (_ISuperGovernor *ISuperGovernorSession) BatchSetOracleUptimeFeed(dataOracles []common.Address, uptimeOracles []common.Address, gracePeriods []*big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.BatchSetOracleUptimeFeed(&_ISuperGovernor.TransactOpts, dataOracles, uptimeOracles, gracePeriods)
}

// BatchSetOracleUptimeFeed is a paid mutator transaction binding the contract method 0x52ad8b00.
//
// Solidity: function batchSetOracleUptimeFeed(address[] dataOracles, address[] uptimeOracles, uint256[] gracePeriods) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) BatchSetOracleUptimeFeed(dataOracles []common.Address, uptimeOracles []common.Address, gracePeriods []*big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.BatchSetOracleUptimeFeed(&_ISuperGovernor.TransactOpts, dataOracles, uptimeOracles, gracePeriods)
}

// ChangeHooksRootUpdateTimelock is a paid mutator transaction binding the contract method 0x9649933b.
//
// Solidity: function changeHooksRootUpdateTimelock(uint256 newTimelock) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) ChangeHooksRootUpdateTimelock(opts *bind.TransactOpts, newTimelock *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "changeHooksRootUpdateTimelock", newTimelock)
}

// ChangeHooksRootUpdateTimelock is a paid mutator transaction binding the contract method 0x9649933b.
//
// Solidity: function changeHooksRootUpdateTimelock(uint256 newTimelock) returns()
func (_ISuperGovernor *ISuperGovernorSession) ChangeHooksRootUpdateTimelock(newTimelock *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ChangeHooksRootUpdateTimelock(&_ISuperGovernor.TransactOpts, newTimelock)
}

// ChangeHooksRootUpdateTimelock is a paid mutator transaction binding the contract method 0x9649933b.
//
// Solidity: function changeHooksRootUpdateTimelock(uint256 newTimelock) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) ChangeHooksRootUpdateTimelock(newTimelock *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ChangeHooksRootUpdateTimelock(&_ISuperGovernor.TransactOpts, newTimelock)
}

// ChangePrimaryManager is a paid mutator transaction binding the contract method 0x906811e0.
//
// Solidity: function changePrimaryManager(address strategy, address newManager) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) ChangePrimaryManager(opts *bind.TransactOpts, strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "changePrimaryManager", strategy, newManager)
}

// ChangePrimaryManager is a paid mutator transaction binding the contract method 0x906811e0.
//
// Solidity: function changePrimaryManager(address strategy, address newManager) returns()
func (_ISuperGovernor *ISuperGovernorSession) ChangePrimaryManager(strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ChangePrimaryManager(&_ISuperGovernor.TransactOpts, strategy, newManager)
}

// ChangePrimaryManager is a paid mutator transaction binding the contract method 0x906811e0.
//
// Solidity: function changePrimaryManager(address strategy, address newManager) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) ChangePrimaryManager(strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ChangePrimaryManager(&_ISuperGovernor.TransactOpts, strategy, newManager)
}

// ExecuteActivePPSOracleChange is a paid mutator transaction binding the contract method 0xf1031b4e.
//
// Solidity: function executeActivePPSOracleChange() returns()
func (_ISuperGovernor *ISuperGovernorTransactor) ExecuteActivePPSOracleChange(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "executeActivePPSOracleChange")
}

// ExecuteActivePPSOracleChange is a paid mutator transaction binding the contract method 0xf1031b4e.
//
// Solidity: function executeActivePPSOracleChange() returns()
func (_ISuperGovernor *ISuperGovernorSession) ExecuteActivePPSOracleChange() (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ExecuteActivePPSOracleChange(&_ISuperGovernor.TransactOpts)
}

// ExecuteActivePPSOracleChange is a paid mutator transaction binding the contract method 0xf1031b4e.
//
// Solidity: function executeActivePPSOracleChange() returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) ExecuteActivePPSOracleChange() (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ExecuteActivePPSOracleChange(&_ISuperGovernor.TransactOpts)
}

// ExecuteFeeUpdate is a paid mutator transaction binding the contract method 0x365d6bf3.
//
// Solidity: function executeFeeUpdate(uint8 feeType) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) ExecuteFeeUpdate(opts *bind.TransactOpts, feeType uint8) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "executeFeeUpdate", feeType)
}

// ExecuteFeeUpdate is a paid mutator transaction binding the contract method 0x365d6bf3.
//
// Solidity: function executeFeeUpdate(uint8 feeType) returns()
func (_ISuperGovernor *ISuperGovernorSession) ExecuteFeeUpdate(feeType uint8) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ExecuteFeeUpdate(&_ISuperGovernor.TransactOpts, feeType)
}

// ExecuteFeeUpdate is a paid mutator transaction binding the contract method 0x365d6bf3.
//
// Solidity: function executeFeeUpdate(uint8 feeType) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) ExecuteFeeUpdate(feeType uint8) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ExecuteFeeUpdate(&_ISuperGovernor.TransactOpts, feeType)
}

// ExecuteMinStalenesChange is a paid mutator transaction binding the contract method 0xdf767d13.
//
// Solidity: function executeMinStalenesChange() returns()
func (_ISuperGovernor *ISuperGovernorTransactor) ExecuteMinStalenesChange(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "executeMinStalenesChange")
}

// ExecuteMinStalenesChange is a paid mutator transaction binding the contract method 0xdf767d13.
//
// Solidity: function executeMinStalenesChange() returns()
func (_ISuperGovernor *ISuperGovernorSession) ExecuteMinStalenesChange() (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ExecuteMinStalenesChange(&_ISuperGovernor.TransactOpts)
}

// ExecuteMinStalenesChange is a paid mutator transaction binding the contract method 0xdf767d13.
//
// Solidity: function executeMinStalenesChange() returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) ExecuteMinStalenesChange() (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ExecuteMinStalenesChange(&_ISuperGovernor.TransactOpts)
}

// ExecuteOracleProviderRemoval is a paid mutator transaction binding the contract method 0x5f0ce3d1.
//
// Solidity: function executeOracleProviderRemoval() returns()
func (_ISuperGovernor *ISuperGovernorTransactor) ExecuteOracleProviderRemoval(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "executeOracleProviderRemoval")
}

// ExecuteOracleProviderRemoval is a paid mutator transaction binding the contract method 0x5f0ce3d1.
//
// Solidity: function executeOracleProviderRemoval() returns()
func (_ISuperGovernor *ISuperGovernorSession) ExecuteOracleProviderRemoval() (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ExecuteOracleProviderRemoval(&_ISuperGovernor.TransactOpts)
}

// ExecuteOracleProviderRemoval is a paid mutator transaction binding the contract method 0x5f0ce3d1.
//
// Solidity: function executeOracleProviderRemoval() returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) ExecuteOracleProviderRemoval() (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ExecuteOracleProviderRemoval(&_ISuperGovernor.TransactOpts)
}

// ExecuteOracleUpdate is a paid mutator transaction binding the contract method 0x45e62881.
//
// Solidity: function executeOracleUpdate() returns()
func (_ISuperGovernor *ISuperGovernorTransactor) ExecuteOracleUpdate(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "executeOracleUpdate")
}

// ExecuteOracleUpdate is a paid mutator transaction binding the contract method 0x45e62881.
//
// Solidity: function executeOracleUpdate() returns()
func (_ISuperGovernor *ISuperGovernorSession) ExecuteOracleUpdate() (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ExecuteOracleUpdate(&_ISuperGovernor.TransactOpts)
}

// ExecuteOracleUpdate is a paid mutator transaction binding the contract method 0x45e62881.
//
// Solidity: function executeOracleUpdate() returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) ExecuteOracleUpdate() (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ExecuteOracleUpdate(&_ISuperGovernor.TransactOpts)
}

// ExecuteSuperBankHookMerkleRootUpdate is a paid mutator transaction binding the contract method 0x290c49a1.
//
// Solidity: function executeSuperBankHookMerkleRootUpdate(address hook) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) ExecuteSuperBankHookMerkleRootUpdate(opts *bind.TransactOpts, hook common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "executeSuperBankHookMerkleRootUpdate", hook)
}

// ExecuteSuperBankHookMerkleRootUpdate is a paid mutator transaction binding the contract method 0x290c49a1.
//
// Solidity: function executeSuperBankHookMerkleRootUpdate(address hook) returns()
func (_ISuperGovernor *ISuperGovernorSession) ExecuteSuperBankHookMerkleRootUpdate(hook common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ExecuteSuperBankHookMerkleRootUpdate(&_ISuperGovernor.TransactOpts, hook)
}

// ExecuteSuperBankHookMerkleRootUpdate is a paid mutator transaction binding the contract method 0x290c49a1.
//
// Solidity: function executeSuperBankHookMerkleRootUpdate(address hook) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) ExecuteSuperBankHookMerkleRootUpdate(hook common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ExecuteSuperBankHookMerkleRootUpdate(&_ISuperGovernor.TransactOpts, hook)
}

// ExecuteUpkeepClaim is a paid mutator transaction binding the contract method 0x3202ac23.
//
// Solidity: function executeUpkeepClaim(uint256 amount) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) ExecuteUpkeepClaim(opts *bind.TransactOpts, amount *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "executeUpkeepClaim", amount)
}

// ExecuteUpkeepClaim is a paid mutator transaction binding the contract method 0x3202ac23.
//
// Solidity: function executeUpkeepClaim(uint256 amount) returns()
func (_ISuperGovernor *ISuperGovernorSession) ExecuteUpkeepClaim(amount *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ExecuteUpkeepClaim(&_ISuperGovernor.TransactOpts, amount)
}

// ExecuteUpkeepClaim is a paid mutator transaction binding the contract method 0x3202ac23.
//
// Solidity: function executeUpkeepClaim(uint256 amount) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) ExecuteUpkeepClaim(amount *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ExecuteUpkeepClaim(&_ISuperGovernor.TransactOpts, amount)
}

// ExecuteUpkeepPaymentsChange is a paid mutator transaction binding the contract method 0xecc3d967.
//
// Solidity: function executeUpkeepPaymentsChange() returns()
func (_ISuperGovernor *ISuperGovernorTransactor) ExecuteUpkeepPaymentsChange(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "executeUpkeepPaymentsChange")
}

// ExecuteUpkeepPaymentsChange is a paid mutator transaction binding the contract method 0xecc3d967.
//
// Solidity: function executeUpkeepPaymentsChange() returns()
func (_ISuperGovernor *ISuperGovernorSession) ExecuteUpkeepPaymentsChange() (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ExecuteUpkeepPaymentsChange(&_ISuperGovernor.TransactOpts)
}

// ExecuteUpkeepPaymentsChange is a paid mutator transaction binding the contract method 0xecc3d967.
//
// Solidity: function executeUpkeepPaymentsChange() returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) ExecuteUpkeepPaymentsChange() (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ExecuteUpkeepPaymentsChange(&_ISuperGovernor.TransactOpts)
}

// FreezeManagerTakeover is a paid mutator transaction binding the contract method 0xca774c12.
//
// Solidity: function freezeManagerTakeover() returns()
func (_ISuperGovernor *ISuperGovernorTransactor) FreezeManagerTakeover(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "freezeManagerTakeover")
}

// FreezeManagerTakeover is a paid mutator transaction binding the contract method 0xca774c12.
//
// Solidity: function freezeManagerTakeover() returns()
func (_ISuperGovernor *ISuperGovernorSession) FreezeManagerTakeover() (*types.Transaction, error) {
	return _ISuperGovernor.Contract.FreezeManagerTakeover(&_ISuperGovernor.TransactOpts)
}

// FreezeManagerTakeover is a paid mutator transaction binding the contract method 0xca774c12.
//
// Solidity: function freezeManagerTakeover() returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) FreezeManagerTakeover() (*types.Transaction, error) {
	return _ISuperGovernor.Contract.FreezeManagerTakeover(&_ISuperGovernor.TransactOpts)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_ISuperGovernor *ISuperGovernorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.GrantRole(&_ISuperGovernor.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.GrantRole(&_ISuperGovernor.TransactOpts, role, account)
}

// ProposeActivePPSOracle is a paid mutator transaction binding the contract method 0x1551c6c0.
//
// Solidity: function proposeActivePPSOracle(address oracle) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) ProposeActivePPSOracle(opts *bind.TransactOpts, oracle common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "proposeActivePPSOracle", oracle)
}

// ProposeActivePPSOracle is a paid mutator transaction binding the contract method 0x1551c6c0.
//
// Solidity: function proposeActivePPSOracle(address oracle) returns()
func (_ISuperGovernor *ISuperGovernorSession) ProposeActivePPSOracle(oracle common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ProposeActivePPSOracle(&_ISuperGovernor.TransactOpts, oracle)
}

// ProposeActivePPSOracle is a paid mutator transaction binding the contract method 0x1551c6c0.
//
// Solidity: function proposeActivePPSOracle(address oracle) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) ProposeActivePPSOracle(oracle common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ProposeActivePPSOracle(&_ISuperGovernor.TransactOpts, oracle)
}

// ProposeFee is a paid mutator transaction binding the contract method 0x022e38cf.
//
// Solidity: function proposeFee(uint8 feeType, uint256 value) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) ProposeFee(opts *bind.TransactOpts, feeType uint8, value *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "proposeFee", feeType, value)
}

// ProposeFee is a paid mutator transaction binding the contract method 0x022e38cf.
//
// Solidity: function proposeFee(uint8 feeType, uint256 value) returns()
func (_ISuperGovernor *ISuperGovernorSession) ProposeFee(feeType uint8, value *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ProposeFee(&_ISuperGovernor.TransactOpts, feeType, value)
}

// ProposeFee is a paid mutator transaction binding the contract method 0x022e38cf.
//
// Solidity: function proposeFee(uint8 feeType, uint256 value) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) ProposeFee(feeType uint8, value *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ProposeFee(&_ISuperGovernor.TransactOpts, feeType, value)
}

// ProposeGlobalHooksRoot is a paid mutator transaction binding the contract method 0xb0e5173b.
//
// Solidity: function proposeGlobalHooksRoot(bytes32 newRoot) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) ProposeGlobalHooksRoot(opts *bind.TransactOpts, newRoot [32]byte) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "proposeGlobalHooksRoot", newRoot)
}

// ProposeGlobalHooksRoot is a paid mutator transaction binding the contract method 0xb0e5173b.
//
// Solidity: function proposeGlobalHooksRoot(bytes32 newRoot) returns()
func (_ISuperGovernor *ISuperGovernorSession) ProposeGlobalHooksRoot(newRoot [32]byte) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ProposeGlobalHooksRoot(&_ISuperGovernor.TransactOpts, newRoot)
}

// ProposeGlobalHooksRoot is a paid mutator transaction binding the contract method 0xb0e5173b.
//
// Solidity: function proposeGlobalHooksRoot(bytes32 newRoot) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) ProposeGlobalHooksRoot(newRoot [32]byte) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ProposeGlobalHooksRoot(&_ISuperGovernor.TransactOpts, newRoot)
}

// ProposeMinStaleness is a paid mutator transaction binding the contract method 0xc0c10943.
//
// Solidity: function proposeMinStaleness(uint256 newMinStaleness) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) ProposeMinStaleness(opts *bind.TransactOpts, newMinStaleness *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "proposeMinStaleness", newMinStaleness)
}

// ProposeMinStaleness is a paid mutator transaction binding the contract method 0xc0c10943.
//
// Solidity: function proposeMinStaleness(uint256 newMinStaleness) returns()
func (_ISuperGovernor *ISuperGovernorSession) ProposeMinStaleness(newMinStaleness *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ProposeMinStaleness(&_ISuperGovernor.TransactOpts, newMinStaleness)
}

// ProposeMinStaleness is a paid mutator transaction binding the contract method 0xc0c10943.
//
// Solidity: function proposeMinStaleness(uint256 newMinStaleness) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) ProposeMinStaleness(newMinStaleness *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ProposeMinStaleness(&_ISuperGovernor.TransactOpts, newMinStaleness)
}

// ProposeSuperBankHookMerkleRoot is a paid mutator transaction binding the contract method 0x5e46e8b9.
//
// Solidity: function proposeSuperBankHookMerkleRoot(address hook, bytes32 proposedRoot) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) ProposeSuperBankHookMerkleRoot(opts *bind.TransactOpts, hook common.Address, proposedRoot [32]byte) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "proposeSuperBankHookMerkleRoot", hook, proposedRoot)
}

// ProposeSuperBankHookMerkleRoot is a paid mutator transaction binding the contract method 0x5e46e8b9.
//
// Solidity: function proposeSuperBankHookMerkleRoot(address hook, bytes32 proposedRoot) returns()
func (_ISuperGovernor *ISuperGovernorSession) ProposeSuperBankHookMerkleRoot(hook common.Address, proposedRoot [32]byte) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ProposeSuperBankHookMerkleRoot(&_ISuperGovernor.TransactOpts, hook, proposedRoot)
}

// ProposeSuperBankHookMerkleRoot is a paid mutator transaction binding the contract method 0x5e46e8b9.
//
// Solidity: function proposeSuperBankHookMerkleRoot(address hook, bytes32 proposedRoot) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) ProposeSuperBankHookMerkleRoot(hook common.Address, proposedRoot [32]byte) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ProposeSuperBankHookMerkleRoot(&_ISuperGovernor.TransactOpts, hook, proposedRoot)
}

// ProposeUpkeepPaymentsChange is a paid mutator transaction binding the contract method 0x778f8a93.
//
// Solidity: function proposeUpkeepPaymentsChange(bool enabled) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) ProposeUpkeepPaymentsChange(opts *bind.TransactOpts, enabled bool) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "proposeUpkeepPaymentsChange", enabled)
}

// ProposeUpkeepPaymentsChange is a paid mutator transaction binding the contract method 0x778f8a93.
//
// Solidity: function proposeUpkeepPaymentsChange(bool enabled) returns()
func (_ISuperGovernor *ISuperGovernorSession) ProposeUpkeepPaymentsChange(enabled bool) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ProposeUpkeepPaymentsChange(&_ISuperGovernor.TransactOpts, enabled)
}

// ProposeUpkeepPaymentsChange is a paid mutator transaction binding the contract method 0x778f8a93.
//
// Solidity: function proposeUpkeepPaymentsChange(bool enabled) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) ProposeUpkeepPaymentsChange(enabled bool) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.ProposeUpkeepPaymentsChange(&_ISuperGovernor.TransactOpts, enabled)
}

// QueueOracleProviderRemoval is a paid mutator transaction binding the contract method 0x6490305f.
//
// Solidity: function queueOracleProviderRemoval(bytes32[] providers) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) QueueOracleProviderRemoval(opts *bind.TransactOpts, providers [][32]byte) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "queueOracleProviderRemoval", providers)
}

// QueueOracleProviderRemoval is a paid mutator transaction binding the contract method 0x6490305f.
//
// Solidity: function queueOracleProviderRemoval(bytes32[] providers) returns()
func (_ISuperGovernor *ISuperGovernorSession) QueueOracleProviderRemoval(providers [][32]byte) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.QueueOracleProviderRemoval(&_ISuperGovernor.TransactOpts, providers)
}

// QueueOracleProviderRemoval is a paid mutator transaction binding the contract method 0x6490305f.
//
// Solidity: function queueOracleProviderRemoval(bytes32[] providers) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) QueueOracleProviderRemoval(providers [][32]byte) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.QueueOracleProviderRemoval(&_ISuperGovernor.TransactOpts, providers)
}

// QueueOracleUpdate is a paid mutator transaction binding the contract method 0xba1f073c.
//
// Solidity: function queueOracleUpdate(address[] bases, address[] quotes, bytes32[] providers, address[] feeds) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) QueueOracleUpdate(opts *bind.TransactOpts, bases []common.Address, quotes []common.Address, providers [][32]byte, feeds []common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "queueOracleUpdate", bases, quotes, providers, feeds)
}

// QueueOracleUpdate is a paid mutator transaction binding the contract method 0xba1f073c.
//
// Solidity: function queueOracleUpdate(address[] bases, address[] quotes, bytes32[] providers, address[] feeds) returns()
func (_ISuperGovernor *ISuperGovernorSession) QueueOracleUpdate(bases []common.Address, quotes []common.Address, providers [][32]byte, feeds []common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.QueueOracleUpdate(&_ISuperGovernor.TransactOpts, bases, quotes, providers, feeds)
}

// QueueOracleUpdate is a paid mutator transaction binding the contract method 0xba1f073c.
//
// Solidity: function queueOracleUpdate(address[] bases, address[] quotes, bytes32[] providers, address[] feeds) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) QueueOracleUpdate(bases []common.Address, quotes []common.Address, providers [][32]byte, feeds []common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.QueueOracleUpdate(&_ISuperGovernor.TransactOpts, bases, quotes, providers, feeds)
}

// RegisterHook is a paid mutator transaction binding the contract method 0x6354b661.
//
// Solidity: function registerHook(address hook) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) RegisterHook(opts *bind.TransactOpts, hook common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "registerHook", hook)
}

// RegisterHook is a paid mutator transaction binding the contract method 0x6354b661.
//
// Solidity: function registerHook(address hook) returns()
func (_ISuperGovernor *ISuperGovernorSession) RegisterHook(hook common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.RegisterHook(&_ISuperGovernor.TransactOpts, hook)
}

// RegisterHook is a paid mutator transaction binding the contract method 0x6354b661.
//
// Solidity: function registerHook(address hook) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) RegisterHook(hook common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.RegisterHook(&_ISuperGovernor.TransactOpts, hook)
}

// RemoveExecutor is a paid mutator transaction binding the contract method 0x24788429.
//
// Solidity: function removeExecutor(address executor) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) RemoveExecutor(opts *bind.TransactOpts, executor common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "removeExecutor", executor)
}

// RemoveExecutor is a paid mutator transaction binding the contract method 0x24788429.
//
// Solidity: function removeExecutor(address executor) returns()
func (_ISuperGovernor *ISuperGovernorSession) RemoveExecutor(executor common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.RemoveExecutor(&_ISuperGovernor.TransactOpts, executor)
}

// RemoveExecutor is a paid mutator transaction binding the contract method 0x24788429.
//
// Solidity: function removeExecutor(address executor) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) RemoveExecutor(executor common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.RemoveExecutor(&_ISuperGovernor.TransactOpts, executor)
}

// RemoveSuperformManager is a paid mutator transaction binding the contract method 0x1c70d542.
//
// Solidity: function removeSuperformManager(address manager) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) RemoveSuperformManager(opts *bind.TransactOpts, manager common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "removeSuperformManager", manager)
}

// RemoveSuperformManager is a paid mutator transaction binding the contract method 0x1c70d542.
//
// Solidity: function removeSuperformManager(address manager) returns()
func (_ISuperGovernor *ISuperGovernorSession) RemoveSuperformManager(manager common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.RemoveSuperformManager(&_ISuperGovernor.TransactOpts, manager)
}

// RemoveSuperformManager is a paid mutator transaction binding the contract method 0x1c70d542.
//
// Solidity: function removeSuperformManager(address manager) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) RemoveSuperformManager(manager common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.RemoveSuperformManager(&_ISuperGovernor.TransactOpts, manager)
}

// RemoveValidator is a paid mutator transaction binding the contract method 0x40a141ff.
//
// Solidity: function removeValidator(address validator) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) RemoveValidator(opts *bind.TransactOpts, validator common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "removeValidator", validator)
}

// RemoveValidator is a paid mutator transaction binding the contract method 0x40a141ff.
//
// Solidity: function removeValidator(address validator) returns()
func (_ISuperGovernor *ISuperGovernorSession) RemoveValidator(validator common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.RemoveValidator(&_ISuperGovernor.TransactOpts, validator)
}

// RemoveValidator is a paid mutator transaction binding the contract method 0x40a141ff.
//
// Solidity: function removeValidator(address validator) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) RemoveValidator(validator common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.RemoveValidator(&_ISuperGovernor.TransactOpts, validator)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "renounceRole", role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_ISuperGovernor *ISuperGovernorSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.RenounceRole(&_ISuperGovernor.TransactOpts, role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.RenounceRole(&_ISuperGovernor.TransactOpts, role, callerConfirmation)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_ISuperGovernor *ISuperGovernorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.RevokeRole(&_ISuperGovernor.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.RevokeRole(&_ISuperGovernor.TransactOpts, role, account)
}

// SetActivePPSOracle is a paid mutator transaction binding the contract method 0xf9525fb7.
//
// Solidity: function setActivePPSOracle(address oracle) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) SetActivePPSOracle(opts *bind.TransactOpts, oracle common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "setActivePPSOracle", oracle)
}

// SetActivePPSOracle is a paid mutator transaction binding the contract method 0xf9525fb7.
//
// Solidity: function setActivePPSOracle(address oracle) returns()
func (_ISuperGovernor *ISuperGovernorSession) SetActivePPSOracle(oracle common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetActivePPSOracle(&_ISuperGovernor.TransactOpts, oracle)
}

// SetActivePPSOracle is a paid mutator transaction binding the contract method 0xf9525fb7.
//
// Solidity: function setActivePPSOracle(address oracle) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) SetActivePPSOracle(oracle common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetActivePPSOracle(&_ISuperGovernor.TransactOpts, oracle)
}

// SetAddress is a paid mutator transaction binding the contract method 0xca446dd9.
//
// Solidity: function setAddress(bytes32 key, address value) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) SetAddress(opts *bind.TransactOpts, key [32]byte, value common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "setAddress", key, value)
}

// SetAddress is a paid mutator transaction binding the contract method 0xca446dd9.
//
// Solidity: function setAddress(bytes32 key, address value) returns()
func (_ISuperGovernor *ISuperGovernorSession) SetAddress(key [32]byte, value common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetAddress(&_ISuperGovernor.TransactOpts, key, value)
}

// SetAddress is a paid mutator transaction binding the contract method 0xca446dd9.
//
// Solidity: function setAddress(bytes32 key, address value) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) SetAddress(key [32]byte, value common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetAddress(&_ISuperGovernor.TransactOpts, key, value)
}

// SetEmergencyPrice is a paid mutator transaction binding the contract method 0x7ee185c1.
//
// Solidity: function setEmergencyPrice(address token, uint256 price) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) SetEmergencyPrice(opts *bind.TransactOpts, token common.Address, price *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "setEmergencyPrice", token, price)
}

// SetEmergencyPrice is a paid mutator transaction binding the contract method 0x7ee185c1.
//
// Solidity: function setEmergencyPrice(address token, uint256 price) returns()
func (_ISuperGovernor *ISuperGovernorSession) SetEmergencyPrice(token common.Address, price *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetEmergencyPrice(&_ISuperGovernor.TransactOpts, token, price)
}

// SetEmergencyPrice is a paid mutator transaction binding the contract method 0x7ee185c1.
//
// Solidity: function setEmergencyPrice(address token, uint256 price) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) SetEmergencyPrice(token common.Address, price *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetEmergencyPrice(&_ISuperGovernor.TransactOpts, token, price)
}

// SetGasInfo is a paid mutator transaction binding the contract method 0x0b4396aa.
//
// Solidity: function setGasInfo(address oracle, uint256 gasIncreasePerEntryBatch) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) SetGasInfo(opts *bind.TransactOpts, oracle common.Address, gasIncreasePerEntryBatch *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "setGasInfo", oracle, gasIncreasePerEntryBatch)
}

// SetGasInfo is a paid mutator transaction binding the contract method 0x0b4396aa.
//
// Solidity: function setGasInfo(address oracle, uint256 gasIncreasePerEntryBatch) returns()
func (_ISuperGovernor *ISuperGovernorSession) SetGasInfo(oracle common.Address, gasIncreasePerEntryBatch *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetGasInfo(&_ISuperGovernor.TransactOpts, oracle, gasIncreasePerEntryBatch)
}

// SetGasInfo is a paid mutator transaction binding the contract method 0x0b4396aa.
//
// Solidity: function setGasInfo(address oracle, uint256 gasIncreasePerEntryBatch) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) SetGasInfo(oracle common.Address, gasIncreasePerEntryBatch *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetGasInfo(&_ISuperGovernor.TransactOpts, oracle, gasIncreasePerEntryBatch)
}

// SetGlobalHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xd5f3cd86.
//
// Solidity: function setGlobalHooksRootVetoStatus(bool vetoed) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) SetGlobalHooksRootVetoStatus(opts *bind.TransactOpts, vetoed bool) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "setGlobalHooksRootVetoStatus", vetoed)
}

// SetGlobalHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xd5f3cd86.
//
// Solidity: function setGlobalHooksRootVetoStatus(bool vetoed) returns()
func (_ISuperGovernor *ISuperGovernorSession) SetGlobalHooksRootVetoStatus(vetoed bool) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetGlobalHooksRootVetoStatus(&_ISuperGovernor.TransactOpts, vetoed)
}

// SetGlobalHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xd5f3cd86.
//
// Solidity: function setGlobalHooksRootVetoStatus(bool vetoed) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) SetGlobalHooksRootVetoStatus(vetoed bool) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetGlobalHooksRootVetoStatus(&_ISuperGovernor.TransactOpts, vetoed)
}

// SetOracleFeedMaxStaleness is a paid mutator transaction binding the contract method 0x17a79fa6.
//
// Solidity: function setOracleFeedMaxStaleness(address feed, uint256 newMaxStaleness) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) SetOracleFeedMaxStaleness(opts *bind.TransactOpts, feed common.Address, newMaxStaleness *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "setOracleFeedMaxStaleness", feed, newMaxStaleness)
}

// SetOracleFeedMaxStaleness is a paid mutator transaction binding the contract method 0x17a79fa6.
//
// Solidity: function setOracleFeedMaxStaleness(address feed, uint256 newMaxStaleness) returns()
func (_ISuperGovernor *ISuperGovernorSession) SetOracleFeedMaxStaleness(feed common.Address, newMaxStaleness *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetOracleFeedMaxStaleness(&_ISuperGovernor.TransactOpts, feed, newMaxStaleness)
}

// SetOracleFeedMaxStaleness is a paid mutator transaction binding the contract method 0x17a79fa6.
//
// Solidity: function setOracleFeedMaxStaleness(address feed, uint256 newMaxStaleness) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) SetOracleFeedMaxStaleness(feed common.Address, newMaxStaleness *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetOracleFeedMaxStaleness(&_ISuperGovernor.TransactOpts, feed, newMaxStaleness)
}

// SetOracleFeedMaxStalenessBatch is a paid mutator transaction binding the contract method 0x3fa9fe64.
//
// Solidity: function setOracleFeedMaxStalenessBatch(address[] feeds, uint256[] newMaxStalenessList) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) SetOracleFeedMaxStalenessBatch(opts *bind.TransactOpts, feeds []common.Address, newMaxStalenessList []*big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "setOracleFeedMaxStalenessBatch", feeds, newMaxStalenessList)
}

// SetOracleFeedMaxStalenessBatch is a paid mutator transaction binding the contract method 0x3fa9fe64.
//
// Solidity: function setOracleFeedMaxStalenessBatch(address[] feeds, uint256[] newMaxStalenessList) returns()
func (_ISuperGovernor *ISuperGovernorSession) SetOracleFeedMaxStalenessBatch(feeds []common.Address, newMaxStalenessList []*big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetOracleFeedMaxStalenessBatch(&_ISuperGovernor.TransactOpts, feeds, newMaxStalenessList)
}

// SetOracleFeedMaxStalenessBatch is a paid mutator transaction binding the contract method 0x3fa9fe64.
//
// Solidity: function setOracleFeedMaxStalenessBatch(address[] feeds, uint256[] newMaxStalenessList) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) SetOracleFeedMaxStalenessBatch(feeds []common.Address, newMaxStalenessList []*big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetOracleFeedMaxStalenessBatch(&_ISuperGovernor.TransactOpts, feeds, newMaxStalenessList)
}

// SetOracleMaxStaleness is a paid mutator transaction binding the contract method 0x324341ed.
//
// Solidity: function setOracleMaxStaleness(uint256 newMaxStaleness) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) SetOracleMaxStaleness(opts *bind.TransactOpts, newMaxStaleness *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "setOracleMaxStaleness", newMaxStaleness)
}

// SetOracleMaxStaleness is a paid mutator transaction binding the contract method 0x324341ed.
//
// Solidity: function setOracleMaxStaleness(uint256 newMaxStaleness) returns()
func (_ISuperGovernor *ISuperGovernorSession) SetOracleMaxStaleness(newMaxStaleness *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetOracleMaxStaleness(&_ISuperGovernor.TransactOpts, newMaxStaleness)
}

// SetOracleMaxStaleness is a paid mutator transaction binding the contract method 0x324341ed.
//
// Solidity: function setOracleMaxStaleness(uint256 newMaxStaleness) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) SetOracleMaxStaleness(newMaxStaleness *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetOracleMaxStaleness(&_ISuperGovernor.TransactOpts, newMaxStaleness)
}

// SetPPSOracleQuorum is a paid mutator transaction binding the contract method 0x52da1de3.
//
// Solidity: function setPPSOracleQuorum(uint256 quorum) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) SetPPSOracleQuorum(opts *bind.TransactOpts, quorum *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "setPPSOracleQuorum", quorum)
}

// SetPPSOracleQuorum is a paid mutator transaction binding the contract method 0x52da1de3.
//
// Solidity: function setPPSOracleQuorum(uint256 quorum) returns()
func (_ISuperGovernor *ISuperGovernorSession) SetPPSOracleQuorum(quorum *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetPPSOracleQuorum(&_ISuperGovernor.TransactOpts, quorum)
}

// SetPPSOracleQuorum is a paid mutator transaction binding the contract method 0x52da1de3.
//
// Solidity: function setPPSOracleQuorum(uint256 quorum) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) SetPPSOracleQuorum(quorum *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetPPSOracleQuorum(&_ISuperGovernor.TransactOpts, quorum)
}

// SetStrategyHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xf5297a47.
//
// Solidity: function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) SetStrategyHooksRootVetoStatus(opts *bind.TransactOpts, strategy common.Address, vetoed bool) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "setStrategyHooksRootVetoStatus", strategy, vetoed)
}

// SetStrategyHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xf5297a47.
//
// Solidity: function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) returns()
func (_ISuperGovernor *ISuperGovernorSession) SetStrategyHooksRootVetoStatus(strategy common.Address, vetoed bool) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetStrategyHooksRootVetoStatus(&_ISuperGovernor.TransactOpts, strategy, vetoed)
}

// SetStrategyHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xf5297a47.
//
// Solidity: function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) SetStrategyHooksRootVetoStatus(strategy common.Address, vetoed bool) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SetStrategyHooksRootVetoStatus(&_ISuperGovernor.TransactOpts, strategy, vetoed)
}

// SlashStake is a paid mutator transaction binding the contract method 0x98d1c5a8.
//
// Solidity: function slashStake(address manager, uint256 amount) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) SlashStake(opts *bind.TransactOpts, manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "slashStake", manager, amount)
}

// SlashStake is a paid mutator transaction binding the contract method 0x98d1c5a8.
//
// Solidity: function slashStake(address manager, uint256 amount) returns()
func (_ISuperGovernor *ISuperGovernorSession) SlashStake(manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SlashStake(&_ISuperGovernor.TransactOpts, manager, amount)
}

// SlashStake is a paid mutator transaction binding the contract method 0x98d1c5a8.
//
// Solidity: function slashStake(address manager, uint256 amount) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) SlashStake(manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.SlashStake(&_ISuperGovernor.TransactOpts, manager, amount)
}

// UnregisterHook is a paid mutator transaction binding the contract method 0xf76f48cb.
//
// Solidity: function unregisterHook(address hook) returns()
func (_ISuperGovernor *ISuperGovernorTransactor) UnregisterHook(opts *bind.TransactOpts, hook common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.contract.Transact(opts, "unregisterHook", hook)
}

// UnregisterHook is a paid mutator transaction binding the contract method 0xf76f48cb.
//
// Solidity: function unregisterHook(address hook) returns()
func (_ISuperGovernor *ISuperGovernorSession) UnregisterHook(hook common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.UnregisterHook(&_ISuperGovernor.TransactOpts, hook)
}

// UnregisterHook is a paid mutator transaction binding the contract method 0xf76f48cb.
//
// Solidity: function unregisterHook(address hook) returns()
func (_ISuperGovernor *ISuperGovernorTransactorSession) UnregisterHook(hook common.Address) (*types.Transaction, error) {
	return _ISuperGovernor.Contract.UnregisterHook(&_ISuperGovernor.TransactOpts, hook)
}

// ISuperGovernorActivePPSOracleChangedIterator is returned from FilterActivePPSOracleChanged and is used to iterate over the raw logs and unpacked data for ActivePPSOracleChanged events raised by the ISuperGovernor contract.
type ISuperGovernorActivePPSOracleChangedIterator struct {
	Event *ISuperGovernorActivePPSOracleChanged // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorActivePPSOracleChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorActivePPSOracleChanged)
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
		it.Event = new(ISuperGovernorActivePPSOracleChanged)
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
func (it *ISuperGovernorActivePPSOracleChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorActivePPSOracleChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorActivePPSOracleChanged represents a ActivePPSOracleChanged event raised by the ISuperGovernor contract.
type ISuperGovernorActivePPSOracleChanged struct {
	OldOracle common.Address
	NewOracle common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterActivePPSOracleChanged is a free log retrieval operation binding the contract event 0x6f32d4a08b9b9b8ee365ed09addde1536e0cc6a14a46e120923bafef349131e4.
//
// Solidity: event ActivePPSOracleChanged(address indexed oldOracle, address indexed newOracle)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterActivePPSOracleChanged(opts *bind.FilterOpts, oldOracle []common.Address, newOracle []common.Address) (*ISuperGovernorActivePPSOracleChangedIterator, error) {

	var oldOracleRule []interface{}
	for _, oldOracleItem := range oldOracle {
		oldOracleRule = append(oldOracleRule, oldOracleItem)
	}
	var newOracleRule []interface{}
	for _, newOracleItem := range newOracle {
		newOracleRule = append(newOracleRule, newOracleItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "ActivePPSOracleChanged", oldOracleRule, newOracleRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorActivePPSOracleChangedIterator{contract: _ISuperGovernor.contract, event: "ActivePPSOracleChanged", logs: logs, sub: sub}, nil
}

// WatchActivePPSOracleChanged is a free log subscription operation binding the contract event 0x6f32d4a08b9b9b8ee365ed09addde1536e0cc6a14a46e120923bafef349131e4.
//
// Solidity: event ActivePPSOracleChanged(address indexed oldOracle, address indexed newOracle)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchActivePPSOracleChanged(opts *bind.WatchOpts, sink chan<- *ISuperGovernorActivePPSOracleChanged, oldOracle []common.Address, newOracle []common.Address) (event.Subscription, error) {

	var oldOracleRule []interface{}
	for _, oldOracleItem := range oldOracle {
		oldOracleRule = append(oldOracleRule, oldOracleItem)
	}
	var newOracleRule []interface{}
	for _, newOracleItem := range newOracle {
		newOracleRule = append(newOracleRule, newOracleItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "ActivePPSOracleChanged", oldOracleRule, newOracleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorActivePPSOracleChanged)
				if err := _ISuperGovernor.contract.UnpackLog(event, "ActivePPSOracleChanged", log); err != nil {
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
// Solidity: event ActivePPSOracleChanged(address indexed oldOracle, address indexed newOracle)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseActivePPSOracleChanged(log types.Log) (*ISuperGovernorActivePPSOracleChanged, error) {
	event := new(ISuperGovernorActivePPSOracleChanged)
	if err := _ISuperGovernor.contract.UnpackLog(event, "ActivePPSOracleChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorActivePPSOracleProposedIterator is returned from FilterActivePPSOracleProposed and is used to iterate over the raw logs and unpacked data for ActivePPSOracleProposed events raised by the ISuperGovernor contract.
type ISuperGovernorActivePPSOracleProposedIterator struct {
	Event *ISuperGovernorActivePPSOracleProposed // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorActivePPSOracleProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorActivePPSOracleProposed)
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
		it.Event = new(ISuperGovernorActivePPSOracleProposed)
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
func (it *ISuperGovernorActivePPSOracleProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorActivePPSOracleProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorActivePPSOracleProposed represents a ActivePPSOracleProposed event raised by the ISuperGovernor contract.
type ISuperGovernorActivePPSOracleProposed struct {
	Oracle        common.Address
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterActivePPSOracleProposed is a free log retrieval operation binding the contract event 0x0081013d01b2d41dec72c3449ec25ce9dda2847a6e11ad584836ab3589efe675.
//
// Solidity: event ActivePPSOracleProposed(address indexed oracle, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterActivePPSOracleProposed(opts *bind.FilterOpts, oracle []common.Address) (*ISuperGovernorActivePPSOracleProposedIterator, error) {

	var oracleRule []interface{}
	for _, oracleItem := range oracle {
		oracleRule = append(oracleRule, oracleItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "ActivePPSOracleProposed", oracleRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorActivePPSOracleProposedIterator{contract: _ISuperGovernor.contract, event: "ActivePPSOracleProposed", logs: logs, sub: sub}, nil
}

// WatchActivePPSOracleProposed is a free log subscription operation binding the contract event 0x0081013d01b2d41dec72c3449ec25ce9dda2847a6e11ad584836ab3589efe675.
//
// Solidity: event ActivePPSOracleProposed(address indexed oracle, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchActivePPSOracleProposed(opts *bind.WatchOpts, sink chan<- *ISuperGovernorActivePPSOracleProposed, oracle []common.Address) (event.Subscription, error) {

	var oracleRule []interface{}
	for _, oracleItem := range oracle {
		oracleRule = append(oracleRule, oracleItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "ActivePPSOracleProposed", oracleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorActivePPSOracleProposed)
				if err := _ISuperGovernor.contract.UnpackLog(event, "ActivePPSOracleProposed", log); err != nil {
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
// Solidity: event ActivePPSOracleProposed(address indexed oracle, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseActivePPSOracleProposed(log types.Log) (*ISuperGovernorActivePPSOracleProposed, error) {
	event := new(ISuperGovernorActivePPSOracleProposed)
	if err := _ISuperGovernor.contract.UnpackLog(event, "ActivePPSOracleProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorActivePPSOracleSetIterator is returned from FilterActivePPSOracleSet and is used to iterate over the raw logs and unpacked data for ActivePPSOracleSet events raised by the ISuperGovernor contract.
type ISuperGovernorActivePPSOracleSetIterator struct {
	Event *ISuperGovernorActivePPSOracleSet // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorActivePPSOracleSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorActivePPSOracleSet)
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
		it.Event = new(ISuperGovernorActivePPSOracleSet)
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
func (it *ISuperGovernorActivePPSOracleSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorActivePPSOracleSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorActivePPSOracleSet represents a ActivePPSOracleSet event raised by the ISuperGovernor contract.
type ISuperGovernorActivePPSOracleSet struct {
	Oracle common.Address
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterActivePPSOracleSet is a free log retrieval operation binding the contract event 0x4f8ebeedbe3d26fd9e31b446c8da12464fc23cd6ce8c45510c211175190d62fa.
//
// Solidity: event ActivePPSOracleSet(address indexed oracle)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterActivePPSOracleSet(opts *bind.FilterOpts, oracle []common.Address) (*ISuperGovernorActivePPSOracleSetIterator, error) {

	var oracleRule []interface{}
	for _, oracleItem := range oracle {
		oracleRule = append(oracleRule, oracleItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "ActivePPSOracleSet", oracleRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorActivePPSOracleSetIterator{contract: _ISuperGovernor.contract, event: "ActivePPSOracleSet", logs: logs, sub: sub}, nil
}

// WatchActivePPSOracleSet is a free log subscription operation binding the contract event 0x4f8ebeedbe3d26fd9e31b446c8da12464fc23cd6ce8c45510c211175190d62fa.
//
// Solidity: event ActivePPSOracleSet(address indexed oracle)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchActivePPSOracleSet(opts *bind.WatchOpts, sink chan<- *ISuperGovernorActivePPSOracleSet, oracle []common.Address) (event.Subscription, error) {

	var oracleRule []interface{}
	for _, oracleItem := range oracle {
		oracleRule = append(oracleRule, oracleItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "ActivePPSOracleSet", oracleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorActivePPSOracleSet)
				if err := _ISuperGovernor.contract.UnpackLog(event, "ActivePPSOracleSet", log); err != nil {
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
// Solidity: event ActivePPSOracleSet(address indexed oracle)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseActivePPSOracleSet(log types.Log) (*ISuperGovernorActivePPSOracleSet, error) {
	event := new(ISuperGovernorActivePPSOracleSet)
	if err := _ISuperGovernor.contract.UnpackLog(event, "ActivePPSOracleSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorAddressSetIterator is returned from FilterAddressSet and is used to iterate over the raw logs and unpacked data for AddressSet events raised by the ISuperGovernor contract.
type ISuperGovernorAddressSetIterator struct {
	Event *ISuperGovernorAddressSet // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorAddressSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorAddressSet)
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
		it.Event = new(ISuperGovernorAddressSet)
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
func (it *ISuperGovernorAddressSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorAddressSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorAddressSet represents a AddressSet event raised by the ISuperGovernor contract.
type ISuperGovernorAddressSet struct {
	Key      [32]byte
	OldValue common.Address
	Value    common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterAddressSet is a free log retrieval operation binding the contract event 0x9ef0e8c8e52743bb38b83b17d9429141d494b8041ca6d616a6c77cebae9cd8b7.
//
// Solidity: event AddressSet(bytes32 indexed key, address indexed oldValue, address indexed value)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterAddressSet(opts *bind.FilterOpts, key [][32]byte, oldValue []common.Address, value []common.Address) (*ISuperGovernorAddressSetIterator, error) {

	var keyRule []interface{}
	for _, keyItem := range key {
		keyRule = append(keyRule, keyItem)
	}
	var oldValueRule []interface{}
	for _, oldValueItem := range oldValue {
		oldValueRule = append(oldValueRule, oldValueItem)
	}
	var valueRule []interface{}
	for _, valueItem := range value {
		valueRule = append(valueRule, valueItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "AddressSet", keyRule, oldValueRule, valueRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorAddressSetIterator{contract: _ISuperGovernor.contract, event: "AddressSet", logs: logs, sub: sub}, nil
}

// WatchAddressSet is a free log subscription operation binding the contract event 0x9ef0e8c8e52743bb38b83b17d9429141d494b8041ca6d616a6c77cebae9cd8b7.
//
// Solidity: event AddressSet(bytes32 indexed key, address indexed oldValue, address indexed value)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchAddressSet(opts *bind.WatchOpts, sink chan<- *ISuperGovernorAddressSet, key [][32]byte, oldValue []common.Address, value []common.Address) (event.Subscription, error) {

	var keyRule []interface{}
	for _, keyItem := range key {
		keyRule = append(keyRule, keyItem)
	}
	var oldValueRule []interface{}
	for _, oldValueItem := range oldValue {
		oldValueRule = append(oldValueRule, oldValueItem)
	}
	var valueRule []interface{}
	for _, valueItem := range value {
		valueRule = append(valueRule, valueItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "AddressSet", keyRule, oldValueRule, valueRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorAddressSet)
				if err := _ISuperGovernor.contract.UnpackLog(event, "AddressSet", log); err != nil {
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

// ParseAddressSet is a log parse operation binding the contract event 0x9ef0e8c8e52743bb38b83b17d9429141d494b8041ca6d616a6c77cebae9cd8b7.
//
// Solidity: event AddressSet(bytes32 indexed key, address indexed oldValue, address indexed value)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseAddressSet(log types.Log) (*ISuperGovernorAddressSet, error) {
	event := new(ISuperGovernorAddressSet)
	if err := _ISuperGovernor.contract.UnpackLog(event, "AddressSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorExecutorAddedIterator is returned from FilterExecutorAdded and is used to iterate over the raw logs and unpacked data for ExecutorAdded events raised by the ISuperGovernor contract.
type ISuperGovernorExecutorAddedIterator struct {
	Event *ISuperGovernorExecutorAdded // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorExecutorAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorExecutorAdded)
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
		it.Event = new(ISuperGovernorExecutorAdded)
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
func (it *ISuperGovernorExecutorAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorExecutorAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorExecutorAdded represents a ExecutorAdded event raised by the ISuperGovernor contract.
type ISuperGovernorExecutorAdded struct {
	Executor common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterExecutorAdded is a free log retrieval operation binding the contract event 0xae5b7c3b000f575c241001dc9bcb3d8778376889353b07121115574eceff78c5.
//
// Solidity: event ExecutorAdded(address indexed executor)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterExecutorAdded(opts *bind.FilterOpts, executor []common.Address) (*ISuperGovernorExecutorAddedIterator, error) {

	var executorRule []interface{}
	for _, executorItem := range executor {
		executorRule = append(executorRule, executorItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "ExecutorAdded", executorRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorExecutorAddedIterator{contract: _ISuperGovernor.contract, event: "ExecutorAdded", logs: logs, sub: sub}, nil
}

// WatchExecutorAdded is a free log subscription operation binding the contract event 0xae5b7c3b000f575c241001dc9bcb3d8778376889353b07121115574eceff78c5.
//
// Solidity: event ExecutorAdded(address indexed executor)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchExecutorAdded(opts *bind.WatchOpts, sink chan<- *ISuperGovernorExecutorAdded, executor []common.Address) (event.Subscription, error) {

	var executorRule []interface{}
	for _, executorItem := range executor {
		executorRule = append(executorRule, executorItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "ExecutorAdded", executorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorExecutorAdded)
				if err := _ISuperGovernor.contract.UnpackLog(event, "ExecutorAdded", log); err != nil {
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
// Solidity: event ExecutorAdded(address indexed executor)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseExecutorAdded(log types.Log) (*ISuperGovernorExecutorAdded, error) {
	event := new(ISuperGovernorExecutorAdded)
	if err := _ISuperGovernor.contract.UnpackLog(event, "ExecutorAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorExecutorRemovedIterator is returned from FilterExecutorRemoved and is used to iterate over the raw logs and unpacked data for ExecutorRemoved events raised by the ISuperGovernor contract.
type ISuperGovernorExecutorRemovedIterator struct {
	Event *ISuperGovernorExecutorRemoved // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorExecutorRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorExecutorRemoved)
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
		it.Event = new(ISuperGovernorExecutorRemoved)
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
func (it *ISuperGovernorExecutorRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorExecutorRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorExecutorRemoved represents a ExecutorRemoved event raised by the ISuperGovernor contract.
type ISuperGovernorExecutorRemoved struct {
	Executor common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterExecutorRemoved is a free log retrieval operation binding the contract event 0x4a2cf608bfb427f53279ec7f0eadf48913b9346ccefc3af138dbdec14ea0907d.
//
// Solidity: event ExecutorRemoved(address indexed executor)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterExecutorRemoved(opts *bind.FilterOpts, executor []common.Address) (*ISuperGovernorExecutorRemovedIterator, error) {

	var executorRule []interface{}
	for _, executorItem := range executor {
		executorRule = append(executorRule, executorItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "ExecutorRemoved", executorRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorExecutorRemovedIterator{contract: _ISuperGovernor.contract, event: "ExecutorRemoved", logs: logs, sub: sub}, nil
}

// WatchExecutorRemoved is a free log subscription operation binding the contract event 0x4a2cf608bfb427f53279ec7f0eadf48913b9346ccefc3af138dbdec14ea0907d.
//
// Solidity: event ExecutorRemoved(address indexed executor)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchExecutorRemoved(opts *bind.WatchOpts, sink chan<- *ISuperGovernorExecutorRemoved, executor []common.Address) (event.Subscription, error) {

	var executorRule []interface{}
	for _, executorItem := range executor {
		executorRule = append(executorRule, executorItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "ExecutorRemoved", executorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorExecutorRemoved)
				if err := _ISuperGovernor.contract.UnpackLog(event, "ExecutorRemoved", log); err != nil {
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
// Solidity: event ExecutorRemoved(address indexed executor)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseExecutorRemoved(log types.Log) (*ISuperGovernorExecutorRemoved, error) {
	event := new(ISuperGovernorExecutorRemoved)
	if err := _ISuperGovernor.contract.UnpackLog(event, "ExecutorRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorFeeProposedIterator is returned from FilterFeeProposed and is used to iterate over the raw logs and unpacked data for FeeProposed events raised by the ISuperGovernor contract.
type ISuperGovernorFeeProposedIterator struct {
	Event *ISuperGovernorFeeProposed // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorFeeProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorFeeProposed)
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
		it.Event = new(ISuperGovernorFeeProposed)
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
func (it *ISuperGovernorFeeProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorFeeProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorFeeProposed represents a FeeProposed event raised by the ISuperGovernor contract.
type ISuperGovernorFeeProposed struct {
	FeeType       uint8
	Value         *big.Int
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterFeeProposed is a free log retrieval operation binding the contract event 0x79548367f12987b3f5043ed1f421f89ebc84ab67cdaa9ee1e4d2a9e76b58ba0b.
//
// Solidity: event FeeProposed(uint8 indexed feeType, uint256 value, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterFeeProposed(opts *bind.FilterOpts, feeType []uint8) (*ISuperGovernorFeeProposedIterator, error) {

	var feeTypeRule []interface{}
	for _, feeTypeItem := range feeType {
		feeTypeRule = append(feeTypeRule, feeTypeItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "FeeProposed", feeTypeRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorFeeProposedIterator{contract: _ISuperGovernor.contract, event: "FeeProposed", logs: logs, sub: sub}, nil
}

// WatchFeeProposed is a free log subscription operation binding the contract event 0x79548367f12987b3f5043ed1f421f89ebc84ab67cdaa9ee1e4d2a9e76b58ba0b.
//
// Solidity: event FeeProposed(uint8 indexed feeType, uint256 value, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchFeeProposed(opts *bind.WatchOpts, sink chan<- *ISuperGovernorFeeProposed, feeType []uint8) (event.Subscription, error) {

	var feeTypeRule []interface{}
	for _, feeTypeItem := range feeType {
		feeTypeRule = append(feeTypeRule, feeTypeItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "FeeProposed", feeTypeRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorFeeProposed)
				if err := _ISuperGovernor.contract.UnpackLog(event, "FeeProposed", log); err != nil {
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
// Solidity: event FeeProposed(uint8 indexed feeType, uint256 value, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseFeeProposed(log types.Log) (*ISuperGovernorFeeProposed, error) {
	event := new(ISuperGovernorFeeProposed)
	if err := _ISuperGovernor.contract.UnpackLog(event, "FeeProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorFeeUpdatedIterator is returned from FilterFeeUpdated and is used to iterate over the raw logs and unpacked data for FeeUpdated events raised by the ISuperGovernor contract.
type ISuperGovernorFeeUpdatedIterator struct {
	Event *ISuperGovernorFeeUpdated // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorFeeUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorFeeUpdated)
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
		it.Event = new(ISuperGovernorFeeUpdated)
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
func (it *ISuperGovernorFeeUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorFeeUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorFeeUpdated represents a FeeUpdated event raised by the ISuperGovernor contract.
type ISuperGovernorFeeUpdated struct {
	FeeType uint8
	Value   *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterFeeUpdated is a free log retrieval operation binding the contract event 0x53b82d85cd75c3f353186408e2e619ae5f01c371100dc061ee0423d12acb7508.
//
// Solidity: event FeeUpdated(uint8 indexed feeType, uint256 value)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterFeeUpdated(opts *bind.FilterOpts, feeType []uint8) (*ISuperGovernorFeeUpdatedIterator, error) {

	var feeTypeRule []interface{}
	for _, feeTypeItem := range feeType {
		feeTypeRule = append(feeTypeRule, feeTypeItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "FeeUpdated", feeTypeRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorFeeUpdatedIterator{contract: _ISuperGovernor.contract, event: "FeeUpdated", logs: logs, sub: sub}, nil
}

// WatchFeeUpdated is a free log subscription operation binding the contract event 0x53b82d85cd75c3f353186408e2e619ae5f01c371100dc061ee0423d12acb7508.
//
// Solidity: event FeeUpdated(uint8 indexed feeType, uint256 value)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchFeeUpdated(opts *bind.WatchOpts, sink chan<- *ISuperGovernorFeeUpdated, feeType []uint8) (event.Subscription, error) {

	var feeTypeRule []interface{}
	for _, feeTypeItem := range feeType {
		feeTypeRule = append(feeTypeRule, feeTypeItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "FeeUpdated", feeTypeRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorFeeUpdated)
				if err := _ISuperGovernor.contract.UnpackLog(event, "FeeUpdated", log); err != nil {
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
// Solidity: event FeeUpdated(uint8 indexed feeType, uint256 value)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseFeeUpdated(log types.Log) (*ISuperGovernorFeeUpdated, error) {
	event := new(ISuperGovernorFeeUpdated)
	if err := _ISuperGovernor.contract.UnpackLog(event, "FeeUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorGasInfoSetIterator is returned from FilterGasInfoSet and is used to iterate over the raw logs and unpacked data for GasInfoSet events raised by the ISuperGovernor contract.
type ISuperGovernorGasInfoSetIterator struct {
	Event *ISuperGovernorGasInfoSet // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorGasInfoSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorGasInfoSet)
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
		it.Event = new(ISuperGovernorGasInfoSet)
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
func (it *ISuperGovernorGasInfoSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorGasInfoSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorGasInfoSet represents a GasInfoSet event raised by the ISuperGovernor contract.
type ISuperGovernorGasInfoSet struct {
	Oracle                   common.Address
	GasIncreasePerEntryBatch *big.Int
	Raw                      types.Log // Blockchain specific contextual infos
}

// FilterGasInfoSet is a free log retrieval operation binding the contract event 0x5a6a2723fb87c76bcd4e5e9194dbdb6286f8cfbaec12fb975707b9d805d3baf5.
//
// Solidity: event GasInfoSet(address indexed oracle, uint256 gasIncreasePerEntryBatch)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterGasInfoSet(opts *bind.FilterOpts, oracle []common.Address) (*ISuperGovernorGasInfoSetIterator, error) {

	var oracleRule []interface{}
	for _, oracleItem := range oracle {
		oracleRule = append(oracleRule, oracleItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "GasInfoSet", oracleRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorGasInfoSetIterator{contract: _ISuperGovernor.contract, event: "GasInfoSet", logs: logs, sub: sub}, nil
}

// WatchGasInfoSet is a free log subscription operation binding the contract event 0x5a6a2723fb87c76bcd4e5e9194dbdb6286f8cfbaec12fb975707b9d805d3baf5.
//
// Solidity: event GasInfoSet(address indexed oracle, uint256 gasIncreasePerEntryBatch)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchGasInfoSet(opts *bind.WatchOpts, sink chan<- *ISuperGovernorGasInfoSet, oracle []common.Address) (event.Subscription, error) {

	var oracleRule []interface{}
	for _, oracleItem := range oracle {
		oracleRule = append(oracleRule, oracleItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "GasInfoSet", oracleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorGasInfoSet)
				if err := _ISuperGovernor.contract.UnpackLog(event, "GasInfoSet", log); err != nil {
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

// ParseGasInfoSet is a log parse operation binding the contract event 0x5a6a2723fb87c76bcd4e5e9194dbdb6286f8cfbaec12fb975707b9d805d3baf5.
//
// Solidity: event GasInfoSet(address indexed oracle, uint256 gasIncreasePerEntryBatch)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseGasInfoSet(log types.Log) (*ISuperGovernorGasInfoSet, error) {
	event := new(ISuperGovernorGasInfoSet)
	if err := _ISuperGovernor.contract.UnpackLog(event, "GasInfoSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorHookApprovedIterator is returned from FilterHookApproved and is used to iterate over the raw logs and unpacked data for HookApproved events raised by the ISuperGovernor contract.
type ISuperGovernorHookApprovedIterator struct {
	Event *ISuperGovernorHookApproved // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorHookApprovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorHookApproved)
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
		it.Event = new(ISuperGovernorHookApproved)
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
func (it *ISuperGovernorHookApprovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorHookApprovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorHookApproved represents a HookApproved event raised by the ISuperGovernor contract.
type ISuperGovernorHookApproved struct {
	Hook common.Address
	Raw  types.Log // Blockchain specific contextual infos
}

// FilterHookApproved is a free log retrieval operation binding the contract event 0x6b2d5736790b4cdb325004b8784c7b94dc55a32af9d82d1f6ceb5bd8c7c8573e.
//
// Solidity: event HookApproved(address indexed hook)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterHookApproved(opts *bind.FilterOpts, hook []common.Address) (*ISuperGovernorHookApprovedIterator, error) {

	var hookRule []interface{}
	for _, hookItem := range hook {
		hookRule = append(hookRule, hookItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "HookApproved", hookRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorHookApprovedIterator{contract: _ISuperGovernor.contract, event: "HookApproved", logs: logs, sub: sub}, nil
}

// WatchHookApproved is a free log subscription operation binding the contract event 0x6b2d5736790b4cdb325004b8784c7b94dc55a32af9d82d1f6ceb5bd8c7c8573e.
//
// Solidity: event HookApproved(address indexed hook)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchHookApproved(opts *bind.WatchOpts, sink chan<- *ISuperGovernorHookApproved, hook []common.Address) (event.Subscription, error) {

	var hookRule []interface{}
	for _, hookItem := range hook {
		hookRule = append(hookRule, hookItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "HookApproved", hookRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorHookApproved)
				if err := _ISuperGovernor.contract.UnpackLog(event, "HookApproved", log); err != nil {
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
// Solidity: event HookApproved(address indexed hook)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseHookApproved(log types.Log) (*ISuperGovernorHookApproved, error) {
	event := new(ISuperGovernorHookApproved)
	if err := _ISuperGovernor.contract.UnpackLog(event, "HookApproved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorHookRemovedIterator is returned from FilterHookRemoved and is used to iterate over the raw logs and unpacked data for HookRemoved events raised by the ISuperGovernor contract.
type ISuperGovernorHookRemovedIterator struct {
	Event *ISuperGovernorHookRemoved // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorHookRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorHookRemoved)
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
		it.Event = new(ISuperGovernorHookRemoved)
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
func (it *ISuperGovernorHookRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorHookRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorHookRemoved represents a HookRemoved event raised by the ISuperGovernor contract.
type ISuperGovernorHookRemoved struct {
	Hook common.Address
	Raw  types.Log // Blockchain specific contextual infos
}

// FilterHookRemoved is a free log retrieval operation binding the contract event 0x47d0871e905ac6550f54ba266e0d90d2dc8ed67a957c064ca3438eddf4e3fd89.
//
// Solidity: event HookRemoved(address indexed hook)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterHookRemoved(opts *bind.FilterOpts, hook []common.Address) (*ISuperGovernorHookRemovedIterator, error) {

	var hookRule []interface{}
	for _, hookItem := range hook {
		hookRule = append(hookRule, hookItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "HookRemoved", hookRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorHookRemovedIterator{contract: _ISuperGovernor.contract, event: "HookRemoved", logs: logs, sub: sub}, nil
}

// WatchHookRemoved is a free log subscription operation binding the contract event 0x47d0871e905ac6550f54ba266e0d90d2dc8ed67a957c064ca3438eddf4e3fd89.
//
// Solidity: event HookRemoved(address indexed hook)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchHookRemoved(opts *bind.WatchOpts, sink chan<- *ISuperGovernorHookRemoved, hook []common.Address) (event.Subscription, error) {

	var hookRule []interface{}
	for _, hookItem := range hook {
		hookRule = append(hookRule, hookItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "HookRemoved", hookRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorHookRemoved)
				if err := _ISuperGovernor.contract.UnpackLog(event, "HookRemoved", log); err != nil {
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
// Solidity: event HookRemoved(address indexed hook)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseHookRemoved(log types.Log) (*ISuperGovernorHookRemoved, error) {
	event := new(ISuperGovernorHookRemoved)
	if err := _ISuperGovernor.contract.UnpackLog(event, "HookRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorManagerTakeoversFrozenIterator is returned from FilterManagerTakeoversFrozen and is used to iterate over the raw logs and unpacked data for ManagerTakeoversFrozen events raised by the ISuperGovernor contract.
type ISuperGovernorManagerTakeoversFrozenIterator struct {
	Event *ISuperGovernorManagerTakeoversFrozen // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorManagerTakeoversFrozenIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorManagerTakeoversFrozen)
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
		it.Event = new(ISuperGovernorManagerTakeoversFrozen)
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
func (it *ISuperGovernorManagerTakeoversFrozenIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorManagerTakeoversFrozenIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorManagerTakeoversFrozen represents a ManagerTakeoversFrozen event raised by the ISuperGovernor contract.
type ISuperGovernorManagerTakeoversFrozen struct {
	Raw types.Log // Blockchain specific contextual infos
}

// FilterManagerTakeoversFrozen is a free log retrieval operation binding the contract event 0x0cfbf370e135d688f4de1107bfa980d42fe9e0884277d500e4a5262e207df76d.
//
// Solidity: event ManagerTakeoversFrozen()
func (_ISuperGovernor *ISuperGovernorFilterer) FilterManagerTakeoversFrozen(opts *bind.FilterOpts) (*ISuperGovernorManagerTakeoversFrozenIterator, error) {

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "ManagerTakeoversFrozen")
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorManagerTakeoversFrozenIterator{contract: _ISuperGovernor.contract, event: "ManagerTakeoversFrozen", logs: logs, sub: sub}, nil
}

// WatchManagerTakeoversFrozen is a free log subscription operation binding the contract event 0x0cfbf370e135d688f4de1107bfa980d42fe9e0884277d500e4a5262e207df76d.
//
// Solidity: event ManagerTakeoversFrozen()
func (_ISuperGovernor *ISuperGovernorFilterer) WatchManagerTakeoversFrozen(opts *bind.WatchOpts, sink chan<- *ISuperGovernorManagerTakeoversFrozen) (event.Subscription, error) {

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "ManagerTakeoversFrozen")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorManagerTakeoversFrozen)
				if err := _ISuperGovernor.contract.UnpackLog(event, "ManagerTakeoversFrozen", log); err != nil {
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
func (_ISuperGovernor *ISuperGovernorFilterer) ParseManagerTakeoversFrozen(log types.Log) (*ISuperGovernorManagerTakeoversFrozen, error) {
	event := new(ISuperGovernorManagerTakeoversFrozen)
	if err := _ISuperGovernor.contract.UnpackLog(event, "ManagerTakeoversFrozen", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorMinStalenesChangedIterator is returned from FilterMinStalenesChanged and is used to iterate over the raw logs and unpacked data for MinStalenesChanged events raised by the ISuperGovernor contract.
type ISuperGovernorMinStalenesChangedIterator struct {
	Event *ISuperGovernorMinStalenesChanged // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorMinStalenesChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorMinStalenesChanged)
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
		it.Event = new(ISuperGovernorMinStalenesChanged)
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
func (it *ISuperGovernorMinStalenesChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorMinStalenesChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorMinStalenesChanged represents a MinStalenesChanged event raised by the ISuperGovernor contract.
type ISuperGovernorMinStalenesChanged struct {
	NewMinStaleness *big.Int
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterMinStalenesChanged is a free log retrieval operation binding the contract event 0x5ef721aefae68d3af172090ad589f1eb72736af265747458daf734c5c60d7daa.
//
// Solidity: event MinStalenesChanged(uint256 newMinStaleness)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterMinStalenesChanged(opts *bind.FilterOpts) (*ISuperGovernorMinStalenesChangedIterator, error) {

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "MinStalenesChanged")
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorMinStalenesChangedIterator{contract: _ISuperGovernor.contract, event: "MinStalenesChanged", logs: logs, sub: sub}, nil
}

// WatchMinStalenesChanged is a free log subscription operation binding the contract event 0x5ef721aefae68d3af172090ad589f1eb72736af265747458daf734c5c60d7daa.
//
// Solidity: event MinStalenesChanged(uint256 newMinStaleness)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchMinStalenesChanged(opts *bind.WatchOpts, sink chan<- *ISuperGovernorMinStalenesChanged) (event.Subscription, error) {

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "MinStalenesChanged")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorMinStalenesChanged)
				if err := _ISuperGovernor.contract.UnpackLog(event, "MinStalenesChanged", log); err != nil {
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
func (_ISuperGovernor *ISuperGovernorFilterer) ParseMinStalenesChanged(log types.Log) (*ISuperGovernorMinStalenesChanged, error) {
	event := new(ISuperGovernorMinStalenesChanged)
	if err := _ISuperGovernor.contract.UnpackLog(event, "MinStalenesChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorMinStalenesProposedIterator is returned from FilterMinStalenesProposed and is used to iterate over the raw logs and unpacked data for MinStalenesProposed events raised by the ISuperGovernor contract.
type ISuperGovernorMinStalenesProposedIterator struct {
	Event *ISuperGovernorMinStalenesProposed // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorMinStalenesProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorMinStalenesProposed)
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
		it.Event = new(ISuperGovernorMinStalenesProposed)
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
func (it *ISuperGovernorMinStalenesProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorMinStalenesProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorMinStalenesProposed represents a MinStalenesProposed event raised by the ISuperGovernor contract.
type ISuperGovernorMinStalenesProposed struct {
	NewMinStaleness *big.Int
	EffectiveTime   *big.Int
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterMinStalenesProposed is a free log retrieval operation binding the contract event 0xae30e7c9277d9f36ab2ab07d353aa93dcc567106b5d571ebead929f12ebcd7ad.
//
// Solidity: event MinStalenesProposed(uint256 newMinStaleness, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterMinStalenesProposed(opts *bind.FilterOpts) (*ISuperGovernorMinStalenesProposedIterator, error) {

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "MinStalenesProposed")
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorMinStalenesProposedIterator{contract: _ISuperGovernor.contract, event: "MinStalenesProposed", logs: logs, sub: sub}, nil
}

// WatchMinStalenesProposed is a free log subscription operation binding the contract event 0xae30e7c9277d9f36ab2ab07d353aa93dcc567106b5d571ebead929f12ebcd7ad.
//
// Solidity: event MinStalenesProposed(uint256 newMinStaleness, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchMinStalenesProposed(opts *bind.WatchOpts, sink chan<- *ISuperGovernorMinStalenesProposed) (event.Subscription, error) {

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "MinStalenesProposed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorMinStalenesProposed)
				if err := _ISuperGovernor.contract.UnpackLog(event, "MinStalenesProposed", log); err != nil {
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
func (_ISuperGovernor *ISuperGovernorFilterer) ParseMinStalenesProposed(log types.Log) (*ISuperGovernorMinStalenesProposed, error) {
	event := new(ISuperGovernorMinStalenesProposed)
	if err := _ISuperGovernor.contract.UnpackLog(event, "MinStalenesProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorPPSOracleQuorumUpdatedIterator is returned from FilterPPSOracleQuorumUpdated and is used to iterate over the raw logs and unpacked data for PPSOracleQuorumUpdated events raised by the ISuperGovernor contract.
type ISuperGovernorPPSOracleQuorumUpdatedIterator struct {
	Event *ISuperGovernorPPSOracleQuorumUpdated // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorPPSOracleQuorumUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorPPSOracleQuorumUpdated)
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
		it.Event = new(ISuperGovernorPPSOracleQuorumUpdated)
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
func (it *ISuperGovernorPPSOracleQuorumUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorPPSOracleQuorumUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorPPSOracleQuorumUpdated represents a PPSOracleQuorumUpdated event raised by the ISuperGovernor contract.
type ISuperGovernorPPSOracleQuorumUpdated struct {
	Quorum *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterPPSOracleQuorumUpdated is a free log retrieval operation binding the contract event 0xf957b69cfa930a437fa0211ed212fe9b40bfbf99f4e5734d9d6068834d33a928.
//
// Solidity: event PPSOracleQuorumUpdated(uint256 quorum)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterPPSOracleQuorumUpdated(opts *bind.FilterOpts) (*ISuperGovernorPPSOracleQuorumUpdatedIterator, error) {

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "PPSOracleQuorumUpdated")
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorPPSOracleQuorumUpdatedIterator{contract: _ISuperGovernor.contract, event: "PPSOracleQuorumUpdated", logs: logs, sub: sub}, nil
}

// WatchPPSOracleQuorumUpdated is a free log subscription operation binding the contract event 0xf957b69cfa930a437fa0211ed212fe9b40bfbf99f4e5734d9d6068834d33a928.
//
// Solidity: event PPSOracleQuorumUpdated(uint256 quorum)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchPPSOracleQuorumUpdated(opts *bind.WatchOpts, sink chan<- *ISuperGovernorPPSOracleQuorumUpdated) (event.Subscription, error) {

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "PPSOracleQuorumUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorPPSOracleQuorumUpdated)
				if err := _ISuperGovernor.contract.UnpackLog(event, "PPSOracleQuorumUpdated", log); err != nil {
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
func (_ISuperGovernor *ISuperGovernorFilterer) ParsePPSOracleQuorumUpdated(log types.Log) (*ISuperGovernorPPSOracleQuorumUpdated, error) {
	event := new(ISuperGovernorPPSOracleQuorumUpdated)
	if err := _ISuperGovernor.contract.UnpackLog(event, "PPSOracleQuorumUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorProtectedKeeperRegisteredIterator is returned from FilterProtectedKeeperRegistered and is used to iterate over the raw logs and unpacked data for ProtectedKeeperRegistered events raised by the ISuperGovernor contract.
type ISuperGovernorProtectedKeeperRegisteredIterator struct {
	Event *ISuperGovernorProtectedKeeperRegistered // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorProtectedKeeperRegisteredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorProtectedKeeperRegistered)
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
		it.Event = new(ISuperGovernorProtectedKeeperRegistered)
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
func (it *ISuperGovernorProtectedKeeperRegisteredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorProtectedKeeperRegisteredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorProtectedKeeperRegistered represents a ProtectedKeeperRegistered event raised by the ISuperGovernor contract.
type ISuperGovernorProtectedKeeperRegistered struct {
	Keeper common.Address
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterProtectedKeeperRegistered is a free log retrieval operation binding the contract event 0x5a17551f8f59aacc175aed9daecc2461b2161d1ca643c75612710502de9d57b1.
//
// Solidity: event ProtectedKeeperRegistered(address indexed keeper)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterProtectedKeeperRegistered(opts *bind.FilterOpts, keeper []common.Address) (*ISuperGovernorProtectedKeeperRegisteredIterator, error) {

	var keeperRule []interface{}
	for _, keeperItem := range keeper {
		keeperRule = append(keeperRule, keeperItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "ProtectedKeeperRegistered", keeperRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorProtectedKeeperRegisteredIterator{contract: _ISuperGovernor.contract, event: "ProtectedKeeperRegistered", logs: logs, sub: sub}, nil
}

// WatchProtectedKeeperRegistered is a free log subscription operation binding the contract event 0x5a17551f8f59aacc175aed9daecc2461b2161d1ca643c75612710502de9d57b1.
//
// Solidity: event ProtectedKeeperRegistered(address indexed keeper)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchProtectedKeeperRegistered(opts *bind.WatchOpts, sink chan<- *ISuperGovernorProtectedKeeperRegistered, keeper []common.Address) (event.Subscription, error) {

	var keeperRule []interface{}
	for _, keeperItem := range keeper {
		keeperRule = append(keeperRule, keeperItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "ProtectedKeeperRegistered", keeperRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorProtectedKeeperRegistered)
				if err := _ISuperGovernor.contract.UnpackLog(event, "ProtectedKeeperRegistered", log); err != nil {
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
// Solidity: event ProtectedKeeperRegistered(address indexed keeper)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseProtectedKeeperRegistered(log types.Log) (*ISuperGovernorProtectedKeeperRegistered, error) {
	event := new(ISuperGovernorProtectedKeeperRegistered)
	if err := _ISuperGovernor.contract.UnpackLog(event, "ProtectedKeeperRegistered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorProtectedKeeperUnregisteredIterator is returned from FilterProtectedKeeperUnregistered and is used to iterate over the raw logs and unpacked data for ProtectedKeeperUnregistered events raised by the ISuperGovernor contract.
type ISuperGovernorProtectedKeeperUnregisteredIterator struct {
	Event *ISuperGovernorProtectedKeeperUnregistered // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorProtectedKeeperUnregisteredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorProtectedKeeperUnregistered)
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
		it.Event = new(ISuperGovernorProtectedKeeperUnregistered)
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
func (it *ISuperGovernorProtectedKeeperUnregisteredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorProtectedKeeperUnregisteredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorProtectedKeeperUnregistered represents a ProtectedKeeperUnregistered event raised by the ISuperGovernor contract.
type ISuperGovernorProtectedKeeperUnregistered struct {
	Keeper common.Address
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterProtectedKeeperUnregistered is a free log retrieval operation binding the contract event 0xd5f663a5782ccd5e7465e8419aa75f38fdc175262978753ee490757f48d7318b.
//
// Solidity: event ProtectedKeeperUnregistered(address indexed keeper)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterProtectedKeeperUnregistered(opts *bind.FilterOpts, keeper []common.Address) (*ISuperGovernorProtectedKeeperUnregisteredIterator, error) {

	var keeperRule []interface{}
	for _, keeperItem := range keeper {
		keeperRule = append(keeperRule, keeperItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "ProtectedKeeperUnregistered", keeperRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorProtectedKeeperUnregisteredIterator{contract: _ISuperGovernor.contract, event: "ProtectedKeeperUnregistered", logs: logs, sub: sub}, nil
}

// WatchProtectedKeeperUnregistered is a free log subscription operation binding the contract event 0xd5f663a5782ccd5e7465e8419aa75f38fdc175262978753ee490757f48d7318b.
//
// Solidity: event ProtectedKeeperUnregistered(address indexed keeper)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchProtectedKeeperUnregistered(opts *bind.WatchOpts, sink chan<- *ISuperGovernorProtectedKeeperUnregistered, keeper []common.Address) (event.Subscription, error) {

	var keeperRule []interface{}
	for _, keeperItem := range keeper {
		keeperRule = append(keeperRule, keeperItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "ProtectedKeeperUnregistered", keeperRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorProtectedKeeperUnregistered)
				if err := _ISuperGovernor.contract.UnpackLog(event, "ProtectedKeeperUnregistered", log); err != nil {
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
// Solidity: event ProtectedKeeperUnregistered(address indexed keeper)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseProtectedKeeperUnregistered(log types.Log) (*ISuperGovernorProtectedKeeperUnregistered, error) {
	event := new(ISuperGovernorProtectedKeeperUnregistered)
	if err := _ISuperGovernor.contract.UnpackLog(event, "ProtectedKeeperUnregistered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorRevenueShareUpdatedIterator is returned from FilterRevenueShareUpdated and is used to iterate over the raw logs and unpacked data for RevenueShareUpdated events raised by the ISuperGovernor contract.
type ISuperGovernorRevenueShareUpdatedIterator struct {
	Event *ISuperGovernorRevenueShareUpdated // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorRevenueShareUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorRevenueShareUpdated)
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
		it.Event = new(ISuperGovernorRevenueShareUpdated)
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
func (it *ISuperGovernorRevenueShareUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorRevenueShareUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorRevenueShareUpdated represents a RevenueShareUpdated event raised by the ISuperGovernor contract.
type ISuperGovernorRevenueShareUpdated struct {
	Share *big.Int
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterRevenueShareUpdated is a free log retrieval operation binding the contract event 0x343a3cad72a9e3a0fe71e8417402226b647587dfd1713f79f85413ed27df7f7b.
//
// Solidity: event RevenueShareUpdated(uint256 share)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterRevenueShareUpdated(opts *bind.FilterOpts) (*ISuperGovernorRevenueShareUpdatedIterator, error) {

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "RevenueShareUpdated")
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorRevenueShareUpdatedIterator{contract: _ISuperGovernor.contract, event: "RevenueShareUpdated", logs: logs, sub: sub}, nil
}

// WatchRevenueShareUpdated is a free log subscription operation binding the contract event 0x343a3cad72a9e3a0fe71e8417402226b647587dfd1713f79f85413ed27df7f7b.
//
// Solidity: event RevenueShareUpdated(uint256 share)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchRevenueShareUpdated(opts *bind.WatchOpts, sink chan<- *ISuperGovernorRevenueShareUpdated) (event.Subscription, error) {

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "RevenueShareUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorRevenueShareUpdated)
				if err := _ISuperGovernor.contract.UnpackLog(event, "RevenueShareUpdated", log); err != nil {
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
func (_ISuperGovernor *ISuperGovernorFilterer) ParseRevenueShareUpdated(log types.Log) (*ISuperGovernorRevenueShareUpdated, error) {
	event := new(ISuperGovernorRevenueShareUpdated)
	if err := _ISuperGovernor.contract.UnpackLog(event, "RevenueShareUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorRoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the ISuperGovernor contract.
type ISuperGovernorRoleAdminChangedIterator struct {
	Event *ISuperGovernorRoleAdminChanged // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorRoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorRoleAdminChanged)
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
		it.Event = new(ISuperGovernorRoleAdminChanged)
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
func (it *ISuperGovernorRoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorRoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorRoleAdminChanged represents a RoleAdminChanged event raised by the ISuperGovernor contract.
type ISuperGovernorRoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterRoleAdminChanged(opts *bind.FilterOpts, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (*ISuperGovernorRoleAdminChangedIterator, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var previousAdminRoleRule []interface{}
	for _, previousAdminRoleItem := range previousAdminRole {
		previousAdminRoleRule = append(previousAdminRoleRule, previousAdminRoleItem)
	}
	var newAdminRoleRule []interface{}
	for _, newAdminRoleItem := range newAdminRole {
		newAdminRoleRule = append(newAdminRoleRule, newAdminRoleItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorRoleAdminChangedIterator{contract: _ISuperGovernor.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *ISuperGovernorRoleAdminChanged, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (event.Subscription, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var previousAdminRoleRule []interface{}
	for _, previousAdminRoleItem := range previousAdminRole {
		previousAdminRoleRule = append(previousAdminRoleRule, previousAdminRoleItem)
	}
	var newAdminRoleRule []interface{}
	for _, newAdminRoleItem := range newAdminRole {
		newAdminRoleRule = append(newAdminRoleRule, newAdminRoleItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorRoleAdminChanged)
				if err := _ISuperGovernor.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
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
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseRoleAdminChanged(log types.Log) (*ISuperGovernorRoleAdminChanged, error) {
	event := new(ISuperGovernorRoleAdminChanged)
	if err := _ISuperGovernor.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorRoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the ISuperGovernor contract.
type ISuperGovernorRoleGrantedIterator struct {
	Event *ISuperGovernorRoleGranted // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorRoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorRoleGranted)
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
		it.Event = new(ISuperGovernorRoleGranted)
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
func (it *ISuperGovernorRoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorRoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorRoleGranted represents a RoleGranted event raised by the ISuperGovernor contract.
type ISuperGovernorRoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterRoleGranted(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*ISuperGovernorRoleGrantedIterator, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorRoleGrantedIterator{contract: _ISuperGovernor.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *ISuperGovernorRoleGranted, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorRoleGranted)
				if err := _ISuperGovernor.contract.UnpackLog(event, "RoleGranted", log); err != nil {
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
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseRoleGranted(log types.Log) (*ISuperGovernorRoleGranted, error) {
	event := new(ISuperGovernorRoleGranted)
	if err := _ISuperGovernor.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorRoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the ISuperGovernor contract.
type ISuperGovernorRoleRevokedIterator struct {
	Event *ISuperGovernorRoleRevoked // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorRoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorRoleRevoked)
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
		it.Event = new(ISuperGovernorRoleRevoked)
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
func (it *ISuperGovernorRoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorRoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorRoleRevoked represents a RoleRevoked event raised by the ISuperGovernor contract.
type ISuperGovernorRoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterRoleRevoked(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*ISuperGovernorRoleRevokedIterator, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorRoleRevokedIterator{contract: _ISuperGovernor.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *ISuperGovernorRoleRevoked, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorRoleRevoked)
				if err := _ISuperGovernor.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
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
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseRoleRevoked(log types.Log) (*ISuperGovernorRoleRevoked, error) {
	event := new(ISuperGovernorRoleRevoked)
	if err := _ISuperGovernor.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorSuperBankHookMerkleRootProposedIterator is returned from FilterSuperBankHookMerkleRootProposed and is used to iterate over the raw logs and unpacked data for SuperBankHookMerkleRootProposed events raised by the ISuperGovernor contract.
type ISuperGovernorSuperBankHookMerkleRootProposedIterator struct {
	Event *ISuperGovernorSuperBankHookMerkleRootProposed // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorSuperBankHookMerkleRootProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorSuperBankHookMerkleRootProposed)
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
		it.Event = new(ISuperGovernorSuperBankHookMerkleRootProposed)
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
func (it *ISuperGovernorSuperBankHookMerkleRootProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorSuperBankHookMerkleRootProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorSuperBankHookMerkleRootProposed represents a SuperBankHookMerkleRootProposed event raised by the ISuperGovernor contract.
type ISuperGovernorSuperBankHookMerkleRootProposed struct {
	Hook          common.Address
	NewRoot       [32]byte
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterSuperBankHookMerkleRootProposed is a free log retrieval operation binding the contract event 0x2f45381bbf8fc39bccf5516ecef3bec5e43aed86711ddaa35c12ab2d6073fd36.
//
// Solidity: event SuperBankHookMerkleRootProposed(address indexed hook, bytes32 newRoot, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterSuperBankHookMerkleRootProposed(opts *bind.FilterOpts, hook []common.Address) (*ISuperGovernorSuperBankHookMerkleRootProposedIterator, error) {

	var hookRule []interface{}
	for _, hookItem := range hook {
		hookRule = append(hookRule, hookItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "SuperBankHookMerkleRootProposed", hookRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorSuperBankHookMerkleRootProposedIterator{contract: _ISuperGovernor.contract, event: "SuperBankHookMerkleRootProposed", logs: logs, sub: sub}, nil
}

// WatchSuperBankHookMerkleRootProposed is a free log subscription operation binding the contract event 0x2f45381bbf8fc39bccf5516ecef3bec5e43aed86711ddaa35c12ab2d6073fd36.
//
// Solidity: event SuperBankHookMerkleRootProposed(address indexed hook, bytes32 newRoot, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchSuperBankHookMerkleRootProposed(opts *bind.WatchOpts, sink chan<- *ISuperGovernorSuperBankHookMerkleRootProposed, hook []common.Address) (event.Subscription, error) {

	var hookRule []interface{}
	for _, hookItem := range hook {
		hookRule = append(hookRule, hookItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "SuperBankHookMerkleRootProposed", hookRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorSuperBankHookMerkleRootProposed)
				if err := _ISuperGovernor.contract.UnpackLog(event, "SuperBankHookMerkleRootProposed", log); err != nil {
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
// Solidity: event SuperBankHookMerkleRootProposed(address indexed hook, bytes32 newRoot, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseSuperBankHookMerkleRootProposed(log types.Log) (*ISuperGovernorSuperBankHookMerkleRootProposed, error) {
	event := new(ISuperGovernorSuperBankHookMerkleRootProposed)
	if err := _ISuperGovernor.contract.UnpackLog(event, "SuperBankHookMerkleRootProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorSuperBankHookMerkleRootUpdatedIterator is returned from FilterSuperBankHookMerkleRootUpdated and is used to iterate over the raw logs and unpacked data for SuperBankHookMerkleRootUpdated events raised by the ISuperGovernor contract.
type ISuperGovernorSuperBankHookMerkleRootUpdatedIterator struct {
	Event *ISuperGovernorSuperBankHookMerkleRootUpdated // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorSuperBankHookMerkleRootUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorSuperBankHookMerkleRootUpdated)
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
		it.Event = new(ISuperGovernorSuperBankHookMerkleRootUpdated)
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
func (it *ISuperGovernorSuperBankHookMerkleRootUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorSuperBankHookMerkleRootUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorSuperBankHookMerkleRootUpdated represents a SuperBankHookMerkleRootUpdated event raised by the ISuperGovernor contract.
type ISuperGovernorSuperBankHookMerkleRootUpdated struct {
	Hook    common.Address
	NewRoot [32]byte
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterSuperBankHookMerkleRootUpdated is a free log retrieval operation binding the contract event 0xac299fc62dbe9994754db34d3374ec4eb38e185895e08b5bbffa75e98bf2a53f.
//
// Solidity: event SuperBankHookMerkleRootUpdated(address indexed hook, bytes32 newRoot)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterSuperBankHookMerkleRootUpdated(opts *bind.FilterOpts, hook []common.Address) (*ISuperGovernorSuperBankHookMerkleRootUpdatedIterator, error) {

	var hookRule []interface{}
	for _, hookItem := range hook {
		hookRule = append(hookRule, hookItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "SuperBankHookMerkleRootUpdated", hookRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorSuperBankHookMerkleRootUpdatedIterator{contract: _ISuperGovernor.contract, event: "SuperBankHookMerkleRootUpdated", logs: logs, sub: sub}, nil
}

// WatchSuperBankHookMerkleRootUpdated is a free log subscription operation binding the contract event 0xac299fc62dbe9994754db34d3374ec4eb38e185895e08b5bbffa75e98bf2a53f.
//
// Solidity: event SuperBankHookMerkleRootUpdated(address indexed hook, bytes32 newRoot)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchSuperBankHookMerkleRootUpdated(opts *bind.WatchOpts, sink chan<- *ISuperGovernorSuperBankHookMerkleRootUpdated, hook []common.Address) (event.Subscription, error) {

	var hookRule []interface{}
	for _, hookItem := range hook {
		hookRule = append(hookRule, hookItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "SuperBankHookMerkleRootUpdated", hookRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorSuperBankHookMerkleRootUpdated)
				if err := _ISuperGovernor.contract.UnpackLog(event, "SuperBankHookMerkleRootUpdated", log); err != nil {
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
// Solidity: event SuperBankHookMerkleRootUpdated(address indexed hook, bytes32 newRoot)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseSuperBankHookMerkleRootUpdated(log types.Log) (*ISuperGovernorSuperBankHookMerkleRootUpdated, error) {
	event := new(ISuperGovernorSuperBankHookMerkleRootUpdated)
	if err := _ISuperGovernor.contract.UnpackLog(event, "SuperBankHookMerkleRootUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorSuperformManagerAddedIterator is returned from FilterSuperformManagerAdded and is used to iterate over the raw logs and unpacked data for SuperformManagerAdded events raised by the ISuperGovernor contract.
type ISuperGovernorSuperformManagerAddedIterator struct {
	Event *ISuperGovernorSuperformManagerAdded // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorSuperformManagerAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorSuperformManagerAdded)
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
		it.Event = new(ISuperGovernorSuperformManagerAdded)
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
func (it *ISuperGovernorSuperformManagerAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorSuperformManagerAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorSuperformManagerAdded represents a SuperformManagerAdded event raised by the ISuperGovernor contract.
type ISuperGovernorSuperformManagerAdded struct {
	Manager common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterSuperformManagerAdded is a free log retrieval operation binding the contract event 0x12c16151d1e0db8865cc79e38b297dcc5b372789b7efc7cc4460df4e3a4afbd6.
//
// Solidity: event SuperformManagerAdded(address indexed manager)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterSuperformManagerAdded(opts *bind.FilterOpts, manager []common.Address) (*ISuperGovernorSuperformManagerAddedIterator, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "SuperformManagerAdded", managerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorSuperformManagerAddedIterator{contract: _ISuperGovernor.contract, event: "SuperformManagerAdded", logs: logs, sub: sub}, nil
}

// WatchSuperformManagerAdded is a free log subscription operation binding the contract event 0x12c16151d1e0db8865cc79e38b297dcc5b372789b7efc7cc4460df4e3a4afbd6.
//
// Solidity: event SuperformManagerAdded(address indexed manager)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchSuperformManagerAdded(opts *bind.WatchOpts, sink chan<- *ISuperGovernorSuperformManagerAdded, manager []common.Address) (event.Subscription, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "SuperformManagerAdded", managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorSuperformManagerAdded)
				if err := _ISuperGovernor.contract.UnpackLog(event, "SuperformManagerAdded", log); err != nil {
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
// Solidity: event SuperformManagerAdded(address indexed manager)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseSuperformManagerAdded(log types.Log) (*ISuperGovernorSuperformManagerAdded, error) {
	event := new(ISuperGovernorSuperformManagerAdded)
	if err := _ISuperGovernor.contract.UnpackLog(event, "SuperformManagerAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorSuperformManagerRemovedIterator is returned from FilterSuperformManagerRemoved and is used to iterate over the raw logs and unpacked data for SuperformManagerRemoved events raised by the ISuperGovernor contract.
type ISuperGovernorSuperformManagerRemovedIterator struct {
	Event *ISuperGovernorSuperformManagerRemoved // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorSuperformManagerRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorSuperformManagerRemoved)
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
		it.Event = new(ISuperGovernorSuperformManagerRemoved)
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
func (it *ISuperGovernorSuperformManagerRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorSuperformManagerRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorSuperformManagerRemoved represents a SuperformManagerRemoved event raised by the ISuperGovernor contract.
type ISuperGovernorSuperformManagerRemoved struct {
	Manager common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterSuperformManagerRemoved is a free log retrieval operation binding the contract event 0x9ea6376bcd095bc346ab7f5c534391c1a6ba1bb5153caf5e068742acd4f55162.
//
// Solidity: event SuperformManagerRemoved(address indexed manager)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterSuperformManagerRemoved(opts *bind.FilterOpts, manager []common.Address) (*ISuperGovernorSuperformManagerRemovedIterator, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "SuperformManagerRemoved", managerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorSuperformManagerRemovedIterator{contract: _ISuperGovernor.contract, event: "SuperformManagerRemoved", logs: logs, sub: sub}, nil
}

// WatchSuperformManagerRemoved is a free log subscription operation binding the contract event 0x9ea6376bcd095bc346ab7f5c534391c1a6ba1bb5153caf5e068742acd4f55162.
//
// Solidity: event SuperformManagerRemoved(address indexed manager)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchSuperformManagerRemoved(opts *bind.WatchOpts, sink chan<- *ISuperGovernorSuperformManagerRemoved, manager []common.Address) (event.Subscription, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "SuperformManagerRemoved", managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorSuperformManagerRemoved)
				if err := _ISuperGovernor.contract.UnpackLog(event, "SuperformManagerRemoved", log); err != nil {
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
// Solidity: event SuperformManagerRemoved(address indexed manager)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseSuperformManagerRemoved(log types.Log) (*ISuperGovernorSuperformManagerRemoved, error) {
	event := new(ISuperGovernorSuperformManagerRemoved)
	if err := _ISuperGovernor.contract.UnpackLog(event, "SuperformManagerRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorUpkeepPaymentsChangeProposedIterator is returned from FilterUpkeepPaymentsChangeProposed and is used to iterate over the raw logs and unpacked data for UpkeepPaymentsChangeProposed events raised by the ISuperGovernor contract.
type ISuperGovernorUpkeepPaymentsChangeProposedIterator struct {
	Event *ISuperGovernorUpkeepPaymentsChangeProposed // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorUpkeepPaymentsChangeProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorUpkeepPaymentsChangeProposed)
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
		it.Event = new(ISuperGovernorUpkeepPaymentsChangeProposed)
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
func (it *ISuperGovernorUpkeepPaymentsChangeProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorUpkeepPaymentsChangeProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorUpkeepPaymentsChangeProposed represents a UpkeepPaymentsChangeProposed event raised by the ISuperGovernor contract.
type ISuperGovernorUpkeepPaymentsChangeProposed struct {
	Enabled       bool
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterUpkeepPaymentsChangeProposed is a free log retrieval operation binding the contract event 0x3ccaf2442d2b29874fd84ceba9675d97d4dde7d521be650f67faab29a9afb10a.
//
// Solidity: event UpkeepPaymentsChangeProposed(bool enabled, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterUpkeepPaymentsChangeProposed(opts *bind.FilterOpts) (*ISuperGovernorUpkeepPaymentsChangeProposedIterator, error) {

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "UpkeepPaymentsChangeProposed")
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorUpkeepPaymentsChangeProposedIterator{contract: _ISuperGovernor.contract, event: "UpkeepPaymentsChangeProposed", logs: logs, sub: sub}, nil
}

// WatchUpkeepPaymentsChangeProposed is a free log subscription operation binding the contract event 0x3ccaf2442d2b29874fd84ceba9675d97d4dde7d521be650f67faab29a9afb10a.
//
// Solidity: event UpkeepPaymentsChangeProposed(bool enabled, uint256 effectiveTime)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchUpkeepPaymentsChangeProposed(opts *bind.WatchOpts, sink chan<- *ISuperGovernorUpkeepPaymentsChangeProposed) (event.Subscription, error) {

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "UpkeepPaymentsChangeProposed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorUpkeepPaymentsChangeProposed)
				if err := _ISuperGovernor.contract.UnpackLog(event, "UpkeepPaymentsChangeProposed", log); err != nil {
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
func (_ISuperGovernor *ISuperGovernorFilterer) ParseUpkeepPaymentsChangeProposed(log types.Log) (*ISuperGovernorUpkeepPaymentsChangeProposed, error) {
	event := new(ISuperGovernorUpkeepPaymentsChangeProposed)
	if err := _ISuperGovernor.contract.UnpackLog(event, "UpkeepPaymentsChangeProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorUpkeepPaymentsChangedIterator is returned from FilterUpkeepPaymentsChanged and is used to iterate over the raw logs and unpacked data for UpkeepPaymentsChanged events raised by the ISuperGovernor contract.
type ISuperGovernorUpkeepPaymentsChangedIterator struct {
	Event *ISuperGovernorUpkeepPaymentsChanged // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorUpkeepPaymentsChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorUpkeepPaymentsChanged)
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
		it.Event = new(ISuperGovernorUpkeepPaymentsChanged)
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
func (it *ISuperGovernorUpkeepPaymentsChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorUpkeepPaymentsChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorUpkeepPaymentsChanged represents a UpkeepPaymentsChanged event raised by the ISuperGovernor contract.
type ISuperGovernorUpkeepPaymentsChanged struct {
	Enabled bool
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterUpkeepPaymentsChanged is a free log retrieval operation binding the contract event 0x434397fd19989030741a6dd038e45b209af876fb83cafbd750fc5ad51be91ce9.
//
// Solidity: event UpkeepPaymentsChanged(bool enabled)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterUpkeepPaymentsChanged(opts *bind.FilterOpts) (*ISuperGovernorUpkeepPaymentsChangedIterator, error) {

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "UpkeepPaymentsChanged")
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorUpkeepPaymentsChangedIterator{contract: _ISuperGovernor.contract, event: "UpkeepPaymentsChanged", logs: logs, sub: sub}, nil
}

// WatchUpkeepPaymentsChanged is a free log subscription operation binding the contract event 0x434397fd19989030741a6dd038e45b209af876fb83cafbd750fc5ad51be91ce9.
//
// Solidity: event UpkeepPaymentsChanged(bool enabled)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchUpkeepPaymentsChanged(opts *bind.WatchOpts, sink chan<- *ISuperGovernorUpkeepPaymentsChanged) (event.Subscription, error) {

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "UpkeepPaymentsChanged")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorUpkeepPaymentsChanged)
				if err := _ISuperGovernor.contract.UnpackLog(event, "UpkeepPaymentsChanged", log); err != nil {
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
func (_ISuperGovernor *ISuperGovernorFilterer) ParseUpkeepPaymentsChanged(log types.Log) (*ISuperGovernorUpkeepPaymentsChanged, error) {
	event := new(ISuperGovernorUpkeepPaymentsChanged)
	if err := _ISuperGovernor.contract.UnpackLog(event, "UpkeepPaymentsChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorValidatorAddedIterator is returned from FilterValidatorAdded and is used to iterate over the raw logs and unpacked data for ValidatorAdded events raised by the ISuperGovernor contract.
type ISuperGovernorValidatorAddedIterator struct {
	Event *ISuperGovernorValidatorAdded // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorValidatorAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorValidatorAdded)
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
		it.Event = new(ISuperGovernorValidatorAdded)
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
func (it *ISuperGovernorValidatorAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorValidatorAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorValidatorAdded represents a ValidatorAdded event raised by the ISuperGovernor contract.
type ISuperGovernorValidatorAdded struct {
	Validator   common.Address
	BlockNumber *big.Int
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterValidatorAdded is a free log retrieval operation binding the contract event 0x9000b209805850a65058f21361a9978cb30f1413ed555553ab52a59b440b5d99.
//
// Solidity: event ValidatorAdded(address indexed validator, uint256 blockNumber)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterValidatorAdded(opts *bind.FilterOpts, validator []common.Address) (*ISuperGovernorValidatorAddedIterator, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "ValidatorAdded", validatorRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorValidatorAddedIterator{contract: _ISuperGovernor.contract, event: "ValidatorAdded", logs: logs, sub: sub}, nil
}

// WatchValidatorAdded is a free log subscription operation binding the contract event 0x9000b209805850a65058f21361a9978cb30f1413ed555553ab52a59b440b5d99.
//
// Solidity: event ValidatorAdded(address indexed validator, uint256 blockNumber)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchValidatorAdded(opts *bind.WatchOpts, sink chan<- *ISuperGovernorValidatorAdded, validator []common.Address) (event.Subscription, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "ValidatorAdded", validatorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorValidatorAdded)
				if err := _ISuperGovernor.contract.UnpackLog(event, "ValidatorAdded", log); err != nil {
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

// ParseValidatorAdded is a log parse operation binding the contract event 0x9000b209805850a65058f21361a9978cb30f1413ed555553ab52a59b440b5d99.
//
// Solidity: event ValidatorAdded(address indexed validator, uint256 blockNumber)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseValidatorAdded(log types.Log) (*ISuperGovernorValidatorAdded, error) {
	event := new(ISuperGovernorValidatorAdded)
	if err := _ISuperGovernor.contract.UnpackLog(event, "ValidatorAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperGovernorValidatorRemovedIterator is returned from FilterValidatorRemoved and is used to iterate over the raw logs and unpacked data for ValidatorRemoved events raised by the ISuperGovernor contract.
type ISuperGovernorValidatorRemovedIterator struct {
	Event *ISuperGovernorValidatorRemoved // Event containing the contract specifics and raw log

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
func (it *ISuperGovernorValidatorRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperGovernorValidatorRemoved)
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
		it.Event = new(ISuperGovernorValidatorRemoved)
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
func (it *ISuperGovernorValidatorRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperGovernorValidatorRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperGovernorValidatorRemoved represents a ValidatorRemoved event raised by the ISuperGovernor contract.
type ISuperGovernorValidatorRemoved struct {
	Validator   common.Address
	BlockNumber *big.Int
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterValidatorRemoved is a free log retrieval operation binding the contract event 0x50ecbf35c0ff0910f48ecaf45471c41781b549230264f6cb51997d7d425a02c3.
//
// Solidity: event ValidatorRemoved(address indexed validator, uint256 blockNumber)
func (_ISuperGovernor *ISuperGovernorFilterer) FilterValidatorRemoved(opts *bind.FilterOpts, validator []common.Address) (*ISuperGovernorValidatorRemovedIterator, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}

	logs, sub, err := _ISuperGovernor.contract.FilterLogs(opts, "ValidatorRemoved", validatorRule)
	if err != nil {
		return nil, err
	}
	return &ISuperGovernorValidatorRemovedIterator{contract: _ISuperGovernor.contract, event: "ValidatorRemoved", logs: logs, sub: sub}, nil
}

// WatchValidatorRemoved is a free log subscription operation binding the contract event 0x50ecbf35c0ff0910f48ecaf45471c41781b549230264f6cb51997d7d425a02c3.
//
// Solidity: event ValidatorRemoved(address indexed validator, uint256 blockNumber)
func (_ISuperGovernor *ISuperGovernorFilterer) WatchValidatorRemoved(opts *bind.WatchOpts, sink chan<- *ISuperGovernorValidatorRemoved, validator []common.Address) (event.Subscription, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}

	logs, sub, err := _ISuperGovernor.contract.WatchLogs(opts, "ValidatorRemoved", validatorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperGovernorValidatorRemoved)
				if err := _ISuperGovernor.contract.UnpackLog(event, "ValidatorRemoved", log); err != nil {
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

// ParseValidatorRemoved is a log parse operation binding the contract event 0x50ecbf35c0ff0910f48ecaf45471c41781b549230264f6cb51997d7d425a02c3.
//
// Solidity: event ValidatorRemoved(address indexed validator, uint256 blockNumber)
func (_ISuperGovernor *ISuperGovernorFilterer) ParseValidatorRemoved(log types.Log) (*ISuperGovernorValidatorRemoved, error) {
	event := new(ISuperGovernorValidatorRemoved)
	if err := _ISuperGovernor.contract.UnpackLog(event, "ValidatorRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
