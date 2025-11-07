// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package SuperGovernor

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

// SuperGovernorMetaData contains all meta data concerning the SuperGovernor contract.
var SuperGovernorMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"superGovernor\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"governor\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bankManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"gasManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"treasury\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"BANK_MANAGER\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"BANK_MANAGER_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ECDSAPPSORACLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"GAS_MANAGER_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"GOVERNOR_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"GUARDIAN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"ORACLE_MANAGER_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"PERFORMANCE_FEE_SHARE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"REVENUE_SHARE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUP\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_BANK\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_GOVERNOR_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"SUPER_ORACLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_VAULT_AGGREGATOR\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"TREASURY\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"UP\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addExecutor\",\"inputs\":[{\"name\":\"executor\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addSuperformManager\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addValidator\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"batchSetEmergencyPrices\",\"inputs\":[{\"name\":\"tokens_\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"prices_\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"batchSetOracleUptimeFeed\",\"inputs\":[{\"name\":\"dataOracles_\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"uptimeOracles_\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"gracePeriods_\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"changeHooksRootUpdateTimelock\",\"inputs\":[{\"name\":\"newTimelock\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"changePrimaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newManager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeActivePPSOracleChange\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeFeeUpdate\",\"inputs\":[{\"name\":\"feeType\",\"type\":\"uint8\",\"internalType\":\"enumFeeType\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeMinStalenesChange\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeOracleProviderRemoval\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeOracleUpdate\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeSuperBankHookMerkleRootUpdate\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeUpkeepClaim\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeUpkeepPaymentsChange\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"freezeManagerTakeover\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getActivePPSOracle\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAddress\",\"inputs\":[{\"name\":\"key\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAllSuperformManagers\",\"inputs\":[],\"outputs\":[{\"name\":\"managers\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getExecutors\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getFee\",\"inputs\":[{\"name\":\"feeType\",\"type\":\"uint8\",\"internalType\":\"enumFeeType\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getGasInfo\",\"inputs\":[{\"name\":\"oracle_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getManagersPaginated\",\"inputs\":[{\"name\":\"cursor\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"limit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"chunkOfManagers\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"next\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMinStaleness\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getPPSOracleQuorum\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedActivePPSOracle\",\"inputs\":[],\"outputs\":[{\"name\":\"proposedOracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedMinStaleness\",\"inputs\":[],\"outputs\":[{\"name\":\"proposedMinStaleness\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedSuperBankHookMerkleRoot\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"proposedRoot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedUpkeepPaymentsStatus\",\"inputs\":[],\"outputs\":[{\"name\":\"enabled\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRegisteredHooks\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSuperBankHookMerkleRoot\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSuperformManagersCount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getUpkeepCostPerSingleUpdate\",\"inputs\":[{\"name\":\"oracle_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorAt\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorConfigVersion\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidators\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getValidatorsCount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isActivePPSOracle\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isExecutor\",\"inputs\":[{\"name\":\"executor\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isGuardian\",\"inputs\":[{\"name\":\"guardian\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isHookRegistered\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isManagerTakeoverFrozen\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isSuperformManager\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"isSuperform\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isUpkeepPaymentsEnabled\",\"inputs\":[],\"outputs\":[{\"name\":\"enabled\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isValidator\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proposeActivePPSOracle\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeFee\",\"inputs\":[{\"name\":\"feeType\",\"type\":\"uint8\",\"internalType\":\"enumFeeType\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeGlobalHooksRoot\",\"inputs\":[{\"name\":\"newRoot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeMinStaleness\",\"inputs\":[{\"name\":\"newMinStaleness\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeSuperBankHookMerkleRoot\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"proposedRoot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeUpkeepPaymentsChange\",\"inputs\":[{\"name\":\"enabled\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"queueOracleProviderRemoval\",\"inputs\":[{\"name\":\"providers\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"queueOracleUpdate\",\"inputs\":[{\"name\":\"bases_\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"quotes_\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"providers_\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"},{\"name\":\"feeds_\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"registerHook\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeExecutor\",\"inputs\":[{\"name\":\"executor\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeSuperformManager\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeValidator\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"callerConfirmation\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setActivePPSOracle\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setAddress\",\"inputs\":[{\"name\":\"key\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"value\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setEmergencyPrice\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"price\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGasInfo\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"gasIncreasePerEntryBatch\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGlobalHooksRootVetoStatus\",\"inputs\":[{\"name\":\"vetoed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setOracleFeedMaxStaleness\",\"inputs\":[{\"name\":\"feed\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newMaxStaleness\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setOracleFeedMaxStalenessBatch\",\"inputs\":[{\"name\":\"feeds_\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"newMaxStalenessList_\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setOracleMaxStaleness\",\"inputs\":[{\"name\":\"newMaxStaleness\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setPPSOracleQuorum\",\"inputs\":[{\"name\":\"quorum\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setStrategyHooksRootVetoStatus\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"vetoed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"slashStake\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"unregisterHook\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"ActivePPSOracleChanged\",\"inputs\":[{\"name\":\"oldOracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ActivePPSOracleProposed\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ActivePPSOracleSet\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AddressSet\",\"inputs\":[{\"name\":\"key\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"oldValue\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"value\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ExecutorAdded\",\"inputs\":[{\"name\":\"executor\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ExecutorRemoved\",\"inputs\":[{\"name\":\"executor\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FeeProposed\",\"inputs\":[{\"name\":\"feeType\",\"type\":\"uint8\",\"indexed\":true,\"internalType\":\"enumFeeType\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FeeUpdated\",\"inputs\":[{\"name\":\"feeType\",\"type\":\"uint8\",\"indexed\":true,\"internalType\":\"enumFeeType\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"GasInfoSet\",\"inputs\":[{\"name\":\"oracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"gasIncreasePerEntryBatch\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"HookApproved\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"HookRemoved\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ManagerTakeoversFrozen\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MinStalenesChanged\",\"inputs\":[{\"name\":\"newMinStaleness\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MinStalenesProposed\",\"inputs\":[{\"name\":\"newMinStaleness\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSOracleQuorumUpdated\",\"inputs\":[{\"name\":\"quorum\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ProtectedKeeperRegistered\",\"inputs\":[{\"name\":\"keeper\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ProtectedKeeperUnregistered\",\"inputs\":[{\"name\":\"keeper\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RevenueShareUpdated\",\"inputs\":[{\"name\":\"share\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SuperBankHookMerkleRootProposed\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newRoot\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SuperBankHookMerkleRootUpdated\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newRoot\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SuperformManagerAdded\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SuperformManagerRemoved\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepPaymentsChangeProposed\",\"inputs\":[{\"name\":\"enabled\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepPaymentsChanged\",\"inputs\":[{\"name\":\"enabled\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorAdded\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"blockNumber\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ValidatorRemoved\",\"inputs\":[{\"name\":\"validator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"blockNumber\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AccessControlBadConfirmation\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"neededRole\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"CONTRACT_ALREADY_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CONTRACT_NOT_FOUND\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"EXECUTOR_ALREADY_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"EXECUTOR_NOT_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"HOOK_ALREADY_APPROVED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"HOOK_NOT_APPROVED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_CHAIN_ID\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_FEE_VALUE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_GAS_INFO\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_QUORUM\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_REVENUE_SHARE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_TIMESTAMP\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"KEEPER_ALREADY_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"KEEPER_NOT_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MANAGER_ALREADY_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MANAGER_NOT_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MANAGER_TAKEOVERS_FROZEN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MAX_STALENESS_TOO_LOW\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MUST_USE_TIMELOCK_FOR_CHANGE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_ACTIVE_PPS_ORACLE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_PENDING_CHANGE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_PROPOSED_FEE\",\"inputs\":[{\"name\":\"feeType\",\"type\":\"uint8\",\"internalType\":\"enumFeeType\"}]},{\"type\":\"error\",\"name\":\"NO_PROPOSED_MERKLE_ROOT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_PROPOSED_MIN_STALENESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_PROPOSED_PPS_ORACLE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ONLY_GOVERNOR\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PRICE_NOT_FOUND\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"STALE_ORACLE_PRICE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SUPER_ORACLE_NOT_FOUND\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"TIMELOCK_NOT_EXPIRED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UP_NOT_FOUND\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"VALIDATOR_ALREADY_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"VALIDATOR_NOT_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_PROPOSED_MERKLE_ROOT\",\"inputs\":[]}]",
}

// SuperGovernorABI is the input ABI used to generate the binding from.
// Deprecated: Use SuperGovernorMetaData.ABI instead.
var SuperGovernorABI = SuperGovernorMetaData.ABI

// SuperGovernor is an auto generated Go binding around an Ethereum contract.
type SuperGovernor struct {
	SuperGovernorCaller     // Read-only binding to the contract
	SuperGovernorTransactor // Write-only binding to the contract
	SuperGovernorFilterer   // Log filterer for contract events
}

// SuperGovernorCaller is an auto generated read-only Go binding around an Ethereum contract.
type SuperGovernorCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperGovernorTransactor is an auto generated write-only Go binding around an Ethereum contract.
type SuperGovernorTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperGovernorFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type SuperGovernorFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperGovernorSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type SuperGovernorSession struct {
	Contract     *SuperGovernor    // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// SuperGovernorCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type SuperGovernorCallerSession struct {
	Contract *SuperGovernorCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts        // Call options to use throughout this session
}

// SuperGovernorTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type SuperGovernorTransactorSession struct {
	Contract     *SuperGovernorTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts        // Transaction auth options to use throughout this session
}

// SuperGovernorRaw is an auto generated low-level Go binding around an Ethereum contract.
type SuperGovernorRaw struct {
	Contract *SuperGovernor // Generic contract binding to access the raw methods on
}

// SuperGovernorCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type SuperGovernorCallerRaw struct {
	Contract *SuperGovernorCaller // Generic read-only contract binding to access the raw methods on
}

// SuperGovernorTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type SuperGovernorTransactorRaw struct {
	Contract *SuperGovernorTransactor // Generic write-only contract binding to access the raw methods on
}

// NewSuperGovernor creates a new instance of SuperGovernor, bound to a specific deployed contract.
func NewSuperGovernor(address common.Address, backend bind.ContractBackend) (*SuperGovernor, error) {
	contract, err := bindSuperGovernor(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &SuperGovernor{SuperGovernorCaller: SuperGovernorCaller{contract: contract}, SuperGovernorTransactor: SuperGovernorTransactor{contract: contract}, SuperGovernorFilterer: SuperGovernorFilterer{contract: contract}}, nil
}

// NewSuperGovernorCaller creates a new read-only instance of SuperGovernor, bound to a specific deployed contract.
func NewSuperGovernorCaller(address common.Address, caller bind.ContractCaller) (*SuperGovernorCaller, error) {
	contract, err := bindSuperGovernor(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorCaller{contract: contract}, nil
}

// NewSuperGovernorTransactor creates a new write-only instance of SuperGovernor, bound to a specific deployed contract.
func NewSuperGovernorTransactor(address common.Address, transactor bind.ContractTransactor) (*SuperGovernorTransactor, error) {
	contract, err := bindSuperGovernor(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorTransactor{contract: contract}, nil
}

// NewSuperGovernorFilterer creates a new log filterer instance of SuperGovernor, bound to a specific deployed contract.
func NewSuperGovernorFilterer(address common.Address, filterer bind.ContractFilterer) (*SuperGovernorFilterer, error) {
	contract, err := bindSuperGovernor(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorFilterer{contract: contract}, nil
}

// bindSuperGovernor binds a generic wrapper to an already deployed contract.
func bindSuperGovernor(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := SuperGovernorMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperGovernor *SuperGovernorRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperGovernor.Contract.SuperGovernorCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperGovernor *SuperGovernorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SuperGovernorTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperGovernor *SuperGovernorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SuperGovernorTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperGovernor *SuperGovernorCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperGovernor.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperGovernor *SuperGovernorTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperGovernor.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperGovernor *SuperGovernorTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperGovernor.Contract.contract.Transact(opts, method, params...)
}

// BANKMANAGER is a free data retrieval call binding the contract method 0x67e21123.
//
// Solidity: function BANK_MANAGER() view returns(bytes32)
func (_SuperGovernor *SuperGovernorCaller) BANKMANAGER(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "BANK_MANAGER")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// BANKMANAGER is a free data retrieval call binding the contract method 0x67e21123.
//
// Solidity: function BANK_MANAGER() view returns(bytes32)
func (_SuperGovernor *SuperGovernorSession) BANKMANAGER() ([32]byte, error) {
	return _SuperGovernor.Contract.BANKMANAGER(&_SuperGovernor.CallOpts)
}

// BANKMANAGER is a free data retrieval call binding the contract method 0x67e21123.
//
// Solidity: function BANK_MANAGER() view returns(bytes32)
func (_SuperGovernor *SuperGovernorCallerSession) BANKMANAGER() ([32]byte, error) {
	return _SuperGovernor.Contract.BANKMANAGER(&_SuperGovernor.CallOpts)
}

// BANKMANAGERROLE is a free data retrieval call binding the contract method 0xf2157052.
//
// Solidity: function BANK_MANAGER_ROLE() pure returns(bytes32)
func (_SuperGovernor *SuperGovernorCaller) BANKMANAGERROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "BANK_MANAGER_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// BANKMANAGERROLE is a free data retrieval call binding the contract method 0xf2157052.
//
// Solidity: function BANK_MANAGER_ROLE() pure returns(bytes32)
func (_SuperGovernor *SuperGovernorSession) BANKMANAGERROLE() ([32]byte, error) {
	return _SuperGovernor.Contract.BANKMANAGERROLE(&_SuperGovernor.CallOpts)
}

// BANKMANAGERROLE is a free data retrieval call binding the contract method 0xf2157052.
//
// Solidity: function BANK_MANAGER_ROLE() pure returns(bytes32)
func (_SuperGovernor *SuperGovernorCallerSession) BANKMANAGERROLE() ([32]byte, error) {
	return _SuperGovernor.Contract.BANKMANAGERROLE(&_SuperGovernor.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_SuperGovernor *SuperGovernorCaller) DEFAULTADMINROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "DEFAULT_ADMIN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_SuperGovernor *SuperGovernorSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _SuperGovernor.Contract.DEFAULTADMINROLE(&_SuperGovernor.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_SuperGovernor *SuperGovernorCallerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _SuperGovernor.Contract.DEFAULTADMINROLE(&_SuperGovernor.CallOpts)
}

// ECDSAPPSORACLE is a free data retrieval call binding the contract method 0xffdb5200.
//
// Solidity: function ECDSAPPSORACLE() view returns(bytes32)
func (_SuperGovernor *SuperGovernorCaller) ECDSAPPSORACLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "ECDSAPPSORACLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// ECDSAPPSORACLE is a free data retrieval call binding the contract method 0xffdb5200.
//
// Solidity: function ECDSAPPSORACLE() view returns(bytes32)
func (_SuperGovernor *SuperGovernorSession) ECDSAPPSORACLE() ([32]byte, error) {
	return _SuperGovernor.Contract.ECDSAPPSORACLE(&_SuperGovernor.CallOpts)
}

// ECDSAPPSORACLE is a free data retrieval call binding the contract method 0xffdb5200.
//
// Solidity: function ECDSAPPSORACLE() view returns(bytes32)
func (_SuperGovernor *SuperGovernorCallerSession) ECDSAPPSORACLE() ([32]byte, error) {
	return _SuperGovernor.Contract.ECDSAPPSORACLE(&_SuperGovernor.CallOpts)
}

// GASMANAGERROLE is a free data retrieval call binding the contract method 0x42436beb.
//
// Solidity: function GAS_MANAGER_ROLE() pure returns(bytes32)
func (_SuperGovernor *SuperGovernorCaller) GASMANAGERROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "GAS_MANAGER_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GASMANAGERROLE is a free data retrieval call binding the contract method 0x42436beb.
//
// Solidity: function GAS_MANAGER_ROLE() pure returns(bytes32)
func (_SuperGovernor *SuperGovernorSession) GASMANAGERROLE() ([32]byte, error) {
	return _SuperGovernor.Contract.GASMANAGERROLE(&_SuperGovernor.CallOpts)
}

// GASMANAGERROLE is a free data retrieval call binding the contract method 0x42436beb.
//
// Solidity: function GAS_MANAGER_ROLE() pure returns(bytes32)
func (_SuperGovernor *SuperGovernorCallerSession) GASMANAGERROLE() ([32]byte, error) {
	return _SuperGovernor.Contract.GASMANAGERROLE(&_SuperGovernor.CallOpts)
}

// GOVERNORROLE is a free data retrieval call binding the contract method 0xccc57490.
//
// Solidity: function GOVERNOR_ROLE() pure returns(bytes32)
func (_SuperGovernor *SuperGovernorCaller) GOVERNORROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "GOVERNOR_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GOVERNORROLE is a free data retrieval call binding the contract method 0xccc57490.
//
// Solidity: function GOVERNOR_ROLE() pure returns(bytes32)
func (_SuperGovernor *SuperGovernorSession) GOVERNORROLE() ([32]byte, error) {
	return _SuperGovernor.Contract.GOVERNORROLE(&_SuperGovernor.CallOpts)
}

// GOVERNORROLE is a free data retrieval call binding the contract method 0xccc57490.
//
// Solidity: function GOVERNOR_ROLE() pure returns(bytes32)
func (_SuperGovernor *SuperGovernorCallerSession) GOVERNORROLE() ([32]byte, error) {
	return _SuperGovernor.Contract.GOVERNORROLE(&_SuperGovernor.CallOpts)
}

// GUARDIANROLE is a free data retrieval call binding the contract method 0x24ea54f4.
//
// Solidity: function GUARDIAN_ROLE() pure returns(bytes32)
func (_SuperGovernor *SuperGovernorCaller) GUARDIANROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "GUARDIAN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GUARDIANROLE is a free data retrieval call binding the contract method 0x24ea54f4.
//
// Solidity: function GUARDIAN_ROLE() pure returns(bytes32)
func (_SuperGovernor *SuperGovernorSession) GUARDIANROLE() ([32]byte, error) {
	return _SuperGovernor.Contract.GUARDIANROLE(&_SuperGovernor.CallOpts)
}

// GUARDIANROLE is a free data retrieval call binding the contract method 0x24ea54f4.
//
// Solidity: function GUARDIAN_ROLE() pure returns(bytes32)
func (_SuperGovernor *SuperGovernorCallerSession) GUARDIANROLE() ([32]byte, error) {
	return _SuperGovernor.Contract.GUARDIANROLE(&_SuperGovernor.CallOpts)
}

// ORACLEMANAGERROLE is a free data retrieval call binding the contract method 0xbfc69e1c.
//
// Solidity: function ORACLE_MANAGER_ROLE() pure returns(bytes32)
func (_SuperGovernor *SuperGovernorCaller) ORACLEMANAGERROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "ORACLE_MANAGER_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// ORACLEMANAGERROLE is a free data retrieval call binding the contract method 0xbfc69e1c.
//
// Solidity: function ORACLE_MANAGER_ROLE() pure returns(bytes32)
func (_SuperGovernor *SuperGovernorSession) ORACLEMANAGERROLE() ([32]byte, error) {
	return _SuperGovernor.Contract.ORACLEMANAGERROLE(&_SuperGovernor.CallOpts)
}

// ORACLEMANAGERROLE is a free data retrieval call binding the contract method 0xbfc69e1c.
//
// Solidity: function ORACLE_MANAGER_ROLE() pure returns(bytes32)
func (_SuperGovernor *SuperGovernorCallerSession) ORACLEMANAGERROLE() ([32]byte, error) {
	return _SuperGovernor.Contract.ORACLEMANAGERROLE(&_SuperGovernor.CallOpts)
}

// PERFORMANCEFEESHARE is a free data retrieval call binding the contract method 0x58f43929.
//
// Solidity: function PERFORMANCE_FEE_SHARE() view returns(uint256)
func (_SuperGovernor *SuperGovernorCaller) PERFORMANCEFEESHARE(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "PERFORMANCE_FEE_SHARE")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PERFORMANCEFEESHARE is a free data retrieval call binding the contract method 0x58f43929.
//
// Solidity: function PERFORMANCE_FEE_SHARE() view returns(uint256)
func (_SuperGovernor *SuperGovernorSession) PERFORMANCEFEESHARE() (*big.Int, error) {
	return _SuperGovernor.Contract.PERFORMANCEFEESHARE(&_SuperGovernor.CallOpts)
}

// PERFORMANCEFEESHARE is a free data retrieval call binding the contract method 0x58f43929.
//
// Solidity: function PERFORMANCE_FEE_SHARE() view returns(uint256)
func (_SuperGovernor *SuperGovernorCallerSession) PERFORMANCEFEESHARE() (*big.Int, error) {
	return _SuperGovernor.Contract.PERFORMANCEFEESHARE(&_SuperGovernor.CallOpts)
}

// REVENUESHARE is a free data retrieval call binding the contract method 0xd9060c4c.
//
// Solidity: function REVENUE_SHARE() view returns(uint256)
func (_SuperGovernor *SuperGovernorCaller) REVENUESHARE(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "REVENUE_SHARE")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// REVENUESHARE is a free data retrieval call binding the contract method 0xd9060c4c.
//
// Solidity: function REVENUE_SHARE() view returns(uint256)
func (_SuperGovernor *SuperGovernorSession) REVENUESHARE() (*big.Int, error) {
	return _SuperGovernor.Contract.REVENUESHARE(&_SuperGovernor.CallOpts)
}

// REVENUESHARE is a free data retrieval call binding the contract method 0xd9060c4c.
//
// Solidity: function REVENUE_SHARE() view returns(uint256)
func (_SuperGovernor *SuperGovernorCallerSession) REVENUESHARE() (*big.Int, error) {
	return _SuperGovernor.Contract.REVENUESHARE(&_SuperGovernor.CallOpts)
}

// SUP is a free data retrieval call binding the contract method 0x95c0bf69.
//
// Solidity: function SUP() view returns(bytes32)
func (_SuperGovernor *SuperGovernorCaller) SUP(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "SUP")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SUP is a free data retrieval call binding the contract method 0x95c0bf69.
//
// Solidity: function SUP() view returns(bytes32)
func (_SuperGovernor *SuperGovernorSession) SUP() ([32]byte, error) {
	return _SuperGovernor.Contract.SUP(&_SuperGovernor.CallOpts)
}

// SUP is a free data retrieval call binding the contract method 0x95c0bf69.
//
// Solidity: function SUP() view returns(bytes32)
func (_SuperGovernor *SuperGovernorCallerSession) SUP() ([32]byte, error) {
	return _SuperGovernor.Contract.SUP(&_SuperGovernor.CallOpts)
}

// SUPERBANK is a free data retrieval call binding the contract method 0x6f2140c1.
//
// Solidity: function SUPER_BANK() view returns(bytes32)
func (_SuperGovernor *SuperGovernorCaller) SUPERBANK(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "SUPER_BANK")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SUPERBANK is a free data retrieval call binding the contract method 0x6f2140c1.
//
// Solidity: function SUPER_BANK() view returns(bytes32)
func (_SuperGovernor *SuperGovernorSession) SUPERBANK() ([32]byte, error) {
	return _SuperGovernor.Contract.SUPERBANK(&_SuperGovernor.CallOpts)
}

// SUPERBANK is a free data retrieval call binding the contract method 0x6f2140c1.
//
// Solidity: function SUPER_BANK() view returns(bytes32)
func (_SuperGovernor *SuperGovernorCallerSession) SUPERBANK() ([32]byte, error) {
	return _SuperGovernor.Contract.SUPERBANK(&_SuperGovernor.CallOpts)
}

// SUPERGOVERNORROLE is a free data retrieval call binding the contract method 0xec45ad53.
//
// Solidity: function SUPER_GOVERNOR_ROLE() pure returns(bytes32)
func (_SuperGovernor *SuperGovernorCaller) SUPERGOVERNORROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "SUPER_GOVERNOR_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SUPERGOVERNORROLE is a free data retrieval call binding the contract method 0xec45ad53.
//
// Solidity: function SUPER_GOVERNOR_ROLE() pure returns(bytes32)
func (_SuperGovernor *SuperGovernorSession) SUPERGOVERNORROLE() ([32]byte, error) {
	return _SuperGovernor.Contract.SUPERGOVERNORROLE(&_SuperGovernor.CallOpts)
}

// SUPERGOVERNORROLE is a free data retrieval call binding the contract method 0xec45ad53.
//
// Solidity: function SUPER_GOVERNOR_ROLE() pure returns(bytes32)
func (_SuperGovernor *SuperGovernorCallerSession) SUPERGOVERNORROLE() ([32]byte, error) {
	return _SuperGovernor.Contract.SUPERGOVERNORROLE(&_SuperGovernor.CallOpts)
}

// SUPERORACLE is a free data retrieval call binding the contract method 0x90d4a56d.
//
// Solidity: function SUPER_ORACLE() view returns(bytes32)
func (_SuperGovernor *SuperGovernorCaller) SUPERORACLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "SUPER_ORACLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SUPERORACLE is a free data retrieval call binding the contract method 0x90d4a56d.
//
// Solidity: function SUPER_ORACLE() view returns(bytes32)
func (_SuperGovernor *SuperGovernorSession) SUPERORACLE() ([32]byte, error) {
	return _SuperGovernor.Contract.SUPERORACLE(&_SuperGovernor.CallOpts)
}

// SUPERORACLE is a free data retrieval call binding the contract method 0x90d4a56d.
//
// Solidity: function SUPER_ORACLE() view returns(bytes32)
func (_SuperGovernor *SuperGovernorCallerSession) SUPERORACLE() ([32]byte, error) {
	return _SuperGovernor.Contract.SUPERORACLE(&_SuperGovernor.CallOpts)
}

// SUPERVAULTAGGREGATOR is a free data retrieval call binding the contract method 0xc9838819.
//
// Solidity: function SUPER_VAULT_AGGREGATOR() view returns(bytes32)
func (_SuperGovernor *SuperGovernorCaller) SUPERVAULTAGGREGATOR(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "SUPER_VAULT_AGGREGATOR")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SUPERVAULTAGGREGATOR is a free data retrieval call binding the contract method 0xc9838819.
//
// Solidity: function SUPER_VAULT_AGGREGATOR() view returns(bytes32)
func (_SuperGovernor *SuperGovernorSession) SUPERVAULTAGGREGATOR() ([32]byte, error) {
	return _SuperGovernor.Contract.SUPERVAULTAGGREGATOR(&_SuperGovernor.CallOpts)
}

// SUPERVAULTAGGREGATOR is a free data retrieval call binding the contract method 0xc9838819.
//
// Solidity: function SUPER_VAULT_AGGREGATOR() view returns(bytes32)
func (_SuperGovernor *SuperGovernorCallerSession) SUPERVAULTAGGREGATOR() ([32]byte, error) {
	return _SuperGovernor.Contract.SUPERVAULTAGGREGATOR(&_SuperGovernor.CallOpts)
}

// TREASURY is a free data retrieval call binding the contract method 0x2d2c5565.
//
// Solidity: function TREASURY() view returns(bytes32)
func (_SuperGovernor *SuperGovernorCaller) TREASURY(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "TREASURY")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// TREASURY is a free data retrieval call binding the contract method 0x2d2c5565.
//
// Solidity: function TREASURY() view returns(bytes32)
func (_SuperGovernor *SuperGovernorSession) TREASURY() ([32]byte, error) {
	return _SuperGovernor.Contract.TREASURY(&_SuperGovernor.CallOpts)
}

// TREASURY is a free data retrieval call binding the contract method 0x2d2c5565.
//
// Solidity: function TREASURY() view returns(bytes32)
func (_SuperGovernor *SuperGovernorCallerSession) TREASURY() ([32]byte, error) {
	return _SuperGovernor.Contract.TREASURY(&_SuperGovernor.CallOpts)
}

// UP is a free data retrieval call binding the contract method 0x24f4ec51.
//
// Solidity: function UP() view returns(bytes32)
func (_SuperGovernor *SuperGovernorCaller) UP(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "UP")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// UP is a free data retrieval call binding the contract method 0x24f4ec51.
//
// Solidity: function UP() view returns(bytes32)
func (_SuperGovernor *SuperGovernorSession) UP() ([32]byte, error) {
	return _SuperGovernor.Contract.UP(&_SuperGovernor.CallOpts)
}

// UP is a free data retrieval call binding the contract method 0x24f4ec51.
//
// Solidity: function UP() view returns(bytes32)
func (_SuperGovernor *SuperGovernorCallerSession) UP() ([32]byte, error) {
	return _SuperGovernor.Contract.UP(&_SuperGovernor.CallOpts)
}

// GetActivePPSOracle is a free data retrieval call binding the contract method 0x275f0f2b.
//
// Solidity: function getActivePPSOracle() view returns(address)
func (_SuperGovernor *SuperGovernorCaller) GetActivePPSOracle(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getActivePPSOracle")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetActivePPSOracle is a free data retrieval call binding the contract method 0x275f0f2b.
//
// Solidity: function getActivePPSOracle() view returns(address)
func (_SuperGovernor *SuperGovernorSession) GetActivePPSOracle() (common.Address, error) {
	return _SuperGovernor.Contract.GetActivePPSOracle(&_SuperGovernor.CallOpts)
}

// GetActivePPSOracle is a free data retrieval call binding the contract method 0x275f0f2b.
//
// Solidity: function getActivePPSOracle() view returns(address)
func (_SuperGovernor *SuperGovernorCallerSession) GetActivePPSOracle() (common.Address, error) {
	return _SuperGovernor.Contract.GetActivePPSOracle(&_SuperGovernor.CallOpts)
}

// GetAddress is a free data retrieval call binding the contract method 0x21f8a721.
//
// Solidity: function getAddress(bytes32 key) view returns(address)
func (_SuperGovernor *SuperGovernorCaller) GetAddress(opts *bind.CallOpts, key [32]byte) (common.Address, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getAddress", key)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetAddress is a free data retrieval call binding the contract method 0x21f8a721.
//
// Solidity: function getAddress(bytes32 key) view returns(address)
func (_SuperGovernor *SuperGovernorSession) GetAddress(key [32]byte) (common.Address, error) {
	return _SuperGovernor.Contract.GetAddress(&_SuperGovernor.CallOpts, key)
}

// GetAddress is a free data retrieval call binding the contract method 0x21f8a721.
//
// Solidity: function getAddress(bytes32 key) view returns(address)
func (_SuperGovernor *SuperGovernorCallerSession) GetAddress(key [32]byte) (common.Address, error) {
	return _SuperGovernor.Contract.GetAddress(&_SuperGovernor.CallOpts, key)
}

// GetAllSuperformManagers is a free data retrieval call binding the contract method 0xa1d1ab43.
//
// Solidity: function getAllSuperformManagers() view returns(address[] managers)
func (_SuperGovernor *SuperGovernorCaller) GetAllSuperformManagers(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getAllSuperformManagers")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetAllSuperformManagers is a free data retrieval call binding the contract method 0xa1d1ab43.
//
// Solidity: function getAllSuperformManagers() view returns(address[] managers)
func (_SuperGovernor *SuperGovernorSession) GetAllSuperformManagers() ([]common.Address, error) {
	return _SuperGovernor.Contract.GetAllSuperformManagers(&_SuperGovernor.CallOpts)
}

// GetAllSuperformManagers is a free data retrieval call binding the contract method 0xa1d1ab43.
//
// Solidity: function getAllSuperformManagers() view returns(address[] managers)
func (_SuperGovernor *SuperGovernorCallerSession) GetAllSuperformManagers() ([]common.Address, error) {
	return _SuperGovernor.Contract.GetAllSuperformManagers(&_SuperGovernor.CallOpts)
}

// GetExecutors is a free data retrieval call binding the contract method 0xef09e78f.
//
// Solidity: function getExecutors() view returns(address[])
func (_SuperGovernor *SuperGovernorCaller) GetExecutors(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getExecutors")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetExecutors is a free data retrieval call binding the contract method 0xef09e78f.
//
// Solidity: function getExecutors() view returns(address[])
func (_SuperGovernor *SuperGovernorSession) GetExecutors() ([]common.Address, error) {
	return _SuperGovernor.Contract.GetExecutors(&_SuperGovernor.CallOpts)
}

// GetExecutors is a free data retrieval call binding the contract method 0xef09e78f.
//
// Solidity: function getExecutors() view returns(address[])
func (_SuperGovernor *SuperGovernorCallerSession) GetExecutors() ([]common.Address, error) {
	return _SuperGovernor.Contract.GetExecutors(&_SuperGovernor.CallOpts)
}

// GetFee is a free data retrieval call binding the contract method 0x083132c4.
//
// Solidity: function getFee(uint8 feeType) view returns(uint256)
func (_SuperGovernor *SuperGovernorCaller) GetFee(opts *bind.CallOpts, feeType uint8) (*big.Int, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getFee", feeType)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetFee is a free data retrieval call binding the contract method 0x083132c4.
//
// Solidity: function getFee(uint8 feeType) view returns(uint256)
func (_SuperGovernor *SuperGovernorSession) GetFee(feeType uint8) (*big.Int, error) {
	return _SuperGovernor.Contract.GetFee(&_SuperGovernor.CallOpts, feeType)
}

// GetFee is a free data retrieval call binding the contract method 0x083132c4.
//
// Solidity: function getFee(uint8 feeType) view returns(uint256)
func (_SuperGovernor *SuperGovernorCallerSession) GetFee(feeType uint8) (*big.Int, error) {
	return _SuperGovernor.Contract.GetFee(&_SuperGovernor.CallOpts, feeType)
}

// GetGasInfo is a free data retrieval call binding the contract method 0xf5f81403.
//
// Solidity: function getGasInfo(address oracle_) view returns(uint256)
func (_SuperGovernor *SuperGovernorCaller) GetGasInfo(opts *bind.CallOpts, oracle_ common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getGasInfo", oracle_)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetGasInfo is a free data retrieval call binding the contract method 0xf5f81403.
//
// Solidity: function getGasInfo(address oracle_) view returns(uint256)
func (_SuperGovernor *SuperGovernorSession) GetGasInfo(oracle_ common.Address) (*big.Int, error) {
	return _SuperGovernor.Contract.GetGasInfo(&_SuperGovernor.CallOpts, oracle_)
}

// GetGasInfo is a free data retrieval call binding the contract method 0xf5f81403.
//
// Solidity: function getGasInfo(address oracle_) view returns(uint256)
func (_SuperGovernor *SuperGovernorCallerSession) GetGasInfo(oracle_ common.Address) (*big.Int, error) {
	return _SuperGovernor.Contract.GetGasInfo(&_SuperGovernor.CallOpts, oracle_)
}

// GetManagersPaginated is a free data retrieval call binding the contract method 0xbe5edae5.
//
// Solidity: function getManagersPaginated(uint256 cursor, uint256 limit) view returns(address[] chunkOfManagers, uint256 next)
func (_SuperGovernor *SuperGovernorCaller) GetManagersPaginated(opts *bind.CallOpts, cursor *big.Int, limit *big.Int) (struct {
	ChunkOfManagers []common.Address
	Next            *big.Int
}, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getManagersPaginated", cursor, limit)

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
func (_SuperGovernor *SuperGovernorSession) GetManagersPaginated(cursor *big.Int, limit *big.Int) (struct {
	ChunkOfManagers []common.Address
	Next            *big.Int
}, error) {
	return _SuperGovernor.Contract.GetManagersPaginated(&_SuperGovernor.CallOpts, cursor, limit)
}

// GetManagersPaginated is a free data retrieval call binding the contract method 0xbe5edae5.
//
// Solidity: function getManagersPaginated(uint256 cursor, uint256 limit) view returns(address[] chunkOfManagers, uint256 next)
func (_SuperGovernor *SuperGovernorCallerSession) GetManagersPaginated(cursor *big.Int, limit *big.Int) (struct {
	ChunkOfManagers []common.Address
	Next            *big.Int
}, error) {
	return _SuperGovernor.Contract.GetManagersPaginated(&_SuperGovernor.CallOpts, cursor, limit)
}

// GetMinStaleness is a free data retrieval call binding the contract method 0x29f05976.
//
// Solidity: function getMinStaleness() view returns(uint256)
func (_SuperGovernor *SuperGovernorCaller) GetMinStaleness(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getMinStaleness")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetMinStaleness is a free data retrieval call binding the contract method 0x29f05976.
//
// Solidity: function getMinStaleness() view returns(uint256)
func (_SuperGovernor *SuperGovernorSession) GetMinStaleness() (*big.Int, error) {
	return _SuperGovernor.Contract.GetMinStaleness(&_SuperGovernor.CallOpts)
}

// GetMinStaleness is a free data retrieval call binding the contract method 0x29f05976.
//
// Solidity: function getMinStaleness() view returns(uint256)
func (_SuperGovernor *SuperGovernorCallerSession) GetMinStaleness() (*big.Int, error) {
	return _SuperGovernor.Contract.GetMinStaleness(&_SuperGovernor.CallOpts)
}

// GetPPSOracleQuorum is a free data retrieval call binding the contract method 0xdf6aaf96.
//
// Solidity: function getPPSOracleQuorum() view returns(uint256)
func (_SuperGovernor *SuperGovernorCaller) GetPPSOracleQuorum(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getPPSOracleQuorum")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetPPSOracleQuorum is a free data retrieval call binding the contract method 0xdf6aaf96.
//
// Solidity: function getPPSOracleQuorum() view returns(uint256)
func (_SuperGovernor *SuperGovernorSession) GetPPSOracleQuorum() (*big.Int, error) {
	return _SuperGovernor.Contract.GetPPSOracleQuorum(&_SuperGovernor.CallOpts)
}

// GetPPSOracleQuorum is a free data retrieval call binding the contract method 0xdf6aaf96.
//
// Solidity: function getPPSOracleQuorum() view returns(uint256)
func (_SuperGovernor *SuperGovernorCallerSession) GetPPSOracleQuorum() (*big.Int, error) {
	return _SuperGovernor.Contract.GetPPSOracleQuorum(&_SuperGovernor.CallOpts)
}

// GetProposedActivePPSOracle is a free data retrieval call binding the contract method 0xa86ed388.
//
// Solidity: function getProposedActivePPSOracle() view returns(address proposedOracle, uint256 effectiveTime)
func (_SuperGovernor *SuperGovernorCaller) GetProposedActivePPSOracle(opts *bind.CallOpts) (struct {
	ProposedOracle common.Address
	EffectiveTime  *big.Int
}, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getProposedActivePPSOracle")

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
func (_SuperGovernor *SuperGovernorSession) GetProposedActivePPSOracle() (struct {
	ProposedOracle common.Address
	EffectiveTime  *big.Int
}, error) {
	return _SuperGovernor.Contract.GetProposedActivePPSOracle(&_SuperGovernor.CallOpts)
}

// GetProposedActivePPSOracle is a free data retrieval call binding the contract method 0xa86ed388.
//
// Solidity: function getProposedActivePPSOracle() view returns(address proposedOracle, uint256 effectiveTime)
func (_SuperGovernor *SuperGovernorCallerSession) GetProposedActivePPSOracle() (struct {
	ProposedOracle common.Address
	EffectiveTime  *big.Int
}, error) {
	return _SuperGovernor.Contract.GetProposedActivePPSOracle(&_SuperGovernor.CallOpts)
}

// GetProposedMinStaleness is a free data retrieval call binding the contract method 0xe8422432.
//
// Solidity: function getProposedMinStaleness() view returns(uint256 proposedMinStaleness, uint256 effectiveTime)
func (_SuperGovernor *SuperGovernorCaller) GetProposedMinStaleness(opts *bind.CallOpts) (struct {
	ProposedMinStaleness *big.Int
	EffectiveTime        *big.Int
}, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getProposedMinStaleness")

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
func (_SuperGovernor *SuperGovernorSession) GetProposedMinStaleness() (struct {
	ProposedMinStaleness *big.Int
	EffectiveTime        *big.Int
}, error) {
	return _SuperGovernor.Contract.GetProposedMinStaleness(&_SuperGovernor.CallOpts)
}

// GetProposedMinStaleness is a free data retrieval call binding the contract method 0xe8422432.
//
// Solidity: function getProposedMinStaleness() view returns(uint256 proposedMinStaleness, uint256 effectiveTime)
func (_SuperGovernor *SuperGovernorCallerSession) GetProposedMinStaleness() (struct {
	ProposedMinStaleness *big.Int
	EffectiveTime        *big.Int
}, error) {
	return _SuperGovernor.Contract.GetProposedMinStaleness(&_SuperGovernor.CallOpts)
}

// GetProposedSuperBankHookMerkleRoot is a free data retrieval call binding the contract method 0x43844de6.
//
// Solidity: function getProposedSuperBankHookMerkleRoot(address hook) view returns(bytes32 proposedRoot, uint256 effectiveTime)
func (_SuperGovernor *SuperGovernorCaller) GetProposedSuperBankHookMerkleRoot(opts *bind.CallOpts, hook common.Address) (struct {
	ProposedRoot  [32]byte
	EffectiveTime *big.Int
}, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getProposedSuperBankHookMerkleRoot", hook)

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
func (_SuperGovernor *SuperGovernorSession) GetProposedSuperBankHookMerkleRoot(hook common.Address) (struct {
	ProposedRoot  [32]byte
	EffectiveTime *big.Int
}, error) {
	return _SuperGovernor.Contract.GetProposedSuperBankHookMerkleRoot(&_SuperGovernor.CallOpts, hook)
}

// GetProposedSuperBankHookMerkleRoot is a free data retrieval call binding the contract method 0x43844de6.
//
// Solidity: function getProposedSuperBankHookMerkleRoot(address hook) view returns(bytes32 proposedRoot, uint256 effectiveTime)
func (_SuperGovernor *SuperGovernorCallerSession) GetProposedSuperBankHookMerkleRoot(hook common.Address) (struct {
	ProposedRoot  [32]byte
	EffectiveTime *big.Int
}, error) {
	return _SuperGovernor.Contract.GetProposedSuperBankHookMerkleRoot(&_SuperGovernor.CallOpts, hook)
}

// GetProposedUpkeepPaymentsStatus is a free data retrieval call binding the contract method 0x57b8b13d.
//
// Solidity: function getProposedUpkeepPaymentsStatus() view returns(bool enabled, uint256 effectiveTime)
func (_SuperGovernor *SuperGovernorCaller) GetProposedUpkeepPaymentsStatus(opts *bind.CallOpts) (struct {
	Enabled       bool
	EffectiveTime *big.Int
}, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getProposedUpkeepPaymentsStatus")

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
func (_SuperGovernor *SuperGovernorSession) GetProposedUpkeepPaymentsStatus() (struct {
	Enabled       bool
	EffectiveTime *big.Int
}, error) {
	return _SuperGovernor.Contract.GetProposedUpkeepPaymentsStatus(&_SuperGovernor.CallOpts)
}

// GetProposedUpkeepPaymentsStatus is a free data retrieval call binding the contract method 0x57b8b13d.
//
// Solidity: function getProposedUpkeepPaymentsStatus() view returns(bool enabled, uint256 effectiveTime)
func (_SuperGovernor *SuperGovernorCallerSession) GetProposedUpkeepPaymentsStatus() (struct {
	Enabled       bool
	EffectiveTime *big.Int
}, error) {
	return _SuperGovernor.Contract.GetProposedUpkeepPaymentsStatus(&_SuperGovernor.CallOpts)
}

// GetRegisteredHooks is a free data retrieval call binding the contract method 0x841b0175.
//
// Solidity: function getRegisteredHooks() view returns(address[])
func (_SuperGovernor *SuperGovernorCaller) GetRegisteredHooks(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getRegisteredHooks")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetRegisteredHooks is a free data retrieval call binding the contract method 0x841b0175.
//
// Solidity: function getRegisteredHooks() view returns(address[])
func (_SuperGovernor *SuperGovernorSession) GetRegisteredHooks() ([]common.Address, error) {
	return _SuperGovernor.Contract.GetRegisteredHooks(&_SuperGovernor.CallOpts)
}

// GetRegisteredHooks is a free data retrieval call binding the contract method 0x841b0175.
//
// Solidity: function getRegisteredHooks() view returns(address[])
func (_SuperGovernor *SuperGovernorCallerSession) GetRegisteredHooks() ([]common.Address, error) {
	return _SuperGovernor.Contract.GetRegisteredHooks(&_SuperGovernor.CallOpts)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_SuperGovernor *SuperGovernorCaller) GetRoleAdmin(opts *bind.CallOpts, role [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getRoleAdmin", role)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_SuperGovernor *SuperGovernorSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _SuperGovernor.Contract.GetRoleAdmin(&_SuperGovernor.CallOpts, role)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_SuperGovernor *SuperGovernorCallerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _SuperGovernor.Contract.GetRoleAdmin(&_SuperGovernor.CallOpts, role)
}

// GetSuperBankHookMerkleRoot is a free data retrieval call binding the contract method 0xf43526f4.
//
// Solidity: function getSuperBankHookMerkleRoot(address hook) view returns(bytes32)
func (_SuperGovernor *SuperGovernorCaller) GetSuperBankHookMerkleRoot(opts *bind.CallOpts, hook common.Address) ([32]byte, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getSuperBankHookMerkleRoot", hook)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetSuperBankHookMerkleRoot is a free data retrieval call binding the contract method 0xf43526f4.
//
// Solidity: function getSuperBankHookMerkleRoot(address hook) view returns(bytes32)
func (_SuperGovernor *SuperGovernorSession) GetSuperBankHookMerkleRoot(hook common.Address) ([32]byte, error) {
	return _SuperGovernor.Contract.GetSuperBankHookMerkleRoot(&_SuperGovernor.CallOpts, hook)
}

// GetSuperBankHookMerkleRoot is a free data retrieval call binding the contract method 0xf43526f4.
//
// Solidity: function getSuperBankHookMerkleRoot(address hook) view returns(bytes32)
func (_SuperGovernor *SuperGovernorCallerSession) GetSuperBankHookMerkleRoot(hook common.Address) ([32]byte, error) {
	return _SuperGovernor.Contract.GetSuperBankHookMerkleRoot(&_SuperGovernor.CallOpts, hook)
}

// GetSuperformManagersCount is a free data retrieval call binding the contract method 0xcc8bb5e4.
//
// Solidity: function getSuperformManagersCount() view returns(uint256)
func (_SuperGovernor *SuperGovernorCaller) GetSuperformManagersCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getSuperformManagersCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetSuperformManagersCount is a free data retrieval call binding the contract method 0xcc8bb5e4.
//
// Solidity: function getSuperformManagersCount() view returns(uint256)
func (_SuperGovernor *SuperGovernorSession) GetSuperformManagersCount() (*big.Int, error) {
	return _SuperGovernor.Contract.GetSuperformManagersCount(&_SuperGovernor.CallOpts)
}

// GetSuperformManagersCount is a free data retrieval call binding the contract method 0xcc8bb5e4.
//
// Solidity: function getSuperformManagersCount() view returns(uint256)
func (_SuperGovernor *SuperGovernorCallerSession) GetSuperformManagersCount() (*big.Int, error) {
	return _SuperGovernor.Contract.GetSuperformManagersCount(&_SuperGovernor.CallOpts)
}

// GetUpkeepCostPerSingleUpdate is a free data retrieval call binding the contract method 0x92f16278.
//
// Solidity: function getUpkeepCostPerSingleUpdate(address oracle_) view returns(uint256)
func (_SuperGovernor *SuperGovernorCaller) GetUpkeepCostPerSingleUpdate(opts *bind.CallOpts, oracle_ common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getUpkeepCostPerSingleUpdate", oracle_)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetUpkeepCostPerSingleUpdate is a free data retrieval call binding the contract method 0x92f16278.
//
// Solidity: function getUpkeepCostPerSingleUpdate(address oracle_) view returns(uint256)
func (_SuperGovernor *SuperGovernorSession) GetUpkeepCostPerSingleUpdate(oracle_ common.Address) (*big.Int, error) {
	return _SuperGovernor.Contract.GetUpkeepCostPerSingleUpdate(&_SuperGovernor.CallOpts, oracle_)
}

// GetUpkeepCostPerSingleUpdate is a free data retrieval call binding the contract method 0x92f16278.
//
// Solidity: function getUpkeepCostPerSingleUpdate(address oracle_) view returns(uint256)
func (_SuperGovernor *SuperGovernorCallerSession) GetUpkeepCostPerSingleUpdate(oracle_ common.Address) (*big.Int, error) {
	return _SuperGovernor.Contract.GetUpkeepCostPerSingleUpdate(&_SuperGovernor.CallOpts, oracle_)
}

// GetValidatorAt is a free data retrieval call binding the contract method 0x9a000e5b.
//
// Solidity: function getValidatorAt(uint256 index) view returns(address)
func (_SuperGovernor *SuperGovernorCaller) GetValidatorAt(opts *bind.CallOpts, index *big.Int) (common.Address, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getValidatorAt", index)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetValidatorAt is a free data retrieval call binding the contract method 0x9a000e5b.
//
// Solidity: function getValidatorAt(uint256 index) view returns(address)
func (_SuperGovernor *SuperGovernorSession) GetValidatorAt(index *big.Int) (common.Address, error) {
	return _SuperGovernor.Contract.GetValidatorAt(&_SuperGovernor.CallOpts, index)
}

// GetValidatorAt is a free data retrieval call binding the contract method 0x9a000e5b.
//
// Solidity: function getValidatorAt(uint256 index) view returns(address)
func (_SuperGovernor *SuperGovernorCallerSession) GetValidatorAt(index *big.Int) (common.Address, error) {
	return _SuperGovernor.Contract.GetValidatorAt(&_SuperGovernor.CallOpts, index)
}

// GetValidatorConfigVersion is a free data retrieval call binding the contract method 0x5bd68dbc.
//
// Solidity: function getValidatorConfigVersion() view returns(uint256)
func (_SuperGovernor *SuperGovernorCaller) GetValidatorConfigVersion(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getValidatorConfigVersion")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetValidatorConfigVersion is a free data retrieval call binding the contract method 0x5bd68dbc.
//
// Solidity: function getValidatorConfigVersion() view returns(uint256)
func (_SuperGovernor *SuperGovernorSession) GetValidatorConfigVersion() (*big.Int, error) {
	return _SuperGovernor.Contract.GetValidatorConfigVersion(&_SuperGovernor.CallOpts)
}

// GetValidatorConfigVersion is a free data retrieval call binding the contract method 0x5bd68dbc.
//
// Solidity: function getValidatorConfigVersion() view returns(uint256)
func (_SuperGovernor *SuperGovernorCallerSession) GetValidatorConfigVersion() (*big.Int, error) {
	return _SuperGovernor.Contract.GetValidatorConfigVersion(&_SuperGovernor.CallOpts)
}

// GetValidators is a free data retrieval call binding the contract method 0xb7ab4db5.
//
// Solidity: function getValidators() view returns(address[])
func (_SuperGovernor *SuperGovernorCaller) GetValidators(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getValidators")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetValidators is a free data retrieval call binding the contract method 0xb7ab4db5.
//
// Solidity: function getValidators() view returns(address[])
func (_SuperGovernor *SuperGovernorSession) GetValidators() ([]common.Address, error) {
	return _SuperGovernor.Contract.GetValidators(&_SuperGovernor.CallOpts)
}

// GetValidators is a free data retrieval call binding the contract method 0xb7ab4db5.
//
// Solidity: function getValidators() view returns(address[])
func (_SuperGovernor *SuperGovernorCallerSession) GetValidators() ([]common.Address, error) {
	return _SuperGovernor.Contract.GetValidators(&_SuperGovernor.CallOpts)
}

// GetValidatorsCount is a free data retrieval call binding the contract method 0x27498240.
//
// Solidity: function getValidatorsCount() view returns(uint256)
func (_SuperGovernor *SuperGovernorCaller) GetValidatorsCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "getValidatorsCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetValidatorsCount is a free data retrieval call binding the contract method 0x27498240.
//
// Solidity: function getValidatorsCount() view returns(uint256)
func (_SuperGovernor *SuperGovernorSession) GetValidatorsCount() (*big.Int, error) {
	return _SuperGovernor.Contract.GetValidatorsCount(&_SuperGovernor.CallOpts)
}

// GetValidatorsCount is a free data retrieval call binding the contract method 0x27498240.
//
// Solidity: function getValidatorsCount() view returns(uint256)
func (_SuperGovernor *SuperGovernorCallerSession) GetValidatorsCount() (*big.Int, error) {
	return _SuperGovernor.Contract.GetValidatorsCount(&_SuperGovernor.CallOpts)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_SuperGovernor *SuperGovernorCaller) HasRole(opts *bind.CallOpts, role [32]byte, account common.Address) (bool, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "hasRole", role, account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_SuperGovernor *SuperGovernorSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _SuperGovernor.Contract.HasRole(&_SuperGovernor.CallOpts, role, account)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_SuperGovernor *SuperGovernorCallerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _SuperGovernor.Contract.HasRole(&_SuperGovernor.CallOpts, role, account)
}

// IsActivePPSOracle is a free data retrieval call binding the contract method 0xfd6f0fc2.
//
// Solidity: function isActivePPSOracle(address oracle) view returns(bool)
func (_SuperGovernor *SuperGovernorCaller) IsActivePPSOracle(opts *bind.CallOpts, oracle common.Address) (bool, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "isActivePPSOracle", oracle)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsActivePPSOracle is a free data retrieval call binding the contract method 0xfd6f0fc2.
//
// Solidity: function isActivePPSOracle(address oracle) view returns(bool)
func (_SuperGovernor *SuperGovernorSession) IsActivePPSOracle(oracle common.Address) (bool, error) {
	return _SuperGovernor.Contract.IsActivePPSOracle(&_SuperGovernor.CallOpts, oracle)
}

// IsActivePPSOracle is a free data retrieval call binding the contract method 0xfd6f0fc2.
//
// Solidity: function isActivePPSOracle(address oracle) view returns(bool)
func (_SuperGovernor *SuperGovernorCallerSession) IsActivePPSOracle(oracle common.Address) (bool, error) {
	return _SuperGovernor.Contract.IsActivePPSOracle(&_SuperGovernor.CallOpts, oracle)
}

// IsExecutor is a free data retrieval call binding the contract method 0xdebfda30.
//
// Solidity: function isExecutor(address executor) view returns(bool)
func (_SuperGovernor *SuperGovernorCaller) IsExecutor(opts *bind.CallOpts, executor common.Address) (bool, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "isExecutor", executor)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsExecutor is a free data retrieval call binding the contract method 0xdebfda30.
//
// Solidity: function isExecutor(address executor) view returns(bool)
func (_SuperGovernor *SuperGovernorSession) IsExecutor(executor common.Address) (bool, error) {
	return _SuperGovernor.Contract.IsExecutor(&_SuperGovernor.CallOpts, executor)
}

// IsExecutor is a free data retrieval call binding the contract method 0xdebfda30.
//
// Solidity: function isExecutor(address executor) view returns(bool)
func (_SuperGovernor *SuperGovernorCallerSession) IsExecutor(executor common.Address) (bool, error) {
	return _SuperGovernor.Contract.IsExecutor(&_SuperGovernor.CallOpts, executor)
}

// IsGuardian is a free data retrieval call binding the contract method 0x0c68ba21.
//
// Solidity: function isGuardian(address guardian) view returns(bool)
func (_SuperGovernor *SuperGovernorCaller) IsGuardian(opts *bind.CallOpts, guardian common.Address) (bool, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "isGuardian", guardian)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsGuardian is a free data retrieval call binding the contract method 0x0c68ba21.
//
// Solidity: function isGuardian(address guardian) view returns(bool)
func (_SuperGovernor *SuperGovernorSession) IsGuardian(guardian common.Address) (bool, error) {
	return _SuperGovernor.Contract.IsGuardian(&_SuperGovernor.CallOpts, guardian)
}

// IsGuardian is a free data retrieval call binding the contract method 0x0c68ba21.
//
// Solidity: function isGuardian(address guardian) view returns(bool)
func (_SuperGovernor *SuperGovernorCallerSession) IsGuardian(guardian common.Address) (bool, error) {
	return _SuperGovernor.Contract.IsGuardian(&_SuperGovernor.CallOpts, guardian)
}

// IsHookRegistered is a free data retrieval call binding the contract method 0x0cbad00c.
//
// Solidity: function isHookRegistered(address hook) view returns(bool)
func (_SuperGovernor *SuperGovernorCaller) IsHookRegistered(opts *bind.CallOpts, hook common.Address) (bool, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "isHookRegistered", hook)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsHookRegistered is a free data retrieval call binding the contract method 0x0cbad00c.
//
// Solidity: function isHookRegistered(address hook) view returns(bool)
func (_SuperGovernor *SuperGovernorSession) IsHookRegistered(hook common.Address) (bool, error) {
	return _SuperGovernor.Contract.IsHookRegistered(&_SuperGovernor.CallOpts, hook)
}

// IsHookRegistered is a free data retrieval call binding the contract method 0x0cbad00c.
//
// Solidity: function isHookRegistered(address hook) view returns(bool)
func (_SuperGovernor *SuperGovernorCallerSession) IsHookRegistered(hook common.Address) (bool, error) {
	return _SuperGovernor.Contract.IsHookRegistered(&_SuperGovernor.CallOpts, hook)
}

// IsManagerTakeoverFrozen is a free data retrieval call binding the contract method 0x5721145f.
//
// Solidity: function isManagerTakeoverFrozen() view returns(bool)
func (_SuperGovernor *SuperGovernorCaller) IsManagerTakeoverFrozen(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "isManagerTakeoverFrozen")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsManagerTakeoverFrozen is a free data retrieval call binding the contract method 0x5721145f.
//
// Solidity: function isManagerTakeoverFrozen() view returns(bool)
func (_SuperGovernor *SuperGovernorSession) IsManagerTakeoverFrozen() (bool, error) {
	return _SuperGovernor.Contract.IsManagerTakeoverFrozen(&_SuperGovernor.CallOpts)
}

// IsManagerTakeoverFrozen is a free data retrieval call binding the contract method 0x5721145f.
//
// Solidity: function isManagerTakeoverFrozen() view returns(bool)
func (_SuperGovernor *SuperGovernorCallerSession) IsManagerTakeoverFrozen() (bool, error) {
	return _SuperGovernor.Contract.IsManagerTakeoverFrozen(&_SuperGovernor.CallOpts)
}

// IsSuperformManager is a free data retrieval call binding the contract method 0xae4d256e.
//
// Solidity: function isSuperformManager(address manager) view returns(bool isSuperform)
func (_SuperGovernor *SuperGovernorCaller) IsSuperformManager(opts *bind.CallOpts, manager common.Address) (bool, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "isSuperformManager", manager)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsSuperformManager is a free data retrieval call binding the contract method 0xae4d256e.
//
// Solidity: function isSuperformManager(address manager) view returns(bool isSuperform)
func (_SuperGovernor *SuperGovernorSession) IsSuperformManager(manager common.Address) (bool, error) {
	return _SuperGovernor.Contract.IsSuperformManager(&_SuperGovernor.CallOpts, manager)
}

// IsSuperformManager is a free data retrieval call binding the contract method 0xae4d256e.
//
// Solidity: function isSuperformManager(address manager) view returns(bool isSuperform)
func (_SuperGovernor *SuperGovernorCallerSession) IsSuperformManager(manager common.Address) (bool, error) {
	return _SuperGovernor.Contract.IsSuperformManager(&_SuperGovernor.CallOpts, manager)
}

// IsUpkeepPaymentsEnabled is a free data retrieval call binding the contract method 0x3ef15059.
//
// Solidity: function isUpkeepPaymentsEnabled() view returns(bool enabled)
func (_SuperGovernor *SuperGovernorCaller) IsUpkeepPaymentsEnabled(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "isUpkeepPaymentsEnabled")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsUpkeepPaymentsEnabled is a free data retrieval call binding the contract method 0x3ef15059.
//
// Solidity: function isUpkeepPaymentsEnabled() view returns(bool enabled)
func (_SuperGovernor *SuperGovernorSession) IsUpkeepPaymentsEnabled() (bool, error) {
	return _SuperGovernor.Contract.IsUpkeepPaymentsEnabled(&_SuperGovernor.CallOpts)
}

// IsUpkeepPaymentsEnabled is a free data retrieval call binding the contract method 0x3ef15059.
//
// Solidity: function isUpkeepPaymentsEnabled() view returns(bool enabled)
func (_SuperGovernor *SuperGovernorCallerSession) IsUpkeepPaymentsEnabled() (bool, error) {
	return _SuperGovernor.Contract.IsUpkeepPaymentsEnabled(&_SuperGovernor.CallOpts)
}

// IsValidator is a free data retrieval call binding the contract method 0xfacd743b.
//
// Solidity: function isValidator(address validator) view returns(bool)
func (_SuperGovernor *SuperGovernorCaller) IsValidator(opts *bind.CallOpts, validator common.Address) (bool, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "isValidator", validator)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsValidator is a free data retrieval call binding the contract method 0xfacd743b.
//
// Solidity: function isValidator(address validator) view returns(bool)
func (_SuperGovernor *SuperGovernorSession) IsValidator(validator common.Address) (bool, error) {
	return _SuperGovernor.Contract.IsValidator(&_SuperGovernor.CallOpts, validator)
}

// IsValidator is a free data retrieval call binding the contract method 0xfacd743b.
//
// Solidity: function isValidator(address validator) view returns(bool)
func (_SuperGovernor *SuperGovernorCallerSession) IsValidator(validator common.Address) (bool, error) {
	return _SuperGovernor.Contract.IsValidator(&_SuperGovernor.CallOpts, validator)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_SuperGovernor *SuperGovernorCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _SuperGovernor.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_SuperGovernor *SuperGovernorSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _SuperGovernor.Contract.SupportsInterface(&_SuperGovernor.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_SuperGovernor *SuperGovernorCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _SuperGovernor.Contract.SupportsInterface(&_SuperGovernor.CallOpts, interfaceId)
}

// AddExecutor is a paid mutator transaction binding the contract method 0x1f5a0bbe.
//
// Solidity: function addExecutor(address executor) returns()
func (_SuperGovernor *SuperGovernorTransactor) AddExecutor(opts *bind.TransactOpts, executor common.Address) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "addExecutor", executor)
}

// AddExecutor is a paid mutator transaction binding the contract method 0x1f5a0bbe.
//
// Solidity: function addExecutor(address executor) returns()
func (_SuperGovernor *SuperGovernorSession) AddExecutor(executor common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.AddExecutor(&_SuperGovernor.TransactOpts, executor)
}

// AddExecutor is a paid mutator transaction binding the contract method 0x1f5a0bbe.
//
// Solidity: function addExecutor(address executor) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) AddExecutor(executor common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.AddExecutor(&_SuperGovernor.TransactOpts, executor)
}

// AddSuperformManager is a paid mutator transaction binding the contract method 0xb291fdf3.
//
// Solidity: function addSuperformManager(address manager) returns()
func (_SuperGovernor *SuperGovernorTransactor) AddSuperformManager(opts *bind.TransactOpts, manager common.Address) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "addSuperformManager", manager)
}

// AddSuperformManager is a paid mutator transaction binding the contract method 0xb291fdf3.
//
// Solidity: function addSuperformManager(address manager) returns()
func (_SuperGovernor *SuperGovernorSession) AddSuperformManager(manager common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.AddSuperformManager(&_SuperGovernor.TransactOpts, manager)
}

// AddSuperformManager is a paid mutator transaction binding the contract method 0xb291fdf3.
//
// Solidity: function addSuperformManager(address manager) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) AddSuperformManager(manager common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.AddSuperformManager(&_SuperGovernor.TransactOpts, manager)
}

// AddValidator is a paid mutator transaction binding the contract method 0x4d238c8e.
//
// Solidity: function addValidator(address validator) returns()
func (_SuperGovernor *SuperGovernorTransactor) AddValidator(opts *bind.TransactOpts, validator common.Address) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "addValidator", validator)
}

// AddValidator is a paid mutator transaction binding the contract method 0x4d238c8e.
//
// Solidity: function addValidator(address validator) returns()
func (_SuperGovernor *SuperGovernorSession) AddValidator(validator common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.AddValidator(&_SuperGovernor.TransactOpts, validator)
}

// AddValidator is a paid mutator transaction binding the contract method 0x4d238c8e.
//
// Solidity: function addValidator(address validator) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) AddValidator(validator common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.AddValidator(&_SuperGovernor.TransactOpts, validator)
}

// BatchSetEmergencyPrices is a paid mutator transaction binding the contract method 0x00f1131f.
//
// Solidity: function batchSetEmergencyPrices(address[] tokens_, uint256[] prices_) returns()
func (_SuperGovernor *SuperGovernorTransactor) BatchSetEmergencyPrices(opts *bind.TransactOpts, tokens_ []common.Address, prices_ []*big.Int) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "batchSetEmergencyPrices", tokens_, prices_)
}

// BatchSetEmergencyPrices is a paid mutator transaction binding the contract method 0x00f1131f.
//
// Solidity: function batchSetEmergencyPrices(address[] tokens_, uint256[] prices_) returns()
func (_SuperGovernor *SuperGovernorSession) BatchSetEmergencyPrices(tokens_ []common.Address, prices_ []*big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.BatchSetEmergencyPrices(&_SuperGovernor.TransactOpts, tokens_, prices_)
}

// BatchSetEmergencyPrices is a paid mutator transaction binding the contract method 0x00f1131f.
//
// Solidity: function batchSetEmergencyPrices(address[] tokens_, uint256[] prices_) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) BatchSetEmergencyPrices(tokens_ []common.Address, prices_ []*big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.BatchSetEmergencyPrices(&_SuperGovernor.TransactOpts, tokens_, prices_)
}

// BatchSetOracleUptimeFeed is a paid mutator transaction binding the contract method 0x52ad8b00.
//
// Solidity: function batchSetOracleUptimeFeed(address[] dataOracles_, address[] uptimeOracles_, uint256[] gracePeriods_) returns()
func (_SuperGovernor *SuperGovernorTransactor) BatchSetOracleUptimeFeed(opts *bind.TransactOpts, dataOracles_ []common.Address, uptimeOracles_ []common.Address, gracePeriods_ []*big.Int) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "batchSetOracleUptimeFeed", dataOracles_, uptimeOracles_, gracePeriods_)
}

// BatchSetOracleUptimeFeed is a paid mutator transaction binding the contract method 0x52ad8b00.
//
// Solidity: function batchSetOracleUptimeFeed(address[] dataOracles_, address[] uptimeOracles_, uint256[] gracePeriods_) returns()
func (_SuperGovernor *SuperGovernorSession) BatchSetOracleUptimeFeed(dataOracles_ []common.Address, uptimeOracles_ []common.Address, gracePeriods_ []*big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.BatchSetOracleUptimeFeed(&_SuperGovernor.TransactOpts, dataOracles_, uptimeOracles_, gracePeriods_)
}

// BatchSetOracleUptimeFeed is a paid mutator transaction binding the contract method 0x52ad8b00.
//
// Solidity: function batchSetOracleUptimeFeed(address[] dataOracles_, address[] uptimeOracles_, uint256[] gracePeriods_) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) BatchSetOracleUptimeFeed(dataOracles_ []common.Address, uptimeOracles_ []common.Address, gracePeriods_ []*big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.BatchSetOracleUptimeFeed(&_SuperGovernor.TransactOpts, dataOracles_, uptimeOracles_, gracePeriods_)
}

// ChangeHooksRootUpdateTimelock is a paid mutator transaction binding the contract method 0x9649933b.
//
// Solidity: function changeHooksRootUpdateTimelock(uint256 newTimelock) returns()
func (_SuperGovernor *SuperGovernorTransactor) ChangeHooksRootUpdateTimelock(opts *bind.TransactOpts, newTimelock *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "changeHooksRootUpdateTimelock", newTimelock)
}

// ChangeHooksRootUpdateTimelock is a paid mutator transaction binding the contract method 0x9649933b.
//
// Solidity: function changeHooksRootUpdateTimelock(uint256 newTimelock) returns()
func (_SuperGovernor *SuperGovernorSession) ChangeHooksRootUpdateTimelock(newTimelock *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ChangeHooksRootUpdateTimelock(&_SuperGovernor.TransactOpts, newTimelock)
}

// ChangeHooksRootUpdateTimelock is a paid mutator transaction binding the contract method 0x9649933b.
//
// Solidity: function changeHooksRootUpdateTimelock(uint256 newTimelock) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) ChangeHooksRootUpdateTimelock(newTimelock *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ChangeHooksRootUpdateTimelock(&_SuperGovernor.TransactOpts, newTimelock)
}

// ChangePrimaryManager is a paid mutator transaction binding the contract method 0x906811e0.
//
// Solidity: function changePrimaryManager(address strategy, address newManager) returns()
func (_SuperGovernor *SuperGovernorTransactor) ChangePrimaryManager(opts *bind.TransactOpts, strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "changePrimaryManager", strategy, newManager)
}

// ChangePrimaryManager is a paid mutator transaction binding the contract method 0x906811e0.
//
// Solidity: function changePrimaryManager(address strategy, address newManager) returns()
func (_SuperGovernor *SuperGovernorSession) ChangePrimaryManager(strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ChangePrimaryManager(&_SuperGovernor.TransactOpts, strategy, newManager)
}

// ChangePrimaryManager is a paid mutator transaction binding the contract method 0x906811e0.
//
// Solidity: function changePrimaryManager(address strategy, address newManager) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) ChangePrimaryManager(strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ChangePrimaryManager(&_SuperGovernor.TransactOpts, strategy, newManager)
}

// ExecuteActivePPSOracleChange is a paid mutator transaction binding the contract method 0xf1031b4e.
//
// Solidity: function executeActivePPSOracleChange() returns()
func (_SuperGovernor *SuperGovernorTransactor) ExecuteActivePPSOracleChange(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "executeActivePPSOracleChange")
}

// ExecuteActivePPSOracleChange is a paid mutator transaction binding the contract method 0xf1031b4e.
//
// Solidity: function executeActivePPSOracleChange() returns()
func (_SuperGovernor *SuperGovernorSession) ExecuteActivePPSOracleChange() (*types.Transaction, error) {
	return _SuperGovernor.Contract.ExecuteActivePPSOracleChange(&_SuperGovernor.TransactOpts)
}

// ExecuteActivePPSOracleChange is a paid mutator transaction binding the contract method 0xf1031b4e.
//
// Solidity: function executeActivePPSOracleChange() returns()
func (_SuperGovernor *SuperGovernorTransactorSession) ExecuteActivePPSOracleChange() (*types.Transaction, error) {
	return _SuperGovernor.Contract.ExecuteActivePPSOracleChange(&_SuperGovernor.TransactOpts)
}

// ExecuteFeeUpdate is a paid mutator transaction binding the contract method 0x365d6bf3.
//
// Solidity: function executeFeeUpdate(uint8 feeType) returns()
func (_SuperGovernor *SuperGovernorTransactor) ExecuteFeeUpdate(opts *bind.TransactOpts, feeType uint8) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "executeFeeUpdate", feeType)
}

// ExecuteFeeUpdate is a paid mutator transaction binding the contract method 0x365d6bf3.
//
// Solidity: function executeFeeUpdate(uint8 feeType) returns()
func (_SuperGovernor *SuperGovernorSession) ExecuteFeeUpdate(feeType uint8) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ExecuteFeeUpdate(&_SuperGovernor.TransactOpts, feeType)
}

// ExecuteFeeUpdate is a paid mutator transaction binding the contract method 0x365d6bf3.
//
// Solidity: function executeFeeUpdate(uint8 feeType) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) ExecuteFeeUpdate(feeType uint8) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ExecuteFeeUpdate(&_SuperGovernor.TransactOpts, feeType)
}

// ExecuteMinStalenesChange is a paid mutator transaction binding the contract method 0xdf767d13.
//
// Solidity: function executeMinStalenesChange() returns()
func (_SuperGovernor *SuperGovernorTransactor) ExecuteMinStalenesChange(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "executeMinStalenesChange")
}

// ExecuteMinStalenesChange is a paid mutator transaction binding the contract method 0xdf767d13.
//
// Solidity: function executeMinStalenesChange() returns()
func (_SuperGovernor *SuperGovernorSession) ExecuteMinStalenesChange() (*types.Transaction, error) {
	return _SuperGovernor.Contract.ExecuteMinStalenesChange(&_SuperGovernor.TransactOpts)
}

// ExecuteMinStalenesChange is a paid mutator transaction binding the contract method 0xdf767d13.
//
// Solidity: function executeMinStalenesChange() returns()
func (_SuperGovernor *SuperGovernorTransactorSession) ExecuteMinStalenesChange() (*types.Transaction, error) {
	return _SuperGovernor.Contract.ExecuteMinStalenesChange(&_SuperGovernor.TransactOpts)
}

// ExecuteOracleProviderRemoval is a paid mutator transaction binding the contract method 0x5f0ce3d1.
//
// Solidity: function executeOracleProviderRemoval() returns()
func (_SuperGovernor *SuperGovernorTransactor) ExecuteOracleProviderRemoval(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "executeOracleProviderRemoval")
}

// ExecuteOracleProviderRemoval is a paid mutator transaction binding the contract method 0x5f0ce3d1.
//
// Solidity: function executeOracleProviderRemoval() returns()
func (_SuperGovernor *SuperGovernorSession) ExecuteOracleProviderRemoval() (*types.Transaction, error) {
	return _SuperGovernor.Contract.ExecuteOracleProviderRemoval(&_SuperGovernor.TransactOpts)
}

// ExecuteOracleProviderRemoval is a paid mutator transaction binding the contract method 0x5f0ce3d1.
//
// Solidity: function executeOracleProviderRemoval() returns()
func (_SuperGovernor *SuperGovernorTransactorSession) ExecuteOracleProviderRemoval() (*types.Transaction, error) {
	return _SuperGovernor.Contract.ExecuteOracleProviderRemoval(&_SuperGovernor.TransactOpts)
}

// ExecuteOracleUpdate is a paid mutator transaction binding the contract method 0x45e62881.
//
// Solidity: function executeOracleUpdate() returns()
func (_SuperGovernor *SuperGovernorTransactor) ExecuteOracleUpdate(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "executeOracleUpdate")
}

// ExecuteOracleUpdate is a paid mutator transaction binding the contract method 0x45e62881.
//
// Solidity: function executeOracleUpdate() returns()
func (_SuperGovernor *SuperGovernorSession) ExecuteOracleUpdate() (*types.Transaction, error) {
	return _SuperGovernor.Contract.ExecuteOracleUpdate(&_SuperGovernor.TransactOpts)
}

// ExecuteOracleUpdate is a paid mutator transaction binding the contract method 0x45e62881.
//
// Solidity: function executeOracleUpdate() returns()
func (_SuperGovernor *SuperGovernorTransactorSession) ExecuteOracleUpdate() (*types.Transaction, error) {
	return _SuperGovernor.Contract.ExecuteOracleUpdate(&_SuperGovernor.TransactOpts)
}

// ExecuteSuperBankHookMerkleRootUpdate is a paid mutator transaction binding the contract method 0x290c49a1.
//
// Solidity: function executeSuperBankHookMerkleRootUpdate(address hook) returns()
func (_SuperGovernor *SuperGovernorTransactor) ExecuteSuperBankHookMerkleRootUpdate(opts *bind.TransactOpts, hook common.Address) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "executeSuperBankHookMerkleRootUpdate", hook)
}

// ExecuteSuperBankHookMerkleRootUpdate is a paid mutator transaction binding the contract method 0x290c49a1.
//
// Solidity: function executeSuperBankHookMerkleRootUpdate(address hook) returns()
func (_SuperGovernor *SuperGovernorSession) ExecuteSuperBankHookMerkleRootUpdate(hook common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ExecuteSuperBankHookMerkleRootUpdate(&_SuperGovernor.TransactOpts, hook)
}

// ExecuteSuperBankHookMerkleRootUpdate is a paid mutator transaction binding the contract method 0x290c49a1.
//
// Solidity: function executeSuperBankHookMerkleRootUpdate(address hook) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) ExecuteSuperBankHookMerkleRootUpdate(hook common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ExecuteSuperBankHookMerkleRootUpdate(&_SuperGovernor.TransactOpts, hook)
}

// ExecuteUpkeepClaim is a paid mutator transaction binding the contract method 0x3202ac23.
//
// Solidity: function executeUpkeepClaim(uint256 amount) returns()
func (_SuperGovernor *SuperGovernorTransactor) ExecuteUpkeepClaim(opts *bind.TransactOpts, amount *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "executeUpkeepClaim", amount)
}

// ExecuteUpkeepClaim is a paid mutator transaction binding the contract method 0x3202ac23.
//
// Solidity: function executeUpkeepClaim(uint256 amount) returns()
func (_SuperGovernor *SuperGovernorSession) ExecuteUpkeepClaim(amount *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ExecuteUpkeepClaim(&_SuperGovernor.TransactOpts, amount)
}

// ExecuteUpkeepClaim is a paid mutator transaction binding the contract method 0x3202ac23.
//
// Solidity: function executeUpkeepClaim(uint256 amount) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) ExecuteUpkeepClaim(amount *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ExecuteUpkeepClaim(&_SuperGovernor.TransactOpts, amount)
}

// ExecuteUpkeepPaymentsChange is a paid mutator transaction binding the contract method 0xecc3d967.
//
// Solidity: function executeUpkeepPaymentsChange() returns()
func (_SuperGovernor *SuperGovernorTransactor) ExecuteUpkeepPaymentsChange(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "executeUpkeepPaymentsChange")
}

// ExecuteUpkeepPaymentsChange is a paid mutator transaction binding the contract method 0xecc3d967.
//
// Solidity: function executeUpkeepPaymentsChange() returns()
func (_SuperGovernor *SuperGovernorSession) ExecuteUpkeepPaymentsChange() (*types.Transaction, error) {
	return _SuperGovernor.Contract.ExecuteUpkeepPaymentsChange(&_SuperGovernor.TransactOpts)
}

// ExecuteUpkeepPaymentsChange is a paid mutator transaction binding the contract method 0xecc3d967.
//
// Solidity: function executeUpkeepPaymentsChange() returns()
func (_SuperGovernor *SuperGovernorTransactorSession) ExecuteUpkeepPaymentsChange() (*types.Transaction, error) {
	return _SuperGovernor.Contract.ExecuteUpkeepPaymentsChange(&_SuperGovernor.TransactOpts)
}

// FreezeManagerTakeover is a paid mutator transaction binding the contract method 0xca774c12.
//
// Solidity: function freezeManagerTakeover() returns()
func (_SuperGovernor *SuperGovernorTransactor) FreezeManagerTakeover(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "freezeManagerTakeover")
}

// FreezeManagerTakeover is a paid mutator transaction binding the contract method 0xca774c12.
//
// Solidity: function freezeManagerTakeover() returns()
func (_SuperGovernor *SuperGovernorSession) FreezeManagerTakeover() (*types.Transaction, error) {
	return _SuperGovernor.Contract.FreezeManagerTakeover(&_SuperGovernor.TransactOpts)
}

// FreezeManagerTakeover is a paid mutator transaction binding the contract method 0xca774c12.
//
// Solidity: function freezeManagerTakeover() returns()
func (_SuperGovernor *SuperGovernorTransactorSession) FreezeManagerTakeover() (*types.Transaction, error) {
	return _SuperGovernor.Contract.FreezeManagerTakeover(&_SuperGovernor.TransactOpts)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_SuperGovernor *SuperGovernorTransactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_SuperGovernor *SuperGovernorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.GrantRole(&_SuperGovernor.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.GrantRole(&_SuperGovernor.TransactOpts, role, account)
}

// ProposeActivePPSOracle is a paid mutator transaction binding the contract method 0x1551c6c0.
//
// Solidity: function proposeActivePPSOracle(address oracle) returns()
func (_SuperGovernor *SuperGovernorTransactor) ProposeActivePPSOracle(opts *bind.TransactOpts, oracle common.Address) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "proposeActivePPSOracle", oracle)
}

// ProposeActivePPSOracle is a paid mutator transaction binding the contract method 0x1551c6c0.
//
// Solidity: function proposeActivePPSOracle(address oracle) returns()
func (_SuperGovernor *SuperGovernorSession) ProposeActivePPSOracle(oracle common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ProposeActivePPSOracle(&_SuperGovernor.TransactOpts, oracle)
}

// ProposeActivePPSOracle is a paid mutator transaction binding the contract method 0x1551c6c0.
//
// Solidity: function proposeActivePPSOracle(address oracle) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) ProposeActivePPSOracle(oracle common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ProposeActivePPSOracle(&_SuperGovernor.TransactOpts, oracle)
}

// ProposeFee is a paid mutator transaction binding the contract method 0x022e38cf.
//
// Solidity: function proposeFee(uint8 feeType, uint256 value) returns()
func (_SuperGovernor *SuperGovernorTransactor) ProposeFee(opts *bind.TransactOpts, feeType uint8, value *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "proposeFee", feeType, value)
}

// ProposeFee is a paid mutator transaction binding the contract method 0x022e38cf.
//
// Solidity: function proposeFee(uint8 feeType, uint256 value) returns()
func (_SuperGovernor *SuperGovernorSession) ProposeFee(feeType uint8, value *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ProposeFee(&_SuperGovernor.TransactOpts, feeType, value)
}

// ProposeFee is a paid mutator transaction binding the contract method 0x022e38cf.
//
// Solidity: function proposeFee(uint8 feeType, uint256 value) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) ProposeFee(feeType uint8, value *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ProposeFee(&_SuperGovernor.TransactOpts, feeType, value)
}

// ProposeGlobalHooksRoot is a paid mutator transaction binding the contract method 0xb0e5173b.
//
// Solidity: function proposeGlobalHooksRoot(bytes32 newRoot) returns()
func (_SuperGovernor *SuperGovernorTransactor) ProposeGlobalHooksRoot(opts *bind.TransactOpts, newRoot [32]byte) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "proposeGlobalHooksRoot", newRoot)
}

// ProposeGlobalHooksRoot is a paid mutator transaction binding the contract method 0xb0e5173b.
//
// Solidity: function proposeGlobalHooksRoot(bytes32 newRoot) returns()
func (_SuperGovernor *SuperGovernorSession) ProposeGlobalHooksRoot(newRoot [32]byte) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ProposeGlobalHooksRoot(&_SuperGovernor.TransactOpts, newRoot)
}

// ProposeGlobalHooksRoot is a paid mutator transaction binding the contract method 0xb0e5173b.
//
// Solidity: function proposeGlobalHooksRoot(bytes32 newRoot) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) ProposeGlobalHooksRoot(newRoot [32]byte) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ProposeGlobalHooksRoot(&_SuperGovernor.TransactOpts, newRoot)
}

// ProposeMinStaleness is a paid mutator transaction binding the contract method 0xc0c10943.
//
// Solidity: function proposeMinStaleness(uint256 newMinStaleness) returns()
func (_SuperGovernor *SuperGovernorTransactor) ProposeMinStaleness(opts *bind.TransactOpts, newMinStaleness *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "proposeMinStaleness", newMinStaleness)
}

// ProposeMinStaleness is a paid mutator transaction binding the contract method 0xc0c10943.
//
// Solidity: function proposeMinStaleness(uint256 newMinStaleness) returns()
func (_SuperGovernor *SuperGovernorSession) ProposeMinStaleness(newMinStaleness *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ProposeMinStaleness(&_SuperGovernor.TransactOpts, newMinStaleness)
}

// ProposeMinStaleness is a paid mutator transaction binding the contract method 0xc0c10943.
//
// Solidity: function proposeMinStaleness(uint256 newMinStaleness) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) ProposeMinStaleness(newMinStaleness *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ProposeMinStaleness(&_SuperGovernor.TransactOpts, newMinStaleness)
}

// ProposeSuperBankHookMerkleRoot is a paid mutator transaction binding the contract method 0x5e46e8b9.
//
// Solidity: function proposeSuperBankHookMerkleRoot(address hook, bytes32 proposedRoot) returns()
func (_SuperGovernor *SuperGovernorTransactor) ProposeSuperBankHookMerkleRoot(opts *bind.TransactOpts, hook common.Address, proposedRoot [32]byte) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "proposeSuperBankHookMerkleRoot", hook, proposedRoot)
}

// ProposeSuperBankHookMerkleRoot is a paid mutator transaction binding the contract method 0x5e46e8b9.
//
// Solidity: function proposeSuperBankHookMerkleRoot(address hook, bytes32 proposedRoot) returns()
func (_SuperGovernor *SuperGovernorSession) ProposeSuperBankHookMerkleRoot(hook common.Address, proposedRoot [32]byte) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ProposeSuperBankHookMerkleRoot(&_SuperGovernor.TransactOpts, hook, proposedRoot)
}

// ProposeSuperBankHookMerkleRoot is a paid mutator transaction binding the contract method 0x5e46e8b9.
//
// Solidity: function proposeSuperBankHookMerkleRoot(address hook, bytes32 proposedRoot) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) ProposeSuperBankHookMerkleRoot(hook common.Address, proposedRoot [32]byte) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ProposeSuperBankHookMerkleRoot(&_SuperGovernor.TransactOpts, hook, proposedRoot)
}

// ProposeUpkeepPaymentsChange is a paid mutator transaction binding the contract method 0x778f8a93.
//
// Solidity: function proposeUpkeepPaymentsChange(bool enabled) returns()
func (_SuperGovernor *SuperGovernorTransactor) ProposeUpkeepPaymentsChange(opts *bind.TransactOpts, enabled bool) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "proposeUpkeepPaymentsChange", enabled)
}

// ProposeUpkeepPaymentsChange is a paid mutator transaction binding the contract method 0x778f8a93.
//
// Solidity: function proposeUpkeepPaymentsChange(bool enabled) returns()
func (_SuperGovernor *SuperGovernorSession) ProposeUpkeepPaymentsChange(enabled bool) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ProposeUpkeepPaymentsChange(&_SuperGovernor.TransactOpts, enabled)
}

// ProposeUpkeepPaymentsChange is a paid mutator transaction binding the contract method 0x778f8a93.
//
// Solidity: function proposeUpkeepPaymentsChange(bool enabled) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) ProposeUpkeepPaymentsChange(enabled bool) (*types.Transaction, error) {
	return _SuperGovernor.Contract.ProposeUpkeepPaymentsChange(&_SuperGovernor.TransactOpts, enabled)
}

// QueueOracleProviderRemoval is a paid mutator transaction binding the contract method 0x6490305f.
//
// Solidity: function queueOracleProviderRemoval(bytes32[] providers) returns()
func (_SuperGovernor *SuperGovernorTransactor) QueueOracleProviderRemoval(opts *bind.TransactOpts, providers [][32]byte) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "queueOracleProviderRemoval", providers)
}

// QueueOracleProviderRemoval is a paid mutator transaction binding the contract method 0x6490305f.
//
// Solidity: function queueOracleProviderRemoval(bytes32[] providers) returns()
func (_SuperGovernor *SuperGovernorSession) QueueOracleProviderRemoval(providers [][32]byte) (*types.Transaction, error) {
	return _SuperGovernor.Contract.QueueOracleProviderRemoval(&_SuperGovernor.TransactOpts, providers)
}

// QueueOracleProviderRemoval is a paid mutator transaction binding the contract method 0x6490305f.
//
// Solidity: function queueOracleProviderRemoval(bytes32[] providers) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) QueueOracleProviderRemoval(providers [][32]byte) (*types.Transaction, error) {
	return _SuperGovernor.Contract.QueueOracleProviderRemoval(&_SuperGovernor.TransactOpts, providers)
}

// QueueOracleUpdate is a paid mutator transaction binding the contract method 0xba1f073c.
//
// Solidity: function queueOracleUpdate(address[] bases_, address[] quotes_, bytes32[] providers_, address[] feeds_) returns()
func (_SuperGovernor *SuperGovernorTransactor) QueueOracleUpdate(opts *bind.TransactOpts, bases_ []common.Address, quotes_ []common.Address, providers_ [][32]byte, feeds_ []common.Address) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "queueOracleUpdate", bases_, quotes_, providers_, feeds_)
}

// QueueOracleUpdate is a paid mutator transaction binding the contract method 0xba1f073c.
//
// Solidity: function queueOracleUpdate(address[] bases_, address[] quotes_, bytes32[] providers_, address[] feeds_) returns()
func (_SuperGovernor *SuperGovernorSession) QueueOracleUpdate(bases_ []common.Address, quotes_ []common.Address, providers_ [][32]byte, feeds_ []common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.QueueOracleUpdate(&_SuperGovernor.TransactOpts, bases_, quotes_, providers_, feeds_)
}

// QueueOracleUpdate is a paid mutator transaction binding the contract method 0xba1f073c.
//
// Solidity: function queueOracleUpdate(address[] bases_, address[] quotes_, bytes32[] providers_, address[] feeds_) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) QueueOracleUpdate(bases_ []common.Address, quotes_ []common.Address, providers_ [][32]byte, feeds_ []common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.QueueOracleUpdate(&_SuperGovernor.TransactOpts, bases_, quotes_, providers_, feeds_)
}

// RegisterHook is a paid mutator transaction binding the contract method 0x6354b661.
//
// Solidity: function registerHook(address hook) returns()
func (_SuperGovernor *SuperGovernorTransactor) RegisterHook(opts *bind.TransactOpts, hook common.Address) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "registerHook", hook)
}

// RegisterHook is a paid mutator transaction binding the contract method 0x6354b661.
//
// Solidity: function registerHook(address hook) returns()
func (_SuperGovernor *SuperGovernorSession) RegisterHook(hook common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.RegisterHook(&_SuperGovernor.TransactOpts, hook)
}

// RegisterHook is a paid mutator transaction binding the contract method 0x6354b661.
//
// Solidity: function registerHook(address hook) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) RegisterHook(hook common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.RegisterHook(&_SuperGovernor.TransactOpts, hook)
}

// RemoveExecutor is a paid mutator transaction binding the contract method 0x24788429.
//
// Solidity: function removeExecutor(address executor) returns()
func (_SuperGovernor *SuperGovernorTransactor) RemoveExecutor(opts *bind.TransactOpts, executor common.Address) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "removeExecutor", executor)
}

// RemoveExecutor is a paid mutator transaction binding the contract method 0x24788429.
//
// Solidity: function removeExecutor(address executor) returns()
func (_SuperGovernor *SuperGovernorSession) RemoveExecutor(executor common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.RemoveExecutor(&_SuperGovernor.TransactOpts, executor)
}

// RemoveExecutor is a paid mutator transaction binding the contract method 0x24788429.
//
// Solidity: function removeExecutor(address executor) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) RemoveExecutor(executor common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.RemoveExecutor(&_SuperGovernor.TransactOpts, executor)
}

// RemoveSuperformManager is a paid mutator transaction binding the contract method 0x1c70d542.
//
// Solidity: function removeSuperformManager(address manager) returns()
func (_SuperGovernor *SuperGovernorTransactor) RemoveSuperformManager(opts *bind.TransactOpts, manager common.Address) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "removeSuperformManager", manager)
}

// RemoveSuperformManager is a paid mutator transaction binding the contract method 0x1c70d542.
//
// Solidity: function removeSuperformManager(address manager) returns()
func (_SuperGovernor *SuperGovernorSession) RemoveSuperformManager(manager common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.RemoveSuperformManager(&_SuperGovernor.TransactOpts, manager)
}

// RemoveSuperformManager is a paid mutator transaction binding the contract method 0x1c70d542.
//
// Solidity: function removeSuperformManager(address manager) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) RemoveSuperformManager(manager common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.RemoveSuperformManager(&_SuperGovernor.TransactOpts, manager)
}

// RemoveValidator is a paid mutator transaction binding the contract method 0x40a141ff.
//
// Solidity: function removeValidator(address validator) returns()
func (_SuperGovernor *SuperGovernorTransactor) RemoveValidator(opts *bind.TransactOpts, validator common.Address) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "removeValidator", validator)
}

// RemoveValidator is a paid mutator transaction binding the contract method 0x40a141ff.
//
// Solidity: function removeValidator(address validator) returns()
func (_SuperGovernor *SuperGovernorSession) RemoveValidator(validator common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.RemoveValidator(&_SuperGovernor.TransactOpts, validator)
}

// RemoveValidator is a paid mutator transaction binding the contract method 0x40a141ff.
//
// Solidity: function removeValidator(address validator) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) RemoveValidator(validator common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.RemoveValidator(&_SuperGovernor.TransactOpts, validator)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_SuperGovernor *SuperGovernorTransactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "renounceRole", role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_SuperGovernor *SuperGovernorSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.RenounceRole(&_SuperGovernor.TransactOpts, role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.RenounceRole(&_SuperGovernor.TransactOpts, role, callerConfirmation)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_SuperGovernor *SuperGovernorTransactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_SuperGovernor *SuperGovernorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.RevokeRole(&_SuperGovernor.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.RevokeRole(&_SuperGovernor.TransactOpts, role, account)
}

// SetActivePPSOracle is a paid mutator transaction binding the contract method 0xf9525fb7.
//
// Solidity: function setActivePPSOracle(address oracle) returns()
func (_SuperGovernor *SuperGovernorTransactor) SetActivePPSOracle(opts *bind.TransactOpts, oracle common.Address) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "setActivePPSOracle", oracle)
}

// SetActivePPSOracle is a paid mutator transaction binding the contract method 0xf9525fb7.
//
// Solidity: function setActivePPSOracle(address oracle) returns()
func (_SuperGovernor *SuperGovernorSession) SetActivePPSOracle(oracle common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetActivePPSOracle(&_SuperGovernor.TransactOpts, oracle)
}

// SetActivePPSOracle is a paid mutator transaction binding the contract method 0xf9525fb7.
//
// Solidity: function setActivePPSOracle(address oracle) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) SetActivePPSOracle(oracle common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetActivePPSOracle(&_SuperGovernor.TransactOpts, oracle)
}

// SetAddress is a paid mutator transaction binding the contract method 0xca446dd9.
//
// Solidity: function setAddress(bytes32 key, address value) returns()
func (_SuperGovernor *SuperGovernorTransactor) SetAddress(opts *bind.TransactOpts, key [32]byte, value common.Address) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "setAddress", key, value)
}

// SetAddress is a paid mutator transaction binding the contract method 0xca446dd9.
//
// Solidity: function setAddress(bytes32 key, address value) returns()
func (_SuperGovernor *SuperGovernorSession) SetAddress(key [32]byte, value common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetAddress(&_SuperGovernor.TransactOpts, key, value)
}

// SetAddress is a paid mutator transaction binding the contract method 0xca446dd9.
//
// Solidity: function setAddress(bytes32 key, address value) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) SetAddress(key [32]byte, value common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetAddress(&_SuperGovernor.TransactOpts, key, value)
}

// SetEmergencyPrice is a paid mutator transaction binding the contract method 0x7ee185c1.
//
// Solidity: function setEmergencyPrice(address token, uint256 price) returns()
func (_SuperGovernor *SuperGovernorTransactor) SetEmergencyPrice(opts *bind.TransactOpts, token common.Address, price *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "setEmergencyPrice", token, price)
}

// SetEmergencyPrice is a paid mutator transaction binding the contract method 0x7ee185c1.
//
// Solidity: function setEmergencyPrice(address token, uint256 price) returns()
func (_SuperGovernor *SuperGovernorSession) SetEmergencyPrice(token common.Address, price *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetEmergencyPrice(&_SuperGovernor.TransactOpts, token, price)
}

// SetEmergencyPrice is a paid mutator transaction binding the contract method 0x7ee185c1.
//
// Solidity: function setEmergencyPrice(address token, uint256 price) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) SetEmergencyPrice(token common.Address, price *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetEmergencyPrice(&_SuperGovernor.TransactOpts, token, price)
}

// SetGasInfo is a paid mutator transaction binding the contract method 0x0b4396aa.
//
// Solidity: function setGasInfo(address oracle, uint256 gasIncreasePerEntryBatch) returns()
func (_SuperGovernor *SuperGovernorTransactor) SetGasInfo(opts *bind.TransactOpts, oracle common.Address, gasIncreasePerEntryBatch *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "setGasInfo", oracle, gasIncreasePerEntryBatch)
}

// SetGasInfo is a paid mutator transaction binding the contract method 0x0b4396aa.
//
// Solidity: function setGasInfo(address oracle, uint256 gasIncreasePerEntryBatch) returns()
func (_SuperGovernor *SuperGovernorSession) SetGasInfo(oracle common.Address, gasIncreasePerEntryBatch *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetGasInfo(&_SuperGovernor.TransactOpts, oracle, gasIncreasePerEntryBatch)
}

// SetGasInfo is a paid mutator transaction binding the contract method 0x0b4396aa.
//
// Solidity: function setGasInfo(address oracle, uint256 gasIncreasePerEntryBatch) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) SetGasInfo(oracle common.Address, gasIncreasePerEntryBatch *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetGasInfo(&_SuperGovernor.TransactOpts, oracle, gasIncreasePerEntryBatch)
}

// SetGlobalHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xd5f3cd86.
//
// Solidity: function setGlobalHooksRootVetoStatus(bool vetoed) returns()
func (_SuperGovernor *SuperGovernorTransactor) SetGlobalHooksRootVetoStatus(opts *bind.TransactOpts, vetoed bool) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "setGlobalHooksRootVetoStatus", vetoed)
}

// SetGlobalHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xd5f3cd86.
//
// Solidity: function setGlobalHooksRootVetoStatus(bool vetoed) returns()
func (_SuperGovernor *SuperGovernorSession) SetGlobalHooksRootVetoStatus(vetoed bool) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetGlobalHooksRootVetoStatus(&_SuperGovernor.TransactOpts, vetoed)
}

// SetGlobalHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xd5f3cd86.
//
// Solidity: function setGlobalHooksRootVetoStatus(bool vetoed) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) SetGlobalHooksRootVetoStatus(vetoed bool) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetGlobalHooksRootVetoStatus(&_SuperGovernor.TransactOpts, vetoed)
}

// SetOracleFeedMaxStaleness is a paid mutator transaction binding the contract method 0x17a79fa6.
//
// Solidity: function setOracleFeedMaxStaleness(address feed, uint256 newMaxStaleness) returns()
func (_SuperGovernor *SuperGovernorTransactor) SetOracleFeedMaxStaleness(opts *bind.TransactOpts, feed common.Address, newMaxStaleness *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "setOracleFeedMaxStaleness", feed, newMaxStaleness)
}

// SetOracleFeedMaxStaleness is a paid mutator transaction binding the contract method 0x17a79fa6.
//
// Solidity: function setOracleFeedMaxStaleness(address feed, uint256 newMaxStaleness) returns()
func (_SuperGovernor *SuperGovernorSession) SetOracleFeedMaxStaleness(feed common.Address, newMaxStaleness *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetOracleFeedMaxStaleness(&_SuperGovernor.TransactOpts, feed, newMaxStaleness)
}

// SetOracleFeedMaxStaleness is a paid mutator transaction binding the contract method 0x17a79fa6.
//
// Solidity: function setOracleFeedMaxStaleness(address feed, uint256 newMaxStaleness) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) SetOracleFeedMaxStaleness(feed common.Address, newMaxStaleness *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetOracleFeedMaxStaleness(&_SuperGovernor.TransactOpts, feed, newMaxStaleness)
}

// SetOracleFeedMaxStalenessBatch is a paid mutator transaction binding the contract method 0x3fa9fe64.
//
// Solidity: function setOracleFeedMaxStalenessBatch(address[] feeds_, uint256[] newMaxStalenessList_) returns()
func (_SuperGovernor *SuperGovernorTransactor) SetOracleFeedMaxStalenessBatch(opts *bind.TransactOpts, feeds_ []common.Address, newMaxStalenessList_ []*big.Int) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "setOracleFeedMaxStalenessBatch", feeds_, newMaxStalenessList_)
}

// SetOracleFeedMaxStalenessBatch is a paid mutator transaction binding the contract method 0x3fa9fe64.
//
// Solidity: function setOracleFeedMaxStalenessBatch(address[] feeds_, uint256[] newMaxStalenessList_) returns()
func (_SuperGovernor *SuperGovernorSession) SetOracleFeedMaxStalenessBatch(feeds_ []common.Address, newMaxStalenessList_ []*big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetOracleFeedMaxStalenessBatch(&_SuperGovernor.TransactOpts, feeds_, newMaxStalenessList_)
}

// SetOracleFeedMaxStalenessBatch is a paid mutator transaction binding the contract method 0x3fa9fe64.
//
// Solidity: function setOracleFeedMaxStalenessBatch(address[] feeds_, uint256[] newMaxStalenessList_) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) SetOracleFeedMaxStalenessBatch(feeds_ []common.Address, newMaxStalenessList_ []*big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetOracleFeedMaxStalenessBatch(&_SuperGovernor.TransactOpts, feeds_, newMaxStalenessList_)
}

// SetOracleMaxStaleness is a paid mutator transaction binding the contract method 0x324341ed.
//
// Solidity: function setOracleMaxStaleness(uint256 newMaxStaleness) returns()
func (_SuperGovernor *SuperGovernorTransactor) SetOracleMaxStaleness(opts *bind.TransactOpts, newMaxStaleness *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "setOracleMaxStaleness", newMaxStaleness)
}

// SetOracleMaxStaleness is a paid mutator transaction binding the contract method 0x324341ed.
//
// Solidity: function setOracleMaxStaleness(uint256 newMaxStaleness) returns()
func (_SuperGovernor *SuperGovernorSession) SetOracleMaxStaleness(newMaxStaleness *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetOracleMaxStaleness(&_SuperGovernor.TransactOpts, newMaxStaleness)
}

// SetOracleMaxStaleness is a paid mutator transaction binding the contract method 0x324341ed.
//
// Solidity: function setOracleMaxStaleness(uint256 newMaxStaleness) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) SetOracleMaxStaleness(newMaxStaleness *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetOracleMaxStaleness(&_SuperGovernor.TransactOpts, newMaxStaleness)
}

// SetPPSOracleQuorum is a paid mutator transaction binding the contract method 0x52da1de3.
//
// Solidity: function setPPSOracleQuorum(uint256 quorum) returns()
func (_SuperGovernor *SuperGovernorTransactor) SetPPSOracleQuorum(opts *bind.TransactOpts, quorum *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "setPPSOracleQuorum", quorum)
}

// SetPPSOracleQuorum is a paid mutator transaction binding the contract method 0x52da1de3.
//
// Solidity: function setPPSOracleQuorum(uint256 quorum) returns()
func (_SuperGovernor *SuperGovernorSession) SetPPSOracleQuorum(quorum *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetPPSOracleQuorum(&_SuperGovernor.TransactOpts, quorum)
}

// SetPPSOracleQuorum is a paid mutator transaction binding the contract method 0x52da1de3.
//
// Solidity: function setPPSOracleQuorum(uint256 quorum) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) SetPPSOracleQuorum(quorum *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetPPSOracleQuorum(&_SuperGovernor.TransactOpts, quorum)
}

// SetStrategyHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xf5297a47.
//
// Solidity: function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) returns()
func (_SuperGovernor *SuperGovernorTransactor) SetStrategyHooksRootVetoStatus(opts *bind.TransactOpts, strategy common.Address, vetoed bool) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "setStrategyHooksRootVetoStatus", strategy, vetoed)
}

// SetStrategyHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xf5297a47.
//
// Solidity: function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) returns()
func (_SuperGovernor *SuperGovernorSession) SetStrategyHooksRootVetoStatus(strategy common.Address, vetoed bool) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetStrategyHooksRootVetoStatus(&_SuperGovernor.TransactOpts, strategy, vetoed)
}

// SetStrategyHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xf5297a47.
//
// Solidity: function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) SetStrategyHooksRootVetoStatus(strategy common.Address, vetoed bool) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SetStrategyHooksRootVetoStatus(&_SuperGovernor.TransactOpts, strategy, vetoed)
}

// SlashStake is a paid mutator transaction binding the contract method 0x98d1c5a8.
//
// Solidity: function slashStake(address manager, uint256 amount) returns()
func (_SuperGovernor *SuperGovernorTransactor) SlashStake(opts *bind.TransactOpts, manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "slashStake", manager, amount)
}

// SlashStake is a paid mutator transaction binding the contract method 0x98d1c5a8.
//
// Solidity: function slashStake(address manager, uint256 amount) returns()
func (_SuperGovernor *SuperGovernorSession) SlashStake(manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SlashStake(&_SuperGovernor.TransactOpts, manager, amount)
}

// SlashStake is a paid mutator transaction binding the contract method 0x98d1c5a8.
//
// Solidity: function slashStake(address manager, uint256 amount) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) SlashStake(manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperGovernor.Contract.SlashStake(&_SuperGovernor.TransactOpts, manager, amount)
}

// UnregisterHook is a paid mutator transaction binding the contract method 0xf76f48cb.
//
// Solidity: function unregisterHook(address hook) returns()
func (_SuperGovernor *SuperGovernorTransactor) UnregisterHook(opts *bind.TransactOpts, hook common.Address) (*types.Transaction, error) {
	return _SuperGovernor.contract.Transact(opts, "unregisterHook", hook)
}

// UnregisterHook is a paid mutator transaction binding the contract method 0xf76f48cb.
//
// Solidity: function unregisterHook(address hook) returns()
func (_SuperGovernor *SuperGovernorSession) UnregisterHook(hook common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.UnregisterHook(&_SuperGovernor.TransactOpts, hook)
}

// UnregisterHook is a paid mutator transaction binding the contract method 0xf76f48cb.
//
// Solidity: function unregisterHook(address hook) returns()
func (_SuperGovernor *SuperGovernorTransactorSession) UnregisterHook(hook common.Address) (*types.Transaction, error) {
	return _SuperGovernor.Contract.UnregisterHook(&_SuperGovernor.TransactOpts, hook)
}

// SuperGovernorActivePPSOracleChangedIterator is returned from FilterActivePPSOracleChanged and is used to iterate over the raw logs and unpacked data for ActivePPSOracleChanged events raised by the SuperGovernor contract.
type SuperGovernorActivePPSOracleChangedIterator struct {
	Event *SuperGovernorActivePPSOracleChanged // Event containing the contract specifics and raw log

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
func (it *SuperGovernorActivePPSOracleChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorActivePPSOracleChanged)
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
		it.Event = new(SuperGovernorActivePPSOracleChanged)
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
func (it *SuperGovernorActivePPSOracleChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorActivePPSOracleChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorActivePPSOracleChanged represents a ActivePPSOracleChanged event raised by the SuperGovernor contract.
type SuperGovernorActivePPSOracleChanged struct {
	OldOracle common.Address
	NewOracle common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterActivePPSOracleChanged is a free log retrieval operation binding the contract event 0x6f32d4a08b9b9b8ee365ed09addde1536e0cc6a14a46e120923bafef349131e4.
//
// Solidity: event ActivePPSOracleChanged(address indexed oldOracle, address indexed newOracle)
func (_SuperGovernor *SuperGovernorFilterer) FilterActivePPSOracleChanged(opts *bind.FilterOpts, oldOracle []common.Address, newOracle []common.Address) (*SuperGovernorActivePPSOracleChangedIterator, error) {

	var oldOracleRule []interface{}
	for _, oldOracleItem := range oldOracle {
		oldOracleRule = append(oldOracleRule, oldOracleItem)
	}
	var newOracleRule []interface{}
	for _, newOracleItem := range newOracle {
		newOracleRule = append(newOracleRule, newOracleItem)
	}

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "ActivePPSOracleChanged", oldOracleRule, newOracleRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorActivePPSOracleChangedIterator{contract: _SuperGovernor.contract, event: "ActivePPSOracleChanged", logs: logs, sub: sub}, nil
}

// WatchActivePPSOracleChanged is a free log subscription operation binding the contract event 0x6f32d4a08b9b9b8ee365ed09addde1536e0cc6a14a46e120923bafef349131e4.
//
// Solidity: event ActivePPSOracleChanged(address indexed oldOracle, address indexed newOracle)
func (_SuperGovernor *SuperGovernorFilterer) WatchActivePPSOracleChanged(opts *bind.WatchOpts, sink chan<- *SuperGovernorActivePPSOracleChanged, oldOracle []common.Address, newOracle []common.Address) (event.Subscription, error) {

	var oldOracleRule []interface{}
	for _, oldOracleItem := range oldOracle {
		oldOracleRule = append(oldOracleRule, oldOracleItem)
	}
	var newOracleRule []interface{}
	for _, newOracleItem := range newOracle {
		newOracleRule = append(newOracleRule, newOracleItem)
	}

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "ActivePPSOracleChanged", oldOracleRule, newOracleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorActivePPSOracleChanged)
				if err := _SuperGovernor.contract.UnpackLog(event, "ActivePPSOracleChanged", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseActivePPSOracleChanged(log types.Log) (*SuperGovernorActivePPSOracleChanged, error) {
	event := new(SuperGovernorActivePPSOracleChanged)
	if err := _SuperGovernor.contract.UnpackLog(event, "ActivePPSOracleChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorActivePPSOracleProposedIterator is returned from FilterActivePPSOracleProposed and is used to iterate over the raw logs and unpacked data for ActivePPSOracleProposed events raised by the SuperGovernor contract.
type SuperGovernorActivePPSOracleProposedIterator struct {
	Event *SuperGovernorActivePPSOracleProposed // Event containing the contract specifics and raw log

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
func (it *SuperGovernorActivePPSOracleProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorActivePPSOracleProposed)
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
		it.Event = new(SuperGovernorActivePPSOracleProposed)
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
func (it *SuperGovernorActivePPSOracleProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorActivePPSOracleProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorActivePPSOracleProposed represents a ActivePPSOracleProposed event raised by the SuperGovernor contract.
type SuperGovernorActivePPSOracleProposed struct {
	Oracle        common.Address
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterActivePPSOracleProposed is a free log retrieval operation binding the contract event 0x0081013d01b2d41dec72c3449ec25ce9dda2847a6e11ad584836ab3589efe675.
//
// Solidity: event ActivePPSOracleProposed(address indexed oracle, uint256 effectiveTime)
func (_SuperGovernor *SuperGovernorFilterer) FilterActivePPSOracleProposed(opts *bind.FilterOpts, oracle []common.Address) (*SuperGovernorActivePPSOracleProposedIterator, error) {

	var oracleRule []interface{}
	for _, oracleItem := range oracle {
		oracleRule = append(oracleRule, oracleItem)
	}

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "ActivePPSOracleProposed", oracleRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorActivePPSOracleProposedIterator{contract: _SuperGovernor.contract, event: "ActivePPSOracleProposed", logs: logs, sub: sub}, nil
}

// WatchActivePPSOracleProposed is a free log subscription operation binding the contract event 0x0081013d01b2d41dec72c3449ec25ce9dda2847a6e11ad584836ab3589efe675.
//
// Solidity: event ActivePPSOracleProposed(address indexed oracle, uint256 effectiveTime)
func (_SuperGovernor *SuperGovernorFilterer) WatchActivePPSOracleProposed(opts *bind.WatchOpts, sink chan<- *SuperGovernorActivePPSOracleProposed, oracle []common.Address) (event.Subscription, error) {

	var oracleRule []interface{}
	for _, oracleItem := range oracle {
		oracleRule = append(oracleRule, oracleItem)
	}

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "ActivePPSOracleProposed", oracleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorActivePPSOracleProposed)
				if err := _SuperGovernor.contract.UnpackLog(event, "ActivePPSOracleProposed", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseActivePPSOracleProposed(log types.Log) (*SuperGovernorActivePPSOracleProposed, error) {
	event := new(SuperGovernorActivePPSOracleProposed)
	if err := _SuperGovernor.contract.UnpackLog(event, "ActivePPSOracleProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorActivePPSOracleSetIterator is returned from FilterActivePPSOracleSet and is used to iterate over the raw logs and unpacked data for ActivePPSOracleSet events raised by the SuperGovernor contract.
type SuperGovernorActivePPSOracleSetIterator struct {
	Event *SuperGovernorActivePPSOracleSet // Event containing the contract specifics and raw log

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
func (it *SuperGovernorActivePPSOracleSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorActivePPSOracleSet)
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
		it.Event = new(SuperGovernorActivePPSOracleSet)
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
func (it *SuperGovernorActivePPSOracleSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorActivePPSOracleSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorActivePPSOracleSet represents a ActivePPSOracleSet event raised by the SuperGovernor contract.
type SuperGovernorActivePPSOracleSet struct {
	Oracle common.Address
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterActivePPSOracleSet is a free log retrieval operation binding the contract event 0x4f8ebeedbe3d26fd9e31b446c8da12464fc23cd6ce8c45510c211175190d62fa.
//
// Solidity: event ActivePPSOracleSet(address indexed oracle)
func (_SuperGovernor *SuperGovernorFilterer) FilterActivePPSOracleSet(opts *bind.FilterOpts, oracle []common.Address) (*SuperGovernorActivePPSOracleSetIterator, error) {

	var oracleRule []interface{}
	for _, oracleItem := range oracle {
		oracleRule = append(oracleRule, oracleItem)
	}

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "ActivePPSOracleSet", oracleRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorActivePPSOracleSetIterator{contract: _SuperGovernor.contract, event: "ActivePPSOracleSet", logs: logs, sub: sub}, nil
}

// WatchActivePPSOracleSet is a free log subscription operation binding the contract event 0x4f8ebeedbe3d26fd9e31b446c8da12464fc23cd6ce8c45510c211175190d62fa.
//
// Solidity: event ActivePPSOracleSet(address indexed oracle)
func (_SuperGovernor *SuperGovernorFilterer) WatchActivePPSOracleSet(opts *bind.WatchOpts, sink chan<- *SuperGovernorActivePPSOracleSet, oracle []common.Address) (event.Subscription, error) {

	var oracleRule []interface{}
	for _, oracleItem := range oracle {
		oracleRule = append(oracleRule, oracleItem)
	}

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "ActivePPSOracleSet", oracleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorActivePPSOracleSet)
				if err := _SuperGovernor.contract.UnpackLog(event, "ActivePPSOracleSet", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseActivePPSOracleSet(log types.Log) (*SuperGovernorActivePPSOracleSet, error) {
	event := new(SuperGovernorActivePPSOracleSet)
	if err := _SuperGovernor.contract.UnpackLog(event, "ActivePPSOracleSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorAddressSetIterator is returned from FilterAddressSet and is used to iterate over the raw logs and unpacked data for AddressSet events raised by the SuperGovernor contract.
type SuperGovernorAddressSetIterator struct {
	Event *SuperGovernorAddressSet // Event containing the contract specifics and raw log

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
func (it *SuperGovernorAddressSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorAddressSet)
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
		it.Event = new(SuperGovernorAddressSet)
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
func (it *SuperGovernorAddressSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorAddressSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorAddressSet represents a AddressSet event raised by the SuperGovernor contract.
type SuperGovernorAddressSet struct {
	Key      [32]byte
	OldValue common.Address
	Value    common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterAddressSet is a free log retrieval operation binding the contract event 0x9ef0e8c8e52743bb38b83b17d9429141d494b8041ca6d616a6c77cebae9cd8b7.
//
// Solidity: event AddressSet(bytes32 indexed key, address indexed oldValue, address indexed value)
func (_SuperGovernor *SuperGovernorFilterer) FilterAddressSet(opts *bind.FilterOpts, key [][32]byte, oldValue []common.Address, value []common.Address) (*SuperGovernorAddressSetIterator, error) {

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

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "AddressSet", keyRule, oldValueRule, valueRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorAddressSetIterator{contract: _SuperGovernor.contract, event: "AddressSet", logs: logs, sub: sub}, nil
}

// WatchAddressSet is a free log subscription operation binding the contract event 0x9ef0e8c8e52743bb38b83b17d9429141d494b8041ca6d616a6c77cebae9cd8b7.
//
// Solidity: event AddressSet(bytes32 indexed key, address indexed oldValue, address indexed value)
func (_SuperGovernor *SuperGovernorFilterer) WatchAddressSet(opts *bind.WatchOpts, sink chan<- *SuperGovernorAddressSet, key [][32]byte, oldValue []common.Address, value []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "AddressSet", keyRule, oldValueRule, valueRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorAddressSet)
				if err := _SuperGovernor.contract.UnpackLog(event, "AddressSet", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseAddressSet(log types.Log) (*SuperGovernorAddressSet, error) {
	event := new(SuperGovernorAddressSet)
	if err := _SuperGovernor.contract.UnpackLog(event, "AddressSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorExecutorAddedIterator is returned from FilterExecutorAdded and is used to iterate over the raw logs and unpacked data for ExecutorAdded events raised by the SuperGovernor contract.
type SuperGovernorExecutorAddedIterator struct {
	Event *SuperGovernorExecutorAdded // Event containing the contract specifics and raw log

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
func (it *SuperGovernorExecutorAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorExecutorAdded)
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
		it.Event = new(SuperGovernorExecutorAdded)
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
func (it *SuperGovernorExecutorAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorExecutorAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorExecutorAdded represents a ExecutorAdded event raised by the SuperGovernor contract.
type SuperGovernorExecutorAdded struct {
	Executor common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterExecutorAdded is a free log retrieval operation binding the contract event 0xae5b7c3b000f575c241001dc9bcb3d8778376889353b07121115574eceff78c5.
//
// Solidity: event ExecutorAdded(address indexed executor)
func (_SuperGovernor *SuperGovernorFilterer) FilterExecutorAdded(opts *bind.FilterOpts, executor []common.Address) (*SuperGovernorExecutorAddedIterator, error) {

	var executorRule []interface{}
	for _, executorItem := range executor {
		executorRule = append(executorRule, executorItem)
	}

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "ExecutorAdded", executorRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorExecutorAddedIterator{contract: _SuperGovernor.contract, event: "ExecutorAdded", logs: logs, sub: sub}, nil
}

// WatchExecutorAdded is a free log subscription operation binding the contract event 0xae5b7c3b000f575c241001dc9bcb3d8778376889353b07121115574eceff78c5.
//
// Solidity: event ExecutorAdded(address indexed executor)
func (_SuperGovernor *SuperGovernorFilterer) WatchExecutorAdded(opts *bind.WatchOpts, sink chan<- *SuperGovernorExecutorAdded, executor []common.Address) (event.Subscription, error) {

	var executorRule []interface{}
	for _, executorItem := range executor {
		executorRule = append(executorRule, executorItem)
	}

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "ExecutorAdded", executorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorExecutorAdded)
				if err := _SuperGovernor.contract.UnpackLog(event, "ExecutorAdded", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseExecutorAdded(log types.Log) (*SuperGovernorExecutorAdded, error) {
	event := new(SuperGovernorExecutorAdded)
	if err := _SuperGovernor.contract.UnpackLog(event, "ExecutorAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorExecutorRemovedIterator is returned from FilterExecutorRemoved and is used to iterate over the raw logs and unpacked data for ExecutorRemoved events raised by the SuperGovernor contract.
type SuperGovernorExecutorRemovedIterator struct {
	Event *SuperGovernorExecutorRemoved // Event containing the contract specifics and raw log

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
func (it *SuperGovernorExecutorRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorExecutorRemoved)
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
		it.Event = new(SuperGovernorExecutorRemoved)
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
func (it *SuperGovernorExecutorRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorExecutorRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorExecutorRemoved represents a ExecutorRemoved event raised by the SuperGovernor contract.
type SuperGovernorExecutorRemoved struct {
	Executor common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterExecutorRemoved is a free log retrieval operation binding the contract event 0x4a2cf608bfb427f53279ec7f0eadf48913b9346ccefc3af138dbdec14ea0907d.
//
// Solidity: event ExecutorRemoved(address indexed executor)
func (_SuperGovernor *SuperGovernorFilterer) FilterExecutorRemoved(opts *bind.FilterOpts, executor []common.Address) (*SuperGovernorExecutorRemovedIterator, error) {

	var executorRule []interface{}
	for _, executorItem := range executor {
		executorRule = append(executorRule, executorItem)
	}

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "ExecutorRemoved", executorRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorExecutorRemovedIterator{contract: _SuperGovernor.contract, event: "ExecutorRemoved", logs: logs, sub: sub}, nil
}

// WatchExecutorRemoved is a free log subscription operation binding the contract event 0x4a2cf608bfb427f53279ec7f0eadf48913b9346ccefc3af138dbdec14ea0907d.
//
// Solidity: event ExecutorRemoved(address indexed executor)
func (_SuperGovernor *SuperGovernorFilterer) WatchExecutorRemoved(opts *bind.WatchOpts, sink chan<- *SuperGovernorExecutorRemoved, executor []common.Address) (event.Subscription, error) {

	var executorRule []interface{}
	for _, executorItem := range executor {
		executorRule = append(executorRule, executorItem)
	}

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "ExecutorRemoved", executorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorExecutorRemoved)
				if err := _SuperGovernor.contract.UnpackLog(event, "ExecutorRemoved", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseExecutorRemoved(log types.Log) (*SuperGovernorExecutorRemoved, error) {
	event := new(SuperGovernorExecutorRemoved)
	if err := _SuperGovernor.contract.UnpackLog(event, "ExecutorRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorFeeProposedIterator is returned from FilterFeeProposed and is used to iterate over the raw logs and unpacked data for FeeProposed events raised by the SuperGovernor contract.
type SuperGovernorFeeProposedIterator struct {
	Event *SuperGovernorFeeProposed // Event containing the contract specifics and raw log

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
func (it *SuperGovernorFeeProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorFeeProposed)
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
		it.Event = new(SuperGovernorFeeProposed)
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
func (it *SuperGovernorFeeProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorFeeProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorFeeProposed represents a FeeProposed event raised by the SuperGovernor contract.
type SuperGovernorFeeProposed struct {
	FeeType       uint8
	Value         *big.Int
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterFeeProposed is a free log retrieval operation binding the contract event 0x79548367f12987b3f5043ed1f421f89ebc84ab67cdaa9ee1e4d2a9e76b58ba0b.
//
// Solidity: event FeeProposed(uint8 indexed feeType, uint256 value, uint256 effectiveTime)
func (_SuperGovernor *SuperGovernorFilterer) FilterFeeProposed(opts *bind.FilterOpts, feeType []uint8) (*SuperGovernorFeeProposedIterator, error) {

	var feeTypeRule []interface{}
	for _, feeTypeItem := range feeType {
		feeTypeRule = append(feeTypeRule, feeTypeItem)
	}

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "FeeProposed", feeTypeRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorFeeProposedIterator{contract: _SuperGovernor.contract, event: "FeeProposed", logs: logs, sub: sub}, nil
}

// WatchFeeProposed is a free log subscription operation binding the contract event 0x79548367f12987b3f5043ed1f421f89ebc84ab67cdaa9ee1e4d2a9e76b58ba0b.
//
// Solidity: event FeeProposed(uint8 indexed feeType, uint256 value, uint256 effectiveTime)
func (_SuperGovernor *SuperGovernorFilterer) WatchFeeProposed(opts *bind.WatchOpts, sink chan<- *SuperGovernorFeeProposed, feeType []uint8) (event.Subscription, error) {

	var feeTypeRule []interface{}
	for _, feeTypeItem := range feeType {
		feeTypeRule = append(feeTypeRule, feeTypeItem)
	}

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "FeeProposed", feeTypeRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorFeeProposed)
				if err := _SuperGovernor.contract.UnpackLog(event, "FeeProposed", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseFeeProposed(log types.Log) (*SuperGovernorFeeProposed, error) {
	event := new(SuperGovernorFeeProposed)
	if err := _SuperGovernor.contract.UnpackLog(event, "FeeProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorFeeUpdatedIterator is returned from FilterFeeUpdated and is used to iterate over the raw logs and unpacked data for FeeUpdated events raised by the SuperGovernor contract.
type SuperGovernorFeeUpdatedIterator struct {
	Event *SuperGovernorFeeUpdated // Event containing the contract specifics and raw log

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
func (it *SuperGovernorFeeUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorFeeUpdated)
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
		it.Event = new(SuperGovernorFeeUpdated)
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
func (it *SuperGovernorFeeUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorFeeUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorFeeUpdated represents a FeeUpdated event raised by the SuperGovernor contract.
type SuperGovernorFeeUpdated struct {
	FeeType uint8
	Value   *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterFeeUpdated is a free log retrieval operation binding the contract event 0x53b82d85cd75c3f353186408e2e619ae5f01c371100dc061ee0423d12acb7508.
//
// Solidity: event FeeUpdated(uint8 indexed feeType, uint256 value)
func (_SuperGovernor *SuperGovernorFilterer) FilterFeeUpdated(opts *bind.FilterOpts, feeType []uint8) (*SuperGovernorFeeUpdatedIterator, error) {

	var feeTypeRule []interface{}
	for _, feeTypeItem := range feeType {
		feeTypeRule = append(feeTypeRule, feeTypeItem)
	}

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "FeeUpdated", feeTypeRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorFeeUpdatedIterator{contract: _SuperGovernor.contract, event: "FeeUpdated", logs: logs, sub: sub}, nil
}

// WatchFeeUpdated is a free log subscription operation binding the contract event 0x53b82d85cd75c3f353186408e2e619ae5f01c371100dc061ee0423d12acb7508.
//
// Solidity: event FeeUpdated(uint8 indexed feeType, uint256 value)
func (_SuperGovernor *SuperGovernorFilterer) WatchFeeUpdated(opts *bind.WatchOpts, sink chan<- *SuperGovernorFeeUpdated, feeType []uint8) (event.Subscription, error) {

	var feeTypeRule []interface{}
	for _, feeTypeItem := range feeType {
		feeTypeRule = append(feeTypeRule, feeTypeItem)
	}

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "FeeUpdated", feeTypeRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorFeeUpdated)
				if err := _SuperGovernor.contract.UnpackLog(event, "FeeUpdated", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseFeeUpdated(log types.Log) (*SuperGovernorFeeUpdated, error) {
	event := new(SuperGovernorFeeUpdated)
	if err := _SuperGovernor.contract.UnpackLog(event, "FeeUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorGasInfoSetIterator is returned from FilterGasInfoSet and is used to iterate over the raw logs and unpacked data for GasInfoSet events raised by the SuperGovernor contract.
type SuperGovernorGasInfoSetIterator struct {
	Event *SuperGovernorGasInfoSet // Event containing the contract specifics and raw log

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
func (it *SuperGovernorGasInfoSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorGasInfoSet)
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
		it.Event = new(SuperGovernorGasInfoSet)
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
func (it *SuperGovernorGasInfoSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorGasInfoSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorGasInfoSet represents a GasInfoSet event raised by the SuperGovernor contract.
type SuperGovernorGasInfoSet struct {
	Oracle                   common.Address
	GasIncreasePerEntryBatch *big.Int
	Raw                      types.Log // Blockchain specific contextual infos
}

// FilterGasInfoSet is a free log retrieval operation binding the contract event 0x5a6a2723fb87c76bcd4e5e9194dbdb6286f8cfbaec12fb975707b9d805d3baf5.
//
// Solidity: event GasInfoSet(address indexed oracle, uint256 gasIncreasePerEntryBatch)
func (_SuperGovernor *SuperGovernorFilterer) FilterGasInfoSet(opts *bind.FilterOpts, oracle []common.Address) (*SuperGovernorGasInfoSetIterator, error) {

	var oracleRule []interface{}
	for _, oracleItem := range oracle {
		oracleRule = append(oracleRule, oracleItem)
	}

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "GasInfoSet", oracleRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorGasInfoSetIterator{contract: _SuperGovernor.contract, event: "GasInfoSet", logs: logs, sub: sub}, nil
}

// WatchGasInfoSet is a free log subscription operation binding the contract event 0x5a6a2723fb87c76bcd4e5e9194dbdb6286f8cfbaec12fb975707b9d805d3baf5.
//
// Solidity: event GasInfoSet(address indexed oracle, uint256 gasIncreasePerEntryBatch)
func (_SuperGovernor *SuperGovernorFilterer) WatchGasInfoSet(opts *bind.WatchOpts, sink chan<- *SuperGovernorGasInfoSet, oracle []common.Address) (event.Subscription, error) {

	var oracleRule []interface{}
	for _, oracleItem := range oracle {
		oracleRule = append(oracleRule, oracleItem)
	}

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "GasInfoSet", oracleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorGasInfoSet)
				if err := _SuperGovernor.contract.UnpackLog(event, "GasInfoSet", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseGasInfoSet(log types.Log) (*SuperGovernorGasInfoSet, error) {
	event := new(SuperGovernorGasInfoSet)
	if err := _SuperGovernor.contract.UnpackLog(event, "GasInfoSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorHookApprovedIterator is returned from FilterHookApproved and is used to iterate over the raw logs and unpacked data for HookApproved events raised by the SuperGovernor contract.
type SuperGovernorHookApprovedIterator struct {
	Event *SuperGovernorHookApproved // Event containing the contract specifics and raw log

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
func (it *SuperGovernorHookApprovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorHookApproved)
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
		it.Event = new(SuperGovernorHookApproved)
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
func (it *SuperGovernorHookApprovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorHookApprovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorHookApproved represents a HookApproved event raised by the SuperGovernor contract.
type SuperGovernorHookApproved struct {
	Hook common.Address
	Raw  types.Log // Blockchain specific contextual infos
}

// FilterHookApproved is a free log retrieval operation binding the contract event 0x6b2d5736790b4cdb325004b8784c7b94dc55a32af9d82d1f6ceb5bd8c7c8573e.
//
// Solidity: event HookApproved(address indexed hook)
func (_SuperGovernor *SuperGovernorFilterer) FilterHookApproved(opts *bind.FilterOpts, hook []common.Address) (*SuperGovernorHookApprovedIterator, error) {

	var hookRule []interface{}
	for _, hookItem := range hook {
		hookRule = append(hookRule, hookItem)
	}

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "HookApproved", hookRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorHookApprovedIterator{contract: _SuperGovernor.contract, event: "HookApproved", logs: logs, sub: sub}, nil
}

// WatchHookApproved is a free log subscription operation binding the contract event 0x6b2d5736790b4cdb325004b8784c7b94dc55a32af9d82d1f6ceb5bd8c7c8573e.
//
// Solidity: event HookApproved(address indexed hook)
func (_SuperGovernor *SuperGovernorFilterer) WatchHookApproved(opts *bind.WatchOpts, sink chan<- *SuperGovernorHookApproved, hook []common.Address) (event.Subscription, error) {

	var hookRule []interface{}
	for _, hookItem := range hook {
		hookRule = append(hookRule, hookItem)
	}

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "HookApproved", hookRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorHookApproved)
				if err := _SuperGovernor.contract.UnpackLog(event, "HookApproved", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseHookApproved(log types.Log) (*SuperGovernorHookApproved, error) {
	event := new(SuperGovernorHookApproved)
	if err := _SuperGovernor.contract.UnpackLog(event, "HookApproved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorHookRemovedIterator is returned from FilterHookRemoved and is used to iterate over the raw logs and unpacked data for HookRemoved events raised by the SuperGovernor contract.
type SuperGovernorHookRemovedIterator struct {
	Event *SuperGovernorHookRemoved // Event containing the contract specifics and raw log

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
func (it *SuperGovernorHookRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorHookRemoved)
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
		it.Event = new(SuperGovernorHookRemoved)
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
func (it *SuperGovernorHookRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorHookRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorHookRemoved represents a HookRemoved event raised by the SuperGovernor contract.
type SuperGovernorHookRemoved struct {
	Hook common.Address
	Raw  types.Log // Blockchain specific contextual infos
}

// FilterHookRemoved is a free log retrieval operation binding the contract event 0x47d0871e905ac6550f54ba266e0d90d2dc8ed67a957c064ca3438eddf4e3fd89.
//
// Solidity: event HookRemoved(address indexed hook)
func (_SuperGovernor *SuperGovernorFilterer) FilterHookRemoved(opts *bind.FilterOpts, hook []common.Address) (*SuperGovernorHookRemovedIterator, error) {

	var hookRule []interface{}
	for _, hookItem := range hook {
		hookRule = append(hookRule, hookItem)
	}

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "HookRemoved", hookRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorHookRemovedIterator{contract: _SuperGovernor.contract, event: "HookRemoved", logs: logs, sub: sub}, nil
}

// WatchHookRemoved is a free log subscription operation binding the contract event 0x47d0871e905ac6550f54ba266e0d90d2dc8ed67a957c064ca3438eddf4e3fd89.
//
// Solidity: event HookRemoved(address indexed hook)
func (_SuperGovernor *SuperGovernorFilterer) WatchHookRemoved(opts *bind.WatchOpts, sink chan<- *SuperGovernorHookRemoved, hook []common.Address) (event.Subscription, error) {

	var hookRule []interface{}
	for _, hookItem := range hook {
		hookRule = append(hookRule, hookItem)
	}

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "HookRemoved", hookRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorHookRemoved)
				if err := _SuperGovernor.contract.UnpackLog(event, "HookRemoved", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseHookRemoved(log types.Log) (*SuperGovernorHookRemoved, error) {
	event := new(SuperGovernorHookRemoved)
	if err := _SuperGovernor.contract.UnpackLog(event, "HookRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorManagerTakeoversFrozenIterator is returned from FilterManagerTakeoversFrozen and is used to iterate over the raw logs and unpacked data for ManagerTakeoversFrozen events raised by the SuperGovernor contract.
type SuperGovernorManagerTakeoversFrozenIterator struct {
	Event *SuperGovernorManagerTakeoversFrozen // Event containing the contract specifics and raw log

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
func (it *SuperGovernorManagerTakeoversFrozenIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorManagerTakeoversFrozen)
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
		it.Event = new(SuperGovernorManagerTakeoversFrozen)
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
func (it *SuperGovernorManagerTakeoversFrozenIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorManagerTakeoversFrozenIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorManagerTakeoversFrozen represents a ManagerTakeoversFrozen event raised by the SuperGovernor contract.
type SuperGovernorManagerTakeoversFrozen struct {
	Raw types.Log // Blockchain specific contextual infos
}

// FilterManagerTakeoversFrozen is a free log retrieval operation binding the contract event 0x0cfbf370e135d688f4de1107bfa980d42fe9e0884277d500e4a5262e207df76d.
//
// Solidity: event ManagerTakeoversFrozen()
func (_SuperGovernor *SuperGovernorFilterer) FilterManagerTakeoversFrozen(opts *bind.FilterOpts) (*SuperGovernorManagerTakeoversFrozenIterator, error) {

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "ManagerTakeoversFrozen")
	if err != nil {
		return nil, err
	}
	return &SuperGovernorManagerTakeoversFrozenIterator{contract: _SuperGovernor.contract, event: "ManagerTakeoversFrozen", logs: logs, sub: sub}, nil
}

// WatchManagerTakeoversFrozen is a free log subscription operation binding the contract event 0x0cfbf370e135d688f4de1107bfa980d42fe9e0884277d500e4a5262e207df76d.
//
// Solidity: event ManagerTakeoversFrozen()
func (_SuperGovernor *SuperGovernorFilterer) WatchManagerTakeoversFrozen(opts *bind.WatchOpts, sink chan<- *SuperGovernorManagerTakeoversFrozen) (event.Subscription, error) {

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "ManagerTakeoversFrozen")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorManagerTakeoversFrozen)
				if err := _SuperGovernor.contract.UnpackLog(event, "ManagerTakeoversFrozen", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseManagerTakeoversFrozen(log types.Log) (*SuperGovernorManagerTakeoversFrozen, error) {
	event := new(SuperGovernorManagerTakeoversFrozen)
	if err := _SuperGovernor.contract.UnpackLog(event, "ManagerTakeoversFrozen", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorMinStalenesChangedIterator is returned from FilterMinStalenesChanged and is used to iterate over the raw logs and unpacked data for MinStalenesChanged events raised by the SuperGovernor contract.
type SuperGovernorMinStalenesChangedIterator struct {
	Event *SuperGovernorMinStalenesChanged // Event containing the contract specifics and raw log

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
func (it *SuperGovernorMinStalenesChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorMinStalenesChanged)
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
		it.Event = new(SuperGovernorMinStalenesChanged)
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
func (it *SuperGovernorMinStalenesChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorMinStalenesChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorMinStalenesChanged represents a MinStalenesChanged event raised by the SuperGovernor contract.
type SuperGovernorMinStalenesChanged struct {
	NewMinStaleness *big.Int
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterMinStalenesChanged is a free log retrieval operation binding the contract event 0x5ef721aefae68d3af172090ad589f1eb72736af265747458daf734c5c60d7daa.
//
// Solidity: event MinStalenesChanged(uint256 newMinStaleness)
func (_SuperGovernor *SuperGovernorFilterer) FilterMinStalenesChanged(opts *bind.FilterOpts) (*SuperGovernorMinStalenesChangedIterator, error) {

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "MinStalenesChanged")
	if err != nil {
		return nil, err
	}
	return &SuperGovernorMinStalenesChangedIterator{contract: _SuperGovernor.contract, event: "MinStalenesChanged", logs: logs, sub: sub}, nil
}

// WatchMinStalenesChanged is a free log subscription operation binding the contract event 0x5ef721aefae68d3af172090ad589f1eb72736af265747458daf734c5c60d7daa.
//
// Solidity: event MinStalenesChanged(uint256 newMinStaleness)
func (_SuperGovernor *SuperGovernorFilterer) WatchMinStalenesChanged(opts *bind.WatchOpts, sink chan<- *SuperGovernorMinStalenesChanged) (event.Subscription, error) {

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "MinStalenesChanged")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorMinStalenesChanged)
				if err := _SuperGovernor.contract.UnpackLog(event, "MinStalenesChanged", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseMinStalenesChanged(log types.Log) (*SuperGovernorMinStalenesChanged, error) {
	event := new(SuperGovernorMinStalenesChanged)
	if err := _SuperGovernor.contract.UnpackLog(event, "MinStalenesChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorMinStalenesProposedIterator is returned from FilterMinStalenesProposed and is used to iterate over the raw logs and unpacked data for MinStalenesProposed events raised by the SuperGovernor contract.
type SuperGovernorMinStalenesProposedIterator struct {
	Event *SuperGovernorMinStalenesProposed // Event containing the contract specifics and raw log

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
func (it *SuperGovernorMinStalenesProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorMinStalenesProposed)
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
		it.Event = new(SuperGovernorMinStalenesProposed)
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
func (it *SuperGovernorMinStalenesProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorMinStalenesProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorMinStalenesProposed represents a MinStalenesProposed event raised by the SuperGovernor contract.
type SuperGovernorMinStalenesProposed struct {
	NewMinStaleness *big.Int
	EffectiveTime   *big.Int
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterMinStalenesProposed is a free log retrieval operation binding the contract event 0xae30e7c9277d9f36ab2ab07d353aa93dcc567106b5d571ebead929f12ebcd7ad.
//
// Solidity: event MinStalenesProposed(uint256 newMinStaleness, uint256 effectiveTime)
func (_SuperGovernor *SuperGovernorFilterer) FilterMinStalenesProposed(opts *bind.FilterOpts) (*SuperGovernorMinStalenesProposedIterator, error) {

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "MinStalenesProposed")
	if err != nil {
		return nil, err
	}
	return &SuperGovernorMinStalenesProposedIterator{contract: _SuperGovernor.contract, event: "MinStalenesProposed", logs: logs, sub: sub}, nil
}

// WatchMinStalenesProposed is a free log subscription operation binding the contract event 0xae30e7c9277d9f36ab2ab07d353aa93dcc567106b5d571ebead929f12ebcd7ad.
//
// Solidity: event MinStalenesProposed(uint256 newMinStaleness, uint256 effectiveTime)
func (_SuperGovernor *SuperGovernorFilterer) WatchMinStalenesProposed(opts *bind.WatchOpts, sink chan<- *SuperGovernorMinStalenesProposed) (event.Subscription, error) {

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "MinStalenesProposed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorMinStalenesProposed)
				if err := _SuperGovernor.contract.UnpackLog(event, "MinStalenesProposed", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseMinStalenesProposed(log types.Log) (*SuperGovernorMinStalenesProposed, error) {
	event := new(SuperGovernorMinStalenesProposed)
	if err := _SuperGovernor.contract.UnpackLog(event, "MinStalenesProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorPPSOracleQuorumUpdatedIterator is returned from FilterPPSOracleQuorumUpdated and is used to iterate over the raw logs and unpacked data for PPSOracleQuorumUpdated events raised by the SuperGovernor contract.
type SuperGovernorPPSOracleQuorumUpdatedIterator struct {
	Event *SuperGovernorPPSOracleQuorumUpdated // Event containing the contract specifics and raw log

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
func (it *SuperGovernorPPSOracleQuorumUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorPPSOracleQuorumUpdated)
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
		it.Event = new(SuperGovernorPPSOracleQuorumUpdated)
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
func (it *SuperGovernorPPSOracleQuorumUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorPPSOracleQuorumUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorPPSOracleQuorumUpdated represents a PPSOracleQuorumUpdated event raised by the SuperGovernor contract.
type SuperGovernorPPSOracleQuorumUpdated struct {
	Quorum *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterPPSOracleQuorumUpdated is a free log retrieval operation binding the contract event 0xf957b69cfa930a437fa0211ed212fe9b40bfbf99f4e5734d9d6068834d33a928.
//
// Solidity: event PPSOracleQuorumUpdated(uint256 quorum)
func (_SuperGovernor *SuperGovernorFilterer) FilterPPSOracleQuorumUpdated(opts *bind.FilterOpts) (*SuperGovernorPPSOracleQuorumUpdatedIterator, error) {

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "PPSOracleQuorumUpdated")
	if err != nil {
		return nil, err
	}
	return &SuperGovernorPPSOracleQuorumUpdatedIterator{contract: _SuperGovernor.contract, event: "PPSOracleQuorumUpdated", logs: logs, sub: sub}, nil
}

// WatchPPSOracleQuorumUpdated is a free log subscription operation binding the contract event 0xf957b69cfa930a437fa0211ed212fe9b40bfbf99f4e5734d9d6068834d33a928.
//
// Solidity: event PPSOracleQuorumUpdated(uint256 quorum)
func (_SuperGovernor *SuperGovernorFilterer) WatchPPSOracleQuorumUpdated(opts *bind.WatchOpts, sink chan<- *SuperGovernorPPSOracleQuorumUpdated) (event.Subscription, error) {

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "PPSOracleQuorumUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorPPSOracleQuorumUpdated)
				if err := _SuperGovernor.contract.UnpackLog(event, "PPSOracleQuorumUpdated", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParsePPSOracleQuorumUpdated(log types.Log) (*SuperGovernorPPSOracleQuorumUpdated, error) {
	event := new(SuperGovernorPPSOracleQuorumUpdated)
	if err := _SuperGovernor.contract.UnpackLog(event, "PPSOracleQuorumUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorProtectedKeeperRegisteredIterator is returned from FilterProtectedKeeperRegistered and is used to iterate over the raw logs and unpacked data for ProtectedKeeperRegistered events raised by the SuperGovernor contract.
type SuperGovernorProtectedKeeperRegisteredIterator struct {
	Event *SuperGovernorProtectedKeeperRegistered // Event containing the contract specifics and raw log

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
func (it *SuperGovernorProtectedKeeperRegisteredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorProtectedKeeperRegistered)
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
		it.Event = new(SuperGovernorProtectedKeeperRegistered)
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
func (it *SuperGovernorProtectedKeeperRegisteredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorProtectedKeeperRegisteredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorProtectedKeeperRegistered represents a ProtectedKeeperRegistered event raised by the SuperGovernor contract.
type SuperGovernorProtectedKeeperRegistered struct {
	Keeper common.Address
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterProtectedKeeperRegistered is a free log retrieval operation binding the contract event 0x5a17551f8f59aacc175aed9daecc2461b2161d1ca643c75612710502de9d57b1.
//
// Solidity: event ProtectedKeeperRegistered(address indexed keeper)
func (_SuperGovernor *SuperGovernorFilterer) FilterProtectedKeeperRegistered(opts *bind.FilterOpts, keeper []common.Address) (*SuperGovernorProtectedKeeperRegisteredIterator, error) {

	var keeperRule []interface{}
	for _, keeperItem := range keeper {
		keeperRule = append(keeperRule, keeperItem)
	}

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "ProtectedKeeperRegistered", keeperRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorProtectedKeeperRegisteredIterator{contract: _SuperGovernor.contract, event: "ProtectedKeeperRegistered", logs: logs, sub: sub}, nil
}

// WatchProtectedKeeperRegistered is a free log subscription operation binding the contract event 0x5a17551f8f59aacc175aed9daecc2461b2161d1ca643c75612710502de9d57b1.
//
// Solidity: event ProtectedKeeperRegistered(address indexed keeper)
func (_SuperGovernor *SuperGovernorFilterer) WatchProtectedKeeperRegistered(opts *bind.WatchOpts, sink chan<- *SuperGovernorProtectedKeeperRegistered, keeper []common.Address) (event.Subscription, error) {

	var keeperRule []interface{}
	for _, keeperItem := range keeper {
		keeperRule = append(keeperRule, keeperItem)
	}

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "ProtectedKeeperRegistered", keeperRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorProtectedKeeperRegistered)
				if err := _SuperGovernor.contract.UnpackLog(event, "ProtectedKeeperRegistered", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseProtectedKeeperRegistered(log types.Log) (*SuperGovernorProtectedKeeperRegistered, error) {
	event := new(SuperGovernorProtectedKeeperRegistered)
	if err := _SuperGovernor.contract.UnpackLog(event, "ProtectedKeeperRegistered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorProtectedKeeperUnregisteredIterator is returned from FilterProtectedKeeperUnregistered and is used to iterate over the raw logs and unpacked data for ProtectedKeeperUnregistered events raised by the SuperGovernor contract.
type SuperGovernorProtectedKeeperUnregisteredIterator struct {
	Event *SuperGovernorProtectedKeeperUnregistered // Event containing the contract specifics and raw log

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
func (it *SuperGovernorProtectedKeeperUnregisteredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorProtectedKeeperUnregistered)
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
		it.Event = new(SuperGovernorProtectedKeeperUnregistered)
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
func (it *SuperGovernorProtectedKeeperUnregisteredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorProtectedKeeperUnregisteredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorProtectedKeeperUnregistered represents a ProtectedKeeperUnregistered event raised by the SuperGovernor contract.
type SuperGovernorProtectedKeeperUnregistered struct {
	Keeper common.Address
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterProtectedKeeperUnregistered is a free log retrieval operation binding the contract event 0xd5f663a5782ccd5e7465e8419aa75f38fdc175262978753ee490757f48d7318b.
//
// Solidity: event ProtectedKeeperUnregistered(address indexed keeper)
func (_SuperGovernor *SuperGovernorFilterer) FilterProtectedKeeperUnregistered(opts *bind.FilterOpts, keeper []common.Address) (*SuperGovernorProtectedKeeperUnregisteredIterator, error) {

	var keeperRule []interface{}
	for _, keeperItem := range keeper {
		keeperRule = append(keeperRule, keeperItem)
	}

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "ProtectedKeeperUnregistered", keeperRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorProtectedKeeperUnregisteredIterator{contract: _SuperGovernor.contract, event: "ProtectedKeeperUnregistered", logs: logs, sub: sub}, nil
}

// WatchProtectedKeeperUnregistered is a free log subscription operation binding the contract event 0xd5f663a5782ccd5e7465e8419aa75f38fdc175262978753ee490757f48d7318b.
//
// Solidity: event ProtectedKeeperUnregistered(address indexed keeper)
func (_SuperGovernor *SuperGovernorFilterer) WatchProtectedKeeperUnregistered(opts *bind.WatchOpts, sink chan<- *SuperGovernorProtectedKeeperUnregistered, keeper []common.Address) (event.Subscription, error) {

	var keeperRule []interface{}
	for _, keeperItem := range keeper {
		keeperRule = append(keeperRule, keeperItem)
	}

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "ProtectedKeeperUnregistered", keeperRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorProtectedKeeperUnregistered)
				if err := _SuperGovernor.contract.UnpackLog(event, "ProtectedKeeperUnregistered", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseProtectedKeeperUnregistered(log types.Log) (*SuperGovernorProtectedKeeperUnregistered, error) {
	event := new(SuperGovernorProtectedKeeperUnregistered)
	if err := _SuperGovernor.contract.UnpackLog(event, "ProtectedKeeperUnregistered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorRevenueShareUpdatedIterator is returned from FilterRevenueShareUpdated and is used to iterate over the raw logs and unpacked data for RevenueShareUpdated events raised by the SuperGovernor contract.
type SuperGovernorRevenueShareUpdatedIterator struct {
	Event *SuperGovernorRevenueShareUpdated // Event containing the contract specifics and raw log

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
func (it *SuperGovernorRevenueShareUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorRevenueShareUpdated)
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
		it.Event = new(SuperGovernorRevenueShareUpdated)
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
func (it *SuperGovernorRevenueShareUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorRevenueShareUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorRevenueShareUpdated represents a RevenueShareUpdated event raised by the SuperGovernor contract.
type SuperGovernorRevenueShareUpdated struct {
	Share *big.Int
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterRevenueShareUpdated is a free log retrieval operation binding the contract event 0x343a3cad72a9e3a0fe71e8417402226b647587dfd1713f79f85413ed27df7f7b.
//
// Solidity: event RevenueShareUpdated(uint256 share)
func (_SuperGovernor *SuperGovernorFilterer) FilterRevenueShareUpdated(opts *bind.FilterOpts) (*SuperGovernorRevenueShareUpdatedIterator, error) {

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "RevenueShareUpdated")
	if err != nil {
		return nil, err
	}
	return &SuperGovernorRevenueShareUpdatedIterator{contract: _SuperGovernor.contract, event: "RevenueShareUpdated", logs: logs, sub: sub}, nil
}

// WatchRevenueShareUpdated is a free log subscription operation binding the contract event 0x343a3cad72a9e3a0fe71e8417402226b647587dfd1713f79f85413ed27df7f7b.
//
// Solidity: event RevenueShareUpdated(uint256 share)
func (_SuperGovernor *SuperGovernorFilterer) WatchRevenueShareUpdated(opts *bind.WatchOpts, sink chan<- *SuperGovernorRevenueShareUpdated) (event.Subscription, error) {

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "RevenueShareUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorRevenueShareUpdated)
				if err := _SuperGovernor.contract.UnpackLog(event, "RevenueShareUpdated", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseRevenueShareUpdated(log types.Log) (*SuperGovernorRevenueShareUpdated, error) {
	event := new(SuperGovernorRevenueShareUpdated)
	if err := _SuperGovernor.contract.UnpackLog(event, "RevenueShareUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorRoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the SuperGovernor contract.
type SuperGovernorRoleAdminChangedIterator struct {
	Event *SuperGovernorRoleAdminChanged // Event containing the contract specifics and raw log

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
func (it *SuperGovernorRoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorRoleAdminChanged)
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
		it.Event = new(SuperGovernorRoleAdminChanged)
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
func (it *SuperGovernorRoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorRoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorRoleAdminChanged represents a RoleAdminChanged event raised by the SuperGovernor contract.
type SuperGovernorRoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_SuperGovernor *SuperGovernorFilterer) FilterRoleAdminChanged(opts *bind.FilterOpts, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (*SuperGovernorRoleAdminChangedIterator, error) {

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

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorRoleAdminChangedIterator{contract: _SuperGovernor.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_SuperGovernor *SuperGovernorFilterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *SuperGovernorRoleAdminChanged, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (event.Subscription, error) {

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

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorRoleAdminChanged)
				if err := _SuperGovernor.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseRoleAdminChanged(log types.Log) (*SuperGovernorRoleAdminChanged, error) {
	event := new(SuperGovernorRoleAdminChanged)
	if err := _SuperGovernor.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorRoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the SuperGovernor contract.
type SuperGovernorRoleGrantedIterator struct {
	Event *SuperGovernorRoleGranted // Event containing the contract specifics and raw log

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
func (it *SuperGovernorRoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorRoleGranted)
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
		it.Event = new(SuperGovernorRoleGranted)
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
func (it *SuperGovernorRoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorRoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorRoleGranted represents a RoleGranted event raised by the SuperGovernor contract.
type SuperGovernorRoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperGovernor *SuperGovernorFilterer) FilterRoleGranted(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*SuperGovernorRoleGrantedIterator, error) {

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

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorRoleGrantedIterator{contract: _SuperGovernor.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperGovernor *SuperGovernorFilterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *SuperGovernorRoleGranted, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorRoleGranted)
				if err := _SuperGovernor.contract.UnpackLog(event, "RoleGranted", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseRoleGranted(log types.Log) (*SuperGovernorRoleGranted, error) {
	event := new(SuperGovernorRoleGranted)
	if err := _SuperGovernor.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorRoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the SuperGovernor contract.
type SuperGovernorRoleRevokedIterator struct {
	Event *SuperGovernorRoleRevoked // Event containing the contract specifics and raw log

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
func (it *SuperGovernorRoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorRoleRevoked)
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
		it.Event = new(SuperGovernorRoleRevoked)
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
func (it *SuperGovernorRoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorRoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorRoleRevoked represents a RoleRevoked event raised by the SuperGovernor contract.
type SuperGovernorRoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperGovernor *SuperGovernorFilterer) FilterRoleRevoked(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*SuperGovernorRoleRevokedIterator, error) {

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

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorRoleRevokedIterator{contract: _SuperGovernor.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperGovernor *SuperGovernorFilterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *SuperGovernorRoleRevoked, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorRoleRevoked)
				if err := _SuperGovernor.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseRoleRevoked(log types.Log) (*SuperGovernorRoleRevoked, error) {
	event := new(SuperGovernorRoleRevoked)
	if err := _SuperGovernor.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorSuperBankHookMerkleRootProposedIterator is returned from FilterSuperBankHookMerkleRootProposed and is used to iterate over the raw logs and unpacked data for SuperBankHookMerkleRootProposed events raised by the SuperGovernor contract.
type SuperGovernorSuperBankHookMerkleRootProposedIterator struct {
	Event *SuperGovernorSuperBankHookMerkleRootProposed // Event containing the contract specifics and raw log

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
func (it *SuperGovernorSuperBankHookMerkleRootProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorSuperBankHookMerkleRootProposed)
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
		it.Event = new(SuperGovernorSuperBankHookMerkleRootProposed)
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
func (it *SuperGovernorSuperBankHookMerkleRootProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorSuperBankHookMerkleRootProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorSuperBankHookMerkleRootProposed represents a SuperBankHookMerkleRootProposed event raised by the SuperGovernor contract.
type SuperGovernorSuperBankHookMerkleRootProposed struct {
	Hook          common.Address
	NewRoot       [32]byte
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterSuperBankHookMerkleRootProposed is a free log retrieval operation binding the contract event 0x2f45381bbf8fc39bccf5516ecef3bec5e43aed86711ddaa35c12ab2d6073fd36.
//
// Solidity: event SuperBankHookMerkleRootProposed(address indexed hook, bytes32 newRoot, uint256 effectiveTime)
func (_SuperGovernor *SuperGovernorFilterer) FilterSuperBankHookMerkleRootProposed(opts *bind.FilterOpts, hook []common.Address) (*SuperGovernorSuperBankHookMerkleRootProposedIterator, error) {

	var hookRule []interface{}
	for _, hookItem := range hook {
		hookRule = append(hookRule, hookItem)
	}

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "SuperBankHookMerkleRootProposed", hookRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorSuperBankHookMerkleRootProposedIterator{contract: _SuperGovernor.contract, event: "SuperBankHookMerkleRootProposed", logs: logs, sub: sub}, nil
}

// WatchSuperBankHookMerkleRootProposed is a free log subscription operation binding the contract event 0x2f45381bbf8fc39bccf5516ecef3bec5e43aed86711ddaa35c12ab2d6073fd36.
//
// Solidity: event SuperBankHookMerkleRootProposed(address indexed hook, bytes32 newRoot, uint256 effectiveTime)
func (_SuperGovernor *SuperGovernorFilterer) WatchSuperBankHookMerkleRootProposed(opts *bind.WatchOpts, sink chan<- *SuperGovernorSuperBankHookMerkleRootProposed, hook []common.Address) (event.Subscription, error) {

	var hookRule []interface{}
	for _, hookItem := range hook {
		hookRule = append(hookRule, hookItem)
	}

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "SuperBankHookMerkleRootProposed", hookRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorSuperBankHookMerkleRootProposed)
				if err := _SuperGovernor.contract.UnpackLog(event, "SuperBankHookMerkleRootProposed", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseSuperBankHookMerkleRootProposed(log types.Log) (*SuperGovernorSuperBankHookMerkleRootProposed, error) {
	event := new(SuperGovernorSuperBankHookMerkleRootProposed)
	if err := _SuperGovernor.contract.UnpackLog(event, "SuperBankHookMerkleRootProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorSuperBankHookMerkleRootUpdatedIterator is returned from FilterSuperBankHookMerkleRootUpdated and is used to iterate over the raw logs and unpacked data for SuperBankHookMerkleRootUpdated events raised by the SuperGovernor contract.
type SuperGovernorSuperBankHookMerkleRootUpdatedIterator struct {
	Event *SuperGovernorSuperBankHookMerkleRootUpdated // Event containing the contract specifics and raw log

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
func (it *SuperGovernorSuperBankHookMerkleRootUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorSuperBankHookMerkleRootUpdated)
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
		it.Event = new(SuperGovernorSuperBankHookMerkleRootUpdated)
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
func (it *SuperGovernorSuperBankHookMerkleRootUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorSuperBankHookMerkleRootUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorSuperBankHookMerkleRootUpdated represents a SuperBankHookMerkleRootUpdated event raised by the SuperGovernor contract.
type SuperGovernorSuperBankHookMerkleRootUpdated struct {
	Hook    common.Address
	NewRoot [32]byte
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterSuperBankHookMerkleRootUpdated is a free log retrieval operation binding the contract event 0xac299fc62dbe9994754db34d3374ec4eb38e185895e08b5bbffa75e98bf2a53f.
//
// Solidity: event SuperBankHookMerkleRootUpdated(address indexed hook, bytes32 newRoot)
func (_SuperGovernor *SuperGovernorFilterer) FilterSuperBankHookMerkleRootUpdated(opts *bind.FilterOpts, hook []common.Address) (*SuperGovernorSuperBankHookMerkleRootUpdatedIterator, error) {

	var hookRule []interface{}
	for _, hookItem := range hook {
		hookRule = append(hookRule, hookItem)
	}

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "SuperBankHookMerkleRootUpdated", hookRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorSuperBankHookMerkleRootUpdatedIterator{contract: _SuperGovernor.contract, event: "SuperBankHookMerkleRootUpdated", logs: logs, sub: sub}, nil
}

// WatchSuperBankHookMerkleRootUpdated is a free log subscription operation binding the contract event 0xac299fc62dbe9994754db34d3374ec4eb38e185895e08b5bbffa75e98bf2a53f.
//
// Solidity: event SuperBankHookMerkleRootUpdated(address indexed hook, bytes32 newRoot)
func (_SuperGovernor *SuperGovernorFilterer) WatchSuperBankHookMerkleRootUpdated(opts *bind.WatchOpts, sink chan<- *SuperGovernorSuperBankHookMerkleRootUpdated, hook []common.Address) (event.Subscription, error) {

	var hookRule []interface{}
	for _, hookItem := range hook {
		hookRule = append(hookRule, hookItem)
	}

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "SuperBankHookMerkleRootUpdated", hookRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorSuperBankHookMerkleRootUpdated)
				if err := _SuperGovernor.contract.UnpackLog(event, "SuperBankHookMerkleRootUpdated", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseSuperBankHookMerkleRootUpdated(log types.Log) (*SuperGovernorSuperBankHookMerkleRootUpdated, error) {
	event := new(SuperGovernorSuperBankHookMerkleRootUpdated)
	if err := _SuperGovernor.contract.UnpackLog(event, "SuperBankHookMerkleRootUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorSuperformManagerAddedIterator is returned from FilterSuperformManagerAdded and is used to iterate over the raw logs and unpacked data for SuperformManagerAdded events raised by the SuperGovernor contract.
type SuperGovernorSuperformManagerAddedIterator struct {
	Event *SuperGovernorSuperformManagerAdded // Event containing the contract specifics and raw log

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
func (it *SuperGovernorSuperformManagerAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorSuperformManagerAdded)
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
		it.Event = new(SuperGovernorSuperformManagerAdded)
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
func (it *SuperGovernorSuperformManagerAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorSuperformManagerAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorSuperformManagerAdded represents a SuperformManagerAdded event raised by the SuperGovernor contract.
type SuperGovernorSuperformManagerAdded struct {
	Manager common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterSuperformManagerAdded is a free log retrieval operation binding the contract event 0x12c16151d1e0db8865cc79e38b297dcc5b372789b7efc7cc4460df4e3a4afbd6.
//
// Solidity: event SuperformManagerAdded(address indexed manager)
func (_SuperGovernor *SuperGovernorFilterer) FilterSuperformManagerAdded(opts *bind.FilterOpts, manager []common.Address) (*SuperGovernorSuperformManagerAddedIterator, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "SuperformManagerAdded", managerRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorSuperformManagerAddedIterator{contract: _SuperGovernor.contract, event: "SuperformManagerAdded", logs: logs, sub: sub}, nil
}

// WatchSuperformManagerAdded is a free log subscription operation binding the contract event 0x12c16151d1e0db8865cc79e38b297dcc5b372789b7efc7cc4460df4e3a4afbd6.
//
// Solidity: event SuperformManagerAdded(address indexed manager)
func (_SuperGovernor *SuperGovernorFilterer) WatchSuperformManagerAdded(opts *bind.WatchOpts, sink chan<- *SuperGovernorSuperformManagerAdded, manager []common.Address) (event.Subscription, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "SuperformManagerAdded", managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorSuperformManagerAdded)
				if err := _SuperGovernor.contract.UnpackLog(event, "SuperformManagerAdded", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseSuperformManagerAdded(log types.Log) (*SuperGovernorSuperformManagerAdded, error) {
	event := new(SuperGovernorSuperformManagerAdded)
	if err := _SuperGovernor.contract.UnpackLog(event, "SuperformManagerAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorSuperformManagerRemovedIterator is returned from FilterSuperformManagerRemoved and is used to iterate over the raw logs and unpacked data for SuperformManagerRemoved events raised by the SuperGovernor contract.
type SuperGovernorSuperformManagerRemovedIterator struct {
	Event *SuperGovernorSuperformManagerRemoved // Event containing the contract specifics and raw log

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
func (it *SuperGovernorSuperformManagerRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorSuperformManagerRemoved)
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
		it.Event = new(SuperGovernorSuperformManagerRemoved)
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
func (it *SuperGovernorSuperformManagerRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorSuperformManagerRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorSuperformManagerRemoved represents a SuperformManagerRemoved event raised by the SuperGovernor contract.
type SuperGovernorSuperformManagerRemoved struct {
	Manager common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterSuperformManagerRemoved is a free log retrieval operation binding the contract event 0x9ea6376bcd095bc346ab7f5c534391c1a6ba1bb5153caf5e068742acd4f55162.
//
// Solidity: event SuperformManagerRemoved(address indexed manager)
func (_SuperGovernor *SuperGovernorFilterer) FilterSuperformManagerRemoved(opts *bind.FilterOpts, manager []common.Address) (*SuperGovernorSuperformManagerRemovedIterator, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "SuperformManagerRemoved", managerRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorSuperformManagerRemovedIterator{contract: _SuperGovernor.contract, event: "SuperformManagerRemoved", logs: logs, sub: sub}, nil
}

// WatchSuperformManagerRemoved is a free log subscription operation binding the contract event 0x9ea6376bcd095bc346ab7f5c534391c1a6ba1bb5153caf5e068742acd4f55162.
//
// Solidity: event SuperformManagerRemoved(address indexed manager)
func (_SuperGovernor *SuperGovernorFilterer) WatchSuperformManagerRemoved(opts *bind.WatchOpts, sink chan<- *SuperGovernorSuperformManagerRemoved, manager []common.Address) (event.Subscription, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "SuperformManagerRemoved", managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorSuperformManagerRemoved)
				if err := _SuperGovernor.contract.UnpackLog(event, "SuperformManagerRemoved", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseSuperformManagerRemoved(log types.Log) (*SuperGovernorSuperformManagerRemoved, error) {
	event := new(SuperGovernorSuperformManagerRemoved)
	if err := _SuperGovernor.contract.UnpackLog(event, "SuperformManagerRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorUpkeepPaymentsChangeProposedIterator is returned from FilterUpkeepPaymentsChangeProposed and is used to iterate over the raw logs and unpacked data for UpkeepPaymentsChangeProposed events raised by the SuperGovernor contract.
type SuperGovernorUpkeepPaymentsChangeProposedIterator struct {
	Event *SuperGovernorUpkeepPaymentsChangeProposed // Event containing the contract specifics and raw log

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
func (it *SuperGovernorUpkeepPaymentsChangeProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorUpkeepPaymentsChangeProposed)
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
		it.Event = new(SuperGovernorUpkeepPaymentsChangeProposed)
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
func (it *SuperGovernorUpkeepPaymentsChangeProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorUpkeepPaymentsChangeProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorUpkeepPaymentsChangeProposed represents a UpkeepPaymentsChangeProposed event raised by the SuperGovernor contract.
type SuperGovernorUpkeepPaymentsChangeProposed struct {
	Enabled       bool
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterUpkeepPaymentsChangeProposed is a free log retrieval operation binding the contract event 0x3ccaf2442d2b29874fd84ceba9675d97d4dde7d521be650f67faab29a9afb10a.
//
// Solidity: event UpkeepPaymentsChangeProposed(bool enabled, uint256 effectiveTime)
func (_SuperGovernor *SuperGovernorFilterer) FilterUpkeepPaymentsChangeProposed(opts *bind.FilterOpts) (*SuperGovernorUpkeepPaymentsChangeProposedIterator, error) {

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "UpkeepPaymentsChangeProposed")
	if err != nil {
		return nil, err
	}
	return &SuperGovernorUpkeepPaymentsChangeProposedIterator{contract: _SuperGovernor.contract, event: "UpkeepPaymentsChangeProposed", logs: logs, sub: sub}, nil
}

// WatchUpkeepPaymentsChangeProposed is a free log subscription operation binding the contract event 0x3ccaf2442d2b29874fd84ceba9675d97d4dde7d521be650f67faab29a9afb10a.
//
// Solidity: event UpkeepPaymentsChangeProposed(bool enabled, uint256 effectiveTime)
func (_SuperGovernor *SuperGovernorFilterer) WatchUpkeepPaymentsChangeProposed(opts *bind.WatchOpts, sink chan<- *SuperGovernorUpkeepPaymentsChangeProposed) (event.Subscription, error) {

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "UpkeepPaymentsChangeProposed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorUpkeepPaymentsChangeProposed)
				if err := _SuperGovernor.contract.UnpackLog(event, "UpkeepPaymentsChangeProposed", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseUpkeepPaymentsChangeProposed(log types.Log) (*SuperGovernorUpkeepPaymentsChangeProposed, error) {
	event := new(SuperGovernorUpkeepPaymentsChangeProposed)
	if err := _SuperGovernor.contract.UnpackLog(event, "UpkeepPaymentsChangeProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorUpkeepPaymentsChangedIterator is returned from FilterUpkeepPaymentsChanged and is used to iterate over the raw logs and unpacked data for UpkeepPaymentsChanged events raised by the SuperGovernor contract.
type SuperGovernorUpkeepPaymentsChangedIterator struct {
	Event *SuperGovernorUpkeepPaymentsChanged // Event containing the contract specifics and raw log

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
func (it *SuperGovernorUpkeepPaymentsChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorUpkeepPaymentsChanged)
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
		it.Event = new(SuperGovernorUpkeepPaymentsChanged)
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
func (it *SuperGovernorUpkeepPaymentsChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorUpkeepPaymentsChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorUpkeepPaymentsChanged represents a UpkeepPaymentsChanged event raised by the SuperGovernor contract.
type SuperGovernorUpkeepPaymentsChanged struct {
	Enabled bool
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterUpkeepPaymentsChanged is a free log retrieval operation binding the contract event 0x434397fd19989030741a6dd038e45b209af876fb83cafbd750fc5ad51be91ce9.
//
// Solidity: event UpkeepPaymentsChanged(bool enabled)
func (_SuperGovernor *SuperGovernorFilterer) FilterUpkeepPaymentsChanged(opts *bind.FilterOpts) (*SuperGovernorUpkeepPaymentsChangedIterator, error) {

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "UpkeepPaymentsChanged")
	if err != nil {
		return nil, err
	}
	return &SuperGovernorUpkeepPaymentsChangedIterator{contract: _SuperGovernor.contract, event: "UpkeepPaymentsChanged", logs: logs, sub: sub}, nil
}

// WatchUpkeepPaymentsChanged is a free log subscription operation binding the contract event 0x434397fd19989030741a6dd038e45b209af876fb83cafbd750fc5ad51be91ce9.
//
// Solidity: event UpkeepPaymentsChanged(bool enabled)
func (_SuperGovernor *SuperGovernorFilterer) WatchUpkeepPaymentsChanged(opts *bind.WatchOpts, sink chan<- *SuperGovernorUpkeepPaymentsChanged) (event.Subscription, error) {

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "UpkeepPaymentsChanged")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorUpkeepPaymentsChanged)
				if err := _SuperGovernor.contract.UnpackLog(event, "UpkeepPaymentsChanged", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseUpkeepPaymentsChanged(log types.Log) (*SuperGovernorUpkeepPaymentsChanged, error) {
	event := new(SuperGovernorUpkeepPaymentsChanged)
	if err := _SuperGovernor.contract.UnpackLog(event, "UpkeepPaymentsChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorValidatorAddedIterator is returned from FilterValidatorAdded and is used to iterate over the raw logs and unpacked data for ValidatorAdded events raised by the SuperGovernor contract.
type SuperGovernorValidatorAddedIterator struct {
	Event *SuperGovernorValidatorAdded // Event containing the contract specifics and raw log

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
func (it *SuperGovernorValidatorAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorValidatorAdded)
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
		it.Event = new(SuperGovernorValidatorAdded)
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
func (it *SuperGovernorValidatorAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorValidatorAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorValidatorAdded represents a ValidatorAdded event raised by the SuperGovernor contract.
type SuperGovernorValidatorAdded struct {
	Validator   common.Address
	BlockNumber *big.Int
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterValidatorAdded is a free log retrieval operation binding the contract event 0x9000b209805850a65058f21361a9978cb30f1413ed555553ab52a59b440b5d99.
//
// Solidity: event ValidatorAdded(address indexed validator, uint256 blockNumber)
func (_SuperGovernor *SuperGovernorFilterer) FilterValidatorAdded(opts *bind.FilterOpts, validator []common.Address) (*SuperGovernorValidatorAddedIterator, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "ValidatorAdded", validatorRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorValidatorAddedIterator{contract: _SuperGovernor.contract, event: "ValidatorAdded", logs: logs, sub: sub}, nil
}

// WatchValidatorAdded is a free log subscription operation binding the contract event 0x9000b209805850a65058f21361a9978cb30f1413ed555553ab52a59b440b5d99.
//
// Solidity: event ValidatorAdded(address indexed validator, uint256 blockNumber)
func (_SuperGovernor *SuperGovernorFilterer) WatchValidatorAdded(opts *bind.WatchOpts, sink chan<- *SuperGovernorValidatorAdded, validator []common.Address) (event.Subscription, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "ValidatorAdded", validatorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorValidatorAdded)
				if err := _SuperGovernor.contract.UnpackLog(event, "ValidatorAdded", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseValidatorAdded(log types.Log) (*SuperGovernorValidatorAdded, error) {
	event := new(SuperGovernorValidatorAdded)
	if err := _SuperGovernor.contract.UnpackLog(event, "ValidatorAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperGovernorValidatorRemovedIterator is returned from FilterValidatorRemoved and is used to iterate over the raw logs and unpacked data for ValidatorRemoved events raised by the SuperGovernor contract.
type SuperGovernorValidatorRemovedIterator struct {
	Event *SuperGovernorValidatorRemoved // Event containing the contract specifics and raw log

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
func (it *SuperGovernorValidatorRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperGovernorValidatorRemoved)
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
		it.Event = new(SuperGovernorValidatorRemoved)
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
func (it *SuperGovernorValidatorRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperGovernorValidatorRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperGovernorValidatorRemoved represents a ValidatorRemoved event raised by the SuperGovernor contract.
type SuperGovernorValidatorRemoved struct {
	Validator   common.Address
	BlockNumber *big.Int
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterValidatorRemoved is a free log retrieval operation binding the contract event 0x50ecbf35c0ff0910f48ecaf45471c41781b549230264f6cb51997d7d425a02c3.
//
// Solidity: event ValidatorRemoved(address indexed validator, uint256 blockNumber)
func (_SuperGovernor *SuperGovernorFilterer) FilterValidatorRemoved(opts *bind.FilterOpts, validator []common.Address) (*SuperGovernorValidatorRemovedIterator, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}

	logs, sub, err := _SuperGovernor.contract.FilterLogs(opts, "ValidatorRemoved", validatorRule)
	if err != nil {
		return nil, err
	}
	return &SuperGovernorValidatorRemovedIterator{contract: _SuperGovernor.contract, event: "ValidatorRemoved", logs: logs, sub: sub}, nil
}

// WatchValidatorRemoved is a free log subscription operation binding the contract event 0x50ecbf35c0ff0910f48ecaf45471c41781b549230264f6cb51997d7d425a02c3.
//
// Solidity: event ValidatorRemoved(address indexed validator, uint256 blockNumber)
func (_SuperGovernor *SuperGovernorFilterer) WatchValidatorRemoved(opts *bind.WatchOpts, sink chan<- *SuperGovernorValidatorRemoved, validator []common.Address) (event.Subscription, error) {

	var validatorRule []interface{}
	for _, validatorItem := range validator {
		validatorRule = append(validatorRule, validatorItem)
	}

	logs, sub, err := _SuperGovernor.contract.WatchLogs(opts, "ValidatorRemoved", validatorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperGovernorValidatorRemoved)
				if err := _SuperGovernor.contract.UnpackLog(event, "ValidatorRemoved", log); err != nil {
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
func (_SuperGovernor *SuperGovernorFilterer) ParseValidatorRemoved(log types.Log) (*SuperGovernorValidatorRemoved, error) {
	event := new(SuperGovernorValidatorRemoved)
	if err := _SuperGovernor.contract.UnpackLog(event, "ValidatorRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
