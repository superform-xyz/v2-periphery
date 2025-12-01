// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package UnsafeSuperVaultAggregator

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

// ISuperVaultAggregatorForwardPPSArgs is an auto generated low-level Go binding around an user-defined struct.
type ISuperVaultAggregatorForwardPPSArgs struct {
	Strategies      []common.Address
	Ppss            []*big.Int
	Timestamps      []*big.Int
	UpdateAuthority common.Address
}

// ISuperVaultAggregatorValidateHookArgs is an auto generated low-level Go binding around an user-defined struct.
type ISuperVaultAggregatorValidateHookArgs struct {
	HookAddress   common.Address
	HookArgs      []byte
	GlobalProof   [][32]byte
	StrategyProof [][32]byte
}

// ISuperVaultAggregatorVaultCreationParams is an auto generated low-level Go binding around an user-defined struct.
type ISuperVaultAggregatorVaultCreationParams struct {
	Asset             common.Address
	Name              string
	Symbol            string
	MainManager       common.Address
	SecondaryManagers []common.Address
	MinUpdateInterval *big.Int
	MaxStaleness      *big.Int
	FeeConfig         ISuperVaultStrategyFeeConfig
}

// ISuperVaultStrategyFeeConfig is an auto generated low-level Go binding around an user-defined struct.
type ISuperVaultStrategyFeeConfig struct {
	PerformanceFeeBps *big.Int
	ManagementFeeBps  *big.Int
	Recipient         common.Address
}

// UnsafeSuperVaultAggregatorMetaData contains all meta data concerning the UnsafeSuperVaultAggregator contract.
var UnsafeSuperVaultAggregatorMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"superGovernor_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"vaultImpl_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"strategyImpl_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"escrowImpl_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"ESCROW_IMPLEMENTATION\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"MAX_SECONDARY_MANAGERS\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"STRATEGY_IMPLEMENTATION\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_GOVERNOR\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISuperGovernor\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"UPKEEP_WITHDRAWAL_TIMELOCK\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"VAULT_IMPLEMENTATION\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addSecondaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"cancelChangePrimaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"cancelMinUpdateIntervalChange\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"changeGlobalLeavesStatus\",\"inputs\":[{\"name\":\"leaves\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"},{\"name\":\"statuses\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"changePrimaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"feeRecipient\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"claimUpkeep\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"claimableUpkeep\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"createVault\",\"inputs\":[{\"name\":\"params\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultAggregator.VaultCreationParams\",\"components\":[{\"name\":\"asset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"symbol\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"mainManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"secondaryManagers\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"minUpdateInterval\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxStaleness\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"feeConfig\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultStrategy.FeeConfig\",\"components\":[{\"name\":\"performanceFeeBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"managementFeeBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"recipient\",\"type\":\"address\",\"internalType\":\"address\"}]}]}],\"outputs\":[{\"name\":\"superVault\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"escrow\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"depositUpkeep\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeChangePrimaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeGlobalHooksRootUpdate\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeMinUpdateIntervalChange\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeStrategyHooksRootUpdate\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeWithdrawUpkeep\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"forwardPPS\",\"inputs\":[{\"name\":\"args\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultAggregator.ForwardPPSArgs\",\"components\":[{\"name\":\"strategies\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"ppss\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"timestamps\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"updateAuthority\",\"type\":\"address\",\"internalType\":\"address\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getAllSuperVaultEscrows\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAllSuperVaultStrategies\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAllSuperVaults\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCurrentNonce\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getDeviationThreshold\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"deviationThreshold\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getGlobalHooksRoot\",\"inputs\":[],\"outputs\":[{\"name\":\"root\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getHooksRootUpdateTimelock\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getLastUnpauseTimestamp\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getLastUpdateTimestamp\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMainManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMaxStaleness\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"staleness\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMinUpdateInterval\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"interval\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getPPS\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"pps\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getPendingManagerChange\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"proposedManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedGlobalHooksRoot\",\"inputs\":[],\"outputs\":[{\"name\":\"root\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedMinUpdateInterval\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"proposedInterval\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedStrategyHooksRoot\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"root\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSecondaryManagers\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getStrategyHooksRoot\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"root\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSuperVaultEscrowsCount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSuperVaultStrategiesCount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSuperVaultsCount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getUpkeepBalance\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isAnyManager\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isGlobalHooksRootActive\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isGlobalHooksRootVetoed\",\"inputs\":[],\"outputs\":[{\"name\":\"vetoed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isMainManager\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isPPSStale\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"isStale\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isSecondaryManager\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isStrategyHooksRootVetoed\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"vetoed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isStrategyPaused\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"isPaused\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pauseStrategy\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"pendingUpkeepWithdrawals\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proposeChangePrimaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"feeRecipient\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeGlobalHooksRoot\",\"inputs\":[{\"name\":\"newRoot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeMinUpdateIntervalChange\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newMinUpdateInterval\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeStrategyHooksRoot\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newRoot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeWithdrawUpkeep\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeSecondaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"resetHighWaterMark\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGlobalHooksRootVetoStatus\",\"inputs\":[{\"name\":\"vetoed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setHooksRootUpdateTimelock\",\"inputs\":[{\"name\":\"newTimelock\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setStrategyHooksRootVetoStatus\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"vetoed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"superVaultEscrows\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"superVaultStrategies\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"superVaults\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"unpauseStrategy\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"updateDeviationThreshold\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"deviationThreshold_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"updatePPSAfterSkim\",\"inputs\":[{\"name\":\"newPPS\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"feeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"validateHook\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultAggregator.ValidateHookArgs\",\"components\":[{\"name\":\"hookAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"hookArgs\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"globalProof\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"},{\"name\":\"strategyProof\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"}]}],\"outputs\":[{\"name\":\"isValid\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"validateHooks\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"argsArray\",\"type\":\"tuple[]\",\"internalType\":\"structISuperVaultAggregator.ValidateHookArgs[]\",\"components\":[{\"name\":\"hookAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"hookArgs\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"globalProof\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"},{\"name\":\"strategyProof\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"}]}],\"outputs\":[{\"name\":\"validHooks\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"}],\"stateMutability\":\"pure\"},{\"type\":\"event\",\"name\":\"DeviationThresholdUpdated\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"deviationThreshold\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"GlobalHooksRootUpdateProposed\",\"inputs\":[{\"name\":\"root\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"GlobalHooksRootUpdated\",\"inputs\":[{\"name\":\"oldRoot\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newRoot\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"GlobalHooksRootVetoStatusChanged\",\"inputs\":[{\"name\":\"vetoed\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"},{\"name\":\"root\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"GlobalLeavesStatusChanged\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"leaves\",\"type\":\"bytes32[]\",\"indexed\":false,\"internalType\":\"bytes32[]\"},{\"name\":\"statuses\",\"type\":\"bool[]\",\"indexed\":false,\"internalType\":\"bool[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"HighWaterMarkReset\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newHWM\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"HooksRootUpdateTimelockChanged\",\"inputs\":[{\"name\":\"newTimelock\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"InsufficientUpkeep\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"strategyAddr\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"balance\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"cost\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MinUpdateIntervalChangeCancelled\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"cancelledInterval\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MinUpdateIntervalChangeProposed\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"proposer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newMinUpdateInterval\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MinUpdateIntervalChangeRejected\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"proposedInterval\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"currentMaxStaleness\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MinUpdateIntervalChanged\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"oldMinUpdateInterval\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"newMinUpdateInterval\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OldPrimaryManagerRemoved\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"oldManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSUpdateRejectedStrategyPaused\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSUpdated\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"pps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSUpdatedAfterSkim\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"oldPPS\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"newPPS\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"feeAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PrimaryManagerChangeCancelled\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"cancelledManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PrimaryManagerChangeProposed\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"proposer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"feeRecipient\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PrimaryManagerChanged\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"oldManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"feeRecipient\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ProvidedTimestampExceedsBlockTimestamp\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"argsTimestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"blockTimestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SecondaryManagerAdded\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SecondaryManagerRemoved\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StaleSignatureAfterUnpause\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"signatureTimestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"lastUnpauseTimestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StaleUpdate\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"updateAuthority\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyCheckFailed\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"reason\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyHooksRootUpdateProposed\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"proposer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"root\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyHooksRootUpdated\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"oldRoot\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"newRoot\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyHooksRootVetoStatusChanged\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"vetoed\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"},{\"name\":\"root\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyPPSStale\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyPPSStaleReset\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyPaused\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyUnpaused\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TimestampNotMonotonic\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UnknownStrategy\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpdateTooFrequent\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepClaimed\",\"inputs\":[{\"name\":\"superBank\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepDeposited\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"depositor\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepSpent\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"balance\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"claimableUpkeep\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepWithdrawalCancelled\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepWithdrawalProposed\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"mainManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepWithdrawn\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"withdrawer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"VaultDeployed\",\"inputs\":[{\"name\":\"vault\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"escrow\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"asset\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"name\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"symbol\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ARRAY_LENGTH_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CALLER_NOT_AUTHORIZED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FailedDeployment\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"HOOK_VALIDATION_FAILED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INDEX_OUT_OF_BOUNDS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_UPKEEP\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_ARRAY_LENGTH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_ASSET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_ASSET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_TIMESTAMP\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"INVALID_VAULT_PARAMS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InsufficientBalance\",\"inputs\":[{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"needed\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"MANAGER_ALREADY_EXISTS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MANAGER_NOT_FOUND\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MAX_STALENESS_TOO_LOW\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MIN_UPDATE_INTERVAL_TOO_HIGH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MISMATCHED_ARRAY_LENGTHS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_PENDING_GLOBAL_ROOT_CHANGE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_PENDING_MANAGER_CHANGE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_PENDING_MIN_UPDATE_INTERVAL_CHANGE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PPS_DEDUCTION_TOO_LARGE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PPS_MUST_DECREASE_AFTER_SKIM\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PPS_STALE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ROOT_UPDATE_NOT_READY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SECONDARY_MANAGER_CANNOT_BE_PRIMARY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"STRATEGY_ALREADY_PAUSED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"STRATEGY_NOT_PAUSED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"STRATEGY_PAUSED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"TIMELOCK_NOT_EXPIRED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"TOO_MANY_SECONDARY_MANAGERS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UNAUTHORIZED_CALLER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UNAUTHORIZED_PPS_ORACLE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UNAUTHORIZED_UPDATE_AUTHORITY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UNKNOWN_STRATEGY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UPKEEP_WITHDRAWAL_NOT_FOUND\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UPKEEP_WITHDRAWAL_NOT_READY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_AMOUNT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_ARRAY_LENGTH\",\"inputs\":[]}]",
}

// UnsafeSuperVaultAggregatorABI is the input ABI used to generate the binding from.
// Deprecated: Use UnsafeSuperVaultAggregatorMetaData.ABI instead.
var UnsafeSuperVaultAggregatorABI = UnsafeSuperVaultAggregatorMetaData.ABI

// UnsafeSuperVaultAggregator is an auto generated Go binding around an Ethereum contract.
type UnsafeSuperVaultAggregator struct {
	UnsafeSuperVaultAggregatorCaller     // Read-only binding to the contract
	UnsafeSuperVaultAggregatorTransactor // Write-only binding to the contract
	UnsafeSuperVaultAggregatorFilterer   // Log filterer for contract events
}

// UnsafeSuperVaultAggregatorCaller is an auto generated read-only Go binding around an Ethereum contract.
type UnsafeSuperVaultAggregatorCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// UnsafeSuperVaultAggregatorTransactor is an auto generated write-only Go binding around an Ethereum contract.
type UnsafeSuperVaultAggregatorTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// UnsafeSuperVaultAggregatorFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type UnsafeSuperVaultAggregatorFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// UnsafeSuperVaultAggregatorSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type UnsafeSuperVaultAggregatorSession struct {
	Contract     *UnsafeSuperVaultAggregator // Generic contract binding to set the session for
	CallOpts     bind.CallOpts               // Call options to use throughout this session
	TransactOpts bind.TransactOpts           // Transaction auth options to use throughout this session
}

// UnsafeSuperVaultAggregatorCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type UnsafeSuperVaultAggregatorCallerSession struct {
	Contract *UnsafeSuperVaultAggregatorCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts                     // Call options to use throughout this session
}

// UnsafeSuperVaultAggregatorTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type UnsafeSuperVaultAggregatorTransactorSession struct {
	Contract     *UnsafeSuperVaultAggregatorTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts                     // Transaction auth options to use throughout this session
}

// UnsafeSuperVaultAggregatorRaw is an auto generated low-level Go binding around an Ethereum contract.
type UnsafeSuperVaultAggregatorRaw struct {
	Contract *UnsafeSuperVaultAggregator // Generic contract binding to access the raw methods on
}

// UnsafeSuperVaultAggregatorCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type UnsafeSuperVaultAggregatorCallerRaw struct {
	Contract *UnsafeSuperVaultAggregatorCaller // Generic read-only contract binding to access the raw methods on
}

// UnsafeSuperVaultAggregatorTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type UnsafeSuperVaultAggregatorTransactorRaw struct {
	Contract *UnsafeSuperVaultAggregatorTransactor // Generic write-only contract binding to access the raw methods on
}

// NewUnsafeSuperVaultAggregator creates a new instance of UnsafeSuperVaultAggregator, bound to a specific deployed contract.
func NewUnsafeSuperVaultAggregator(address common.Address, backend bind.ContractBackend) (*UnsafeSuperVaultAggregator, error) {
	contract, err := bindUnsafeSuperVaultAggregator(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregator{UnsafeSuperVaultAggregatorCaller: UnsafeSuperVaultAggregatorCaller{contract: contract}, UnsafeSuperVaultAggregatorTransactor: UnsafeSuperVaultAggregatorTransactor{contract: contract}, UnsafeSuperVaultAggregatorFilterer: UnsafeSuperVaultAggregatorFilterer{contract: contract}}, nil
}

// NewUnsafeSuperVaultAggregatorCaller creates a new read-only instance of UnsafeSuperVaultAggregator, bound to a specific deployed contract.
func NewUnsafeSuperVaultAggregatorCaller(address common.Address, caller bind.ContractCaller) (*UnsafeSuperVaultAggregatorCaller, error) {
	contract, err := bindUnsafeSuperVaultAggregator(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorCaller{contract: contract}, nil
}

// NewUnsafeSuperVaultAggregatorTransactor creates a new write-only instance of UnsafeSuperVaultAggregator, bound to a specific deployed contract.
func NewUnsafeSuperVaultAggregatorTransactor(address common.Address, transactor bind.ContractTransactor) (*UnsafeSuperVaultAggregatorTransactor, error) {
	contract, err := bindUnsafeSuperVaultAggregator(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorTransactor{contract: contract}, nil
}

// NewUnsafeSuperVaultAggregatorFilterer creates a new log filterer instance of UnsafeSuperVaultAggregator, bound to a specific deployed contract.
func NewUnsafeSuperVaultAggregatorFilterer(address common.Address, filterer bind.ContractFilterer) (*UnsafeSuperVaultAggregatorFilterer, error) {
	contract, err := bindUnsafeSuperVaultAggregator(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorFilterer{contract: contract}, nil
}

// bindUnsafeSuperVaultAggregator binds a generic wrapper to an already deployed contract.
func bindUnsafeSuperVaultAggregator(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := UnsafeSuperVaultAggregatorMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _UnsafeSuperVaultAggregator.Contract.UnsafeSuperVaultAggregatorCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.UnsafeSuperVaultAggregatorTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.UnsafeSuperVaultAggregatorTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _UnsafeSuperVaultAggregator.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.contract.Transact(opts, method, params...)
}

// ESCROWIMPLEMENTATION is a free data retrieval call binding the contract method 0x1de18ae6.
//
// Solidity: function ESCROW_IMPLEMENTATION() view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) ESCROWIMPLEMENTATION(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "ESCROW_IMPLEMENTATION")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ESCROWIMPLEMENTATION is a free data retrieval call binding the contract method 0x1de18ae6.
//
// Solidity: function ESCROW_IMPLEMENTATION() view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ESCROWIMPLEMENTATION() (common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.ESCROWIMPLEMENTATION(&_UnsafeSuperVaultAggregator.CallOpts)
}

// ESCROWIMPLEMENTATION is a free data retrieval call binding the contract method 0x1de18ae6.
//
// Solidity: function ESCROW_IMPLEMENTATION() view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) ESCROWIMPLEMENTATION() (common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.ESCROWIMPLEMENTATION(&_UnsafeSuperVaultAggregator.CallOpts)
}

// MAXSECONDARYMANAGERS is a free data retrieval call binding the contract method 0x08db8901.
//
// Solidity: function MAX_SECONDARY_MANAGERS() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) MAXSECONDARYMANAGERS(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "MAX_SECONDARY_MANAGERS")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MAXSECONDARYMANAGERS is a free data retrieval call binding the contract method 0x08db8901.
//
// Solidity: function MAX_SECONDARY_MANAGERS() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) MAXSECONDARYMANAGERS() (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.MAXSECONDARYMANAGERS(&_UnsafeSuperVaultAggregator.CallOpts)
}

// MAXSECONDARYMANAGERS is a free data retrieval call binding the contract method 0x08db8901.
//
// Solidity: function MAX_SECONDARY_MANAGERS() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) MAXSECONDARYMANAGERS() (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.MAXSECONDARYMANAGERS(&_UnsafeSuperVaultAggregator.CallOpts)
}

// STRATEGYIMPLEMENTATION is a free data retrieval call binding the contract method 0xf301061d.
//
// Solidity: function STRATEGY_IMPLEMENTATION() view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) STRATEGYIMPLEMENTATION(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "STRATEGY_IMPLEMENTATION")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// STRATEGYIMPLEMENTATION is a free data retrieval call binding the contract method 0xf301061d.
//
// Solidity: function STRATEGY_IMPLEMENTATION() view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) STRATEGYIMPLEMENTATION() (common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.STRATEGYIMPLEMENTATION(&_UnsafeSuperVaultAggregator.CallOpts)
}

// STRATEGYIMPLEMENTATION is a free data retrieval call binding the contract method 0xf301061d.
//
// Solidity: function STRATEGY_IMPLEMENTATION() view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) STRATEGYIMPLEMENTATION() (common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.STRATEGYIMPLEMENTATION(&_UnsafeSuperVaultAggregator.CallOpts)
}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) SUPERGOVERNOR(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "SUPER_GOVERNOR")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) SUPERGOVERNOR() (common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.SUPERGOVERNOR(&_UnsafeSuperVaultAggregator.CallOpts)
}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) SUPERGOVERNOR() (common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.SUPERGOVERNOR(&_UnsafeSuperVaultAggregator.CallOpts)
}

// UPKEEPWITHDRAWALTIMELOCK is a free data retrieval call binding the contract method 0xf00e2f88.
//
// Solidity: function UPKEEP_WITHDRAWAL_TIMELOCK() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) UPKEEPWITHDRAWALTIMELOCK(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "UPKEEP_WITHDRAWAL_TIMELOCK")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// UPKEEPWITHDRAWALTIMELOCK is a free data retrieval call binding the contract method 0xf00e2f88.
//
// Solidity: function UPKEEP_WITHDRAWAL_TIMELOCK() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) UPKEEPWITHDRAWALTIMELOCK() (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.UPKEEPWITHDRAWALTIMELOCK(&_UnsafeSuperVaultAggregator.CallOpts)
}

// UPKEEPWITHDRAWALTIMELOCK is a free data retrieval call binding the contract method 0xf00e2f88.
//
// Solidity: function UPKEEP_WITHDRAWAL_TIMELOCK() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) UPKEEPWITHDRAWALTIMELOCK() (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.UPKEEPWITHDRAWALTIMELOCK(&_UnsafeSuperVaultAggregator.CallOpts)
}

// VAULTIMPLEMENTATION is a free data retrieval call binding the contract method 0x1f9b5aaf.
//
// Solidity: function VAULT_IMPLEMENTATION() view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) VAULTIMPLEMENTATION(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "VAULT_IMPLEMENTATION")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// VAULTIMPLEMENTATION is a free data retrieval call binding the contract method 0x1f9b5aaf.
//
// Solidity: function VAULT_IMPLEMENTATION() view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) VAULTIMPLEMENTATION() (common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.VAULTIMPLEMENTATION(&_UnsafeSuperVaultAggregator.CallOpts)
}

// VAULTIMPLEMENTATION is a free data retrieval call binding the contract method 0x1f9b5aaf.
//
// Solidity: function VAULT_IMPLEMENTATION() view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) VAULTIMPLEMENTATION() (common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.VAULTIMPLEMENTATION(&_UnsafeSuperVaultAggregator.CallOpts)
}

// ClaimableUpkeep is a free data retrieval call binding the contract method 0x05027eee.
//
// Solidity: function claimableUpkeep() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) ClaimableUpkeep(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "claimableUpkeep")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ClaimableUpkeep is a free data retrieval call binding the contract method 0x05027eee.
//
// Solidity: function claimableUpkeep() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ClaimableUpkeep() (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.ClaimableUpkeep(&_UnsafeSuperVaultAggregator.CallOpts)
}

// ClaimableUpkeep is a free data retrieval call binding the contract method 0x05027eee.
//
// Solidity: function claimableUpkeep() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) ClaimableUpkeep() (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.ClaimableUpkeep(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetAllSuperVaultEscrows is a free data retrieval call binding the contract method 0x154fd23f.
//
// Solidity: function getAllSuperVaultEscrows() view returns(address[])
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetAllSuperVaultEscrows(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getAllSuperVaultEscrows")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetAllSuperVaultEscrows is a free data retrieval call binding the contract method 0x154fd23f.
//
// Solidity: function getAllSuperVaultEscrows() view returns(address[])
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetAllSuperVaultEscrows() ([]common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetAllSuperVaultEscrows(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetAllSuperVaultEscrows is a free data retrieval call binding the contract method 0x154fd23f.
//
// Solidity: function getAllSuperVaultEscrows() view returns(address[])
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetAllSuperVaultEscrows() ([]common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetAllSuperVaultEscrows(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetAllSuperVaultStrategies is a free data retrieval call binding the contract method 0x8e9615c9.
//
// Solidity: function getAllSuperVaultStrategies() view returns(address[])
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetAllSuperVaultStrategies(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getAllSuperVaultStrategies")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetAllSuperVaultStrategies is a free data retrieval call binding the contract method 0x8e9615c9.
//
// Solidity: function getAllSuperVaultStrategies() view returns(address[])
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetAllSuperVaultStrategies() ([]common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetAllSuperVaultStrategies(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetAllSuperVaultStrategies is a free data retrieval call binding the contract method 0x8e9615c9.
//
// Solidity: function getAllSuperVaultStrategies() view returns(address[])
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetAllSuperVaultStrategies() ([]common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetAllSuperVaultStrategies(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetAllSuperVaults is a free data retrieval call binding the contract method 0xa5256bf2.
//
// Solidity: function getAllSuperVaults() view returns(address[])
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetAllSuperVaults(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getAllSuperVaults")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetAllSuperVaults is a free data retrieval call binding the contract method 0xa5256bf2.
//
// Solidity: function getAllSuperVaults() view returns(address[])
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetAllSuperVaults() ([]common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetAllSuperVaults(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetAllSuperVaults is a free data retrieval call binding the contract method 0xa5256bf2.
//
// Solidity: function getAllSuperVaults() view returns(address[])
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetAllSuperVaults() ([]common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetAllSuperVaults(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetCurrentNonce is a free data retrieval call binding the contract method 0x3a60c386.
//
// Solidity: function getCurrentNonce() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetCurrentNonce(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getCurrentNonce")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetCurrentNonce is a free data retrieval call binding the contract method 0x3a60c386.
//
// Solidity: function getCurrentNonce() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetCurrentNonce() (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetCurrentNonce(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetCurrentNonce is a free data retrieval call binding the contract method 0x3a60c386.
//
// Solidity: function getCurrentNonce() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetCurrentNonce() (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetCurrentNonce(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetDeviationThreshold is a free data retrieval call binding the contract method 0x1a63b6fb.
//
// Solidity: function getDeviationThreshold(address strategy) view returns(uint256 deviationThreshold)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetDeviationThreshold(opts *bind.CallOpts, strategy common.Address) (*big.Int, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getDeviationThreshold", strategy)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetDeviationThreshold is a free data retrieval call binding the contract method 0x1a63b6fb.
//
// Solidity: function getDeviationThreshold(address strategy) view returns(uint256 deviationThreshold)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetDeviationThreshold(strategy common.Address) (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetDeviationThreshold(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetDeviationThreshold is a free data retrieval call binding the contract method 0x1a63b6fb.
//
// Solidity: function getDeviationThreshold(address strategy) view returns(uint256 deviationThreshold)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetDeviationThreshold(strategy common.Address) (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetDeviationThreshold(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetGlobalHooksRoot is a free data retrieval call binding the contract method 0x2a90a055.
//
// Solidity: function getGlobalHooksRoot() view returns(bytes32 root)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetGlobalHooksRoot(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getGlobalHooksRoot")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetGlobalHooksRoot is a free data retrieval call binding the contract method 0x2a90a055.
//
// Solidity: function getGlobalHooksRoot() view returns(bytes32 root)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetGlobalHooksRoot() ([32]byte, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetGlobalHooksRoot(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetGlobalHooksRoot is a free data retrieval call binding the contract method 0x2a90a055.
//
// Solidity: function getGlobalHooksRoot() view returns(bytes32 root)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetGlobalHooksRoot() ([32]byte, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetGlobalHooksRoot(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetHooksRootUpdateTimelock is a free data retrieval call binding the contract method 0x7be3d10f.
//
// Solidity: function getHooksRootUpdateTimelock() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetHooksRootUpdateTimelock(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getHooksRootUpdateTimelock")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetHooksRootUpdateTimelock is a free data retrieval call binding the contract method 0x7be3d10f.
//
// Solidity: function getHooksRootUpdateTimelock() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetHooksRootUpdateTimelock() (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetHooksRootUpdateTimelock(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetHooksRootUpdateTimelock is a free data retrieval call binding the contract method 0x7be3d10f.
//
// Solidity: function getHooksRootUpdateTimelock() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetHooksRootUpdateTimelock() (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetHooksRootUpdateTimelock(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetLastUnpauseTimestamp is a free data retrieval call binding the contract method 0x92352ed2.
//
// Solidity: function getLastUnpauseTimestamp(address strategy) view returns(uint256 timestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetLastUnpauseTimestamp(opts *bind.CallOpts, strategy common.Address) (*big.Int, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getLastUnpauseTimestamp", strategy)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetLastUnpauseTimestamp is a free data retrieval call binding the contract method 0x92352ed2.
//
// Solidity: function getLastUnpauseTimestamp(address strategy) view returns(uint256 timestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetLastUnpauseTimestamp(strategy common.Address) (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetLastUnpauseTimestamp(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetLastUnpauseTimestamp is a free data retrieval call binding the contract method 0x92352ed2.
//
// Solidity: function getLastUnpauseTimestamp(address strategy) view returns(uint256 timestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetLastUnpauseTimestamp(strategy common.Address) (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetLastUnpauseTimestamp(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetLastUpdateTimestamp is a free data retrieval call binding the contract method 0x1a351d62.
//
// Solidity: function getLastUpdateTimestamp(address strategy) view returns(uint256 timestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetLastUpdateTimestamp(opts *bind.CallOpts, strategy common.Address) (*big.Int, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getLastUpdateTimestamp", strategy)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetLastUpdateTimestamp is a free data retrieval call binding the contract method 0x1a351d62.
//
// Solidity: function getLastUpdateTimestamp(address strategy) view returns(uint256 timestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetLastUpdateTimestamp(strategy common.Address) (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetLastUpdateTimestamp(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetLastUpdateTimestamp is a free data retrieval call binding the contract method 0x1a351d62.
//
// Solidity: function getLastUpdateTimestamp(address strategy) view returns(uint256 timestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetLastUpdateTimestamp(strategy common.Address) (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetLastUpdateTimestamp(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetMainManager is a free data retrieval call binding the contract method 0xceb7b7a3.
//
// Solidity: function getMainManager(address strategy) view returns(address manager)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetMainManager(opts *bind.CallOpts, strategy common.Address) (common.Address, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getMainManager", strategy)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetMainManager is a free data retrieval call binding the contract method 0xceb7b7a3.
//
// Solidity: function getMainManager(address strategy) view returns(address manager)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetMainManager(strategy common.Address) (common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetMainManager(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetMainManager is a free data retrieval call binding the contract method 0xceb7b7a3.
//
// Solidity: function getMainManager(address strategy) view returns(address manager)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetMainManager(strategy common.Address) (common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetMainManager(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetMaxStaleness is a free data retrieval call binding the contract method 0xc25b784f.
//
// Solidity: function getMaxStaleness(address strategy) view returns(uint256 staleness)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetMaxStaleness(opts *bind.CallOpts, strategy common.Address) (*big.Int, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getMaxStaleness", strategy)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetMaxStaleness is a free data retrieval call binding the contract method 0xc25b784f.
//
// Solidity: function getMaxStaleness(address strategy) view returns(uint256 staleness)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetMaxStaleness(strategy common.Address) (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetMaxStaleness(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetMaxStaleness is a free data retrieval call binding the contract method 0xc25b784f.
//
// Solidity: function getMaxStaleness(address strategy) view returns(uint256 staleness)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetMaxStaleness(strategy common.Address) (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetMaxStaleness(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetMinUpdateInterval is a free data retrieval call binding the contract method 0x3ab973a3.
//
// Solidity: function getMinUpdateInterval(address strategy) view returns(uint256 interval)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetMinUpdateInterval(opts *bind.CallOpts, strategy common.Address) (*big.Int, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getMinUpdateInterval", strategy)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetMinUpdateInterval is a free data retrieval call binding the contract method 0x3ab973a3.
//
// Solidity: function getMinUpdateInterval(address strategy) view returns(uint256 interval)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetMinUpdateInterval(strategy common.Address) (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetMinUpdateInterval(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetMinUpdateInterval is a free data retrieval call binding the contract method 0x3ab973a3.
//
// Solidity: function getMinUpdateInterval(address strategy) view returns(uint256 interval)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetMinUpdateInterval(strategy common.Address) (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetMinUpdateInterval(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetPPS is a free data retrieval call binding the contract method 0xbef02b8c.
//
// Solidity: function getPPS(address strategy) view returns(uint256 pps)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetPPS(opts *bind.CallOpts, strategy common.Address) (*big.Int, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getPPS", strategy)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetPPS is a free data retrieval call binding the contract method 0xbef02b8c.
//
// Solidity: function getPPS(address strategy) view returns(uint256 pps)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetPPS(strategy common.Address) (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetPPS(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetPPS is a free data retrieval call binding the contract method 0xbef02b8c.
//
// Solidity: function getPPS(address strategy) view returns(uint256 pps)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetPPS(strategy common.Address) (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetPPS(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetPendingManagerChange is a free data retrieval call binding the contract method 0x0c9431b5.
//
// Solidity: function getPendingManagerChange(address strategy) view returns(address proposedManager, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetPendingManagerChange(opts *bind.CallOpts, strategy common.Address) (struct {
	ProposedManager common.Address
	EffectiveTime   *big.Int
}, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getPendingManagerChange", strategy)

	outstruct := new(struct {
		ProposedManager common.Address
		EffectiveTime   *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.ProposedManager = *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	outstruct.EffectiveTime = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// GetPendingManagerChange is a free data retrieval call binding the contract method 0x0c9431b5.
//
// Solidity: function getPendingManagerChange(address strategy) view returns(address proposedManager, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetPendingManagerChange(strategy common.Address) (struct {
	ProposedManager common.Address
	EffectiveTime   *big.Int
}, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetPendingManagerChange(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetPendingManagerChange is a free data retrieval call binding the contract method 0x0c9431b5.
//
// Solidity: function getPendingManagerChange(address strategy) view returns(address proposedManager, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetPendingManagerChange(strategy common.Address) (struct {
	ProposedManager common.Address
	EffectiveTime   *big.Int
}, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetPendingManagerChange(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetProposedGlobalHooksRoot is a free data retrieval call binding the contract method 0x9ab4e37b.
//
// Solidity: function getProposedGlobalHooksRoot() view returns(bytes32 root, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetProposedGlobalHooksRoot(opts *bind.CallOpts) (struct {
	Root          [32]byte
	EffectiveTime *big.Int
}, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getProposedGlobalHooksRoot")

	outstruct := new(struct {
		Root          [32]byte
		EffectiveTime *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Root = *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)
	outstruct.EffectiveTime = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// GetProposedGlobalHooksRoot is a free data retrieval call binding the contract method 0x9ab4e37b.
//
// Solidity: function getProposedGlobalHooksRoot() view returns(bytes32 root, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetProposedGlobalHooksRoot() (struct {
	Root          [32]byte
	EffectiveTime *big.Int
}, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetProposedGlobalHooksRoot(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetProposedGlobalHooksRoot is a free data retrieval call binding the contract method 0x9ab4e37b.
//
// Solidity: function getProposedGlobalHooksRoot() view returns(bytes32 root, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetProposedGlobalHooksRoot() (struct {
	Root          [32]byte
	EffectiveTime *big.Int
}, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetProposedGlobalHooksRoot(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetProposedMinUpdateInterval is a free data retrieval call binding the contract method 0xa618940f.
//
// Solidity: function getProposedMinUpdateInterval(address strategy) view returns(uint256 proposedInterval, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetProposedMinUpdateInterval(opts *bind.CallOpts, strategy common.Address) (struct {
	ProposedInterval *big.Int
	EffectiveTime    *big.Int
}, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getProposedMinUpdateInterval", strategy)

	outstruct := new(struct {
		ProposedInterval *big.Int
		EffectiveTime    *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.ProposedInterval = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.EffectiveTime = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// GetProposedMinUpdateInterval is a free data retrieval call binding the contract method 0xa618940f.
//
// Solidity: function getProposedMinUpdateInterval(address strategy) view returns(uint256 proposedInterval, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetProposedMinUpdateInterval(strategy common.Address) (struct {
	ProposedInterval *big.Int
	EffectiveTime    *big.Int
}, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetProposedMinUpdateInterval(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetProposedMinUpdateInterval is a free data retrieval call binding the contract method 0xa618940f.
//
// Solidity: function getProposedMinUpdateInterval(address strategy) view returns(uint256 proposedInterval, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetProposedMinUpdateInterval(strategy common.Address) (struct {
	ProposedInterval *big.Int
	EffectiveTime    *big.Int
}, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetProposedMinUpdateInterval(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetProposedStrategyHooksRoot is a free data retrieval call binding the contract method 0x2b4bb841.
//
// Solidity: function getProposedStrategyHooksRoot(address strategy) view returns(bytes32 root, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetProposedStrategyHooksRoot(opts *bind.CallOpts, strategy common.Address) (struct {
	Root          [32]byte
	EffectiveTime *big.Int
}, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getProposedStrategyHooksRoot", strategy)

	outstruct := new(struct {
		Root          [32]byte
		EffectiveTime *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Root = *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)
	outstruct.EffectiveTime = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// GetProposedStrategyHooksRoot is a free data retrieval call binding the contract method 0x2b4bb841.
//
// Solidity: function getProposedStrategyHooksRoot(address strategy) view returns(bytes32 root, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetProposedStrategyHooksRoot(strategy common.Address) (struct {
	Root          [32]byte
	EffectiveTime *big.Int
}, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetProposedStrategyHooksRoot(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetProposedStrategyHooksRoot is a free data retrieval call binding the contract method 0x2b4bb841.
//
// Solidity: function getProposedStrategyHooksRoot(address strategy) view returns(bytes32 root, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetProposedStrategyHooksRoot(strategy common.Address) (struct {
	Root          [32]byte
	EffectiveTime *big.Int
}, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetProposedStrategyHooksRoot(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetSecondaryManagers is a free data retrieval call binding the contract method 0x5f853d40.
//
// Solidity: function getSecondaryManagers(address strategy) view returns(address[])
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetSecondaryManagers(opts *bind.CallOpts, strategy common.Address) ([]common.Address, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getSecondaryManagers", strategy)

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetSecondaryManagers is a free data retrieval call binding the contract method 0x5f853d40.
//
// Solidity: function getSecondaryManagers(address strategy) view returns(address[])
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetSecondaryManagers(strategy common.Address) ([]common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetSecondaryManagers(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetSecondaryManagers is a free data retrieval call binding the contract method 0x5f853d40.
//
// Solidity: function getSecondaryManagers(address strategy) view returns(address[])
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetSecondaryManagers(strategy common.Address) ([]common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetSecondaryManagers(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetStrategyHooksRoot is a free data retrieval call binding the contract method 0xc99d2c89.
//
// Solidity: function getStrategyHooksRoot(address strategy) view returns(bytes32 root)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetStrategyHooksRoot(opts *bind.CallOpts, strategy common.Address) ([32]byte, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getStrategyHooksRoot", strategy)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetStrategyHooksRoot is a free data retrieval call binding the contract method 0xc99d2c89.
//
// Solidity: function getStrategyHooksRoot(address strategy) view returns(bytes32 root)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetStrategyHooksRoot(strategy common.Address) ([32]byte, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetStrategyHooksRoot(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetStrategyHooksRoot is a free data retrieval call binding the contract method 0xc99d2c89.
//
// Solidity: function getStrategyHooksRoot(address strategy) view returns(bytes32 root)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetStrategyHooksRoot(strategy common.Address) ([32]byte, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetStrategyHooksRoot(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetSuperVaultEscrowsCount is a free data retrieval call binding the contract method 0x5558c3cc.
//
// Solidity: function getSuperVaultEscrowsCount() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetSuperVaultEscrowsCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getSuperVaultEscrowsCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetSuperVaultEscrowsCount is a free data retrieval call binding the contract method 0x5558c3cc.
//
// Solidity: function getSuperVaultEscrowsCount() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetSuperVaultEscrowsCount() (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetSuperVaultEscrowsCount(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetSuperVaultEscrowsCount is a free data retrieval call binding the contract method 0x5558c3cc.
//
// Solidity: function getSuperVaultEscrowsCount() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetSuperVaultEscrowsCount() (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetSuperVaultEscrowsCount(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetSuperVaultStrategiesCount is a free data retrieval call binding the contract method 0x94459ea4.
//
// Solidity: function getSuperVaultStrategiesCount() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetSuperVaultStrategiesCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getSuperVaultStrategiesCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetSuperVaultStrategiesCount is a free data retrieval call binding the contract method 0x94459ea4.
//
// Solidity: function getSuperVaultStrategiesCount() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetSuperVaultStrategiesCount() (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetSuperVaultStrategiesCount(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetSuperVaultStrategiesCount is a free data retrieval call binding the contract method 0x94459ea4.
//
// Solidity: function getSuperVaultStrategiesCount() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetSuperVaultStrategiesCount() (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetSuperVaultStrategiesCount(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetSuperVaultsCount is a free data retrieval call binding the contract method 0x07cbebc1.
//
// Solidity: function getSuperVaultsCount() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetSuperVaultsCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getSuperVaultsCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetSuperVaultsCount is a free data retrieval call binding the contract method 0x07cbebc1.
//
// Solidity: function getSuperVaultsCount() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetSuperVaultsCount() (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetSuperVaultsCount(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetSuperVaultsCount is a free data retrieval call binding the contract method 0x07cbebc1.
//
// Solidity: function getSuperVaultsCount() view returns(uint256)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetSuperVaultsCount() (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetSuperVaultsCount(&_UnsafeSuperVaultAggregator.CallOpts)
}

// GetUpkeepBalance is a free data retrieval call binding the contract method 0x1aef3510.
//
// Solidity: function getUpkeepBalance(address strategy) view returns(uint256 balance)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) GetUpkeepBalance(opts *bind.CallOpts, strategy common.Address) (*big.Int, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "getUpkeepBalance", strategy)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetUpkeepBalance is a free data retrieval call binding the contract method 0x1aef3510.
//
// Solidity: function getUpkeepBalance(address strategy) view returns(uint256 balance)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) GetUpkeepBalance(strategy common.Address) (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetUpkeepBalance(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// GetUpkeepBalance is a free data retrieval call binding the contract method 0x1aef3510.
//
// Solidity: function getUpkeepBalance(address strategy) view returns(uint256 balance)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) GetUpkeepBalance(strategy common.Address) (*big.Int, error) {
	return _UnsafeSuperVaultAggregator.Contract.GetUpkeepBalance(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// IsAnyManager is a free data retrieval call binding the contract method 0x9e87cb3f.
//
// Solidity: function isAnyManager(address manager, address strategy) view returns(bool)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) IsAnyManager(opts *bind.CallOpts, manager common.Address, strategy common.Address) (bool, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "isAnyManager", manager, strategy)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsAnyManager is a free data retrieval call binding the contract method 0x9e87cb3f.
//
// Solidity: function isAnyManager(address manager, address strategy) view returns(bool)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) IsAnyManager(manager common.Address, strategy common.Address) (bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.IsAnyManager(&_UnsafeSuperVaultAggregator.CallOpts, manager, strategy)
}

// IsAnyManager is a free data retrieval call binding the contract method 0x9e87cb3f.
//
// Solidity: function isAnyManager(address manager, address strategy) view returns(bool)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) IsAnyManager(manager common.Address, strategy common.Address) (bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.IsAnyManager(&_UnsafeSuperVaultAggregator.CallOpts, manager, strategy)
}

// IsGlobalHooksRootActive is a free data retrieval call binding the contract method 0x28f36ff0.
//
// Solidity: function isGlobalHooksRootActive() view returns(bool)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) IsGlobalHooksRootActive(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "isGlobalHooksRootActive")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsGlobalHooksRootActive is a free data retrieval call binding the contract method 0x28f36ff0.
//
// Solidity: function isGlobalHooksRootActive() view returns(bool)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) IsGlobalHooksRootActive() (bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.IsGlobalHooksRootActive(&_UnsafeSuperVaultAggregator.CallOpts)
}

// IsGlobalHooksRootActive is a free data retrieval call binding the contract method 0x28f36ff0.
//
// Solidity: function isGlobalHooksRootActive() view returns(bool)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) IsGlobalHooksRootActive() (bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.IsGlobalHooksRootActive(&_UnsafeSuperVaultAggregator.CallOpts)
}

// IsGlobalHooksRootVetoed is a free data retrieval call binding the contract method 0x81ed8df4.
//
// Solidity: function isGlobalHooksRootVetoed() view returns(bool vetoed)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) IsGlobalHooksRootVetoed(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "isGlobalHooksRootVetoed")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsGlobalHooksRootVetoed is a free data retrieval call binding the contract method 0x81ed8df4.
//
// Solidity: function isGlobalHooksRootVetoed() view returns(bool vetoed)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) IsGlobalHooksRootVetoed() (bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.IsGlobalHooksRootVetoed(&_UnsafeSuperVaultAggregator.CallOpts)
}

// IsGlobalHooksRootVetoed is a free data retrieval call binding the contract method 0x81ed8df4.
//
// Solidity: function isGlobalHooksRootVetoed() view returns(bool vetoed)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) IsGlobalHooksRootVetoed() (bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.IsGlobalHooksRootVetoed(&_UnsafeSuperVaultAggregator.CallOpts)
}

// IsMainManager is a free data retrieval call binding the contract method 0xeb91a9b2.
//
// Solidity: function isMainManager(address manager, address strategy) view returns(bool)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) IsMainManager(opts *bind.CallOpts, manager common.Address, strategy common.Address) (bool, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "isMainManager", manager, strategy)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsMainManager is a free data retrieval call binding the contract method 0xeb91a9b2.
//
// Solidity: function isMainManager(address manager, address strategy) view returns(bool)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) IsMainManager(manager common.Address, strategy common.Address) (bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.IsMainManager(&_UnsafeSuperVaultAggregator.CallOpts, manager, strategy)
}

// IsMainManager is a free data retrieval call binding the contract method 0xeb91a9b2.
//
// Solidity: function isMainManager(address manager, address strategy) view returns(bool)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) IsMainManager(manager common.Address, strategy common.Address) (bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.IsMainManager(&_UnsafeSuperVaultAggregator.CallOpts, manager, strategy)
}

// IsPPSStale is a free data retrieval call binding the contract method 0x7e8c1517.
//
// Solidity: function isPPSStale(address strategy) view returns(bool isStale)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) IsPPSStale(opts *bind.CallOpts, strategy common.Address) (bool, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "isPPSStale", strategy)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsPPSStale is a free data retrieval call binding the contract method 0x7e8c1517.
//
// Solidity: function isPPSStale(address strategy) view returns(bool isStale)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) IsPPSStale(strategy common.Address) (bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.IsPPSStale(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// IsPPSStale is a free data retrieval call binding the contract method 0x7e8c1517.
//
// Solidity: function isPPSStale(address strategy) view returns(bool isStale)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) IsPPSStale(strategy common.Address) (bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.IsPPSStale(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// IsSecondaryManager is a free data retrieval call binding the contract method 0x83aa6836.
//
// Solidity: function isSecondaryManager(address manager, address strategy) view returns(bool)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) IsSecondaryManager(opts *bind.CallOpts, manager common.Address, strategy common.Address) (bool, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "isSecondaryManager", manager, strategy)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsSecondaryManager is a free data retrieval call binding the contract method 0x83aa6836.
//
// Solidity: function isSecondaryManager(address manager, address strategy) view returns(bool)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) IsSecondaryManager(manager common.Address, strategy common.Address) (bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.IsSecondaryManager(&_UnsafeSuperVaultAggregator.CallOpts, manager, strategy)
}

// IsSecondaryManager is a free data retrieval call binding the contract method 0x83aa6836.
//
// Solidity: function isSecondaryManager(address manager, address strategy) view returns(bool)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) IsSecondaryManager(manager common.Address, strategy common.Address) (bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.IsSecondaryManager(&_UnsafeSuperVaultAggregator.CallOpts, manager, strategy)
}

// IsStrategyHooksRootVetoed is a free data retrieval call binding the contract method 0xa8485b73.
//
// Solidity: function isStrategyHooksRootVetoed(address strategy) view returns(bool vetoed)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) IsStrategyHooksRootVetoed(opts *bind.CallOpts, strategy common.Address) (bool, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "isStrategyHooksRootVetoed", strategy)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsStrategyHooksRootVetoed is a free data retrieval call binding the contract method 0xa8485b73.
//
// Solidity: function isStrategyHooksRootVetoed(address strategy) view returns(bool vetoed)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) IsStrategyHooksRootVetoed(strategy common.Address) (bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.IsStrategyHooksRootVetoed(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// IsStrategyHooksRootVetoed is a free data retrieval call binding the contract method 0xa8485b73.
//
// Solidity: function isStrategyHooksRootVetoed(address strategy) view returns(bool vetoed)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) IsStrategyHooksRootVetoed(strategy common.Address) (bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.IsStrategyHooksRootVetoed(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// IsStrategyPaused is a free data retrieval call binding the contract method 0xc06a02e8.
//
// Solidity: function isStrategyPaused(address strategy) view returns(bool isPaused)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) IsStrategyPaused(opts *bind.CallOpts, strategy common.Address) (bool, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "isStrategyPaused", strategy)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsStrategyPaused is a free data retrieval call binding the contract method 0xc06a02e8.
//
// Solidity: function isStrategyPaused(address strategy) view returns(bool isPaused)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) IsStrategyPaused(strategy common.Address) (bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.IsStrategyPaused(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// IsStrategyPaused is a free data retrieval call binding the contract method 0xc06a02e8.
//
// Solidity: function isStrategyPaused(address strategy) view returns(bool isPaused)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) IsStrategyPaused(strategy common.Address) (bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.IsStrategyPaused(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// PendingUpkeepWithdrawals is a free data retrieval call binding the contract method 0x5f4bc1be.
//
// Solidity: function pendingUpkeepWithdrawals(address strategy) view returns(uint256 amount, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) PendingUpkeepWithdrawals(opts *bind.CallOpts, strategy common.Address) (struct {
	Amount        *big.Int
	EffectiveTime *big.Int
}, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "pendingUpkeepWithdrawals", strategy)

	outstruct := new(struct {
		Amount        *big.Int
		EffectiveTime *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Amount = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.EffectiveTime = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// PendingUpkeepWithdrawals is a free data retrieval call binding the contract method 0x5f4bc1be.
//
// Solidity: function pendingUpkeepWithdrawals(address strategy) view returns(uint256 amount, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) PendingUpkeepWithdrawals(strategy common.Address) (struct {
	Amount        *big.Int
	EffectiveTime *big.Int
}, error) {
	return _UnsafeSuperVaultAggregator.Contract.PendingUpkeepWithdrawals(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// PendingUpkeepWithdrawals is a free data retrieval call binding the contract method 0x5f4bc1be.
//
// Solidity: function pendingUpkeepWithdrawals(address strategy) view returns(uint256 amount, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) PendingUpkeepWithdrawals(strategy common.Address) (struct {
	Amount        *big.Int
	EffectiveTime *big.Int
}, error) {
	return _UnsafeSuperVaultAggregator.Contract.PendingUpkeepWithdrawals(&_UnsafeSuperVaultAggregator.CallOpts, strategy)
}

// SuperVaultEscrows is a free data retrieval call binding the contract method 0xbda262d7.
//
// Solidity: function superVaultEscrows(uint256 index) view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) SuperVaultEscrows(opts *bind.CallOpts, index *big.Int) (common.Address, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "superVaultEscrows", index)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SuperVaultEscrows is a free data retrieval call binding the contract method 0xbda262d7.
//
// Solidity: function superVaultEscrows(uint256 index) view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) SuperVaultEscrows(index *big.Int) (common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.SuperVaultEscrows(&_UnsafeSuperVaultAggregator.CallOpts, index)
}

// SuperVaultEscrows is a free data retrieval call binding the contract method 0xbda262d7.
//
// Solidity: function superVaultEscrows(uint256 index) view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) SuperVaultEscrows(index *big.Int) (common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.SuperVaultEscrows(&_UnsafeSuperVaultAggregator.CallOpts, index)
}

// SuperVaultStrategies is a free data retrieval call binding the contract method 0x9dc0ad84.
//
// Solidity: function superVaultStrategies(uint256 index) view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) SuperVaultStrategies(opts *bind.CallOpts, index *big.Int) (common.Address, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "superVaultStrategies", index)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SuperVaultStrategies is a free data retrieval call binding the contract method 0x9dc0ad84.
//
// Solidity: function superVaultStrategies(uint256 index) view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) SuperVaultStrategies(index *big.Int) (common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.SuperVaultStrategies(&_UnsafeSuperVaultAggregator.CallOpts, index)
}

// SuperVaultStrategies is a free data retrieval call binding the contract method 0x9dc0ad84.
//
// Solidity: function superVaultStrategies(uint256 index) view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) SuperVaultStrategies(index *big.Int) (common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.SuperVaultStrategies(&_UnsafeSuperVaultAggregator.CallOpts, index)
}

// SuperVaults is a free data retrieval call binding the contract method 0x44648c76.
//
// Solidity: function superVaults(uint256 index) view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) SuperVaults(opts *bind.CallOpts, index *big.Int) (common.Address, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "superVaults", index)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SuperVaults is a free data retrieval call binding the contract method 0x44648c76.
//
// Solidity: function superVaults(uint256 index) view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) SuperVaults(index *big.Int) (common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.SuperVaults(&_UnsafeSuperVaultAggregator.CallOpts, index)
}

// SuperVaults is a free data retrieval call binding the contract method 0x44648c76.
//
// Solidity: function superVaults(uint256 index) view returns(address)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) SuperVaults(index *big.Int) (common.Address, error) {
	return _UnsafeSuperVaultAggregator.Contract.SuperVaults(&_UnsafeSuperVaultAggregator.CallOpts, index)
}

// ValidateHook is a free data retrieval call binding the contract method 0x9e7b8c3a.
//
// Solidity: function validateHook(address , (address,bytes,bytes32[],bytes32[]) ) pure returns(bool isValid)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) ValidateHook(opts *bind.CallOpts, arg0 common.Address, arg1 ISuperVaultAggregatorValidateHookArgs) (bool, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "validateHook", arg0, arg1)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// ValidateHook is a free data retrieval call binding the contract method 0x9e7b8c3a.
//
// Solidity: function validateHook(address , (address,bytes,bytes32[],bytes32[]) ) pure returns(bool isValid)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ValidateHook(arg0 common.Address, arg1 ISuperVaultAggregatorValidateHookArgs) (bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.ValidateHook(&_UnsafeSuperVaultAggregator.CallOpts, arg0, arg1)
}

// ValidateHook is a free data retrieval call binding the contract method 0x9e7b8c3a.
//
// Solidity: function validateHook(address , (address,bytes,bytes32[],bytes32[]) ) pure returns(bool isValid)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) ValidateHook(arg0 common.Address, arg1 ISuperVaultAggregatorValidateHookArgs) (bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.ValidateHook(&_UnsafeSuperVaultAggregator.CallOpts, arg0, arg1)
}

// ValidateHooks is a free data retrieval call binding the contract method 0x6cbd5796.
//
// Solidity: function validateHooks(address , (address,bytes,bytes32[],bytes32[])[] argsArray) pure returns(bool[] validHooks)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCaller) ValidateHooks(opts *bind.CallOpts, arg0 common.Address, argsArray []ISuperVaultAggregatorValidateHookArgs) ([]bool, error) {
	var out []interface{}
	err := _UnsafeSuperVaultAggregator.contract.Call(opts, &out, "validateHooks", arg0, argsArray)

	if err != nil {
		return *new([]bool), err
	}

	out0 := *abi.ConvertType(out[0], new([]bool)).(*[]bool)

	return out0, err

}

// ValidateHooks is a free data retrieval call binding the contract method 0x6cbd5796.
//
// Solidity: function validateHooks(address , (address,bytes,bytes32[],bytes32[])[] argsArray) pure returns(bool[] validHooks)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ValidateHooks(arg0 common.Address, argsArray []ISuperVaultAggregatorValidateHookArgs) ([]bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.ValidateHooks(&_UnsafeSuperVaultAggregator.CallOpts, arg0, argsArray)
}

// ValidateHooks is a free data retrieval call binding the contract method 0x6cbd5796.
//
// Solidity: function validateHooks(address , (address,bytes,bytes32[],bytes32[])[] argsArray) pure returns(bool[] validHooks)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorCallerSession) ValidateHooks(arg0 common.Address, argsArray []ISuperVaultAggregatorValidateHookArgs) ([]bool, error) {
	return _UnsafeSuperVaultAggregator.Contract.ValidateHooks(&_UnsafeSuperVaultAggregator.CallOpts, arg0, argsArray)
}

// AddSecondaryManager is a paid mutator transaction binding the contract method 0xc0c3bbd8.
//
// Solidity: function addSecondaryManager(address strategy, address manager) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) AddSecondaryManager(opts *bind.TransactOpts, strategy common.Address, manager common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "addSecondaryManager", strategy, manager)
}

// AddSecondaryManager is a paid mutator transaction binding the contract method 0xc0c3bbd8.
//
// Solidity: function addSecondaryManager(address strategy, address manager) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) AddSecondaryManager(strategy common.Address, manager common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.AddSecondaryManager(&_UnsafeSuperVaultAggregator.TransactOpts, strategy, manager)
}

// AddSecondaryManager is a paid mutator transaction binding the contract method 0xc0c3bbd8.
//
// Solidity: function addSecondaryManager(address strategy, address manager) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) AddSecondaryManager(strategy common.Address, manager common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.AddSecondaryManager(&_UnsafeSuperVaultAggregator.TransactOpts, strategy, manager)
}

// CancelChangePrimaryManager is a paid mutator transaction binding the contract method 0x464229b4.
//
// Solidity: function cancelChangePrimaryManager(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) CancelChangePrimaryManager(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "cancelChangePrimaryManager", strategy)
}

// CancelChangePrimaryManager is a paid mutator transaction binding the contract method 0x464229b4.
//
// Solidity: function cancelChangePrimaryManager(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) CancelChangePrimaryManager(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.CancelChangePrimaryManager(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// CancelChangePrimaryManager is a paid mutator transaction binding the contract method 0x464229b4.
//
// Solidity: function cancelChangePrimaryManager(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) CancelChangePrimaryManager(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.CancelChangePrimaryManager(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// CancelMinUpdateIntervalChange is a paid mutator transaction binding the contract method 0x40bb67e1.
//
// Solidity: function cancelMinUpdateIntervalChange(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) CancelMinUpdateIntervalChange(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "cancelMinUpdateIntervalChange", strategy)
}

// CancelMinUpdateIntervalChange is a paid mutator transaction binding the contract method 0x40bb67e1.
//
// Solidity: function cancelMinUpdateIntervalChange(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) CancelMinUpdateIntervalChange(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.CancelMinUpdateIntervalChange(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// CancelMinUpdateIntervalChange is a paid mutator transaction binding the contract method 0x40bb67e1.
//
// Solidity: function cancelMinUpdateIntervalChange(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) CancelMinUpdateIntervalChange(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.CancelMinUpdateIntervalChange(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// ChangeGlobalLeavesStatus is a paid mutator transaction binding the contract method 0xf430b328.
//
// Solidity: function changeGlobalLeavesStatus(bytes32[] leaves, bool[] statuses, address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) ChangeGlobalLeavesStatus(opts *bind.TransactOpts, leaves [][32]byte, statuses []bool, strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "changeGlobalLeavesStatus", leaves, statuses, strategy)
}

// ChangeGlobalLeavesStatus is a paid mutator transaction binding the contract method 0xf430b328.
//
// Solidity: function changeGlobalLeavesStatus(bytes32[] leaves, bool[] statuses, address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ChangeGlobalLeavesStatus(leaves [][32]byte, statuses []bool, strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ChangeGlobalLeavesStatus(&_UnsafeSuperVaultAggregator.TransactOpts, leaves, statuses, strategy)
}

// ChangeGlobalLeavesStatus is a paid mutator transaction binding the contract method 0xf430b328.
//
// Solidity: function changeGlobalLeavesStatus(bytes32[] leaves, bool[] statuses, address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) ChangeGlobalLeavesStatus(leaves [][32]byte, statuses []bool, strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ChangeGlobalLeavesStatus(&_UnsafeSuperVaultAggregator.TransactOpts, leaves, statuses, strategy)
}

// ChangePrimaryManager is a paid mutator transaction binding the contract method 0xbd579e55.
//
// Solidity: function changePrimaryManager(address strategy, address newManager, address feeRecipient) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) ChangePrimaryManager(opts *bind.TransactOpts, strategy common.Address, newManager common.Address, feeRecipient common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "changePrimaryManager", strategy, newManager, feeRecipient)
}

// ChangePrimaryManager is a paid mutator transaction binding the contract method 0xbd579e55.
//
// Solidity: function changePrimaryManager(address strategy, address newManager, address feeRecipient) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ChangePrimaryManager(strategy common.Address, newManager common.Address, feeRecipient common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ChangePrimaryManager(&_UnsafeSuperVaultAggregator.TransactOpts, strategy, newManager, feeRecipient)
}

// ChangePrimaryManager is a paid mutator transaction binding the contract method 0xbd579e55.
//
// Solidity: function changePrimaryManager(address strategy, address newManager, address feeRecipient) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) ChangePrimaryManager(strategy common.Address, newManager common.Address, feeRecipient common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ChangePrimaryManager(&_UnsafeSuperVaultAggregator.TransactOpts, strategy, newManager, feeRecipient)
}

// ClaimUpkeep is a paid mutator transaction binding the contract method 0xd4eb9083.
//
// Solidity: function claimUpkeep(uint256 amount) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) ClaimUpkeep(opts *bind.TransactOpts, amount *big.Int) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "claimUpkeep", amount)
}

// ClaimUpkeep is a paid mutator transaction binding the contract method 0xd4eb9083.
//
// Solidity: function claimUpkeep(uint256 amount) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ClaimUpkeep(amount *big.Int) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ClaimUpkeep(&_UnsafeSuperVaultAggregator.TransactOpts, amount)
}

// ClaimUpkeep is a paid mutator transaction binding the contract method 0xd4eb9083.
//
// Solidity: function claimUpkeep(uint256 amount) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) ClaimUpkeep(amount *big.Int) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ClaimUpkeep(&_UnsafeSuperVaultAggregator.TransactOpts, amount)
}

// CreateVault is a paid mutator transaction binding the contract method 0x86853dfd.
//
// Solidity: function createVault((address,string,string,address,address[],uint256,uint256,(uint256,uint256,address)) params) returns(address superVault, address strategy, address escrow)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) CreateVault(opts *bind.TransactOpts, params ISuperVaultAggregatorVaultCreationParams) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "createVault", params)
}

// CreateVault is a paid mutator transaction binding the contract method 0x86853dfd.
//
// Solidity: function createVault((address,string,string,address,address[],uint256,uint256,(uint256,uint256,address)) params) returns(address superVault, address strategy, address escrow)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) CreateVault(params ISuperVaultAggregatorVaultCreationParams) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.CreateVault(&_UnsafeSuperVaultAggregator.TransactOpts, params)
}

// CreateVault is a paid mutator transaction binding the contract method 0x86853dfd.
//
// Solidity: function createVault((address,string,string,address,address[],uint256,uint256,(uint256,uint256,address)) params) returns(address superVault, address strategy, address escrow)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) CreateVault(params ISuperVaultAggregatorVaultCreationParams) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.CreateVault(&_UnsafeSuperVaultAggregator.TransactOpts, params)
}

// DepositUpkeep is a paid mutator transaction binding the contract method 0x6fe79652.
//
// Solidity: function depositUpkeep(address strategy, uint256 amount) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) DepositUpkeep(opts *bind.TransactOpts, strategy common.Address, amount *big.Int) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "depositUpkeep", strategy, amount)
}

// DepositUpkeep is a paid mutator transaction binding the contract method 0x6fe79652.
//
// Solidity: function depositUpkeep(address strategy, uint256 amount) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) DepositUpkeep(strategy common.Address, amount *big.Int) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.DepositUpkeep(&_UnsafeSuperVaultAggregator.TransactOpts, strategy, amount)
}

// DepositUpkeep is a paid mutator transaction binding the contract method 0x6fe79652.
//
// Solidity: function depositUpkeep(address strategy, uint256 amount) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) DepositUpkeep(strategy common.Address, amount *big.Int) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.DepositUpkeep(&_UnsafeSuperVaultAggregator.TransactOpts, strategy, amount)
}

// ExecuteChangePrimaryManager is a paid mutator transaction binding the contract method 0x9249c392.
//
// Solidity: function executeChangePrimaryManager(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) ExecuteChangePrimaryManager(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "executeChangePrimaryManager", strategy)
}

// ExecuteChangePrimaryManager is a paid mutator transaction binding the contract method 0x9249c392.
//
// Solidity: function executeChangePrimaryManager(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ExecuteChangePrimaryManager(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ExecuteChangePrimaryManager(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// ExecuteChangePrimaryManager is a paid mutator transaction binding the contract method 0x9249c392.
//
// Solidity: function executeChangePrimaryManager(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) ExecuteChangePrimaryManager(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ExecuteChangePrimaryManager(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// ExecuteGlobalHooksRootUpdate is a paid mutator transaction binding the contract method 0x0a48d243.
//
// Solidity: function executeGlobalHooksRootUpdate() returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) ExecuteGlobalHooksRootUpdate(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "executeGlobalHooksRootUpdate")
}

// ExecuteGlobalHooksRootUpdate is a paid mutator transaction binding the contract method 0x0a48d243.
//
// Solidity: function executeGlobalHooksRootUpdate() returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ExecuteGlobalHooksRootUpdate() (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ExecuteGlobalHooksRootUpdate(&_UnsafeSuperVaultAggregator.TransactOpts)
}

// ExecuteGlobalHooksRootUpdate is a paid mutator transaction binding the contract method 0x0a48d243.
//
// Solidity: function executeGlobalHooksRootUpdate() returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) ExecuteGlobalHooksRootUpdate() (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ExecuteGlobalHooksRootUpdate(&_UnsafeSuperVaultAggregator.TransactOpts)
}

// ExecuteMinUpdateIntervalChange is a paid mutator transaction binding the contract method 0x98b00504.
//
// Solidity: function executeMinUpdateIntervalChange(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) ExecuteMinUpdateIntervalChange(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "executeMinUpdateIntervalChange", strategy)
}

// ExecuteMinUpdateIntervalChange is a paid mutator transaction binding the contract method 0x98b00504.
//
// Solidity: function executeMinUpdateIntervalChange(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ExecuteMinUpdateIntervalChange(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ExecuteMinUpdateIntervalChange(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// ExecuteMinUpdateIntervalChange is a paid mutator transaction binding the contract method 0x98b00504.
//
// Solidity: function executeMinUpdateIntervalChange(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) ExecuteMinUpdateIntervalChange(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ExecuteMinUpdateIntervalChange(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// ExecuteStrategyHooksRootUpdate is a paid mutator transaction binding the contract method 0x7825784b.
//
// Solidity: function executeStrategyHooksRootUpdate(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) ExecuteStrategyHooksRootUpdate(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "executeStrategyHooksRootUpdate", strategy)
}

// ExecuteStrategyHooksRootUpdate is a paid mutator transaction binding the contract method 0x7825784b.
//
// Solidity: function executeStrategyHooksRootUpdate(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ExecuteStrategyHooksRootUpdate(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ExecuteStrategyHooksRootUpdate(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// ExecuteStrategyHooksRootUpdate is a paid mutator transaction binding the contract method 0x7825784b.
//
// Solidity: function executeStrategyHooksRootUpdate(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) ExecuteStrategyHooksRootUpdate(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ExecuteStrategyHooksRootUpdate(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// ExecuteWithdrawUpkeep is a paid mutator transaction binding the contract method 0x888e3cde.
//
// Solidity: function executeWithdrawUpkeep(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) ExecuteWithdrawUpkeep(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "executeWithdrawUpkeep", strategy)
}

// ExecuteWithdrawUpkeep is a paid mutator transaction binding the contract method 0x888e3cde.
//
// Solidity: function executeWithdrawUpkeep(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ExecuteWithdrawUpkeep(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ExecuteWithdrawUpkeep(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// ExecuteWithdrawUpkeep is a paid mutator transaction binding the contract method 0x888e3cde.
//
// Solidity: function executeWithdrawUpkeep(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) ExecuteWithdrawUpkeep(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ExecuteWithdrawUpkeep(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// ForwardPPS is a paid mutator transaction binding the contract method 0xc27bda9b.
//
// Solidity: function forwardPPS((address[],uint256[],uint256[],address) args) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) ForwardPPS(opts *bind.TransactOpts, args ISuperVaultAggregatorForwardPPSArgs) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "forwardPPS", args)
}

// ForwardPPS is a paid mutator transaction binding the contract method 0xc27bda9b.
//
// Solidity: function forwardPPS((address[],uint256[],uint256[],address) args) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ForwardPPS(args ISuperVaultAggregatorForwardPPSArgs) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ForwardPPS(&_UnsafeSuperVaultAggregator.TransactOpts, args)
}

// ForwardPPS is a paid mutator transaction binding the contract method 0xc27bda9b.
//
// Solidity: function forwardPPS((address[],uint256[],uint256[],address) args) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) ForwardPPS(args ISuperVaultAggregatorForwardPPSArgs) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ForwardPPS(&_UnsafeSuperVaultAggregator.TransactOpts, args)
}

// PauseStrategy is a paid mutator transaction binding the contract method 0xd3f6b598.
//
// Solidity: function pauseStrategy(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) PauseStrategy(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "pauseStrategy", strategy)
}

// PauseStrategy is a paid mutator transaction binding the contract method 0xd3f6b598.
//
// Solidity: function pauseStrategy(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) PauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.PauseStrategy(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// PauseStrategy is a paid mutator transaction binding the contract method 0xd3f6b598.
//
// Solidity: function pauseStrategy(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) PauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.PauseStrategy(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// ProposeChangePrimaryManager is a paid mutator transaction binding the contract method 0xbea3edb1.
//
// Solidity: function proposeChangePrimaryManager(address strategy, address newManager, address feeRecipient) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) ProposeChangePrimaryManager(opts *bind.TransactOpts, strategy common.Address, newManager common.Address, feeRecipient common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "proposeChangePrimaryManager", strategy, newManager, feeRecipient)
}

// ProposeChangePrimaryManager is a paid mutator transaction binding the contract method 0xbea3edb1.
//
// Solidity: function proposeChangePrimaryManager(address strategy, address newManager, address feeRecipient) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ProposeChangePrimaryManager(strategy common.Address, newManager common.Address, feeRecipient common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ProposeChangePrimaryManager(&_UnsafeSuperVaultAggregator.TransactOpts, strategy, newManager, feeRecipient)
}

// ProposeChangePrimaryManager is a paid mutator transaction binding the contract method 0xbea3edb1.
//
// Solidity: function proposeChangePrimaryManager(address strategy, address newManager, address feeRecipient) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) ProposeChangePrimaryManager(strategy common.Address, newManager common.Address, feeRecipient common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ProposeChangePrimaryManager(&_UnsafeSuperVaultAggregator.TransactOpts, strategy, newManager, feeRecipient)
}

// ProposeGlobalHooksRoot is a paid mutator transaction binding the contract method 0xb0e5173b.
//
// Solidity: function proposeGlobalHooksRoot(bytes32 newRoot) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) ProposeGlobalHooksRoot(opts *bind.TransactOpts, newRoot [32]byte) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "proposeGlobalHooksRoot", newRoot)
}

// ProposeGlobalHooksRoot is a paid mutator transaction binding the contract method 0xb0e5173b.
//
// Solidity: function proposeGlobalHooksRoot(bytes32 newRoot) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ProposeGlobalHooksRoot(newRoot [32]byte) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ProposeGlobalHooksRoot(&_UnsafeSuperVaultAggregator.TransactOpts, newRoot)
}

// ProposeGlobalHooksRoot is a paid mutator transaction binding the contract method 0xb0e5173b.
//
// Solidity: function proposeGlobalHooksRoot(bytes32 newRoot) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) ProposeGlobalHooksRoot(newRoot [32]byte) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ProposeGlobalHooksRoot(&_UnsafeSuperVaultAggregator.TransactOpts, newRoot)
}

// ProposeMinUpdateIntervalChange is a paid mutator transaction binding the contract method 0xf3cd2a33.
//
// Solidity: function proposeMinUpdateIntervalChange(address strategy, uint256 newMinUpdateInterval) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) ProposeMinUpdateIntervalChange(opts *bind.TransactOpts, strategy common.Address, newMinUpdateInterval *big.Int) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "proposeMinUpdateIntervalChange", strategy, newMinUpdateInterval)
}

// ProposeMinUpdateIntervalChange is a paid mutator transaction binding the contract method 0xf3cd2a33.
//
// Solidity: function proposeMinUpdateIntervalChange(address strategy, uint256 newMinUpdateInterval) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ProposeMinUpdateIntervalChange(strategy common.Address, newMinUpdateInterval *big.Int) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ProposeMinUpdateIntervalChange(&_UnsafeSuperVaultAggregator.TransactOpts, strategy, newMinUpdateInterval)
}

// ProposeMinUpdateIntervalChange is a paid mutator transaction binding the contract method 0xf3cd2a33.
//
// Solidity: function proposeMinUpdateIntervalChange(address strategy, uint256 newMinUpdateInterval) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) ProposeMinUpdateIntervalChange(strategy common.Address, newMinUpdateInterval *big.Int) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ProposeMinUpdateIntervalChange(&_UnsafeSuperVaultAggregator.TransactOpts, strategy, newMinUpdateInterval)
}

// ProposeStrategyHooksRoot is a paid mutator transaction binding the contract method 0x5e12b2db.
//
// Solidity: function proposeStrategyHooksRoot(address strategy, bytes32 newRoot) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) ProposeStrategyHooksRoot(opts *bind.TransactOpts, strategy common.Address, newRoot [32]byte) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "proposeStrategyHooksRoot", strategy, newRoot)
}

// ProposeStrategyHooksRoot is a paid mutator transaction binding the contract method 0x5e12b2db.
//
// Solidity: function proposeStrategyHooksRoot(address strategy, bytes32 newRoot) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ProposeStrategyHooksRoot(strategy common.Address, newRoot [32]byte) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ProposeStrategyHooksRoot(&_UnsafeSuperVaultAggregator.TransactOpts, strategy, newRoot)
}

// ProposeStrategyHooksRoot is a paid mutator transaction binding the contract method 0x5e12b2db.
//
// Solidity: function proposeStrategyHooksRoot(address strategy, bytes32 newRoot) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) ProposeStrategyHooksRoot(strategy common.Address, newRoot [32]byte) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ProposeStrategyHooksRoot(&_UnsafeSuperVaultAggregator.TransactOpts, strategy, newRoot)
}

// ProposeWithdrawUpkeep is a paid mutator transaction binding the contract method 0x7911232a.
//
// Solidity: function proposeWithdrawUpkeep(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) ProposeWithdrawUpkeep(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "proposeWithdrawUpkeep", strategy)
}

// ProposeWithdrawUpkeep is a paid mutator transaction binding the contract method 0x7911232a.
//
// Solidity: function proposeWithdrawUpkeep(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ProposeWithdrawUpkeep(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ProposeWithdrawUpkeep(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// ProposeWithdrawUpkeep is a paid mutator transaction binding the contract method 0x7911232a.
//
// Solidity: function proposeWithdrawUpkeep(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) ProposeWithdrawUpkeep(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ProposeWithdrawUpkeep(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// RemoveSecondaryManager is a paid mutator transaction binding the contract method 0x3c248029.
//
// Solidity: function removeSecondaryManager(address strategy, address manager) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) RemoveSecondaryManager(opts *bind.TransactOpts, strategy common.Address, manager common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "removeSecondaryManager", strategy, manager)
}

// RemoveSecondaryManager is a paid mutator transaction binding the contract method 0x3c248029.
//
// Solidity: function removeSecondaryManager(address strategy, address manager) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) RemoveSecondaryManager(strategy common.Address, manager common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.RemoveSecondaryManager(&_UnsafeSuperVaultAggregator.TransactOpts, strategy, manager)
}

// RemoveSecondaryManager is a paid mutator transaction binding the contract method 0x3c248029.
//
// Solidity: function removeSecondaryManager(address strategy, address manager) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) RemoveSecondaryManager(strategy common.Address, manager common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.RemoveSecondaryManager(&_UnsafeSuperVaultAggregator.TransactOpts, strategy, manager)
}

// ResetHighWaterMark is a paid mutator transaction binding the contract method 0x7ac432ff.
//
// Solidity: function resetHighWaterMark(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) ResetHighWaterMark(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "resetHighWaterMark", strategy)
}

// ResetHighWaterMark is a paid mutator transaction binding the contract method 0x7ac432ff.
//
// Solidity: function resetHighWaterMark(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) ResetHighWaterMark(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ResetHighWaterMark(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// ResetHighWaterMark is a paid mutator transaction binding the contract method 0x7ac432ff.
//
// Solidity: function resetHighWaterMark(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) ResetHighWaterMark(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.ResetHighWaterMark(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// SetGlobalHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xd5f3cd86.
//
// Solidity: function setGlobalHooksRootVetoStatus(bool vetoed) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) SetGlobalHooksRootVetoStatus(opts *bind.TransactOpts, vetoed bool) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "setGlobalHooksRootVetoStatus", vetoed)
}

// SetGlobalHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xd5f3cd86.
//
// Solidity: function setGlobalHooksRootVetoStatus(bool vetoed) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) SetGlobalHooksRootVetoStatus(vetoed bool) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.SetGlobalHooksRootVetoStatus(&_UnsafeSuperVaultAggregator.TransactOpts, vetoed)
}

// SetGlobalHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xd5f3cd86.
//
// Solidity: function setGlobalHooksRootVetoStatus(bool vetoed) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) SetGlobalHooksRootVetoStatus(vetoed bool) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.SetGlobalHooksRootVetoStatus(&_UnsafeSuperVaultAggregator.TransactOpts, vetoed)
}

// SetHooksRootUpdateTimelock is a paid mutator transaction binding the contract method 0x272b7add.
//
// Solidity: function setHooksRootUpdateTimelock(uint256 newTimelock) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) SetHooksRootUpdateTimelock(opts *bind.TransactOpts, newTimelock *big.Int) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "setHooksRootUpdateTimelock", newTimelock)
}

// SetHooksRootUpdateTimelock is a paid mutator transaction binding the contract method 0x272b7add.
//
// Solidity: function setHooksRootUpdateTimelock(uint256 newTimelock) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) SetHooksRootUpdateTimelock(newTimelock *big.Int) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.SetHooksRootUpdateTimelock(&_UnsafeSuperVaultAggregator.TransactOpts, newTimelock)
}

// SetHooksRootUpdateTimelock is a paid mutator transaction binding the contract method 0x272b7add.
//
// Solidity: function setHooksRootUpdateTimelock(uint256 newTimelock) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) SetHooksRootUpdateTimelock(newTimelock *big.Int) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.SetHooksRootUpdateTimelock(&_UnsafeSuperVaultAggregator.TransactOpts, newTimelock)
}

// SetStrategyHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xf5297a47.
//
// Solidity: function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) SetStrategyHooksRootVetoStatus(opts *bind.TransactOpts, strategy common.Address, vetoed bool) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "setStrategyHooksRootVetoStatus", strategy, vetoed)
}

// SetStrategyHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xf5297a47.
//
// Solidity: function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) SetStrategyHooksRootVetoStatus(strategy common.Address, vetoed bool) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.SetStrategyHooksRootVetoStatus(&_UnsafeSuperVaultAggregator.TransactOpts, strategy, vetoed)
}

// SetStrategyHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xf5297a47.
//
// Solidity: function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) SetStrategyHooksRootVetoStatus(strategy common.Address, vetoed bool) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.SetStrategyHooksRootVetoStatus(&_UnsafeSuperVaultAggregator.TransactOpts, strategy, vetoed)
}

// UnpauseStrategy is a paid mutator transaction binding the contract method 0x0ff323a3.
//
// Solidity: function unpauseStrategy(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) UnpauseStrategy(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "unpauseStrategy", strategy)
}

// UnpauseStrategy is a paid mutator transaction binding the contract method 0x0ff323a3.
//
// Solidity: function unpauseStrategy(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) UnpauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.UnpauseStrategy(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// UnpauseStrategy is a paid mutator transaction binding the contract method 0x0ff323a3.
//
// Solidity: function unpauseStrategy(address strategy) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) UnpauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.UnpauseStrategy(&_UnsafeSuperVaultAggregator.TransactOpts, strategy)
}

// UpdateDeviationThreshold is a paid mutator transaction binding the contract method 0x00ee68ba.
//
// Solidity: function updateDeviationThreshold(address strategy, uint256 deviationThreshold_) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) UpdateDeviationThreshold(opts *bind.TransactOpts, strategy common.Address, deviationThreshold_ *big.Int) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "updateDeviationThreshold", strategy, deviationThreshold_)
}

// UpdateDeviationThreshold is a paid mutator transaction binding the contract method 0x00ee68ba.
//
// Solidity: function updateDeviationThreshold(address strategy, uint256 deviationThreshold_) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) UpdateDeviationThreshold(strategy common.Address, deviationThreshold_ *big.Int) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.UpdateDeviationThreshold(&_UnsafeSuperVaultAggregator.TransactOpts, strategy, deviationThreshold_)
}

// UpdateDeviationThreshold is a paid mutator transaction binding the contract method 0x00ee68ba.
//
// Solidity: function updateDeviationThreshold(address strategy, uint256 deviationThreshold_) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) UpdateDeviationThreshold(strategy common.Address, deviationThreshold_ *big.Int) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.UpdateDeviationThreshold(&_UnsafeSuperVaultAggregator.TransactOpts, strategy, deviationThreshold_)
}

// UpdatePPSAfterSkim is a paid mutator transaction binding the contract method 0x12e1ac5a.
//
// Solidity: function updatePPSAfterSkim(uint256 newPPS, uint256 feeAmount) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactor) UpdatePPSAfterSkim(opts *bind.TransactOpts, newPPS *big.Int, feeAmount *big.Int) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.contract.Transact(opts, "updatePPSAfterSkim", newPPS, feeAmount)
}

// UpdatePPSAfterSkim is a paid mutator transaction binding the contract method 0x12e1ac5a.
//
// Solidity: function updatePPSAfterSkim(uint256 newPPS, uint256 feeAmount) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorSession) UpdatePPSAfterSkim(newPPS *big.Int, feeAmount *big.Int) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.UpdatePPSAfterSkim(&_UnsafeSuperVaultAggregator.TransactOpts, newPPS, feeAmount)
}

// UpdatePPSAfterSkim is a paid mutator transaction binding the contract method 0x12e1ac5a.
//
// Solidity: function updatePPSAfterSkim(uint256 newPPS, uint256 feeAmount) returns()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorTransactorSession) UpdatePPSAfterSkim(newPPS *big.Int, feeAmount *big.Int) (*types.Transaction, error) {
	return _UnsafeSuperVaultAggregator.Contract.UpdatePPSAfterSkim(&_UnsafeSuperVaultAggregator.TransactOpts, newPPS, feeAmount)
}

// UnsafeSuperVaultAggregatorDeviationThresholdUpdatedIterator is returned from FilterDeviationThresholdUpdated and is used to iterate over the raw logs and unpacked data for DeviationThresholdUpdated events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorDeviationThresholdUpdatedIterator struct {
	Event *UnsafeSuperVaultAggregatorDeviationThresholdUpdated // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorDeviationThresholdUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorDeviationThresholdUpdated)
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
		it.Event = new(UnsafeSuperVaultAggregatorDeviationThresholdUpdated)
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
func (it *UnsafeSuperVaultAggregatorDeviationThresholdUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorDeviationThresholdUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorDeviationThresholdUpdated represents a DeviationThresholdUpdated event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorDeviationThresholdUpdated struct {
	Strategy           common.Address
	DeviationThreshold *big.Int
	Raw                types.Log // Blockchain specific contextual infos
}

// FilterDeviationThresholdUpdated is a free log retrieval operation binding the contract event 0xc632e59fe65d75ed53f1e4c619a5cc8b5015d1e9e1db3be7e123adf8b975f06e.
//
// Solidity: event DeviationThresholdUpdated(address indexed strategy, uint256 deviationThreshold)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterDeviationThresholdUpdated(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorDeviationThresholdUpdatedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "DeviationThresholdUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorDeviationThresholdUpdatedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "DeviationThresholdUpdated", logs: logs, sub: sub}, nil
}

// WatchDeviationThresholdUpdated is a free log subscription operation binding the contract event 0xc632e59fe65d75ed53f1e4c619a5cc8b5015d1e9e1db3be7e123adf8b975f06e.
//
// Solidity: event DeviationThresholdUpdated(address indexed strategy, uint256 deviationThreshold)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchDeviationThresholdUpdated(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorDeviationThresholdUpdated, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "DeviationThresholdUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorDeviationThresholdUpdated)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "DeviationThresholdUpdated", log); err != nil {
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

// ParseDeviationThresholdUpdated is a log parse operation binding the contract event 0xc632e59fe65d75ed53f1e4c619a5cc8b5015d1e9e1db3be7e123adf8b975f06e.
//
// Solidity: event DeviationThresholdUpdated(address indexed strategy, uint256 deviationThreshold)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseDeviationThresholdUpdated(log types.Log) (*UnsafeSuperVaultAggregatorDeviationThresholdUpdated, error) {
	event := new(UnsafeSuperVaultAggregatorDeviationThresholdUpdated)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "DeviationThresholdUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorGlobalHooksRootUpdateProposedIterator is returned from FilterGlobalHooksRootUpdateProposed and is used to iterate over the raw logs and unpacked data for GlobalHooksRootUpdateProposed events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorGlobalHooksRootUpdateProposedIterator struct {
	Event *UnsafeSuperVaultAggregatorGlobalHooksRootUpdateProposed // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorGlobalHooksRootUpdateProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorGlobalHooksRootUpdateProposed)
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
		it.Event = new(UnsafeSuperVaultAggregatorGlobalHooksRootUpdateProposed)
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
func (it *UnsafeSuperVaultAggregatorGlobalHooksRootUpdateProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorGlobalHooksRootUpdateProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorGlobalHooksRootUpdateProposed represents a GlobalHooksRootUpdateProposed event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorGlobalHooksRootUpdateProposed struct {
	Root          [32]byte
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterGlobalHooksRootUpdateProposed is a free log retrieval operation binding the contract event 0x71e72baaa2bffcb51d34de71bba7ea258c9c5667a86e69b1c684f0e1ecb4f395.
//
// Solidity: event GlobalHooksRootUpdateProposed(bytes32 indexed root, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterGlobalHooksRootUpdateProposed(opts *bind.FilterOpts, root [][32]byte) (*UnsafeSuperVaultAggregatorGlobalHooksRootUpdateProposedIterator, error) {

	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "GlobalHooksRootUpdateProposed", rootRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorGlobalHooksRootUpdateProposedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "GlobalHooksRootUpdateProposed", logs: logs, sub: sub}, nil
}

// WatchGlobalHooksRootUpdateProposed is a free log subscription operation binding the contract event 0x71e72baaa2bffcb51d34de71bba7ea258c9c5667a86e69b1c684f0e1ecb4f395.
//
// Solidity: event GlobalHooksRootUpdateProposed(bytes32 indexed root, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchGlobalHooksRootUpdateProposed(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorGlobalHooksRootUpdateProposed, root [][32]byte) (event.Subscription, error) {

	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "GlobalHooksRootUpdateProposed", rootRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorGlobalHooksRootUpdateProposed)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootUpdateProposed", log); err != nil {
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

// ParseGlobalHooksRootUpdateProposed is a log parse operation binding the contract event 0x71e72baaa2bffcb51d34de71bba7ea258c9c5667a86e69b1c684f0e1ecb4f395.
//
// Solidity: event GlobalHooksRootUpdateProposed(bytes32 indexed root, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseGlobalHooksRootUpdateProposed(log types.Log) (*UnsafeSuperVaultAggregatorGlobalHooksRootUpdateProposed, error) {
	event := new(UnsafeSuperVaultAggregatorGlobalHooksRootUpdateProposed)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootUpdateProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorGlobalHooksRootUpdatedIterator is returned from FilterGlobalHooksRootUpdated and is used to iterate over the raw logs and unpacked data for GlobalHooksRootUpdated events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorGlobalHooksRootUpdatedIterator struct {
	Event *UnsafeSuperVaultAggregatorGlobalHooksRootUpdated // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorGlobalHooksRootUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorGlobalHooksRootUpdated)
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
		it.Event = new(UnsafeSuperVaultAggregatorGlobalHooksRootUpdated)
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
func (it *UnsafeSuperVaultAggregatorGlobalHooksRootUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorGlobalHooksRootUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorGlobalHooksRootUpdated represents a GlobalHooksRootUpdated event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorGlobalHooksRootUpdated struct {
	OldRoot [32]byte
	NewRoot [32]byte
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterGlobalHooksRootUpdated is a free log retrieval operation binding the contract event 0x0360da73fad480d9a31212f8337d4a576e6b9749d68fc663acf171bb07f950ba.
//
// Solidity: event GlobalHooksRootUpdated(bytes32 indexed oldRoot, bytes32 newRoot)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterGlobalHooksRootUpdated(opts *bind.FilterOpts, oldRoot [][32]byte) (*UnsafeSuperVaultAggregatorGlobalHooksRootUpdatedIterator, error) {

	var oldRootRule []interface{}
	for _, oldRootItem := range oldRoot {
		oldRootRule = append(oldRootRule, oldRootItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "GlobalHooksRootUpdated", oldRootRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorGlobalHooksRootUpdatedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "GlobalHooksRootUpdated", logs: logs, sub: sub}, nil
}

// WatchGlobalHooksRootUpdated is a free log subscription operation binding the contract event 0x0360da73fad480d9a31212f8337d4a576e6b9749d68fc663acf171bb07f950ba.
//
// Solidity: event GlobalHooksRootUpdated(bytes32 indexed oldRoot, bytes32 newRoot)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchGlobalHooksRootUpdated(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorGlobalHooksRootUpdated, oldRoot [][32]byte) (event.Subscription, error) {

	var oldRootRule []interface{}
	for _, oldRootItem := range oldRoot {
		oldRootRule = append(oldRootRule, oldRootItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "GlobalHooksRootUpdated", oldRootRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorGlobalHooksRootUpdated)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootUpdated", log); err != nil {
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

// ParseGlobalHooksRootUpdated is a log parse operation binding the contract event 0x0360da73fad480d9a31212f8337d4a576e6b9749d68fc663acf171bb07f950ba.
//
// Solidity: event GlobalHooksRootUpdated(bytes32 indexed oldRoot, bytes32 newRoot)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseGlobalHooksRootUpdated(log types.Log) (*UnsafeSuperVaultAggregatorGlobalHooksRootUpdated, error) {
	event := new(UnsafeSuperVaultAggregatorGlobalHooksRootUpdated)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator is returned from FilterGlobalHooksRootVetoStatusChanged and is used to iterate over the raw logs and unpacked data for GlobalHooksRootVetoStatusChanged events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator struct {
	Event *UnsafeSuperVaultAggregatorGlobalHooksRootVetoStatusChanged // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorGlobalHooksRootVetoStatusChanged)
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
		it.Event = new(UnsafeSuperVaultAggregatorGlobalHooksRootVetoStatusChanged)
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
func (it *UnsafeSuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorGlobalHooksRootVetoStatusChanged represents a GlobalHooksRootVetoStatusChanged event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorGlobalHooksRootVetoStatusChanged struct {
	Vetoed bool
	Root   [32]byte
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterGlobalHooksRootVetoStatusChanged is a free log retrieval operation binding the contract event 0xd867c555762bc6e6e6c9f80aa6c8132ccc5909f83266bc4d24489c8aa10e5e8d.
//
// Solidity: event GlobalHooksRootVetoStatusChanged(bool vetoed, bytes32 indexed root)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterGlobalHooksRootVetoStatusChanged(opts *bind.FilterOpts, root [][32]byte) (*UnsafeSuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator, error) {

	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "GlobalHooksRootVetoStatusChanged", rootRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "GlobalHooksRootVetoStatusChanged", logs: logs, sub: sub}, nil
}

// WatchGlobalHooksRootVetoStatusChanged is a free log subscription operation binding the contract event 0xd867c555762bc6e6e6c9f80aa6c8132ccc5909f83266bc4d24489c8aa10e5e8d.
//
// Solidity: event GlobalHooksRootVetoStatusChanged(bool vetoed, bytes32 indexed root)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchGlobalHooksRootVetoStatusChanged(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorGlobalHooksRootVetoStatusChanged, root [][32]byte) (event.Subscription, error) {

	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "GlobalHooksRootVetoStatusChanged", rootRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorGlobalHooksRootVetoStatusChanged)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootVetoStatusChanged", log); err != nil {
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

// ParseGlobalHooksRootVetoStatusChanged is a log parse operation binding the contract event 0xd867c555762bc6e6e6c9f80aa6c8132ccc5909f83266bc4d24489c8aa10e5e8d.
//
// Solidity: event GlobalHooksRootVetoStatusChanged(bool vetoed, bytes32 indexed root)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseGlobalHooksRootVetoStatusChanged(log types.Log) (*UnsafeSuperVaultAggregatorGlobalHooksRootVetoStatusChanged, error) {
	event := new(UnsafeSuperVaultAggregatorGlobalHooksRootVetoStatusChanged)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootVetoStatusChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorGlobalLeavesStatusChangedIterator is returned from FilterGlobalLeavesStatusChanged and is used to iterate over the raw logs and unpacked data for GlobalLeavesStatusChanged events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorGlobalLeavesStatusChangedIterator struct {
	Event *UnsafeSuperVaultAggregatorGlobalLeavesStatusChanged // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorGlobalLeavesStatusChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorGlobalLeavesStatusChanged)
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
		it.Event = new(UnsafeSuperVaultAggregatorGlobalLeavesStatusChanged)
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
func (it *UnsafeSuperVaultAggregatorGlobalLeavesStatusChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorGlobalLeavesStatusChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorGlobalLeavesStatusChanged represents a GlobalLeavesStatusChanged event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorGlobalLeavesStatusChanged struct {
	Strategy common.Address
	Leaves   [][32]byte
	Statuses []bool
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterGlobalLeavesStatusChanged is a free log retrieval operation binding the contract event 0x671df22165975c9055ff482eedb4963e75f35ac9f3040346699bd97228a8c790.
//
// Solidity: event GlobalLeavesStatusChanged(address indexed strategy, bytes32[] leaves, bool[] statuses)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterGlobalLeavesStatusChanged(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorGlobalLeavesStatusChangedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "GlobalLeavesStatusChanged", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorGlobalLeavesStatusChangedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "GlobalLeavesStatusChanged", logs: logs, sub: sub}, nil
}

// WatchGlobalLeavesStatusChanged is a free log subscription operation binding the contract event 0x671df22165975c9055ff482eedb4963e75f35ac9f3040346699bd97228a8c790.
//
// Solidity: event GlobalLeavesStatusChanged(address indexed strategy, bytes32[] leaves, bool[] statuses)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchGlobalLeavesStatusChanged(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorGlobalLeavesStatusChanged, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "GlobalLeavesStatusChanged", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorGlobalLeavesStatusChanged)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "GlobalLeavesStatusChanged", log); err != nil {
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

// ParseGlobalLeavesStatusChanged is a log parse operation binding the contract event 0x671df22165975c9055ff482eedb4963e75f35ac9f3040346699bd97228a8c790.
//
// Solidity: event GlobalLeavesStatusChanged(address indexed strategy, bytes32[] leaves, bool[] statuses)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseGlobalLeavesStatusChanged(log types.Log) (*UnsafeSuperVaultAggregatorGlobalLeavesStatusChanged, error) {
	event := new(UnsafeSuperVaultAggregatorGlobalLeavesStatusChanged)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "GlobalLeavesStatusChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorHighWaterMarkResetIterator is returned from FilterHighWaterMarkReset and is used to iterate over the raw logs and unpacked data for HighWaterMarkReset events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorHighWaterMarkResetIterator struct {
	Event *UnsafeSuperVaultAggregatorHighWaterMarkReset // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorHighWaterMarkResetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorHighWaterMarkReset)
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
		it.Event = new(UnsafeSuperVaultAggregatorHighWaterMarkReset)
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
func (it *UnsafeSuperVaultAggregatorHighWaterMarkResetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorHighWaterMarkResetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorHighWaterMarkReset represents a HighWaterMarkReset event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorHighWaterMarkReset struct {
	Strategy common.Address
	NewHWM   *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterHighWaterMarkReset is a free log retrieval operation binding the contract event 0x38e30977945dee262f7d3e5f9f9ece987d5ecad1b6889f39dfcf011923dbdf2b.
//
// Solidity: event HighWaterMarkReset(address indexed strategy, uint256 indexed newHWM)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterHighWaterMarkReset(opts *bind.FilterOpts, strategy []common.Address, newHWM []*big.Int) (*UnsafeSuperVaultAggregatorHighWaterMarkResetIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var newHWMRule []interface{}
	for _, newHWMItem := range newHWM {
		newHWMRule = append(newHWMRule, newHWMItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "HighWaterMarkReset", strategyRule, newHWMRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorHighWaterMarkResetIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "HighWaterMarkReset", logs: logs, sub: sub}, nil
}

// WatchHighWaterMarkReset is a free log subscription operation binding the contract event 0x38e30977945dee262f7d3e5f9f9ece987d5ecad1b6889f39dfcf011923dbdf2b.
//
// Solidity: event HighWaterMarkReset(address indexed strategy, uint256 indexed newHWM)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchHighWaterMarkReset(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorHighWaterMarkReset, strategy []common.Address, newHWM []*big.Int) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var newHWMRule []interface{}
	for _, newHWMItem := range newHWM {
		newHWMRule = append(newHWMRule, newHWMItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "HighWaterMarkReset", strategyRule, newHWMRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorHighWaterMarkReset)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "HighWaterMarkReset", log); err != nil {
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

// ParseHighWaterMarkReset is a log parse operation binding the contract event 0x38e30977945dee262f7d3e5f9f9ece987d5ecad1b6889f39dfcf011923dbdf2b.
//
// Solidity: event HighWaterMarkReset(address indexed strategy, uint256 indexed newHWM)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseHighWaterMarkReset(log types.Log) (*UnsafeSuperVaultAggregatorHighWaterMarkReset, error) {
	event := new(UnsafeSuperVaultAggregatorHighWaterMarkReset)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "HighWaterMarkReset", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorHooksRootUpdateTimelockChangedIterator is returned from FilterHooksRootUpdateTimelockChanged and is used to iterate over the raw logs and unpacked data for HooksRootUpdateTimelockChanged events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorHooksRootUpdateTimelockChangedIterator struct {
	Event *UnsafeSuperVaultAggregatorHooksRootUpdateTimelockChanged // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorHooksRootUpdateTimelockChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorHooksRootUpdateTimelockChanged)
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
		it.Event = new(UnsafeSuperVaultAggregatorHooksRootUpdateTimelockChanged)
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
func (it *UnsafeSuperVaultAggregatorHooksRootUpdateTimelockChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorHooksRootUpdateTimelockChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorHooksRootUpdateTimelockChanged represents a HooksRootUpdateTimelockChanged event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorHooksRootUpdateTimelockChanged struct {
	NewTimelock *big.Int
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterHooksRootUpdateTimelockChanged is a free log retrieval operation binding the contract event 0x132309f91d275ae9cafe2088eea8945ed3b52dac1012d3be4a6e44622488a4f6.
//
// Solidity: event HooksRootUpdateTimelockChanged(uint256 newTimelock)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterHooksRootUpdateTimelockChanged(opts *bind.FilterOpts) (*UnsafeSuperVaultAggregatorHooksRootUpdateTimelockChangedIterator, error) {

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "HooksRootUpdateTimelockChanged")
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorHooksRootUpdateTimelockChangedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "HooksRootUpdateTimelockChanged", logs: logs, sub: sub}, nil
}

// WatchHooksRootUpdateTimelockChanged is a free log subscription operation binding the contract event 0x132309f91d275ae9cafe2088eea8945ed3b52dac1012d3be4a6e44622488a4f6.
//
// Solidity: event HooksRootUpdateTimelockChanged(uint256 newTimelock)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchHooksRootUpdateTimelockChanged(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorHooksRootUpdateTimelockChanged) (event.Subscription, error) {

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "HooksRootUpdateTimelockChanged")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorHooksRootUpdateTimelockChanged)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "HooksRootUpdateTimelockChanged", log); err != nil {
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

// ParseHooksRootUpdateTimelockChanged is a log parse operation binding the contract event 0x132309f91d275ae9cafe2088eea8945ed3b52dac1012d3be4a6e44622488a4f6.
//
// Solidity: event HooksRootUpdateTimelockChanged(uint256 newTimelock)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseHooksRootUpdateTimelockChanged(log types.Log) (*UnsafeSuperVaultAggregatorHooksRootUpdateTimelockChanged, error) {
	event := new(UnsafeSuperVaultAggregatorHooksRootUpdateTimelockChanged)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "HooksRootUpdateTimelockChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorInsufficientUpkeepIterator is returned from FilterInsufficientUpkeep and is used to iterate over the raw logs and unpacked data for InsufficientUpkeep events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorInsufficientUpkeepIterator struct {
	Event *UnsafeSuperVaultAggregatorInsufficientUpkeep // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorInsufficientUpkeepIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorInsufficientUpkeep)
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
		it.Event = new(UnsafeSuperVaultAggregatorInsufficientUpkeep)
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
func (it *UnsafeSuperVaultAggregatorInsufficientUpkeepIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorInsufficientUpkeepIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorInsufficientUpkeep represents a InsufficientUpkeep event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorInsufficientUpkeep struct {
	Strategy     common.Address
	StrategyAddr common.Address
	Balance      *big.Int
	Cost         *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterInsufficientUpkeep is a free log retrieval operation binding the contract event 0x9f17e0625b7890f465cad6295db4c1abad9d5afeea38a1d7d64f390aef73a770.
//
// Solidity: event InsufficientUpkeep(address indexed strategy, address indexed strategyAddr, uint256 balance, uint256 cost)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterInsufficientUpkeep(opts *bind.FilterOpts, strategy []common.Address, strategyAddr []common.Address) (*UnsafeSuperVaultAggregatorInsufficientUpkeepIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var strategyAddrRule []interface{}
	for _, strategyAddrItem := range strategyAddr {
		strategyAddrRule = append(strategyAddrRule, strategyAddrItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "InsufficientUpkeep", strategyRule, strategyAddrRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorInsufficientUpkeepIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "InsufficientUpkeep", logs: logs, sub: sub}, nil
}

// WatchInsufficientUpkeep is a free log subscription operation binding the contract event 0x9f17e0625b7890f465cad6295db4c1abad9d5afeea38a1d7d64f390aef73a770.
//
// Solidity: event InsufficientUpkeep(address indexed strategy, address indexed strategyAddr, uint256 balance, uint256 cost)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchInsufficientUpkeep(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorInsufficientUpkeep, strategy []common.Address, strategyAddr []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var strategyAddrRule []interface{}
	for _, strategyAddrItem := range strategyAddr {
		strategyAddrRule = append(strategyAddrRule, strategyAddrItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "InsufficientUpkeep", strategyRule, strategyAddrRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorInsufficientUpkeep)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "InsufficientUpkeep", log); err != nil {
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

// ParseInsufficientUpkeep is a log parse operation binding the contract event 0x9f17e0625b7890f465cad6295db4c1abad9d5afeea38a1d7d64f390aef73a770.
//
// Solidity: event InsufficientUpkeep(address indexed strategy, address indexed strategyAddr, uint256 balance, uint256 cost)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseInsufficientUpkeep(log types.Log) (*UnsafeSuperVaultAggregatorInsufficientUpkeep, error) {
	event := new(UnsafeSuperVaultAggregatorInsufficientUpkeep)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "InsufficientUpkeep", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorMinUpdateIntervalChangeCancelledIterator is returned from FilterMinUpdateIntervalChangeCancelled and is used to iterate over the raw logs and unpacked data for MinUpdateIntervalChangeCancelled events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorMinUpdateIntervalChangeCancelledIterator struct {
	Event *UnsafeSuperVaultAggregatorMinUpdateIntervalChangeCancelled // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorMinUpdateIntervalChangeCancelledIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorMinUpdateIntervalChangeCancelled)
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
		it.Event = new(UnsafeSuperVaultAggregatorMinUpdateIntervalChangeCancelled)
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
func (it *UnsafeSuperVaultAggregatorMinUpdateIntervalChangeCancelledIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorMinUpdateIntervalChangeCancelledIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorMinUpdateIntervalChangeCancelled represents a MinUpdateIntervalChangeCancelled event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorMinUpdateIntervalChangeCancelled struct {
	Strategy          common.Address
	CancelledInterval *big.Int
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterMinUpdateIntervalChangeCancelled is a free log retrieval operation binding the contract event 0x03ed1b00c79644c2f1066b475c92818992a014d513078a5fd3305c491b28dc67.
//
// Solidity: event MinUpdateIntervalChangeCancelled(address indexed strategy, uint256 cancelledInterval)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterMinUpdateIntervalChangeCancelled(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorMinUpdateIntervalChangeCancelledIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "MinUpdateIntervalChangeCancelled", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorMinUpdateIntervalChangeCancelledIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "MinUpdateIntervalChangeCancelled", logs: logs, sub: sub}, nil
}

// WatchMinUpdateIntervalChangeCancelled is a free log subscription operation binding the contract event 0x03ed1b00c79644c2f1066b475c92818992a014d513078a5fd3305c491b28dc67.
//
// Solidity: event MinUpdateIntervalChangeCancelled(address indexed strategy, uint256 cancelledInterval)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchMinUpdateIntervalChangeCancelled(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorMinUpdateIntervalChangeCancelled, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "MinUpdateIntervalChangeCancelled", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorMinUpdateIntervalChangeCancelled)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "MinUpdateIntervalChangeCancelled", log); err != nil {
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

// ParseMinUpdateIntervalChangeCancelled is a log parse operation binding the contract event 0x03ed1b00c79644c2f1066b475c92818992a014d513078a5fd3305c491b28dc67.
//
// Solidity: event MinUpdateIntervalChangeCancelled(address indexed strategy, uint256 cancelledInterval)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseMinUpdateIntervalChangeCancelled(log types.Log) (*UnsafeSuperVaultAggregatorMinUpdateIntervalChangeCancelled, error) {
	event := new(UnsafeSuperVaultAggregatorMinUpdateIntervalChangeCancelled)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "MinUpdateIntervalChangeCancelled", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorMinUpdateIntervalChangeProposedIterator is returned from FilterMinUpdateIntervalChangeProposed and is used to iterate over the raw logs and unpacked data for MinUpdateIntervalChangeProposed events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorMinUpdateIntervalChangeProposedIterator struct {
	Event *UnsafeSuperVaultAggregatorMinUpdateIntervalChangeProposed // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorMinUpdateIntervalChangeProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorMinUpdateIntervalChangeProposed)
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
		it.Event = new(UnsafeSuperVaultAggregatorMinUpdateIntervalChangeProposed)
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
func (it *UnsafeSuperVaultAggregatorMinUpdateIntervalChangeProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorMinUpdateIntervalChangeProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorMinUpdateIntervalChangeProposed represents a MinUpdateIntervalChangeProposed event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorMinUpdateIntervalChangeProposed struct {
	Strategy             common.Address
	Proposer             common.Address
	NewMinUpdateInterval *big.Int
	EffectiveTime        *big.Int
	Raw                  types.Log // Blockchain specific contextual infos
}

// FilterMinUpdateIntervalChangeProposed is a free log retrieval operation binding the contract event 0xfaabc7622c15965d088243dee3943358c4b09cacae32f9b23d8c19014711ea9b.
//
// Solidity: event MinUpdateIntervalChangeProposed(address indexed strategy, address indexed proposer, uint256 newMinUpdateInterval, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterMinUpdateIntervalChangeProposed(opts *bind.FilterOpts, strategy []common.Address, proposer []common.Address) (*UnsafeSuperVaultAggregatorMinUpdateIntervalChangeProposedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var proposerRule []interface{}
	for _, proposerItem := range proposer {
		proposerRule = append(proposerRule, proposerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "MinUpdateIntervalChangeProposed", strategyRule, proposerRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorMinUpdateIntervalChangeProposedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "MinUpdateIntervalChangeProposed", logs: logs, sub: sub}, nil
}

// WatchMinUpdateIntervalChangeProposed is a free log subscription operation binding the contract event 0xfaabc7622c15965d088243dee3943358c4b09cacae32f9b23d8c19014711ea9b.
//
// Solidity: event MinUpdateIntervalChangeProposed(address indexed strategy, address indexed proposer, uint256 newMinUpdateInterval, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchMinUpdateIntervalChangeProposed(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorMinUpdateIntervalChangeProposed, strategy []common.Address, proposer []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var proposerRule []interface{}
	for _, proposerItem := range proposer {
		proposerRule = append(proposerRule, proposerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "MinUpdateIntervalChangeProposed", strategyRule, proposerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorMinUpdateIntervalChangeProposed)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "MinUpdateIntervalChangeProposed", log); err != nil {
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

// ParseMinUpdateIntervalChangeProposed is a log parse operation binding the contract event 0xfaabc7622c15965d088243dee3943358c4b09cacae32f9b23d8c19014711ea9b.
//
// Solidity: event MinUpdateIntervalChangeProposed(address indexed strategy, address indexed proposer, uint256 newMinUpdateInterval, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseMinUpdateIntervalChangeProposed(log types.Log) (*UnsafeSuperVaultAggregatorMinUpdateIntervalChangeProposed, error) {
	event := new(UnsafeSuperVaultAggregatorMinUpdateIntervalChangeProposed)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "MinUpdateIntervalChangeProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorMinUpdateIntervalChangeRejectedIterator is returned from FilterMinUpdateIntervalChangeRejected and is used to iterate over the raw logs and unpacked data for MinUpdateIntervalChangeRejected events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorMinUpdateIntervalChangeRejectedIterator struct {
	Event *UnsafeSuperVaultAggregatorMinUpdateIntervalChangeRejected // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorMinUpdateIntervalChangeRejectedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorMinUpdateIntervalChangeRejected)
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
		it.Event = new(UnsafeSuperVaultAggregatorMinUpdateIntervalChangeRejected)
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
func (it *UnsafeSuperVaultAggregatorMinUpdateIntervalChangeRejectedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorMinUpdateIntervalChangeRejectedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorMinUpdateIntervalChangeRejected represents a MinUpdateIntervalChangeRejected event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorMinUpdateIntervalChangeRejected struct {
	Strategy            common.Address
	ProposedInterval    *big.Int
	CurrentMaxStaleness *big.Int
	Raw                 types.Log // Blockchain specific contextual infos
}

// FilterMinUpdateIntervalChangeRejected is a free log retrieval operation binding the contract event 0xc78d60f229311c9a83149509d6e485dbc36550d23de31de5210dfef81271c6fa.
//
// Solidity: event MinUpdateIntervalChangeRejected(address indexed strategy, uint256 proposedInterval, uint256 currentMaxStaleness)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterMinUpdateIntervalChangeRejected(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorMinUpdateIntervalChangeRejectedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "MinUpdateIntervalChangeRejected", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorMinUpdateIntervalChangeRejectedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "MinUpdateIntervalChangeRejected", logs: logs, sub: sub}, nil
}

// WatchMinUpdateIntervalChangeRejected is a free log subscription operation binding the contract event 0xc78d60f229311c9a83149509d6e485dbc36550d23de31de5210dfef81271c6fa.
//
// Solidity: event MinUpdateIntervalChangeRejected(address indexed strategy, uint256 proposedInterval, uint256 currentMaxStaleness)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchMinUpdateIntervalChangeRejected(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorMinUpdateIntervalChangeRejected, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "MinUpdateIntervalChangeRejected", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorMinUpdateIntervalChangeRejected)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "MinUpdateIntervalChangeRejected", log); err != nil {
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

// ParseMinUpdateIntervalChangeRejected is a log parse operation binding the contract event 0xc78d60f229311c9a83149509d6e485dbc36550d23de31de5210dfef81271c6fa.
//
// Solidity: event MinUpdateIntervalChangeRejected(address indexed strategy, uint256 proposedInterval, uint256 currentMaxStaleness)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseMinUpdateIntervalChangeRejected(log types.Log) (*UnsafeSuperVaultAggregatorMinUpdateIntervalChangeRejected, error) {
	event := new(UnsafeSuperVaultAggregatorMinUpdateIntervalChangeRejected)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "MinUpdateIntervalChangeRejected", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorMinUpdateIntervalChangedIterator is returned from FilterMinUpdateIntervalChanged and is used to iterate over the raw logs and unpacked data for MinUpdateIntervalChanged events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorMinUpdateIntervalChangedIterator struct {
	Event *UnsafeSuperVaultAggregatorMinUpdateIntervalChanged // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorMinUpdateIntervalChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorMinUpdateIntervalChanged)
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
		it.Event = new(UnsafeSuperVaultAggregatorMinUpdateIntervalChanged)
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
func (it *UnsafeSuperVaultAggregatorMinUpdateIntervalChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorMinUpdateIntervalChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorMinUpdateIntervalChanged represents a MinUpdateIntervalChanged event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorMinUpdateIntervalChanged struct {
	Strategy             common.Address
	OldMinUpdateInterval *big.Int
	NewMinUpdateInterval *big.Int
	Raw                  types.Log // Blockchain specific contextual infos
}

// FilterMinUpdateIntervalChanged is a free log retrieval operation binding the contract event 0xfdbb1b47608591d414ef3f42c654d856dc78d11a78b029627cc9fff1645d2a56.
//
// Solidity: event MinUpdateIntervalChanged(address indexed strategy, uint256 oldMinUpdateInterval, uint256 newMinUpdateInterval)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterMinUpdateIntervalChanged(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorMinUpdateIntervalChangedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "MinUpdateIntervalChanged", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorMinUpdateIntervalChangedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "MinUpdateIntervalChanged", logs: logs, sub: sub}, nil
}

// WatchMinUpdateIntervalChanged is a free log subscription operation binding the contract event 0xfdbb1b47608591d414ef3f42c654d856dc78d11a78b029627cc9fff1645d2a56.
//
// Solidity: event MinUpdateIntervalChanged(address indexed strategy, uint256 oldMinUpdateInterval, uint256 newMinUpdateInterval)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchMinUpdateIntervalChanged(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorMinUpdateIntervalChanged, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "MinUpdateIntervalChanged", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorMinUpdateIntervalChanged)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "MinUpdateIntervalChanged", log); err != nil {
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

// ParseMinUpdateIntervalChanged is a log parse operation binding the contract event 0xfdbb1b47608591d414ef3f42c654d856dc78d11a78b029627cc9fff1645d2a56.
//
// Solidity: event MinUpdateIntervalChanged(address indexed strategy, uint256 oldMinUpdateInterval, uint256 newMinUpdateInterval)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseMinUpdateIntervalChanged(log types.Log) (*UnsafeSuperVaultAggregatorMinUpdateIntervalChanged, error) {
	event := new(UnsafeSuperVaultAggregatorMinUpdateIntervalChanged)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "MinUpdateIntervalChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorOldPrimaryManagerRemovedIterator is returned from FilterOldPrimaryManagerRemoved and is used to iterate over the raw logs and unpacked data for OldPrimaryManagerRemoved events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorOldPrimaryManagerRemovedIterator struct {
	Event *UnsafeSuperVaultAggregatorOldPrimaryManagerRemoved // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorOldPrimaryManagerRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorOldPrimaryManagerRemoved)
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
		it.Event = new(UnsafeSuperVaultAggregatorOldPrimaryManagerRemoved)
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
func (it *UnsafeSuperVaultAggregatorOldPrimaryManagerRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorOldPrimaryManagerRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorOldPrimaryManagerRemoved represents a OldPrimaryManagerRemoved event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorOldPrimaryManagerRemoved struct {
	Strategy   common.Address
	OldManager common.Address
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterOldPrimaryManagerRemoved is a free log retrieval operation binding the contract event 0x744302e838f7c0c35e8971c67d7229a331a29eb270e24b7ceb261658ac679f6d.
//
// Solidity: event OldPrimaryManagerRemoved(address indexed strategy, address indexed oldManager)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterOldPrimaryManagerRemoved(opts *bind.FilterOpts, strategy []common.Address, oldManager []common.Address) (*UnsafeSuperVaultAggregatorOldPrimaryManagerRemovedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var oldManagerRule []interface{}
	for _, oldManagerItem := range oldManager {
		oldManagerRule = append(oldManagerRule, oldManagerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "OldPrimaryManagerRemoved", strategyRule, oldManagerRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorOldPrimaryManagerRemovedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "OldPrimaryManagerRemoved", logs: logs, sub: sub}, nil
}

// WatchOldPrimaryManagerRemoved is a free log subscription operation binding the contract event 0x744302e838f7c0c35e8971c67d7229a331a29eb270e24b7ceb261658ac679f6d.
//
// Solidity: event OldPrimaryManagerRemoved(address indexed strategy, address indexed oldManager)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchOldPrimaryManagerRemoved(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorOldPrimaryManagerRemoved, strategy []common.Address, oldManager []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var oldManagerRule []interface{}
	for _, oldManagerItem := range oldManager {
		oldManagerRule = append(oldManagerRule, oldManagerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "OldPrimaryManagerRemoved", strategyRule, oldManagerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorOldPrimaryManagerRemoved)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "OldPrimaryManagerRemoved", log); err != nil {
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

// ParseOldPrimaryManagerRemoved is a log parse operation binding the contract event 0x744302e838f7c0c35e8971c67d7229a331a29eb270e24b7ceb261658ac679f6d.
//
// Solidity: event OldPrimaryManagerRemoved(address indexed strategy, address indexed oldManager)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseOldPrimaryManagerRemoved(log types.Log) (*UnsafeSuperVaultAggregatorOldPrimaryManagerRemoved, error) {
	event := new(UnsafeSuperVaultAggregatorOldPrimaryManagerRemoved)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "OldPrimaryManagerRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorPPSUpdateRejectedStrategyPausedIterator is returned from FilterPPSUpdateRejectedStrategyPaused and is used to iterate over the raw logs and unpacked data for PPSUpdateRejectedStrategyPaused events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorPPSUpdateRejectedStrategyPausedIterator struct {
	Event *UnsafeSuperVaultAggregatorPPSUpdateRejectedStrategyPaused // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorPPSUpdateRejectedStrategyPausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorPPSUpdateRejectedStrategyPaused)
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
		it.Event = new(UnsafeSuperVaultAggregatorPPSUpdateRejectedStrategyPaused)
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
func (it *UnsafeSuperVaultAggregatorPPSUpdateRejectedStrategyPausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorPPSUpdateRejectedStrategyPausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorPPSUpdateRejectedStrategyPaused represents a PPSUpdateRejectedStrategyPaused event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorPPSUpdateRejectedStrategyPaused struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterPPSUpdateRejectedStrategyPaused is a free log retrieval operation binding the contract event 0xf3e21bd07cf4050faf914678b23f5d9a218123f79904e55a5fb41a41a7d057b0.
//
// Solidity: event PPSUpdateRejectedStrategyPaused(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterPPSUpdateRejectedStrategyPaused(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorPPSUpdateRejectedStrategyPausedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "PPSUpdateRejectedStrategyPaused", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorPPSUpdateRejectedStrategyPausedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "PPSUpdateRejectedStrategyPaused", logs: logs, sub: sub}, nil
}

// WatchPPSUpdateRejectedStrategyPaused is a free log subscription operation binding the contract event 0xf3e21bd07cf4050faf914678b23f5d9a218123f79904e55a5fb41a41a7d057b0.
//
// Solidity: event PPSUpdateRejectedStrategyPaused(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchPPSUpdateRejectedStrategyPaused(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorPPSUpdateRejectedStrategyPaused, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "PPSUpdateRejectedStrategyPaused", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorPPSUpdateRejectedStrategyPaused)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "PPSUpdateRejectedStrategyPaused", log); err != nil {
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

// ParsePPSUpdateRejectedStrategyPaused is a log parse operation binding the contract event 0xf3e21bd07cf4050faf914678b23f5d9a218123f79904e55a5fb41a41a7d057b0.
//
// Solidity: event PPSUpdateRejectedStrategyPaused(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParsePPSUpdateRejectedStrategyPaused(log types.Log) (*UnsafeSuperVaultAggregatorPPSUpdateRejectedStrategyPaused, error) {
	event := new(UnsafeSuperVaultAggregatorPPSUpdateRejectedStrategyPaused)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "PPSUpdateRejectedStrategyPaused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorPPSUpdatedIterator is returned from FilterPPSUpdated and is used to iterate over the raw logs and unpacked data for PPSUpdated events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorPPSUpdatedIterator struct {
	Event *UnsafeSuperVaultAggregatorPPSUpdated // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorPPSUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorPPSUpdated)
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
		it.Event = new(UnsafeSuperVaultAggregatorPPSUpdated)
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
func (it *UnsafeSuperVaultAggregatorPPSUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorPPSUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorPPSUpdated represents a PPSUpdated event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorPPSUpdated struct {
	Strategy  common.Address
	Pps       *big.Int
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterPPSUpdated is a free log retrieval operation binding the contract event 0xdacecd2f542e0332ebba232014aeb2099cc06386862bc8d88d8446b826382ece.
//
// Solidity: event PPSUpdated(address indexed strategy, uint256 pps, uint256 timestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterPPSUpdated(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorPPSUpdatedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "PPSUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorPPSUpdatedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "PPSUpdated", logs: logs, sub: sub}, nil
}

// WatchPPSUpdated is a free log subscription operation binding the contract event 0xdacecd2f542e0332ebba232014aeb2099cc06386862bc8d88d8446b826382ece.
//
// Solidity: event PPSUpdated(address indexed strategy, uint256 pps, uint256 timestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchPPSUpdated(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorPPSUpdated, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "PPSUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorPPSUpdated)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "PPSUpdated", log); err != nil {
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

// ParsePPSUpdated is a log parse operation binding the contract event 0xdacecd2f542e0332ebba232014aeb2099cc06386862bc8d88d8446b826382ece.
//
// Solidity: event PPSUpdated(address indexed strategy, uint256 pps, uint256 timestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParsePPSUpdated(log types.Log) (*UnsafeSuperVaultAggregatorPPSUpdated, error) {
	event := new(UnsafeSuperVaultAggregatorPPSUpdated)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "PPSUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorPPSUpdatedAfterSkimIterator is returned from FilterPPSUpdatedAfterSkim and is used to iterate over the raw logs and unpacked data for PPSUpdatedAfterSkim events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorPPSUpdatedAfterSkimIterator struct {
	Event *UnsafeSuperVaultAggregatorPPSUpdatedAfterSkim // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorPPSUpdatedAfterSkimIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorPPSUpdatedAfterSkim)
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
		it.Event = new(UnsafeSuperVaultAggregatorPPSUpdatedAfterSkim)
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
func (it *UnsafeSuperVaultAggregatorPPSUpdatedAfterSkimIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorPPSUpdatedAfterSkimIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorPPSUpdatedAfterSkim represents a PPSUpdatedAfterSkim event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorPPSUpdatedAfterSkim struct {
	Strategy  common.Address
	OldPPS    *big.Int
	NewPPS    *big.Int
	FeeAmount *big.Int
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterPPSUpdatedAfterSkim is a free log retrieval operation binding the contract event 0x482a01d8e596a883e67895d310f80b2c151a445aa5e277325a6499b0be869845.
//
// Solidity: event PPSUpdatedAfterSkim(address indexed strategy, uint256 oldPPS, uint256 newPPS, uint256 feeAmount, uint256 timestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterPPSUpdatedAfterSkim(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorPPSUpdatedAfterSkimIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "PPSUpdatedAfterSkim", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorPPSUpdatedAfterSkimIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "PPSUpdatedAfterSkim", logs: logs, sub: sub}, nil
}

// WatchPPSUpdatedAfterSkim is a free log subscription operation binding the contract event 0x482a01d8e596a883e67895d310f80b2c151a445aa5e277325a6499b0be869845.
//
// Solidity: event PPSUpdatedAfterSkim(address indexed strategy, uint256 oldPPS, uint256 newPPS, uint256 feeAmount, uint256 timestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchPPSUpdatedAfterSkim(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorPPSUpdatedAfterSkim, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "PPSUpdatedAfterSkim", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorPPSUpdatedAfterSkim)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "PPSUpdatedAfterSkim", log); err != nil {
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

// ParsePPSUpdatedAfterSkim is a log parse operation binding the contract event 0x482a01d8e596a883e67895d310f80b2c151a445aa5e277325a6499b0be869845.
//
// Solidity: event PPSUpdatedAfterSkim(address indexed strategy, uint256 oldPPS, uint256 newPPS, uint256 feeAmount, uint256 timestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParsePPSUpdatedAfterSkim(log types.Log) (*UnsafeSuperVaultAggregatorPPSUpdatedAfterSkim, error) {
	event := new(UnsafeSuperVaultAggregatorPPSUpdatedAfterSkim)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "PPSUpdatedAfterSkim", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorPrimaryManagerChangeCancelledIterator is returned from FilterPrimaryManagerChangeCancelled and is used to iterate over the raw logs and unpacked data for PrimaryManagerChangeCancelled events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorPrimaryManagerChangeCancelledIterator struct {
	Event *UnsafeSuperVaultAggregatorPrimaryManagerChangeCancelled // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorPrimaryManagerChangeCancelledIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorPrimaryManagerChangeCancelled)
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
		it.Event = new(UnsafeSuperVaultAggregatorPrimaryManagerChangeCancelled)
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
func (it *UnsafeSuperVaultAggregatorPrimaryManagerChangeCancelledIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorPrimaryManagerChangeCancelledIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorPrimaryManagerChangeCancelled represents a PrimaryManagerChangeCancelled event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorPrimaryManagerChangeCancelled struct {
	Strategy         common.Address
	CancelledManager common.Address
	Raw              types.Log // Blockchain specific contextual infos
}

// FilterPrimaryManagerChangeCancelled is a free log retrieval operation binding the contract event 0x12a87226e0c76047d6fef7f70bd906fa61a48e44cf4151617f9a7adecda4f479.
//
// Solidity: event PrimaryManagerChangeCancelled(address indexed strategy, address indexed cancelledManager)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterPrimaryManagerChangeCancelled(opts *bind.FilterOpts, strategy []common.Address, cancelledManager []common.Address) (*UnsafeSuperVaultAggregatorPrimaryManagerChangeCancelledIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var cancelledManagerRule []interface{}
	for _, cancelledManagerItem := range cancelledManager {
		cancelledManagerRule = append(cancelledManagerRule, cancelledManagerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "PrimaryManagerChangeCancelled", strategyRule, cancelledManagerRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorPrimaryManagerChangeCancelledIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "PrimaryManagerChangeCancelled", logs: logs, sub: sub}, nil
}

// WatchPrimaryManagerChangeCancelled is a free log subscription operation binding the contract event 0x12a87226e0c76047d6fef7f70bd906fa61a48e44cf4151617f9a7adecda4f479.
//
// Solidity: event PrimaryManagerChangeCancelled(address indexed strategy, address indexed cancelledManager)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchPrimaryManagerChangeCancelled(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorPrimaryManagerChangeCancelled, strategy []common.Address, cancelledManager []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var cancelledManagerRule []interface{}
	for _, cancelledManagerItem := range cancelledManager {
		cancelledManagerRule = append(cancelledManagerRule, cancelledManagerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "PrimaryManagerChangeCancelled", strategyRule, cancelledManagerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorPrimaryManagerChangeCancelled)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "PrimaryManagerChangeCancelled", log); err != nil {
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

// ParsePrimaryManagerChangeCancelled is a log parse operation binding the contract event 0x12a87226e0c76047d6fef7f70bd906fa61a48e44cf4151617f9a7adecda4f479.
//
// Solidity: event PrimaryManagerChangeCancelled(address indexed strategy, address indexed cancelledManager)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParsePrimaryManagerChangeCancelled(log types.Log) (*UnsafeSuperVaultAggregatorPrimaryManagerChangeCancelled, error) {
	event := new(UnsafeSuperVaultAggregatorPrimaryManagerChangeCancelled)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "PrimaryManagerChangeCancelled", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorPrimaryManagerChangeProposedIterator is returned from FilterPrimaryManagerChangeProposed and is used to iterate over the raw logs and unpacked data for PrimaryManagerChangeProposed events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorPrimaryManagerChangeProposedIterator struct {
	Event *UnsafeSuperVaultAggregatorPrimaryManagerChangeProposed // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorPrimaryManagerChangeProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorPrimaryManagerChangeProposed)
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
		it.Event = new(UnsafeSuperVaultAggregatorPrimaryManagerChangeProposed)
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
func (it *UnsafeSuperVaultAggregatorPrimaryManagerChangeProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorPrimaryManagerChangeProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorPrimaryManagerChangeProposed represents a PrimaryManagerChangeProposed event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorPrimaryManagerChangeProposed struct {
	Strategy      common.Address
	Proposer      common.Address
	NewManager    common.Address
	FeeRecipient  common.Address
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterPrimaryManagerChangeProposed is a free log retrieval operation binding the contract event 0xfb67e6bbbfba8245b27d33889b32a324c5cdc2b0c52d738d9e65642d770a2164.
//
// Solidity: event PrimaryManagerChangeProposed(address indexed strategy, address indexed proposer, address indexed newManager, address feeRecipient, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterPrimaryManagerChangeProposed(opts *bind.FilterOpts, strategy []common.Address, proposer []common.Address, newManager []common.Address) (*UnsafeSuperVaultAggregatorPrimaryManagerChangeProposedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var proposerRule []interface{}
	for _, proposerItem := range proposer {
		proposerRule = append(proposerRule, proposerItem)
	}
	var newManagerRule []interface{}
	for _, newManagerItem := range newManager {
		newManagerRule = append(newManagerRule, newManagerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "PrimaryManagerChangeProposed", strategyRule, proposerRule, newManagerRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorPrimaryManagerChangeProposedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "PrimaryManagerChangeProposed", logs: logs, sub: sub}, nil
}

// WatchPrimaryManagerChangeProposed is a free log subscription operation binding the contract event 0xfb67e6bbbfba8245b27d33889b32a324c5cdc2b0c52d738d9e65642d770a2164.
//
// Solidity: event PrimaryManagerChangeProposed(address indexed strategy, address indexed proposer, address indexed newManager, address feeRecipient, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchPrimaryManagerChangeProposed(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorPrimaryManagerChangeProposed, strategy []common.Address, proposer []common.Address, newManager []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var proposerRule []interface{}
	for _, proposerItem := range proposer {
		proposerRule = append(proposerRule, proposerItem)
	}
	var newManagerRule []interface{}
	for _, newManagerItem := range newManager {
		newManagerRule = append(newManagerRule, newManagerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "PrimaryManagerChangeProposed", strategyRule, proposerRule, newManagerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorPrimaryManagerChangeProposed)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "PrimaryManagerChangeProposed", log); err != nil {
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

// ParsePrimaryManagerChangeProposed is a log parse operation binding the contract event 0xfb67e6bbbfba8245b27d33889b32a324c5cdc2b0c52d738d9e65642d770a2164.
//
// Solidity: event PrimaryManagerChangeProposed(address indexed strategy, address indexed proposer, address indexed newManager, address feeRecipient, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParsePrimaryManagerChangeProposed(log types.Log) (*UnsafeSuperVaultAggregatorPrimaryManagerChangeProposed, error) {
	event := new(UnsafeSuperVaultAggregatorPrimaryManagerChangeProposed)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "PrimaryManagerChangeProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorPrimaryManagerChangedIterator is returned from FilterPrimaryManagerChanged and is used to iterate over the raw logs and unpacked data for PrimaryManagerChanged events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorPrimaryManagerChangedIterator struct {
	Event *UnsafeSuperVaultAggregatorPrimaryManagerChanged // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorPrimaryManagerChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorPrimaryManagerChanged)
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
		it.Event = new(UnsafeSuperVaultAggregatorPrimaryManagerChanged)
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
func (it *UnsafeSuperVaultAggregatorPrimaryManagerChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorPrimaryManagerChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorPrimaryManagerChanged represents a PrimaryManagerChanged event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorPrimaryManagerChanged struct {
	Strategy     common.Address
	OldManager   common.Address
	NewManager   common.Address
	FeeRecipient common.Address
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterPrimaryManagerChanged is a free log retrieval operation binding the contract event 0x7e62e1ec80a87937e5d40f5a5e42a516befc032971f2b16e0dc1839c9b08b5b7.
//
// Solidity: event PrimaryManagerChanged(address indexed strategy, address indexed oldManager, address indexed newManager, address feeRecipient)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterPrimaryManagerChanged(opts *bind.FilterOpts, strategy []common.Address, oldManager []common.Address, newManager []common.Address) (*UnsafeSuperVaultAggregatorPrimaryManagerChangedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var oldManagerRule []interface{}
	for _, oldManagerItem := range oldManager {
		oldManagerRule = append(oldManagerRule, oldManagerItem)
	}
	var newManagerRule []interface{}
	for _, newManagerItem := range newManager {
		newManagerRule = append(newManagerRule, newManagerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "PrimaryManagerChanged", strategyRule, oldManagerRule, newManagerRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorPrimaryManagerChangedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "PrimaryManagerChanged", logs: logs, sub: sub}, nil
}

// WatchPrimaryManagerChanged is a free log subscription operation binding the contract event 0x7e62e1ec80a87937e5d40f5a5e42a516befc032971f2b16e0dc1839c9b08b5b7.
//
// Solidity: event PrimaryManagerChanged(address indexed strategy, address indexed oldManager, address indexed newManager, address feeRecipient)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchPrimaryManagerChanged(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorPrimaryManagerChanged, strategy []common.Address, oldManager []common.Address, newManager []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var oldManagerRule []interface{}
	for _, oldManagerItem := range oldManager {
		oldManagerRule = append(oldManagerRule, oldManagerItem)
	}
	var newManagerRule []interface{}
	for _, newManagerItem := range newManager {
		newManagerRule = append(newManagerRule, newManagerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "PrimaryManagerChanged", strategyRule, oldManagerRule, newManagerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorPrimaryManagerChanged)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "PrimaryManagerChanged", log); err != nil {
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

// ParsePrimaryManagerChanged is a log parse operation binding the contract event 0x7e62e1ec80a87937e5d40f5a5e42a516befc032971f2b16e0dc1839c9b08b5b7.
//
// Solidity: event PrimaryManagerChanged(address indexed strategy, address indexed oldManager, address indexed newManager, address feeRecipient)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParsePrimaryManagerChanged(log types.Log) (*UnsafeSuperVaultAggregatorPrimaryManagerChanged, error) {
	event := new(UnsafeSuperVaultAggregatorPrimaryManagerChanged)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "PrimaryManagerChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator is returned from FilterProvidedTimestampExceedsBlockTimestamp and is used to iterate over the raw logs and unpacked data for ProvidedTimestampExceedsBlockTimestamp events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator struct {
	Event *UnsafeSuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp)
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
		it.Event = new(UnsafeSuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp)
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
func (it *UnsafeSuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp represents a ProvidedTimestampExceedsBlockTimestamp event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp struct {
	Strategy       common.Address
	ArgsTimestamp  *big.Int
	BlockTimestamp *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterProvidedTimestampExceedsBlockTimestamp is a free log retrieval operation binding the contract event 0x11ce21eb8049b15d3cb258f2a3e207e24b6ca2141010b9c063228faa8628b9b5.
//
// Solidity: event ProvidedTimestampExceedsBlockTimestamp(address indexed strategy, uint256 argsTimestamp, uint256 blockTimestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterProvidedTimestampExceedsBlockTimestamp(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "ProvidedTimestampExceedsBlockTimestamp", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "ProvidedTimestampExceedsBlockTimestamp", logs: logs, sub: sub}, nil
}

// WatchProvidedTimestampExceedsBlockTimestamp is a free log subscription operation binding the contract event 0x11ce21eb8049b15d3cb258f2a3e207e24b6ca2141010b9c063228faa8628b9b5.
//
// Solidity: event ProvidedTimestampExceedsBlockTimestamp(address indexed strategy, uint256 argsTimestamp, uint256 blockTimestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchProvidedTimestampExceedsBlockTimestamp(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "ProvidedTimestampExceedsBlockTimestamp", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "ProvidedTimestampExceedsBlockTimestamp", log); err != nil {
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

// ParseProvidedTimestampExceedsBlockTimestamp is a log parse operation binding the contract event 0x11ce21eb8049b15d3cb258f2a3e207e24b6ca2141010b9c063228faa8628b9b5.
//
// Solidity: event ProvidedTimestampExceedsBlockTimestamp(address indexed strategy, uint256 argsTimestamp, uint256 blockTimestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseProvidedTimestampExceedsBlockTimestamp(log types.Log) (*UnsafeSuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp, error) {
	event := new(UnsafeSuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "ProvidedTimestampExceedsBlockTimestamp", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorSecondaryManagerAddedIterator is returned from FilterSecondaryManagerAdded and is used to iterate over the raw logs and unpacked data for SecondaryManagerAdded events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorSecondaryManagerAddedIterator struct {
	Event *UnsafeSuperVaultAggregatorSecondaryManagerAdded // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorSecondaryManagerAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorSecondaryManagerAdded)
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
		it.Event = new(UnsafeSuperVaultAggregatorSecondaryManagerAdded)
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
func (it *UnsafeSuperVaultAggregatorSecondaryManagerAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorSecondaryManagerAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorSecondaryManagerAdded represents a SecondaryManagerAdded event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorSecondaryManagerAdded struct {
	Strategy common.Address
	Manager  common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterSecondaryManagerAdded is a free log retrieval operation binding the contract event 0xb62a858ba4f3ba693ebca539c91a5c78f4514d4c1ea35b9d336ce5ce8f071f76.
//
// Solidity: event SecondaryManagerAdded(address indexed strategy, address indexed manager)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterSecondaryManagerAdded(opts *bind.FilterOpts, strategy []common.Address, manager []common.Address) (*UnsafeSuperVaultAggregatorSecondaryManagerAddedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "SecondaryManagerAdded", strategyRule, managerRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorSecondaryManagerAddedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "SecondaryManagerAdded", logs: logs, sub: sub}, nil
}

// WatchSecondaryManagerAdded is a free log subscription operation binding the contract event 0xb62a858ba4f3ba693ebca539c91a5c78f4514d4c1ea35b9d336ce5ce8f071f76.
//
// Solidity: event SecondaryManagerAdded(address indexed strategy, address indexed manager)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchSecondaryManagerAdded(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorSecondaryManagerAdded, strategy []common.Address, manager []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "SecondaryManagerAdded", strategyRule, managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorSecondaryManagerAdded)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "SecondaryManagerAdded", log); err != nil {
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

// ParseSecondaryManagerAdded is a log parse operation binding the contract event 0xb62a858ba4f3ba693ebca539c91a5c78f4514d4c1ea35b9d336ce5ce8f071f76.
//
// Solidity: event SecondaryManagerAdded(address indexed strategy, address indexed manager)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseSecondaryManagerAdded(log types.Log) (*UnsafeSuperVaultAggregatorSecondaryManagerAdded, error) {
	event := new(UnsafeSuperVaultAggregatorSecondaryManagerAdded)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "SecondaryManagerAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorSecondaryManagerRemovedIterator is returned from FilterSecondaryManagerRemoved and is used to iterate over the raw logs and unpacked data for SecondaryManagerRemoved events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorSecondaryManagerRemovedIterator struct {
	Event *UnsafeSuperVaultAggregatorSecondaryManagerRemoved // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorSecondaryManagerRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorSecondaryManagerRemoved)
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
		it.Event = new(UnsafeSuperVaultAggregatorSecondaryManagerRemoved)
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
func (it *UnsafeSuperVaultAggregatorSecondaryManagerRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorSecondaryManagerRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorSecondaryManagerRemoved represents a SecondaryManagerRemoved event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorSecondaryManagerRemoved struct {
	Strategy common.Address
	Manager  common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterSecondaryManagerRemoved is a free log retrieval operation binding the contract event 0x466dd5513a82de99caf12b8d5176cd2174dec8013f9c3ec7be7254e54b2c417c.
//
// Solidity: event SecondaryManagerRemoved(address indexed strategy, address indexed manager)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterSecondaryManagerRemoved(opts *bind.FilterOpts, strategy []common.Address, manager []common.Address) (*UnsafeSuperVaultAggregatorSecondaryManagerRemovedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "SecondaryManagerRemoved", strategyRule, managerRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorSecondaryManagerRemovedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "SecondaryManagerRemoved", logs: logs, sub: sub}, nil
}

// WatchSecondaryManagerRemoved is a free log subscription operation binding the contract event 0x466dd5513a82de99caf12b8d5176cd2174dec8013f9c3ec7be7254e54b2c417c.
//
// Solidity: event SecondaryManagerRemoved(address indexed strategy, address indexed manager)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchSecondaryManagerRemoved(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorSecondaryManagerRemoved, strategy []common.Address, manager []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "SecondaryManagerRemoved", strategyRule, managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorSecondaryManagerRemoved)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "SecondaryManagerRemoved", log); err != nil {
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

// ParseSecondaryManagerRemoved is a log parse operation binding the contract event 0x466dd5513a82de99caf12b8d5176cd2174dec8013f9c3ec7be7254e54b2c417c.
//
// Solidity: event SecondaryManagerRemoved(address indexed strategy, address indexed manager)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseSecondaryManagerRemoved(log types.Log) (*UnsafeSuperVaultAggregatorSecondaryManagerRemoved, error) {
	event := new(UnsafeSuperVaultAggregatorSecondaryManagerRemoved)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "SecondaryManagerRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorStaleSignatureAfterUnpauseIterator is returned from FilterStaleSignatureAfterUnpause and is used to iterate over the raw logs and unpacked data for StaleSignatureAfterUnpause events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStaleSignatureAfterUnpauseIterator struct {
	Event *UnsafeSuperVaultAggregatorStaleSignatureAfterUnpause // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorStaleSignatureAfterUnpauseIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorStaleSignatureAfterUnpause)
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
		it.Event = new(UnsafeSuperVaultAggregatorStaleSignatureAfterUnpause)
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
func (it *UnsafeSuperVaultAggregatorStaleSignatureAfterUnpauseIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorStaleSignatureAfterUnpauseIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorStaleSignatureAfterUnpause represents a StaleSignatureAfterUnpause event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStaleSignatureAfterUnpause struct {
	Strategy             common.Address
	SignatureTimestamp   *big.Int
	LastUnpauseTimestamp *big.Int
	Raw                  types.Log // Blockchain specific contextual infos
}

// FilterStaleSignatureAfterUnpause is a free log retrieval operation binding the contract event 0x253dc90db1f408af7684ca176fd3b27f8e0d92b39817e87c63a8d2cd312d8bce.
//
// Solidity: event StaleSignatureAfterUnpause(address indexed strategy, uint256 signatureTimestamp, uint256 lastUnpauseTimestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterStaleSignatureAfterUnpause(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorStaleSignatureAfterUnpauseIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "StaleSignatureAfterUnpause", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorStaleSignatureAfterUnpauseIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "StaleSignatureAfterUnpause", logs: logs, sub: sub}, nil
}

// WatchStaleSignatureAfterUnpause is a free log subscription operation binding the contract event 0x253dc90db1f408af7684ca176fd3b27f8e0d92b39817e87c63a8d2cd312d8bce.
//
// Solidity: event StaleSignatureAfterUnpause(address indexed strategy, uint256 signatureTimestamp, uint256 lastUnpauseTimestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchStaleSignatureAfterUnpause(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorStaleSignatureAfterUnpause, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "StaleSignatureAfterUnpause", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorStaleSignatureAfterUnpause)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StaleSignatureAfterUnpause", log); err != nil {
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

// ParseStaleSignatureAfterUnpause is a log parse operation binding the contract event 0x253dc90db1f408af7684ca176fd3b27f8e0d92b39817e87c63a8d2cd312d8bce.
//
// Solidity: event StaleSignatureAfterUnpause(address indexed strategy, uint256 signatureTimestamp, uint256 lastUnpauseTimestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseStaleSignatureAfterUnpause(log types.Log) (*UnsafeSuperVaultAggregatorStaleSignatureAfterUnpause, error) {
	event := new(UnsafeSuperVaultAggregatorStaleSignatureAfterUnpause)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StaleSignatureAfterUnpause", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorStaleUpdateIterator is returned from FilterStaleUpdate and is used to iterate over the raw logs and unpacked data for StaleUpdate events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStaleUpdateIterator struct {
	Event *UnsafeSuperVaultAggregatorStaleUpdate // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorStaleUpdateIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorStaleUpdate)
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
		it.Event = new(UnsafeSuperVaultAggregatorStaleUpdate)
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
func (it *UnsafeSuperVaultAggregatorStaleUpdateIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorStaleUpdateIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorStaleUpdate represents a StaleUpdate event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStaleUpdate struct {
	Strategy        common.Address
	UpdateAuthority common.Address
	Timestamp       *big.Int
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterStaleUpdate is a free log retrieval operation binding the contract event 0x5413368ef0fd371d352762fd42f794381bdd66d2b2c3860549bc61f12f6ab2ba.
//
// Solidity: event StaleUpdate(address indexed strategy, address indexed updateAuthority, uint256 timestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterStaleUpdate(opts *bind.FilterOpts, strategy []common.Address, updateAuthority []common.Address) (*UnsafeSuperVaultAggregatorStaleUpdateIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var updateAuthorityRule []interface{}
	for _, updateAuthorityItem := range updateAuthority {
		updateAuthorityRule = append(updateAuthorityRule, updateAuthorityItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "StaleUpdate", strategyRule, updateAuthorityRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorStaleUpdateIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "StaleUpdate", logs: logs, sub: sub}, nil
}

// WatchStaleUpdate is a free log subscription operation binding the contract event 0x5413368ef0fd371d352762fd42f794381bdd66d2b2c3860549bc61f12f6ab2ba.
//
// Solidity: event StaleUpdate(address indexed strategy, address indexed updateAuthority, uint256 timestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchStaleUpdate(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorStaleUpdate, strategy []common.Address, updateAuthority []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var updateAuthorityRule []interface{}
	for _, updateAuthorityItem := range updateAuthority {
		updateAuthorityRule = append(updateAuthorityRule, updateAuthorityItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "StaleUpdate", strategyRule, updateAuthorityRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorStaleUpdate)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StaleUpdate", log); err != nil {
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

// ParseStaleUpdate is a log parse operation binding the contract event 0x5413368ef0fd371d352762fd42f794381bdd66d2b2c3860549bc61f12f6ab2ba.
//
// Solidity: event StaleUpdate(address indexed strategy, address indexed updateAuthority, uint256 timestamp)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseStaleUpdate(log types.Log) (*UnsafeSuperVaultAggregatorStaleUpdate, error) {
	event := new(UnsafeSuperVaultAggregatorStaleUpdate)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StaleUpdate", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorStrategyCheckFailedIterator is returned from FilterStrategyCheckFailed and is used to iterate over the raw logs and unpacked data for StrategyCheckFailed events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStrategyCheckFailedIterator struct {
	Event *UnsafeSuperVaultAggregatorStrategyCheckFailed // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorStrategyCheckFailedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorStrategyCheckFailed)
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
		it.Event = new(UnsafeSuperVaultAggregatorStrategyCheckFailed)
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
func (it *UnsafeSuperVaultAggregatorStrategyCheckFailedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorStrategyCheckFailedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorStrategyCheckFailed represents a StrategyCheckFailed event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStrategyCheckFailed struct {
	Strategy common.Address
	Reason   string
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyCheckFailed is a free log retrieval operation binding the contract event 0xe364669b114d8ecba48ed1742526a04c78dd506cd3af6beb910f6622a928cbdb.
//
// Solidity: event StrategyCheckFailed(address indexed strategy, string reason)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterStrategyCheckFailed(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorStrategyCheckFailedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "StrategyCheckFailed", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorStrategyCheckFailedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "StrategyCheckFailed", logs: logs, sub: sub}, nil
}

// WatchStrategyCheckFailed is a free log subscription operation binding the contract event 0xe364669b114d8ecba48ed1742526a04c78dd506cd3af6beb910f6622a928cbdb.
//
// Solidity: event StrategyCheckFailed(address indexed strategy, string reason)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchStrategyCheckFailed(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorStrategyCheckFailed, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "StrategyCheckFailed", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorStrategyCheckFailed)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StrategyCheckFailed", log); err != nil {
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

// ParseStrategyCheckFailed is a log parse operation binding the contract event 0xe364669b114d8ecba48ed1742526a04c78dd506cd3af6beb910f6622a928cbdb.
//
// Solidity: event StrategyCheckFailed(address indexed strategy, string reason)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseStrategyCheckFailed(log types.Log) (*UnsafeSuperVaultAggregatorStrategyCheckFailed, error) {
	event := new(UnsafeSuperVaultAggregatorStrategyCheckFailed)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StrategyCheckFailed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorStrategyHooksRootUpdateProposedIterator is returned from FilterStrategyHooksRootUpdateProposed and is used to iterate over the raw logs and unpacked data for StrategyHooksRootUpdateProposed events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStrategyHooksRootUpdateProposedIterator struct {
	Event *UnsafeSuperVaultAggregatorStrategyHooksRootUpdateProposed // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorStrategyHooksRootUpdateProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorStrategyHooksRootUpdateProposed)
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
		it.Event = new(UnsafeSuperVaultAggregatorStrategyHooksRootUpdateProposed)
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
func (it *UnsafeSuperVaultAggregatorStrategyHooksRootUpdateProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorStrategyHooksRootUpdateProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorStrategyHooksRootUpdateProposed represents a StrategyHooksRootUpdateProposed event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStrategyHooksRootUpdateProposed struct {
	Strategy      common.Address
	Proposer      common.Address
	Root          [32]byte
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterStrategyHooksRootUpdateProposed is a free log retrieval operation binding the contract event 0x3c67f914ba911b08519fae976b442675afa7d36b96bab1276ca2ab142c1b1714.
//
// Solidity: event StrategyHooksRootUpdateProposed(address indexed strategy, address indexed proposer, bytes32 root, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterStrategyHooksRootUpdateProposed(opts *bind.FilterOpts, strategy []common.Address, proposer []common.Address) (*UnsafeSuperVaultAggregatorStrategyHooksRootUpdateProposedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var proposerRule []interface{}
	for _, proposerItem := range proposer {
		proposerRule = append(proposerRule, proposerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "StrategyHooksRootUpdateProposed", strategyRule, proposerRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorStrategyHooksRootUpdateProposedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "StrategyHooksRootUpdateProposed", logs: logs, sub: sub}, nil
}

// WatchStrategyHooksRootUpdateProposed is a free log subscription operation binding the contract event 0x3c67f914ba911b08519fae976b442675afa7d36b96bab1276ca2ab142c1b1714.
//
// Solidity: event StrategyHooksRootUpdateProposed(address indexed strategy, address indexed proposer, bytes32 root, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchStrategyHooksRootUpdateProposed(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorStrategyHooksRootUpdateProposed, strategy []common.Address, proposer []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var proposerRule []interface{}
	for _, proposerItem := range proposer {
		proposerRule = append(proposerRule, proposerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "StrategyHooksRootUpdateProposed", strategyRule, proposerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorStrategyHooksRootUpdateProposed)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootUpdateProposed", log); err != nil {
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

// ParseStrategyHooksRootUpdateProposed is a log parse operation binding the contract event 0x3c67f914ba911b08519fae976b442675afa7d36b96bab1276ca2ab142c1b1714.
//
// Solidity: event StrategyHooksRootUpdateProposed(address indexed strategy, address indexed proposer, bytes32 root, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseStrategyHooksRootUpdateProposed(log types.Log) (*UnsafeSuperVaultAggregatorStrategyHooksRootUpdateProposed, error) {
	event := new(UnsafeSuperVaultAggregatorStrategyHooksRootUpdateProposed)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootUpdateProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorStrategyHooksRootUpdatedIterator is returned from FilterStrategyHooksRootUpdated and is used to iterate over the raw logs and unpacked data for StrategyHooksRootUpdated events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStrategyHooksRootUpdatedIterator struct {
	Event *UnsafeSuperVaultAggregatorStrategyHooksRootUpdated // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorStrategyHooksRootUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorStrategyHooksRootUpdated)
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
		it.Event = new(UnsafeSuperVaultAggregatorStrategyHooksRootUpdated)
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
func (it *UnsafeSuperVaultAggregatorStrategyHooksRootUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorStrategyHooksRootUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorStrategyHooksRootUpdated represents a StrategyHooksRootUpdated event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStrategyHooksRootUpdated struct {
	Strategy common.Address
	OldRoot  [32]byte
	NewRoot  [32]byte
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyHooksRootUpdated is a free log retrieval operation binding the contract event 0x50db1dc8f2cc634e637edbe632acec34656994c29a699c817c89e8de694035f6.
//
// Solidity: event StrategyHooksRootUpdated(address indexed strategy, bytes32 oldRoot, bytes32 newRoot)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterStrategyHooksRootUpdated(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorStrategyHooksRootUpdatedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "StrategyHooksRootUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorStrategyHooksRootUpdatedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "StrategyHooksRootUpdated", logs: logs, sub: sub}, nil
}

// WatchStrategyHooksRootUpdated is a free log subscription operation binding the contract event 0x50db1dc8f2cc634e637edbe632acec34656994c29a699c817c89e8de694035f6.
//
// Solidity: event StrategyHooksRootUpdated(address indexed strategy, bytes32 oldRoot, bytes32 newRoot)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchStrategyHooksRootUpdated(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorStrategyHooksRootUpdated, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "StrategyHooksRootUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorStrategyHooksRootUpdated)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootUpdated", log); err != nil {
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

// ParseStrategyHooksRootUpdated is a log parse operation binding the contract event 0x50db1dc8f2cc634e637edbe632acec34656994c29a699c817c89e8de694035f6.
//
// Solidity: event StrategyHooksRootUpdated(address indexed strategy, bytes32 oldRoot, bytes32 newRoot)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseStrategyHooksRootUpdated(log types.Log) (*UnsafeSuperVaultAggregatorStrategyHooksRootUpdated, error) {
	event := new(UnsafeSuperVaultAggregatorStrategyHooksRootUpdated)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator is returned from FilterStrategyHooksRootVetoStatusChanged and is used to iterate over the raw logs and unpacked data for StrategyHooksRootVetoStatusChanged events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator struct {
	Event *UnsafeSuperVaultAggregatorStrategyHooksRootVetoStatusChanged // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorStrategyHooksRootVetoStatusChanged)
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
		it.Event = new(UnsafeSuperVaultAggregatorStrategyHooksRootVetoStatusChanged)
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
func (it *UnsafeSuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorStrategyHooksRootVetoStatusChanged represents a StrategyHooksRootVetoStatusChanged event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStrategyHooksRootVetoStatusChanged struct {
	Strategy common.Address
	Vetoed   bool
	Root     [32]byte
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyHooksRootVetoStatusChanged is a free log retrieval operation binding the contract event 0x927440ad59e90a7b01af1effd4191955ea9e6ef812fc415e7f8e71eadbc5bc35.
//
// Solidity: event StrategyHooksRootVetoStatusChanged(address indexed strategy, bool vetoed, bytes32 indexed root)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterStrategyHooksRootVetoStatusChanged(opts *bind.FilterOpts, strategy []common.Address, root [][32]byte) (*UnsafeSuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "StrategyHooksRootVetoStatusChanged", strategyRule, rootRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "StrategyHooksRootVetoStatusChanged", logs: logs, sub: sub}, nil
}

// WatchStrategyHooksRootVetoStatusChanged is a free log subscription operation binding the contract event 0x927440ad59e90a7b01af1effd4191955ea9e6ef812fc415e7f8e71eadbc5bc35.
//
// Solidity: event StrategyHooksRootVetoStatusChanged(address indexed strategy, bool vetoed, bytes32 indexed root)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchStrategyHooksRootVetoStatusChanged(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorStrategyHooksRootVetoStatusChanged, strategy []common.Address, root [][32]byte) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "StrategyHooksRootVetoStatusChanged", strategyRule, rootRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorStrategyHooksRootVetoStatusChanged)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootVetoStatusChanged", log); err != nil {
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

// ParseStrategyHooksRootVetoStatusChanged is a log parse operation binding the contract event 0x927440ad59e90a7b01af1effd4191955ea9e6ef812fc415e7f8e71eadbc5bc35.
//
// Solidity: event StrategyHooksRootVetoStatusChanged(address indexed strategy, bool vetoed, bytes32 indexed root)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseStrategyHooksRootVetoStatusChanged(log types.Log) (*UnsafeSuperVaultAggregatorStrategyHooksRootVetoStatusChanged, error) {
	event := new(UnsafeSuperVaultAggregatorStrategyHooksRootVetoStatusChanged)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootVetoStatusChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorStrategyPPSStaleIterator is returned from FilterStrategyPPSStale and is used to iterate over the raw logs and unpacked data for StrategyPPSStale events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStrategyPPSStaleIterator struct {
	Event *UnsafeSuperVaultAggregatorStrategyPPSStale // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorStrategyPPSStaleIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorStrategyPPSStale)
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
		it.Event = new(UnsafeSuperVaultAggregatorStrategyPPSStale)
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
func (it *UnsafeSuperVaultAggregatorStrategyPPSStaleIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorStrategyPPSStaleIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorStrategyPPSStale represents a StrategyPPSStale event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStrategyPPSStale struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyPPSStale is a free log retrieval operation binding the contract event 0x80796c8d1dc90790262881896e3680e577f032ca370f16b8dccd1cd4cef254f1.
//
// Solidity: event StrategyPPSStale(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterStrategyPPSStale(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorStrategyPPSStaleIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "StrategyPPSStale", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorStrategyPPSStaleIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "StrategyPPSStale", logs: logs, sub: sub}, nil
}

// WatchStrategyPPSStale is a free log subscription operation binding the contract event 0x80796c8d1dc90790262881896e3680e577f032ca370f16b8dccd1cd4cef254f1.
//
// Solidity: event StrategyPPSStale(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchStrategyPPSStale(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorStrategyPPSStale, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "StrategyPPSStale", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorStrategyPPSStale)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StrategyPPSStale", log); err != nil {
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

// ParseStrategyPPSStale is a log parse operation binding the contract event 0x80796c8d1dc90790262881896e3680e577f032ca370f16b8dccd1cd4cef254f1.
//
// Solidity: event StrategyPPSStale(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseStrategyPPSStale(log types.Log) (*UnsafeSuperVaultAggregatorStrategyPPSStale, error) {
	event := new(UnsafeSuperVaultAggregatorStrategyPPSStale)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StrategyPPSStale", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorStrategyPPSStaleResetIterator is returned from FilterStrategyPPSStaleReset and is used to iterate over the raw logs and unpacked data for StrategyPPSStaleReset events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStrategyPPSStaleResetIterator struct {
	Event *UnsafeSuperVaultAggregatorStrategyPPSStaleReset // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorStrategyPPSStaleResetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorStrategyPPSStaleReset)
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
		it.Event = new(UnsafeSuperVaultAggregatorStrategyPPSStaleReset)
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
func (it *UnsafeSuperVaultAggregatorStrategyPPSStaleResetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorStrategyPPSStaleResetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorStrategyPPSStaleReset represents a StrategyPPSStaleReset event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStrategyPPSStaleReset struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyPPSStaleReset is a free log retrieval operation binding the contract event 0x87afbf71df10b23be48535f5f7689b97e949bf5b76a67c76e79fd0f10db005d8.
//
// Solidity: event StrategyPPSStaleReset(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterStrategyPPSStaleReset(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorStrategyPPSStaleResetIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "StrategyPPSStaleReset", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorStrategyPPSStaleResetIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "StrategyPPSStaleReset", logs: logs, sub: sub}, nil
}

// WatchStrategyPPSStaleReset is a free log subscription operation binding the contract event 0x87afbf71df10b23be48535f5f7689b97e949bf5b76a67c76e79fd0f10db005d8.
//
// Solidity: event StrategyPPSStaleReset(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchStrategyPPSStaleReset(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorStrategyPPSStaleReset, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "StrategyPPSStaleReset", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorStrategyPPSStaleReset)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StrategyPPSStaleReset", log); err != nil {
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

// ParseStrategyPPSStaleReset is a log parse operation binding the contract event 0x87afbf71df10b23be48535f5f7689b97e949bf5b76a67c76e79fd0f10db005d8.
//
// Solidity: event StrategyPPSStaleReset(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseStrategyPPSStaleReset(log types.Log) (*UnsafeSuperVaultAggregatorStrategyPPSStaleReset, error) {
	event := new(UnsafeSuperVaultAggregatorStrategyPPSStaleReset)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StrategyPPSStaleReset", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorStrategyPausedIterator is returned from FilterStrategyPaused and is used to iterate over the raw logs and unpacked data for StrategyPaused events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStrategyPausedIterator struct {
	Event *UnsafeSuperVaultAggregatorStrategyPaused // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorStrategyPausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorStrategyPaused)
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
		it.Event = new(UnsafeSuperVaultAggregatorStrategyPaused)
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
func (it *UnsafeSuperVaultAggregatorStrategyPausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorStrategyPausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorStrategyPaused represents a StrategyPaused event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStrategyPaused struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyPaused is a free log retrieval operation binding the contract event 0xc2897a3765ea6cd9ed9ce463d3bc9c9cf968f21f8664b62684e1254d3b0f9ee5.
//
// Solidity: event StrategyPaused(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterStrategyPaused(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorStrategyPausedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "StrategyPaused", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorStrategyPausedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "StrategyPaused", logs: logs, sub: sub}, nil
}

// WatchStrategyPaused is a free log subscription operation binding the contract event 0xc2897a3765ea6cd9ed9ce463d3bc9c9cf968f21f8664b62684e1254d3b0f9ee5.
//
// Solidity: event StrategyPaused(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchStrategyPaused(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorStrategyPaused, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "StrategyPaused", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorStrategyPaused)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StrategyPaused", log); err != nil {
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

// ParseStrategyPaused is a log parse operation binding the contract event 0xc2897a3765ea6cd9ed9ce463d3bc9c9cf968f21f8664b62684e1254d3b0f9ee5.
//
// Solidity: event StrategyPaused(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseStrategyPaused(log types.Log) (*UnsafeSuperVaultAggregatorStrategyPaused, error) {
	event := new(UnsafeSuperVaultAggregatorStrategyPaused)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StrategyPaused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorStrategyUnpausedIterator is returned from FilterStrategyUnpaused and is used to iterate over the raw logs and unpacked data for StrategyUnpaused events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStrategyUnpausedIterator struct {
	Event *UnsafeSuperVaultAggregatorStrategyUnpaused // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorStrategyUnpausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorStrategyUnpaused)
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
		it.Event = new(UnsafeSuperVaultAggregatorStrategyUnpaused)
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
func (it *UnsafeSuperVaultAggregatorStrategyUnpausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorStrategyUnpausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorStrategyUnpaused represents a StrategyUnpaused event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorStrategyUnpaused struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyUnpaused is a free log retrieval operation binding the contract event 0x9de75c520457842eb5fe159114348bf5358100a1acaf1bcb5052f64f347503df.
//
// Solidity: event StrategyUnpaused(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterStrategyUnpaused(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorStrategyUnpausedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "StrategyUnpaused", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorStrategyUnpausedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "StrategyUnpaused", logs: logs, sub: sub}, nil
}

// WatchStrategyUnpaused is a free log subscription operation binding the contract event 0x9de75c520457842eb5fe159114348bf5358100a1acaf1bcb5052f64f347503df.
//
// Solidity: event StrategyUnpaused(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchStrategyUnpaused(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorStrategyUnpaused, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "StrategyUnpaused", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorStrategyUnpaused)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StrategyUnpaused", log); err != nil {
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

// ParseStrategyUnpaused is a log parse operation binding the contract event 0x9de75c520457842eb5fe159114348bf5358100a1acaf1bcb5052f64f347503df.
//
// Solidity: event StrategyUnpaused(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseStrategyUnpaused(log types.Log) (*UnsafeSuperVaultAggregatorStrategyUnpaused, error) {
	event := new(UnsafeSuperVaultAggregatorStrategyUnpaused)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "StrategyUnpaused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorTimestampNotMonotonicIterator is returned from FilterTimestampNotMonotonic and is used to iterate over the raw logs and unpacked data for TimestampNotMonotonic events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorTimestampNotMonotonicIterator struct {
	Event *UnsafeSuperVaultAggregatorTimestampNotMonotonic // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorTimestampNotMonotonicIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorTimestampNotMonotonic)
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
		it.Event = new(UnsafeSuperVaultAggregatorTimestampNotMonotonic)
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
func (it *UnsafeSuperVaultAggregatorTimestampNotMonotonicIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorTimestampNotMonotonicIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorTimestampNotMonotonic represents a TimestampNotMonotonic event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorTimestampNotMonotonic struct {
	Raw types.Log // Blockchain specific contextual infos
}

// FilterTimestampNotMonotonic is a free log retrieval operation binding the contract event 0x2e78c6ab27a29f5c1471d797dd0809527031b55c91aa70143ffa36ceecfab75f.
//
// Solidity: event TimestampNotMonotonic()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterTimestampNotMonotonic(opts *bind.FilterOpts) (*UnsafeSuperVaultAggregatorTimestampNotMonotonicIterator, error) {

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "TimestampNotMonotonic")
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorTimestampNotMonotonicIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "TimestampNotMonotonic", logs: logs, sub: sub}, nil
}

// WatchTimestampNotMonotonic is a free log subscription operation binding the contract event 0x2e78c6ab27a29f5c1471d797dd0809527031b55c91aa70143ffa36ceecfab75f.
//
// Solidity: event TimestampNotMonotonic()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchTimestampNotMonotonic(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorTimestampNotMonotonic) (event.Subscription, error) {

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "TimestampNotMonotonic")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorTimestampNotMonotonic)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "TimestampNotMonotonic", log); err != nil {
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

// ParseTimestampNotMonotonic is a log parse operation binding the contract event 0x2e78c6ab27a29f5c1471d797dd0809527031b55c91aa70143ffa36ceecfab75f.
//
// Solidity: event TimestampNotMonotonic()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseTimestampNotMonotonic(log types.Log) (*UnsafeSuperVaultAggregatorTimestampNotMonotonic, error) {
	event := new(UnsafeSuperVaultAggregatorTimestampNotMonotonic)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "TimestampNotMonotonic", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorUnknownStrategyIterator is returned from FilterUnknownStrategy and is used to iterate over the raw logs and unpacked data for UnknownStrategy events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorUnknownStrategyIterator struct {
	Event *UnsafeSuperVaultAggregatorUnknownStrategy // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorUnknownStrategyIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorUnknownStrategy)
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
		it.Event = new(UnsafeSuperVaultAggregatorUnknownStrategy)
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
func (it *UnsafeSuperVaultAggregatorUnknownStrategyIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorUnknownStrategyIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorUnknownStrategy represents a UnknownStrategy event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorUnknownStrategy struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterUnknownStrategy is a free log retrieval operation binding the contract event 0xde5abf6fb8e50b9c44ca7d6b0b47660db6158640044348124a98dbb8c94d6524.
//
// Solidity: event UnknownStrategy(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterUnknownStrategy(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorUnknownStrategyIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "UnknownStrategy", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorUnknownStrategyIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "UnknownStrategy", logs: logs, sub: sub}, nil
}

// WatchUnknownStrategy is a free log subscription operation binding the contract event 0xde5abf6fb8e50b9c44ca7d6b0b47660db6158640044348124a98dbb8c94d6524.
//
// Solidity: event UnknownStrategy(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchUnknownStrategy(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorUnknownStrategy, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "UnknownStrategy", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorUnknownStrategy)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "UnknownStrategy", log); err != nil {
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

// ParseUnknownStrategy is a log parse operation binding the contract event 0xde5abf6fb8e50b9c44ca7d6b0b47660db6158640044348124a98dbb8c94d6524.
//
// Solidity: event UnknownStrategy(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseUnknownStrategy(log types.Log) (*UnsafeSuperVaultAggregatorUnknownStrategy, error) {
	event := new(UnsafeSuperVaultAggregatorUnknownStrategy)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "UnknownStrategy", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorUpdateTooFrequentIterator is returned from FilterUpdateTooFrequent and is used to iterate over the raw logs and unpacked data for UpdateTooFrequent events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorUpdateTooFrequentIterator struct {
	Event *UnsafeSuperVaultAggregatorUpdateTooFrequent // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorUpdateTooFrequentIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorUpdateTooFrequent)
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
		it.Event = new(UnsafeSuperVaultAggregatorUpdateTooFrequent)
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
func (it *UnsafeSuperVaultAggregatorUpdateTooFrequentIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorUpdateTooFrequentIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorUpdateTooFrequent represents a UpdateTooFrequent event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorUpdateTooFrequent struct {
	Raw types.Log // Blockchain specific contextual infos
}

// FilterUpdateTooFrequent is a free log retrieval operation binding the contract event 0x53f7a6ee85aab0f20869755601a6424676aa3807e9ef249627fa11a39e9a0e0c.
//
// Solidity: event UpdateTooFrequent()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterUpdateTooFrequent(opts *bind.FilterOpts) (*UnsafeSuperVaultAggregatorUpdateTooFrequentIterator, error) {

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "UpdateTooFrequent")
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorUpdateTooFrequentIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "UpdateTooFrequent", logs: logs, sub: sub}, nil
}

// WatchUpdateTooFrequent is a free log subscription operation binding the contract event 0x53f7a6ee85aab0f20869755601a6424676aa3807e9ef249627fa11a39e9a0e0c.
//
// Solidity: event UpdateTooFrequent()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchUpdateTooFrequent(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorUpdateTooFrequent) (event.Subscription, error) {

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "UpdateTooFrequent")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorUpdateTooFrequent)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "UpdateTooFrequent", log); err != nil {
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

// ParseUpdateTooFrequent is a log parse operation binding the contract event 0x53f7a6ee85aab0f20869755601a6424676aa3807e9ef249627fa11a39e9a0e0c.
//
// Solidity: event UpdateTooFrequent()
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseUpdateTooFrequent(log types.Log) (*UnsafeSuperVaultAggregatorUpdateTooFrequent, error) {
	event := new(UnsafeSuperVaultAggregatorUpdateTooFrequent)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "UpdateTooFrequent", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorUpkeepClaimedIterator is returned from FilterUpkeepClaimed and is used to iterate over the raw logs and unpacked data for UpkeepClaimed events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorUpkeepClaimedIterator struct {
	Event *UnsafeSuperVaultAggregatorUpkeepClaimed // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorUpkeepClaimedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorUpkeepClaimed)
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
		it.Event = new(UnsafeSuperVaultAggregatorUpkeepClaimed)
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
func (it *UnsafeSuperVaultAggregatorUpkeepClaimedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorUpkeepClaimedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorUpkeepClaimed represents a UpkeepClaimed event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorUpkeepClaimed struct {
	SuperBank common.Address
	Amount    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterUpkeepClaimed is a free log retrieval operation binding the contract event 0x43214536812d90daa91186dfb744049f5e3c6f3379765892f0f41b204a87e0ee.
//
// Solidity: event UpkeepClaimed(address indexed superBank, uint256 amount)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterUpkeepClaimed(opts *bind.FilterOpts, superBank []common.Address) (*UnsafeSuperVaultAggregatorUpkeepClaimedIterator, error) {

	var superBankRule []interface{}
	for _, superBankItem := range superBank {
		superBankRule = append(superBankRule, superBankItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "UpkeepClaimed", superBankRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorUpkeepClaimedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "UpkeepClaimed", logs: logs, sub: sub}, nil
}

// WatchUpkeepClaimed is a free log subscription operation binding the contract event 0x43214536812d90daa91186dfb744049f5e3c6f3379765892f0f41b204a87e0ee.
//
// Solidity: event UpkeepClaimed(address indexed superBank, uint256 amount)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchUpkeepClaimed(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorUpkeepClaimed, superBank []common.Address) (event.Subscription, error) {

	var superBankRule []interface{}
	for _, superBankItem := range superBank {
		superBankRule = append(superBankRule, superBankItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "UpkeepClaimed", superBankRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorUpkeepClaimed)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "UpkeepClaimed", log); err != nil {
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

// ParseUpkeepClaimed is a log parse operation binding the contract event 0x43214536812d90daa91186dfb744049f5e3c6f3379765892f0f41b204a87e0ee.
//
// Solidity: event UpkeepClaimed(address indexed superBank, uint256 amount)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseUpkeepClaimed(log types.Log) (*UnsafeSuperVaultAggregatorUpkeepClaimed, error) {
	event := new(UnsafeSuperVaultAggregatorUpkeepClaimed)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "UpkeepClaimed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorUpkeepDepositedIterator is returned from FilterUpkeepDeposited and is used to iterate over the raw logs and unpacked data for UpkeepDeposited events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorUpkeepDepositedIterator struct {
	Event *UnsafeSuperVaultAggregatorUpkeepDeposited // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorUpkeepDepositedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorUpkeepDeposited)
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
		it.Event = new(UnsafeSuperVaultAggregatorUpkeepDeposited)
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
func (it *UnsafeSuperVaultAggregatorUpkeepDepositedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorUpkeepDepositedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorUpkeepDeposited represents a UpkeepDeposited event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorUpkeepDeposited struct {
	Strategy  common.Address
	Depositor common.Address
	Amount    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterUpkeepDeposited is a free log retrieval operation binding the contract event 0x0af030417f3b88e41ea1b8c5905f05884e87e393e129c5e207896f8a0e29b15a.
//
// Solidity: event UpkeepDeposited(address indexed strategy, address indexed depositor, uint256 amount)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterUpkeepDeposited(opts *bind.FilterOpts, strategy []common.Address, depositor []common.Address) (*UnsafeSuperVaultAggregatorUpkeepDepositedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var depositorRule []interface{}
	for _, depositorItem := range depositor {
		depositorRule = append(depositorRule, depositorItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "UpkeepDeposited", strategyRule, depositorRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorUpkeepDepositedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "UpkeepDeposited", logs: logs, sub: sub}, nil
}

// WatchUpkeepDeposited is a free log subscription operation binding the contract event 0x0af030417f3b88e41ea1b8c5905f05884e87e393e129c5e207896f8a0e29b15a.
//
// Solidity: event UpkeepDeposited(address indexed strategy, address indexed depositor, uint256 amount)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchUpkeepDeposited(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorUpkeepDeposited, strategy []common.Address, depositor []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var depositorRule []interface{}
	for _, depositorItem := range depositor {
		depositorRule = append(depositorRule, depositorItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "UpkeepDeposited", strategyRule, depositorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorUpkeepDeposited)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "UpkeepDeposited", log); err != nil {
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

// ParseUpkeepDeposited is a log parse operation binding the contract event 0x0af030417f3b88e41ea1b8c5905f05884e87e393e129c5e207896f8a0e29b15a.
//
// Solidity: event UpkeepDeposited(address indexed strategy, address indexed depositor, uint256 amount)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseUpkeepDeposited(log types.Log) (*UnsafeSuperVaultAggregatorUpkeepDeposited, error) {
	event := new(UnsafeSuperVaultAggregatorUpkeepDeposited)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "UpkeepDeposited", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorUpkeepSpentIterator is returned from FilterUpkeepSpent and is used to iterate over the raw logs and unpacked data for UpkeepSpent events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorUpkeepSpentIterator struct {
	Event *UnsafeSuperVaultAggregatorUpkeepSpent // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorUpkeepSpentIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorUpkeepSpent)
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
		it.Event = new(UnsafeSuperVaultAggregatorUpkeepSpent)
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
func (it *UnsafeSuperVaultAggregatorUpkeepSpentIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorUpkeepSpentIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorUpkeepSpent represents a UpkeepSpent event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorUpkeepSpent struct {
	Strategy        common.Address
	Amount          *big.Int
	Balance         *big.Int
	ClaimableUpkeep *big.Int
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterUpkeepSpent is a free log retrieval operation binding the contract event 0x70485ec1c1ebd5a2176ff9969ef90917bbeca387cb89fee9a5fac5840d7253d9.
//
// Solidity: event UpkeepSpent(address indexed strategy, uint256 amount, uint256 balance, uint256 claimableUpkeep)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterUpkeepSpent(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorUpkeepSpentIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "UpkeepSpent", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorUpkeepSpentIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "UpkeepSpent", logs: logs, sub: sub}, nil
}

// WatchUpkeepSpent is a free log subscription operation binding the contract event 0x70485ec1c1ebd5a2176ff9969ef90917bbeca387cb89fee9a5fac5840d7253d9.
//
// Solidity: event UpkeepSpent(address indexed strategy, uint256 amount, uint256 balance, uint256 claimableUpkeep)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchUpkeepSpent(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorUpkeepSpent, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "UpkeepSpent", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorUpkeepSpent)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "UpkeepSpent", log); err != nil {
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

// ParseUpkeepSpent is a log parse operation binding the contract event 0x70485ec1c1ebd5a2176ff9969ef90917bbeca387cb89fee9a5fac5840d7253d9.
//
// Solidity: event UpkeepSpent(address indexed strategy, uint256 amount, uint256 balance, uint256 claimableUpkeep)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseUpkeepSpent(log types.Log) (*UnsafeSuperVaultAggregatorUpkeepSpent, error) {
	event := new(UnsafeSuperVaultAggregatorUpkeepSpent)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "UpkeepSpent", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorUpkeepWithdrawalCancelledIterator is returned from FilterUpkeepWithdrawalCancelled and is used to iterate over the raw logs and unpacked data for UpkeepWithdrawalCancelled events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorUpkeepWithdrawalCancelledIterator struct {
	Event *UnsafeSuperVaultAggregatorUpkeepWithdrawalCancelled // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorUpkeepWithdrawalCancelledIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorUpkeepWithdrawalCancelled)
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
		it.Event = new(UnsafeSuperVaultAggregatorUpkeepWithdrawalCancelled)
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
func (it *UnsafeSuperVaultAggregatorUpkeepWithdrawalCancelledIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorUpkeepWithdrawalCancelledIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorUpkeepWithdrawalCancelled represents a UpkeepWithdrawalCancelled event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorUpkeepWithdrawalCancelled struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterUpkeepWithdrawalCancelled is a free log retrieval operation binding the contract event 0x8076f2f1c856d087aea9a80a6ee119648f2b95063efe6acf798797367d37210c.
//
// Solidity: event UpkeepWithdrawalCancelled(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterUpkeepWithdrawalCancelled(opts *bind.FilterOpts, strategy []common.Address) (*UnsafeSuperVaultAggregatorUpkeepWithdrawalCancelledIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "UpkeepWithdrawalCancelled", strategyRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorUpkeepWithdrawalCancelledIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "UpkeepWithdrawalCancelled", logs: logs, sub: sub}, nil
}

// WatchUpkeepWithdrawalCancelled is a free log subscription operation binding the contract event 0x8076f2f1c856d087aea9a80a6ee119648f2b95063efe6acf798797367d37210c.
//
// Solidity: event UpkeepWithdrawalCancelled(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchUpkeepWithdrawalCancelled(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorUpkeepWithdrawalCancelled, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "UpkeepWithdrawalCancelled", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorUpkeepWithdrawalCancelled)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "UpkeepWithdrawalCancelled", log); err != nil {
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

// ParseUpkeepWithdrawalCancelled is a log parse operation binding the contract event 0x8076f2f1c856d087aea9a80a6ee119648f2b95063efe6acf798797367d37210c.
//
// Solidity: event UpkeepWithdrawalCancelled(address indexed strategy)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseUpkeepWithdrawalCancelled(log types.Log) (*UnsafeSuperVaultAggregatorUpkeepWithdrawalCancelled, error) {
	event := new(UnsafeSuperVaultAggregatorUpkeepWithdrawalCancelled)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "UpkeepWithdrawalCancelled", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorUpkeepWithdrawalProposedIterator is returned from FilterUpkeepWithdrawalProposed and is used to iterate over the raw logs and unpacked data for UpkeepWithdrawalProposed events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorUpkeepWithdrawalProposedIterator struct {
	Event *UnsafeSuperVaultAggregatorUpkeepWithdrawalProposed // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorUpkeepWithdrawalProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorUpkeepWithdrawalProposed)
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
		it.Event = new(UnsafeSuperVaultAggregatorUpkeepWithdrawalProposed)
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
func (it *UnsafeSuperVaultAggregatorUpkeepWithdrawalProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorUpkeepWithdrawalProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorUpkeepWithdrawalProposed represents a UpkeepWithdrawalProposed event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorUpkeepWithdrawalProposed struct {
	Strategy      common.Address
	MainManager   common.Address
	Amount        *big.Int
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterUpkeepWithdrawalProposed is a free log retrieval operation binding the contract event 0x9609899ca39d06bc75b43075ca3e965886967fd4cd3ec9d86aec014aaa5169db.
//
// Solidity: event UpkeepWithdrawalProposed(address indexed strategy, address indexed mainManager, uint256 amount, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterUpkeepWithdrawalProposed(opts *bind.FilterOpts, strategy []common.Address, mainManager []common.Address) (*UnsafeSuperVaultAggregatorUpkeepWithdrawalProposedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var mainManagerRule []interface{}
	for _, mainManagerItem := range mainManager {
		mainManagerRule = append(mainManagerRule, mainManagerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "UpkeepWithdrawalProposed", strategyRule, mainManagerRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorUpkeepWithdrawalProposedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "UpkeepWithdrawalProposed", logs: logs, sub: sub}, nil
}

// WatchUpkeepWithdrawalProposed is a free log subscription operation binding the contract event 0x9609899ca39d06bc75b43075ca3e965886967fd4cd3ec9d86aec014aaa5169db.
//
// Solidity: event UpkeepWithdrawalProposed(address indexed strategy, address indexed mainManager, uint256 amount, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchUpkeepWithdrawalProposed(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorUpkeepWithdrawalProposed, strategy []common.Address, mainManager []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var mainManagerRule []interface{}
	for _, mainManagerItem := range mainManager {
		mainManagerRule = append(mainManagerRule, mainManagerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "UpkeepWithdrawalProposed", strategyRule, mainManagerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorUpkeepWithdrawalProposed)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "UpkeepWithdrawalProposed", log); err != nil {
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

// ParseUpkeepWithdrawalProposed is a log parse operation binding the contract event 0x9609899ca39d06bc75b43075ca3e965886967fd4cd3ec9d86aec014aaa5169db.
//
// Solidity: event UpkeepWithdrawalProposed(address indexed strategy, address indexed mainManager, uint256 amount, uint256 effectiveTime)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseUpkeepWithdrawalProposed(log types.Log) (*UnsafeSuperVaultAggregatorUpkeepWithdrawalProposed, error) {
	event := new(UnsafeSuperVaultAggregatorUpkeepWithdrawalProposed)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "UpkeepWithdrawalProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorUpkeepWithdrawnIterator is returned from FilterUpkeepWithdrawn and is used to iterate over the raw logs and unpacked data for UpkeepWithdrawn events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorUpkeepWithdrawnIterator struct {
	Event *UnsafeSuperVaultAggregatorUpkeepWithdrawn // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorUpkeepWithdrawnIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorUpkeepWithdrawn)
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
		it.Event = new(UnsafeSuperVaultAggregatorUpkeepWithdrawn)
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
func (it *UnsafeSuperVaultAggregatorUpkeepWithdrawnIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorUpkeepWithdrawnIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorUpkeepWithdrawn represents a UpkeepWithdrawn event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorUpkeepWithdrawn struct {
	Strategy   common.Address
	Withdrawer common.Address
	Amount     *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterUpkeepWithdrawn is a free log retrieval operation binding the contract event 0x5e02dcaf3d3c04e0d6054134d489d13868467dbcff5930e7dd0d5cdd9ed59443.
//
// Solidity: event UpkeepWithdrawn(address indexed strategy, address indexed withdrawer, uint256 amount)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterUpkeepWithdrawn(opts *bind.FilterOpts, strategy []common.Address, withdrawer []common.Address) (*UnsafeSuperVaultAggregatorUpkeepWithdrawnIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var withdrawerRule []interface{}
	for _, withdrawerItem := range withdrawer {
		withdrawerRule = append(withdrawerRule, withdrawerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "UpkeepWithdrawn", strategyRule, withdrawerRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorUpkeepWithdrawnIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "UpkeepWithdrawn", logs: logs, sub: sub}, nil
}

// WatchUpkeepWithdrawn is a free log subscription operation binding the contract event 0x5e02dcaf3d3c04e0d6054134d489d13868467dbcff5930e7dd0d5cdd9ed59443.
//
// Solidity: event UpkeepWithdrawn(address indexed strategy, address indexed withdrawer, uint256 amount)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchUpkeepWithdrawn(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorUpkeepWithdrawn, strategy []common.Address, withdrawer []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var withdrawerRule []interface{}
	for _, withdrawerItem := range withdrawer {
		withdrawerRule = append(withdrawerRule, withdrawerItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "UpkeepWithdrawn", strategyRule, withdrawerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorUpkeepWithdrawn)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "UpkeepWithdrawn", log); err != nil {
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

// ParseUpkeepWithdrawn is a log parse operation binding the contract event 0x5e02dcaf3d3c04e0d6054134d489d13868467dbcff5930e7dd0d5cdd9ed59443.
//
// Solidity: event UpkeepWithdrawn(address indexed strategy, address indexed withdrawer, uint256 amount)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseUpkeepWithdrawn(log types.Log) (*UnsafeSuperVaultAggregatorUpkeepWithdrawn, error) {
	event := new(UnsafeSuperVaultAggregatorUpkeepWithdrawn)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "UpkeepWithdrawn", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UnsafeSuperVaultAggregatorVaultDeployedIterator is returned from FilterVaultDeployed and is used to iterate over the raw logs and unpacked data for VaultDeployed events raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorVaultDeployedIterator struct {
	Event *UnsafeSuperVaultAggregatorVaultDeployed // Event containing the contract specifics and raw log

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
func (it *UnsafeSuperVaultAggregatorVaultDeployedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UnsafeSuperVaultAggregatorVaultDeployed)
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
		it.Event = new(UnsafeSuperVaultAggregatorVaultDeployed)
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
func (it *UnsafeSuperVaultAggregatorVaultDeployedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UnsafeSuperVaultAggregatorVaultDeployedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UnsafeSuperVaultAggregatorVaultDeployed represents a VaultDeployed event raised by the UnsafeSuperVaultAggregator contract.
type UnsafeSuperVaultAggregatorVaultDeployed struct {
	Vault    common.Address
	Strategy common.Address
	Escrow   common.Address
	Asset    common.Address
	Name     string
	Symbol   string
	Nonce    *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterVaultDeployed is a free log retrieval operation binding the contract event 0xb71e4c3b886bfa372037021505c466d28e41fc077044f0f8be29eeff13713347.
//
// Solidity: event VaultDeployed(address indexed vault, address indexed strategy, address escrow, address asset, string name, string symbol, uint256 indexed nonce)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) FilterVaultDeployed(opts *bind.FilterOpts, vault []common.Address, strategy []common.Address, nonce []*big.Int) (*UnsafeSuperVaultAggregatorVaultDeployedIterator, error) {

	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}
	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	var nonceRule []interface{}
	for _, nonceItem := range nonce {
		nonceRule = append(nonceRule, nonceItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.FilterLogs(opts, "VaultDeployed", vaultRule, strategyRule, nonceRule)
	if err != nil {
		return nil, err
	}
	return &UnsafeSuperVaultAggregatorVaultDeployedIterator{contract: _UnsafeSuperVaultAggregator.contract, event: "VaultDeployed", logs: logs, sub: sub}, nil
}

// WatchVaultDeployed is a free log subscription operation binding the contract event 0xb71e4c3b886bfa372037021505c466d28e41fc077044f0f8be29eeff13713347.
//
// Solidity: event VaultDeployed(address indexed vault, address indexed strategy, address escrow, address asset, string name, string symbol, uint256 indexed nonce)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) WatchVaultDeployed(opts *bind.WatchOpts, sink chan<- *UnsafeSuperVaultAggregatorVaultDeployed, vault []common.Address, strategy []common.Address, nonce []*big.Int) (event.Subscription, error) {

	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}
	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	var nonceRule []interface{}
	for _, nonceItem := range nonce {
		nonceRule = append(nonceRule, nonceItem)
	}

	logs, sub, err := _UnsafeSuperVaultAggregator.contract.WatchLogs(opts, "VaultDeployed", vaultRule, strategyRule, nonceRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UnsafeSuperVaultAggregatorVaultDeployed)
				if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "VaultDeployed", log); err != nil {
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

// ParseVaultDeployed is a log parse operation binding the contract event 0xb71e4c3b886bfa372037021505c466d28e41fc077044f0f8be29eeff13713347.
//
// Solidity: event VaultDeployed(address indexed vault, address indexed strategy, address escrow, address asset, string name, string symbol, uint256 indexed nonce)
func (_UnsafeSuperVaultAggregator *UnsafeSuperVaultAggregatorFilterer) ParseVaultDeployed(log types.Log) (*UnsafeSuperVaultAggregatorVaultDeployed, error) {
	event := new(UnsafeSuperVaultAggregatorVaultDeployed)
	if err := _UnsafeSuperVaultAggregator.contract.UnpackLog(event, "VaultDeployed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
