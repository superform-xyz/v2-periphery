// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package ISuperVaultAggregator

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
	ValidatorSets   []*big.Int
	TotalValidator  *big.Int
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
	Asset              common.Address
	Name               string
	Symbol             string
	MainManager        common.Address
	SecondaryManagers  []common.Address
	MinUpdateInterval  *big.Int
	MaxStaleness       *big.Int
	FeeConfig          ISuperVaultStrategyFeeConfig
	MaxUnpauseTimeLock *big.Int
}

// ISuperVaultStrategyFeeConfig is an auto generated low-level Go binding around an user-defined struct.
type ISuperVaultStrategyFeeConfig struct {
	PerformanceFeeBps *big.Int
	ManagementFeeBps  *big.Int
	Recipient         common.Address
}

// ISuperVaultAggregatorMetaData contains all meta data concerning the ISuperVaultAggregator contract.
var ISuperVaultAggregatorMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"addAuthorizedCaller\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"caller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addSecondaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"changeGlobalLeavesStatus\",\"inputs\":[{\"name\":\"leaves\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"},{\"name\":\"statuses\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"changePrimaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newManager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"claimUpkeep\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"completeStakeWithdrawal\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"createVault\",\"inputs\":[{\"name\":\"params\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultAggregator.VaultCreationParams\",\"components\":[{\"name\":\"asset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"symbol\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"mainManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"secondaryManagers\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"minUpdateInterval\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxStaleness\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"feeConfig\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultStrategy.FeeConfig\",\"components\":[{\"name\":\"performanceFeeBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"managementFeeBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"recipient\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"name\":\"maxUnpauseTimeLock\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"outputs\":[{\"name\":\"superVault\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"escrow\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"depositStake\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"depositUpkeep\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeChangePrimaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeGlobalHooksRootUpdate\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeStrategyHooksRootUpdate\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"forwardPPS\",\"inputs\":[{\"name\":\"args\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultAggregator.ForwardPPSArgs\",\"components\":[{\"name\":\"strategies\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"ppss\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"validatorSets\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"totalValidator\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"timestamps\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"updateAuthority\",\"type\":\"address\",\"internalType\":\"address\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getAllSuperVaultEscrows\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAllSuperVaultStrategies\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAllSuperVaults\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAuthorizedCallers\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"callers\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCurrentNonce\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getGlobalHooksRoot\",\"inputs\":[],\"outputs\":[{\"name\":\"root\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getHooksRootUpdateTimelock\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getLastUpdateTimestamp\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMainManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMaxStaleness\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"staleness\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMinUpdateInterval\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"interval\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getPPS\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"pps\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getPPSVerificationThresholds\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"deviationThreshold\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"mnThreshold\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedGlobalHooksRoot\",\"inputs\":[],\"outputs\":[{\"name\":\"root\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedStrategyHooksRoot\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"root\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSecondaryManagers\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"secondaryManagers\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getStakeBalance\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getStrategyHooksRoot\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"root\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getUpkeepBalance\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isAnyManager\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isGlobalHooksRootActive\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isGlobalHooksRootVetoed\",\"inputs\":[],\"outputs\":[{\"name\":\"vetoed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isMainManager\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"isMainManager\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isPPSStale\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"isStale\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isSecondaryManager\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"isSecondaryManager\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isStrategyHooksRootVetoed\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"vetoed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isStrategyPaused\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"isPaused\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pauseStrategy\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeChangePrimaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newManager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeGlobalHooksRoot\",\"inputs\":[{\"name\":\"newRoot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeStrategyHooksRoot\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newRoot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeAuthorizedCaller\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"caller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeSecondaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"requestStakeWithdrawal\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGlobalHooksRootVetoStatus\",\"inputs\":[{\"name\":\"vetoed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setHooksRootUpdateTimelock\",\"inputs\":[{\"name\":\"newTimelock\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setStrategyHooksRootVetoStatus\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"vetoed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"slashStake\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"superVaultEscrows\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"superVaultStrategies\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"superVaults\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"unpauseStrategy\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"updatePPSAfterSkim\",\"inputs\":[{\"name\":\"newPPS\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"feeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"updatePPSVerificationThresholds\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"deviationThreshold_\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"mnThreshold_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"validateHook\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"args\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultAggregator.ValidateHookArgs\",\"components\":[{\"name\":\"hookAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"hookArgs\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"globalProof\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"},{\"name\":\"strategyProof\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"}]}],\"outputs\":[{\"name\":\"isValid\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validateHooks\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"argsArray\",\"type\":\"tuple[]\",\"internalType\":\"structISuperVaultAggregator.ValidateHookArgs[]\",\"components\":[{\"name\":\"hookAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"hookArgs\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"globalProof\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"},{\"name\":\"strategyProof\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"}]}],\"outputs\":[{\"name\":\"validHooks\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"withdrawUpkeep\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"AuthorizedCaller\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"caller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AuthorizedCallerAdded\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"caller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AuthorizedCallerRemoved\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"caller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"GlobalHooksRootUpdateProposed\",\"inputs\":[{\"name\":\"root\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"GlobalHooksRootUpdated\",\"inputs\":[{\"name\":\"oldRoot\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newRoot\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"GlobalHooksRootVetoStatusChanged\",\"inputs\":[{\"name\":\"vetoed\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"},{\"name\":\"root\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"GlobalHooksRootVetoed\",\"inputs\":[{\"name\":\"guardian\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"root\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"GlobalLeavesStatusChanged\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"leaves\",\"type\":\"bytes32[]\",\"indexed\":false,\"internalType\":\"bytes32[]\"},{\"name\":\"statuses\",\"type\":\"bool[]\",\"indexed\":false,\"internalType\":\"bool[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"HooksRootUpdateTimelockChanged\",\"inputs\":[{\"name\":\"newTimelock\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"InsufficientUpkeep\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"balance\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"cost\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OldPrimaryManagerRemoved\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"oldManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSUpdated\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"pps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"validatorSet\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"totalValidators\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSUpdatedAfterSkim\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"oldPPS\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"newPPS\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"feeAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSVerificationThresholdsUpdated\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"deviationThreshold\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"mnThreshold\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PaymentSkippedForPausedStrategy\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PrimaryManagerChangeProposed\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"proposer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PrimaryManagerChanged\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"oldManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PrimaryManagerChangedToSuperform\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"oldManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ProvidedTimestampExceedsBlockTimestamp\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"argsTimestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"blockTimestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SecondaryManagerAdded\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SecondaryManagerRemoved\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StakeDeposited\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StakeSlashed\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StakeWithdrawRequested\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StakeWithdrawn\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StaleUpdate\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"updateAuthority\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyCheckFailed\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"reason\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyHooksRootUpdateProposed\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"proposer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"root\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyHooksRootUpdated\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"oldRoot\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"newRoot\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyHooksRootVetoStatusChanged\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"vetoed\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"},{\"name\":\"root\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyHooksRootVetoed\",\"inputs\":[{\"name\":\"guardian\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"root\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyPPSStale\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyPPSStaleReset\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyPaused\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyUnpausePPSTimelockUpdated\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newTimelock\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyUnpaused\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TimestampNotMonotonic\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UnknownStrategy\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpdateTooFrequent\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepClaimed\",\"inputs\":[{\"name\":\"superBank\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepCostUpdated\",\"inputs\":[{\"name\":\"oldCost\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"newCost\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepDeposited\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepSpent\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"balance\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"claimableUpkeep\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepWithdrawn\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"VaultDeployed\",\"inputs\":[{\"name\":\"vault\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"escrow\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"asset\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"name\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"symbol\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ARRAY_LENGTH_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CALLER_ALREADY_AUTHORIZED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CALLER_NOT_AUTHORIZED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CANNOT_ADD_PROTECTED_KEEPER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CANNOT_REMOVE_LAST_MANAGER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"HOOK_VALIDATION_FAILED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INDEX_OUT_OF_BOUNDS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_STAKE_BALANCE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_UPKEEP\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_UPKEEP_BALANCE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_ARRAY_LENGTH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_ASSET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_TIMESTAMP\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"MANAGER_ALREADY_EXISTS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MANAGER_CHANGE_NOT_READY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MANAGER_NOT_FOUND\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MAX_STALENESS_TOO_LOW\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MISMATCHED_ARRAY_LENGTHS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_A_GUARDIAN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_PENDING_GLOBAL_ROOT_CHANGE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_PENDING_MANAGER_CHANGE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_PENDING_ROOT_UPDATE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PPS_DEDUCTION_TOO_LARGE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PPS_MUST_DECREASE_AFTER_SKIM\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ROOT_UPDATE_NOT_READY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"STRATEGY_ALREADY_PAUSED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"STRATEGY_NOT_PAUSED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"TIMELOCK_NOT_EXPIRED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"TOO_MANY_SECONDARY_MANAGERS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UNAUTHORIZED_CALLER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UNAUTHORIZED_PPS_ORACLE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UNAUTHORIZED_UPDATE_AUTHORITY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UNKNOWN_STRATEGY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UNPAUSE_TIMELOCK_NOT_MET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UPDATE_TOO_STALE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"VAULT_PAUSED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"WITHDRAWAL_REQUEST_EXPIRED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"WITHDRAW_STAKE_REQUEST_NOT_FOUND\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"WITHDRAW_STAKE_REQUEST_NOT_READY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_AMOUNT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_ARRAY_LENGTH\",\"inputs\":[]}]",
}

// ISuperVaultAggregatorABI is the input ABI used to generate the binding from.
// Deprecated: Use ISuperVaultAggregatorMetaData.ABI instead.
var ISuperVaultAggregatorABI = ISuperVaultAggregatorMetaData.ABI

// ISuperVaultAggregator is an auto generated Go binding around an Ethereum contract.
type ISuperVaultAggregator struct {
	ISuperVaultAggregatorCaller     // Read-only binding to the contract
	ISuperVaultAggregatorTransactor // Write-only binding to the contract
	ISuperVaultAggregatorFilterer   // Log filterer for contract events
}

// ISuperVaultAggregatorCaller is an auto generated read-only Go binding around an Ethereum contract.
type ISuperVaultAggregatorCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ISuperVaultAggregatorTransactor is an auto generated write-only Go binding around an Ethereum contract.
type ISuperVaultAggregatorTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ISuperVaultAggregatorFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type ISuperVaultAggregatorFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ISuperVaultAggregatorSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type ISuperVaultAggregatorSession struct {
	Contract     *ISuperVaultAggregator // Generic contract binding to set the session for
	CallOpts     bind.CallOpts          // Call options to use throughout this session
	TransactOpts bind.TransactOpts      // Transaction auth options to use throughout this session
}

// ISuperVaultAggregatorCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type ISuperVaultAggregatorCallerSession struct {
	Contract *ISuperVaultAggregatorCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts                // Call options to use throughout this session
}

// ISuperVaultAggregatorTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type ISuperVaultAggregatorTransactorSession struct {
	Contract     *ISuperVaultAggregatorTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts                // Transaction auth options to use throughout this session
}

// ISuperVaultAggregatorRaw is an auto generated low-level Go binding around an Ethereum contract.
type ISuperVaultAggregatorRaw struct {
	Contract *ISuperVaultAggregator // Generic contract binding to access the raw methods on
}

// ISuperVaultAggregatorCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type ISuperVaultAggregatorCallerRaw struct {
	Contract *ISuperVaultAggregatorCaller // Generic read-only contract binding to access the raw methods on
}

// ISuperVaultAggregatorTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type ISuperVaultAggregatorTransactorRaw struct {
	Contract *ISuperVaultAggregatorTransactor // Generic write-only contract binding to access the raw methods on
}

// NewISuperVaultAggregator creates a new instance of ISuperVaultAggregator, bound to a specific deployed contract.
func NewISuperVaultAggregator(address common.Address, backend bind.ContractBackend) (*ISuperVaultAggregator, error) {
	contract, err := bindISuperVaultAggregator(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregator{ISuperVaultAggregatorCaller: ISuperVaultAggregatorCaller{contract: contract}, ISuperVaultAggregatorTransactor: ISuperVaultAggregatorTransactor{contract: contract}, ISuperVaultAggregatorFilterer: ISuperVaultAggregatorFilterer{contract: contract}}, nil
}

// NewISuperVaultAggregatorCaller creates a new read-only instance of ISuperVaultAggregator, bound to a specific deployed contract.
func NewISuperVaultAggregatorCaller(address common.Address, caller bind.ContractCaller) (*ISuperVaultAggregatorCaller, error) {
	contract, err := bindISuperVaultAggregator(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorCaller{contract: contract}, nil
}

// NewISuperVaultAggregatorTransactor creates a new write-only instance of ISuperVaultAggregator, bound to a specific deployed contract.
func NewISuperVaultAggregatorTransactor(address common.Address, transactor bind.ContractTransactor) (*ISuperVaultAggregatorTransactor, error) {
	contract, err := bindISuperVaultAggregator(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorTransactor{contract: contract}, nil
}

// NewISuperVaultAggregatorFilterer creates a new log filterer instance of ISuperVaultAggregator, bound to a specific deployed contract.
func NewISuperVaultAggregatorFilterer(address common.Address, filterer bind.ContractFilterer) (*ISuperVaultAggregatorFilterer, error) {
	contract, err := bindISuperVaultAggregator(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorFilterer{contract: contract}, nil
}

// bindISuperVaultAggregator binds a generic wrapper to an already deployed contract.
func bindISuperVaultAggregator(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := ISuperVaultAggregatorMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_ISuperVaultAggregator *ISuperVaultAggregatorRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _ISuperVaultAggregator.Contract.ISuperVaultAggregatorCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_ISuperVaultAggregator *ISuperVaultAggregatorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ISuperVaultAggregatorTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_ISuperVaultAggregator *ISuperVaultAggregatorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ISuperVaultAggregatorTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _ISuperVaultAggregator.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.contract.Transact(opts, method, params...)
}

// GetAllSuperVaultEscrows is a free data retrieval call binding the contract method 0x154fd23f.
//
// Solidity: function getAllSuperVaultEscrows() view returns(address[])
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetAllSuperVaultEscrows(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getAllSuperVaultEscrows")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetAllSuperVaultEscrows is a free data retrieval call binding the contract method 0x154fd23f.
//
// Solidity: function getAllSuperVaultEscrows() view returns(address[])
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetAllSuperVaultEscrows() ([]common.Address, error) {
	return _ISuperVaultAggregator.Contract.GetAllSuperVaultEscrows(&_ISuperVaultAggregator.CallOpts)
}

// GetAllSuperVaultEscrows is a free data retrieval call binding the contract method 0x154fd23f.
//
// Solidity: function getAllSuperVaultEscrows() view returns(address[])
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetAllSuperVaultEscrows() ([]common.Address, error) {
	return _ISuperVaultAggregator.Contract.GetAllSuperVaultEscrows(&_ISuperVaultAggregator.CallOpts)
}

// GetAllSuperVaultStrategies is a free data retrieval call binding the contract method 0x8e9615c9.
//
// Solidity: function getAllSuperVaultStrategies() view returns(address[])
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetAllSuperVaultStrategies(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getAllSuperVaultStrategies")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetAllSuperVaultStrategies is a free data retrieval call binding the contract method 0x8e9615c9.
//
// Solidity: function getAllSuperVaultStrategies() view returns(address[])
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetAllSuperVaultStrategies() ([]common.Address, error) {
	return _ISuperVaultAggregator.Contract.GetAllSuperVaultStrategies(&_ISuperVaultAggregator.CallOpts)
}

// GetAllSuperVaultStrategies is a free data retrieval call binding the contract method 0x8e9615c9.
//
// Solidity: function getAllSuperVaultStrategies() view returns(address[])
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetAllSuperVaultStrategies() ([]common.Address, error) {
	return _ISuperVaultAggregator.Contract.GetAllSuperVaultStrategies(&_ISuperVaultAggregator.CallOpts)
}

// GetAllSuperVaults is a free data retrieval call binding the contract method 0xa5256bf2.
//
// Solidity: function getAllSuperVaults() view returns(address[])
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetAllSuperVaults(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getAllSuperVaults")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetAllSuperVaults is a free data retrieval call binding the contract method 0xa5256bf2.
//
// Solidity: function getAllSuperVaults() view returns(address[])
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetAllSuperVaults() ([]common.Address, error) {
	return _ISuperVaultAggregator.Contract.GetAllSuperVaults(&_ISuperVaultAggregator.CallOpts)
}

// GetAllSuperVaults is a free data retrieval call binding the contract method 0xa5256bf2.
//
// Solidity: function getAllSuperVaults() view returns(address[])
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetAllSuperVaults() ([]common.Address, error) {
	return _ISuperVaultAggregator.Contract.GetAllSuperVaults(&_ISuperVaultAggregator.CallOpts)
}

// GetAuthorizedCallers is a free data retrieval call binding the contract method 0xceb18ce4.
//
// Solidity: function getAuthorizedCallers(address strategy) view returns(address[] callers)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetAuthorizedCallers(opts *bind.CallOpts, strategy common.Address) ([]common.Address, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getAuthorizedCallers", strategy)

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetAuthorizedCallers is a free data retrieval call binding the contract method 0xceb18ce4.
//
// Solidity: function getAuthorizedCallers(address strategy) view returns(address[] callers)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetAuthorizedCallers(strategy common.Address) ([]common.Address, error) {
	return _ISuperVaultAggregator.Contract.GetAuthorizedCallers(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetAuthorizedCallers is a free data retrieval call binding the contract method 0xceb18ce4.
//
// Solidity: function getAuthorizedCallers(address strategy) view returns(address[] callers)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetAuthorizedCallers(strategy common.Address) ([]common.Address, error) {
	return _ISuperVaultAggregator.Contract.GetAuthorizedCallers(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetCurrentNonce is a free data retrieval call binding the contract method 0x3a60c386.
//
// Solidity: function getCurrentNonce() view returns(uint256)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetCurrentNonce(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getCurrentNonce")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetCurrentNonce is a free data retrieval call binding the contract method 0x3a60c386.
//
// Solidity: function getCurrentNonce() view returns(uint256)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetCurrentNonce() (*big.Int, error) {
	return _ISuperVaultAggregator.Contract.GetCurrentNonce(&_ISuperVaultAggregator.CallOpts)
}

// GetCurrentNonce is a free data retrieval call binding the contract method 0x3a60c386.
//
// Solidity: function getCurrentNonce() view returns(uint256)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetCurrentNonce() (*big.Int, error) {
	return _ISuperVaultAggregator.Contract.GetCurrentNonce(&_ISuperVaultAggregator.CallOpts)
}

// GetGlobalHooksRoot is a free data retrieval call binding the contract method 0x2a90a055.
//
// Solidity: function getGlobalHooksRoot() view returns(bytes32 root)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetGlobalHooksRoot(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getGlobalHooksRoot")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetGlobalHooksRoot is a free data retrieval call binding the contract method 0x2a90a055.
//
// Solidity: function getGlobalHooksRoot() view returns(bytes32 root)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetGlobalHooksRoot() ([32]byte, error) {
	return _ISuperVaultAggregator.Contract.GetGlobalHooksRoot(&_ISuperVaultAggregator.CallOpts)
}

// GetGlobalHooksRoot is a free data retrieval call binding the contract method 0x2a90a055.
//
// Solidity: function getGlobalHooksRoot() view returns(bytes32 root)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetGlobalHooksRoot() ([32]byte, error) {
	return _ISuperVaultAggregator.Contract.GetGlobalHooksRoot(&_ISuperVaultAggregator.CallOpts)
}

// GetHooksRootUpdateTimelock is a free data retrieval call binding the contract method 0x7be3d10f.
//
// Solidity: function getHooksRootUpdateTimelock() view returns(uint256)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetHooksRootUpdateTimelock(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getHooksRootUpdateTimelock")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetHooksRootUpdateTimelock is a free data retrieval call binding the contract method 0x7be3d10f.
//
// Solidity: function getHooksRootUpdateTimelock() view returns(uint256)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetHooksRootUpdateTimelock() (*big.Int, error) {
	return _ISuperVaultAggregator.Contract.GetHooksRootUpdateTimelock(&_ISuperVaultAggregator.CallOpts)
}

// GetHooksRootUpdateTimelock is a free data retrieval call binding the contract method 0x7be3d10f.
//
// Solidity: function getHooksRootUpdateTimelock() view returns(uint256)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetHooksRootUpdateTimelock() (*big.Int, error) {
	return _ISuperVaultAggregator.Contract.GetHooksRootUpdateTimelock(&_ISuperVaultAggregator.CallOpts)
}

// GetLastUpdateTimestamp is a free data retrieval call binding the contract method 0x1a351d62.
//
// Solidity: function getLastUpdateTimestamp(address strategy) view returns(uint256 timestamp)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetLastUpdateTimestamp(opts *bind.CallOpts, strategy common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getLastUpdateTimestamp", strategy)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetLastUpdateTimestamp is a free data retrieval call binding the contract method 0x1a351d62.
//
// Solidity: function getLastUpdateTimestamp(address strategy) view returns(uint256 timestamp)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetLastUpdateTimestamp(strategy common.Address) (*big.Int, error) {
	return _ISuperVaultAggregator.Contract.GetLastUpdateTimestamp(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetLastUpdateTimestamp is a free data retrieval call binding the contract method 0x1a351d62.
//
// Solidity: function getLastUpdateTimestamp(address strategy) view returns(uint256 timestamp)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetLastUpdateTimestamp(strategy common.Address) (*big.Int, error) {
	return _ISuperVaultAggregator.Contract.GetLastUpdateTimestamp(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetMainManager is a free data retrieval call binding the contract method 0xceb7b7a3.
//
// Solidity: function getMainManager(address strategy) view returns(address manager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetMainManager(opts *bind.CallOpts, strategy common.Address) (common.Address, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getMainManager", strategy)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetMainManager is a free data retrieval call binding the contract method 0xceb7b7a3.
//
// Solidity: function getMainManager(address strategy) view returns(address manager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetMainManager(strategy common.Address) (common.Address, error) {
	return _ISuperVaultAggregator.Contract.GetMainManager(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetMainManager is a free data retrieval call binding the contract method 0xceb7b7a3.
//
// Solidity: function getMainManager(address strategy) view returns(address manager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetMainManager(strategy common.Address) (common.Address, error) {
	return _ISuperVaultAggregator.Contract.GetMainManager(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetMaxStaleness is a free data retrieval call binding the contract method 0xc25b784f.
//
// Solidity: function getMaxStaleness(address strategy) view returns(uint256 staleness)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetMaxStaleness(opts *bind.CallOpts, strategy common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getMaxStaleness", strategy)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetMaxStaleness is a free data retrieval call binding the contract method 0xc25b784f.
//
// Solidity: function getMaxStaleness(address strategy) view returns(uint256 staleness)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetMaxStaleness(strategy common.Address) (*big.Int, error) {
	return _ISuperVaultAggregator.Contract.GetMaxStaleness(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetMaxStaleness is a free data retrieval call binding the contract method 0xc25b784f.
//
// Solidity: function getMaxStaleness(address strategy) view returns(uint256 staleness)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetMaxStaleness(strategy common.Address) (*big.Int, error) {
	return _ISuperVaultAggregator.Contract.GetMaxStaleness(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetMinUpdateInterval is a free data retrieval call binding the contract method 0x3ab973a3.
//
// Solidity: function getMinUpdateInterval(address strategy) view returns(uint256 interval)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetMinUpdateInterval(opts *bind.CallOpts, strategy common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getMinUpdateInterval", strategy)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetMinUpdateInterval is a free data retrieval call binding the contract method 0x3ab973a3.
//
// Solidity: function getMinUpdateInterval(address strategy) view returns(uint256 interval)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetMinUpdateInterval(strategy common.Address) (*big.Int, error) {
	return _ISuperVaultAggregator.Contract.GetMinUpdateInterval(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetMinUpdateInterval is a free data retrieval call binding the contract method 0x3ab973a3.
//
// Solidity: function getMinUpdateInterval(address strategy) view returns(uint256 interval)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetMinUpdateInterval(strategy common.Address) (*big.Int, error) {
	return _ISuperVaultAggregator.Contract.GetMinUpdateInterval(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetPPS is a free data retrieval call binding the contract method 0xbef02b8c.
//
// Solidity: function getPPS(address strategy) view returns(uint256 pps)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetPPS(opts *bind.CallOpts, strategy common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getPPS", strategy)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetPPS is a free data retrieval call binding the contract method 0xbef02b8c.
//
// Solidity: function getPPS(address strategy) view returns(uint256 pps)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetPPS(strategy common.Address) (*big.Int, error) {
	return _ISuperVaultAggregator.Contract.GetPPS(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetPPS is a free data retrieval call binding the contract method 0xbef02b8c.
//
// Solidity: function getPPS(address strategy) view returns(uint256 pps)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetPPS(strategy common.Address) (*big.Int, error) {
	return _ISuperVaultAggregator.Contract.GetPPS(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetPPSVerificationThresholds is a free data retrieval call binding the contract method 0x322ae311.
//
// Solidity: function getPPSVerificationThresholds(address strategy) view returns(uint256 deviationThreshold, uint256 mnThreshold)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetPPSVerificationThresholds(opts *bind.CallOpts, strategy common.Address) (struct {
	DeviationThreshold *big.Int
	MnThreshold        *big.Int
}, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getPPSVerificationThresholds", strategy)

	outstruct := new(struct {
		DeviationThreshold *big.Int
		MnThreshold        *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.DeviationThreshold = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.MnThreshold = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// GetPPSVerificationThresholds is a free data retrieval call binding the contract method 0x322ae311.
//
// Solidity: function getPPSVerificationThresholds(address strategy) view returns(uint256 deviationThreshold, uint256 mnThreshold)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetPPSVerificationThresholds(strategy common.Address) (struct {
	DeviationThreshold *big.Int
	MnThreshold        *big.Int
}, error) {
	return _ISuperVaultAggregator.Contract.GetPPSVerificationThresholds(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetPPSVerificationThresholds is a free data retrieval call binding the contract method 0x322ae311.
//
// Solidity: function getPPSVerificationThresholds(address strategy) view returns(uint256 deviationThreshold, uint256 mnThreshold)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetPPSVerificationThresholds(strategy common.Address) (struct {
	DeviationThreshold *big.Int
	MnThreshold        *big.Int
}, error) {
	return _ISuperVaultAggregator.Contract.GetPPSVerificationThresholds(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetProposedGlobalHooksRoot is a free data retrieval call binding the contract method 0x9ab4e37b.
//
// Solidity: function getProposedGlobalHooksRoot() view returns(bytes32 root, uint256 effectiveTime)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetProposedGlobalHooksRoot(opts *bind.CallOpts) (struct {
	Root          [32]byte
	EffectiveTime *big.Int
}, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getProposedGlobalHooksRoot")

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
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetProposedGlobalHooksRoot() (struct {
	Root          [32]byte
	EffectiveTime *big.Int
}, error) {
	return _ISuperVaultAggregator.Contract.GetProposedGlobalHooksRoot(&_ISuperVaultAggregator.CallOpts)
}

// GetProposedGlobalHooksRoot is a free data retrieval call binding the contract method 0x9ab4e37b.
//
// Solidity: function getProposedGlobalHooksRoot() view returns(bytes32 root, uint256 effectiveTime)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetProposedGlobalHooksRoot() (struct {
	Root          [32]byte
	EffectiveTime *big.Int
}, error) {
	return _ISuperVaultAggregator.Contract.GetProposedGlobalHooksRoot(&_ISuperVaultAggregator.CallOpts)
}

// GetProposedStrategyHooksRoot is a free data retrieval call binding the contract method 0x2b4bb841.
//
// Solidity: function getProposedStrategyHooksRoot(address strategy) view returns(bytes32 root, uint256 effectiveTime)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetProposedStrategyHooksRoot(opts *bind.CallOpts, strategy common.Address) (struct {
	Root          [32]byte
	EffectiveTime *big.Int
}, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getProposedStrategyHooksRoot", strategy)

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
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetProposedStrategyHooksRoot(strategy common.Address) (struct {
	Root          [32]byte
	EffectiveTime *big.Int
}, error) {
	return _ISuperVaultAggregator.Contract.GetProposedStrategyHooksRoot(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetProposedStrategyHooksRoot is a free data retrieval call binding the contract method 0x2b4bb841.
//
// Solidity: function getProposedStrategyHooksRoot(address strategy) view returns(bytes32 root, uint256 effectiveTime)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetProposedStrategyHooksRoot(strategy common.Address) (struct {
	Root          [32]byte
	EffectiveTime *big.Int
}, error) {
	return _ISuperVaultAggregator.Contract.GetProposedStrategyHooksRoot(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetSecondaryManagers is a free data retrieval call binding the contract method 0x5f853d40.
//
// Solidity: function getSecondaryManagers(address strategy) view returns(address[] secondaryManagers)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetSecondaryManagers(opts *bind.CallOpts, strategy common.Address) ([]common.Address, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getSecondaryManagers", strategy)

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetSecondaryManagers is a free data retrieval call binding the contract method 0x5f853d40.
//
// Solidity: function getSecondaryManagers(address strategy) view returns(address[] secondaryManagers)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetSecondaryManagers(strategy common.Address) ([]common.Address, error) {
	return _ISuperVaultAggregator.Contract.GetSecondaryManagers(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetSecondaryManagers is a free data retrieval call binding the contract method 0x5f853d40.
//
// Solidity: function getSecondaryManagers(address strategy) view returns(address[] secondaryManagers)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetSecondaryManagers(strategy common.Address) ([]common.Address, error) {
	return _ISuperVaultAggregator.Contract.GetSecondaryManagers(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetStakeBalance is a free data retrieval call binding the contract method 0xef869773.
//
// Solidity: function getStakeBalance(address manager) view returns(uint256 balance)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetStakeBalance(opts *bind.CallOpts, manager common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getStakeBalance", manager)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetStakeBalance is a free data retrieval call binding the contract method 0xef869773.
//
// Solidity: function getStakeBalance(address manager) view returns(uint256 balance)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetStakeBalance(manager common.Address) (*big.Int, error) {
	return _ISuperVaultAggregator.Contract.GetStakeBalance(&_ISuperVaultAggregator.CallOpts, manager)
}

// GetStakeBalance is a free data retrieval call binding the contract method 0xef869773.
//
// Solidity: function getStakeBalance(address manager) view returns(uint256 balance)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetStakeBalance(manager common.Address) (*big.Int, error) {
	return _ISuperVaultAggregator.Contract.GetStakeBalance(&_ISuperVaultAggregator.CallOpts, manager)
}

// GetStrategyHooksRoot is a free data retrieval call binding the contract method 0xc99d2c89.
//
// Solidity: function getStrategyHooksRoot(address strategy) view returns(bytes32 root)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetStrategyHooksRoot(opts *bind.CallOpts, strategy common.Address) ([32]byte, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getStrategyHooksRoot", strategy)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetStrategyHooksRoot is a free data retrieval call binding the contract method 0xc99d2c89.
//
// Solidity: function getStrategyHooksRoot(address strategy) view returns(bytes32 root)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetStrategyHooksRoot(strategy common.Address) ([32]byte, error) {
	return _ISuperVaultAggregator.Contract.GetStrategyHooksRoot(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetStrategyHooksRoot is a free data retrieval call binding the contract method 0xc99d2c89.
//
// Solidity: function getStrategyHooksRoot(address strategy) view returns(bytes32 root)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetStrategyHooksRoot(strategy common.Address) ([32]byte, error) {
	return _ISuperVaultAggregator.Contract.GetStrategyHooksRoot(&_ISuperVaultAggregator.CallOpts, strategy)
}

// GetUpkeepBalance is a free data retrieval call binding the contract method 0x1aef3510.
//
// Solidity: function getUpkeepBalance(address manager) view returns(uint256 balance)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) GetUpkeepBalance(opts *bind.CallOpts, manager common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "getUpkeepBalance", manager)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetUpkeepBalance is a free data retrieval call binding the contract method 0x1aef3510.
//
// Solidity: function getUpkeepBalance(address manager) view returns(uint256 balance)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) GetUpkeepBalance(manager common.Address) (*big.Int, error) {
	return _ISuperVaultAggregator.Contract.GetUpkeepBalance(&_ISuperVaultAggregator.CallOpts, manager)
}

// GetUpkeepBalance is a free data retrieval call binding the contract method 0x1aef3510.
//
// Solidity: function getUpkeepBalance(address manager) view returns(uint256 balance)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) GetUpkeepBalance(manager common.Address) (*big.Int, error) {
	return _ISuperVaultAggregator.Contract.GetUpkeepBalance(&_ISuperVaultAggregator.CallOpts, manager)
}

// IsAnyManager is a free data retrieval call binding the contract method 0x9e87cb3f.
//
// Solidity: function isAnyManager(address manager, address strategy) view returns(bool)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) IsAnyManager(opts *bind.CallOpts, manager common.Address, strategy common.Address) (bool, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "isAnyManager", manager, strategy)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsAnyManager is a free data retrieval call binding the contract method 0x9e87cb3f.
//
// Solidity: function isAnyManager(address manager, address strategy) view returns(bool)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) IsAnyManager(manager common.Address, strategy common.Address) (bool, error) {
	return _ISuperVaultAggregator.Contract.IsAnyManager(&_ISuperVaultAggregator.CallOpts, manager, strategy)
}

// IsAnyManager is a free data retrieval call binding the contract method 0x9e87cb3f.
//
// Solidity: function isAnyManager(address manager, address strategy) view returns(bool)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) IsAnyManager(manager common.Address, strategy common.Address) (bool, error) {
	return _ISuperVaultAggregator.Contract.IsAnyManager(&_ISuperVaultAggregator.CallOpts, manager, strategy)
}

// IsGlobalHooksRootActive is a free data retrieval call binding the contract method 0x28f36ff0.
//
// Solidity: function isGlobalHooksRootActive() view returns(bool)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) IsGlobalHooksRootActive(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "isGlobalHooksRootActive")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsGlobalHooksRootActive is a free data retrieval call binding the contract method 0x28f36ff0.
//
// Solidity: function isGlobalHooksRootActive() view returns(bool)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) IsGlobalHooksRootActive() (bool, error) {
	return _ISuperVaultAggregator.Contract.IsGlobalHooksRootActive(&_ISuperVaultAggregator.CallOpts)
}

// IsGlobalHooksRootActive is a free data retrieval call binding the contract method 0x28f36ff0.
//
// Solidity: function isGlobalHooksRootActive() view returns(bool)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) IsGlobalHooksRootActive() (bool, error) {
	return _ISuperVaultAggregator.Contract.IsGlobalHooksRootActive(&_ISuperVaultAggregator.CallOpts)
}

// IsGlobalHooksRootVetoed is a free data retrieval call binding the contract method 0x81ed8df4.
//
// Solidity: function isGlobalHooksRootVetoed() view returns(bool vetoed)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) IsGlobalHooksRootVetoed(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "isGlobalHooksRootVetoed")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsGlobalHooksRootVetoed is a free data retrieval call binding the contract method 0x81ed8df4.
//
// Solidity: function isGlobalHooksRootVetoed() view returns(bool vetoed)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) IsGlobalHooksRootVetoed() (bool, error) {
	return _ISuperVaultAggregator.Contract.IsGlobalHooksRootVetoed(&_ISuperVaultAggregator.CallOpts)
}

// IsGlobalHooksRootVetoed is a free data retrieval call binding the contract method 0x81ed8df4.
//
// Solidity: function isGlobalHooksRootVetoed() view returns(bool vetoed)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) IsGlobalHooksRootVetoed() (bool, error) {
	return _ISuperVaultAggregator.Contract.IsGlobalHooksRootVetoed(&_ISuperVaultAggregator.CallOpts)
}

// IsMainManager is a free data retrieval call binding the contract method 0xeb91a9b2.
//
// Solidity: function isMainManager(address manager, address strategy) view returns(bool isMainManager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) IsMainManager(opts *bind.CallOpts, manager common.Address, strategy common.Address) (bool, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "isMainManager", manager, strategy)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsMainManager is a free data retrieval call binding the contract method 0xeb91a9b2.
//
// Solidity: function isMainManager(address manager, address strategy) view returns(bool isMainManager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) IsMainManager(manager common.Address, strategy common.Address) (bool, error) {
	return _ISuperVaultAggregator.Contract.IsMainManager(&_ISuperVaultAggregator.CallOpts, manager, strategy)
}

// IsMainManager is a free data retrieval call binding the contract method 0xeb91a9b2.
//
// Solidity: function isMainManager(address manager, address strategy) view returns(bool isMainManager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) IsMainManager(manager common.Address, strategy common.Address) (bool, error) {
	return _ISuperVaultAggregator.Contract.IsMainManager(&_ISuperVaultAggregator.CallOpts, manager, strategy)
}

// IsPPSStale is a free data retrieval call binding the contract method 0x7e8c1517.
//
// Solidity: function isPPSStale(address strategy) view returns(bool isStale)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) IsPPSStale(opts *bind.CallOpts, strategy common.Address) (bool, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "isPPSStale", strategy)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsPPSStale is a free data retrieval call binding the contract method 0x7e8c1517.
//
// Solidity: function isPPSStale(address strategy) view returns(bool isStale)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) IsPPSStale(strategy common.Address) (bool, error) {
	return _ISuperVaultAggregator.Contract.IsPPSStale(&_ISuperVaultAggregator.CallOpts, strategy)
}

// IsPPSStale is a free data retrieval call binding the contract method 0x7e8c1517.
//
// Solidity: function isPPSStale(address strategy) view returns(bool isStale)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) IsPPSStale(strategy common.Address) (bool, error) {
	return _ISuperVaultAggregator.Contract.IsPPSStale(&_ISuperVaultAggregator.CallOpts, strategy)
}

// IsSecondaryManager is a free data retrieval call binding the contract method 0x83aa6836.
//
// Solidity: function isSecondaryManager(address manager, address strategy) view returns(bool isSecondaryManager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) IsSecondaryManager(opts *bind.CallOpts, manager common.Address, strategy common.Address) (bool, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "isSecondaryManager", manager, strategy)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsSecondaryManager is a free data retrieval call binding the contract method 0x83aa6836.
//
// Solidity: function isSecondaryManager(address manager, address strategy) view returns(bool isSecondaryManager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) IsSecondaryManager(manager common.Address, strategy common.Address) (bool, error) {
	return _ISuperVaultAggregator.Contract.IsSecondaryManager(&_ISuperVaultAggregator.CallOpts, manager, strategy)
}

// IsSecondaryManager is a free data retrieval call binding the contract method 0x83aa6836.
//
// Solidity: function isSecondaryManager(address manager, address strategy) view returns(bool isSecondaryManager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) IsSecondaryManager(manager common.Address, strategy common.Address) (bool, error) {
	return _ISuperVaultAggregator.Contract.IsSecondaryManager(&_ISuperVaultAggregator.CallOpts, manager, strategy)
}

// IsStrategyHooksRootVetoed is a free data retrieval call binding the contract method 0xa8485b73.
//
// Solidity: function isStrategyHooksRootVetoed(address strategy) view returns(bool vetoed)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) IsStrategyHooksRootVetoed(opts *bind.CallOpts, strategy common.Address) (bool, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "isStrategyHooksRootVetoed", strategy)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsStrategyHooksRootVetoed is a free data retrieval call binding the contract method 0xa8485b73.
//
// Solidity: function isStrategyHooksRootVetoed(address strategy) view returns(bool vetoed)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) IsStrategyHooksRootVetoed(strategy common.Address) (bool, error) {
	return _ISuperVaultAggregator.Contract.IsStrategyHooksRootVetoed(&_ISuperVaultAggregator.CallOpts, strategy)
}

// IsStrategyHooksRootVetoed is a free data retrieval call binding the contract method 0xa8485b73.
//
// Solidity: function isStrategyHooksRootVetoed(address strategy) view returns(bool vetoed)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) IsStrategyHooksRootVetoed(strategy common.Address) (bool, error) {
	return _ISuperVaultAggregator.Contract.IsStrategyHooksRootVetoed(&_ISuperVaultAggregator.CallOpts, strategy)
}

// IsStrategyPaused is a free data retrieval call binding the contract method 0xc06a02e8.
//
// Solidity: function isStrategyPaused(address strategy) view returns(bool isPaused)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) IsStrategyPaused(opts *bind.CallOpts, strategy common.Address) (bool, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "isStrategyPaused", strategy)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsStrategyPaused is a free data retrieval call binding the contract method 0xc06a02e8.
//
// Solidity: function isStrategyPaused(address strategy) view returns(bool isPaused)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) IsStrategyPaused(strategy common.Address) (bool, error) {
	return _ISuperVaultAggregator.Contract.IsStrategyPaused(&_ISuperVaultAggregator.CallOpts, strategy)
}

// IsStrategyPaused is a free data retrieval call binding the contract method 0xc06a02e8.
//
// Solidity: function isStrategyPaused(address strategy) view returns(bool isPaused)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) IsStrategyPaused(strategy common.Address) (bool, error) {
	return _ISuperVaultAggregator.Contract.IsStrategyPaused(&_ISuperVaultAggregator.CallOpts, strategy)
}

// SuperVaultEscrows is a free data retrieval call binding the contract method 0xbda262d7.
//
// Solidity: function superVaultEscrows(uint256 index) view returns(address)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) SuperVaultEscrows(opts *bind.CallOpts, index *big.Int) (common.Address, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "superVaultEscrows", index)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SuperVaultEscrows is a free data retrieval call binding the contract method 0xbda262d7.
//
// Solidity: function superVaultEscrows(uint256 index) view returns(address)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) SuperVaultEscrows(index *big.Int) (common.Address, error) {
	return _ISuperVaultAggregator.Contract.SuperVaultEscrows(&_ISuperVaultAggregator.CallOpts, index)
}

// SuperVaultEscrows is a free data retrieval call binding the contract method 0xbda262d7.
//
// Solidity: function superVaultEscrows(uint256 index) view returns(address)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) SuperVaultEscrows(index *big.Int) (common.Address, error) {
	return _ISuperVaultAggregator.Contract.SuperVaultEscrows(&_ISuperVaultAggregator.CallOpts, index)
}

// SuperVaultStrategies is a free data retrieval call binding the contract method 0x9dc0ad84.
//
// Solidity: function superVaultStrategies(uint256 index) view returns(address)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) SuperVaultStrategies(opts *bind.CallOpts, index *big.Int) (common.Address, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "superVaultStrategies", index)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SuperVaultStrategies is a free data retrieval call binding the contract method 0x9dc0ad84.
//
// Solidity: function superVaultStrategies(uint256 index) view returns(address)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) SuperVaultStrategies(index *big.Int) (common.Address, error) {
	return _ISuperVaultAggregator.Contract.SuperVaultStrategies(&_ISuperVaultAggregator.CallOpts, index)
}

// SuperVaultStrategies is a free data retrieval call binding the contract method 0x9dc0ad84.
//
// Solidity: function superVaultStrategies(uint256 index) view returns(address)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) SuperVaultStrategies(index *big.Int) (common.Address, error) {
	return _ISuperVaultAggregator.Contract.SuperVaultStrategies(&_ISuperVaultAggregator.CallOpts, index)
}

// SuperVaults is a free data retrieval call binding the contract method 0x44648c76.
//
// Solidity: function superVaults(uint256 index) view returns(address)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) SuperVaults(opts *bind.CallOpts, index *big.Int) (common.Address, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "superVaults", index)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SuperVaults is a free data retrieval call binding the contract method 0x44648c76.
//
// Solidity: function superVaults(uint256 index) view returns(address)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) SuperVaults(index *big.Int) (common.Address, error) {
	return _ISuperVaultAggregator.Contract.SuperVaults(&_ISuperVaultAggregator.CallOpts, index)
}

// SuperVaults is a free data retrieval call binding the contract method 0x44648c76.
//
// Solidity: function superVaults(uint256 index) view returns(address)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) SuperVaults(index *big.Int) (common.Address, error) {
	return _ISuperVaultAggregator.Contract.SuperVaults(&_ISuperVaultAggregator.CallOpts, index)
}

// ValidateHook is a free data retrieval call binding the contract method 0x9e7b8c3a.
//
// Solidity: function validateHook(address strategy, (address,bytes,bytes32[],bytes32[]) args) view returns(bool isValid)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) ValidateHook(opts *bind.CallOpts, strategy common.Address, args ISuperVaultAggregatorValidateHookArgs) (bool, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "validateHook", strategy, args)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// ValidateHook is a free data retrieval call binding the contract method 0x9e7b8c3a.
//
// Solidity: function validateHook(address strategy, (address,bytes,bytes32[],bytes32[]) args) view returns(bool isValid)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) ValidateHook(strategy common.Address, args ISuperVaultAggregatorValidateHookArgs) (bool, error) {
	return _ISuperVaultAggregator.Contract.ValidateHook(&_ISuperVaultAggregator.CallOpts, strategy, args)
}

// ValidateHook is a free data retrieval call binding the contract method 0x9e7b8c3a.
//
// Solidity: function validateHook(address strategy, (address,bytes,bytes32[],bytes32[]) args) view returns(bool isValid)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) ValidateHook(strategy common.Address, args ISuperVaultAggregatorValidateHookArgs) (bool, error) {
	return _ISuperVaultAggregator.Contract.ValidateHook(&_ISuperVaultAggregator.CallOpts, strategy, args)
}

// ValidateHooks is a free data retrieval call binding the contract method 0x6cbd5796.
//
// Solidity: function validateHooks(address strategy, (address,bytes,bytes32[],bytes32[])[] argsArray) view returns(bool[] validHooks)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCaller) ValidateHooks(opts *bind.CallOpts, strategy common.Address, argsArray []ISuperVaultAggregatorValidateHookArgs) ([]bool, error) {
	var out []interface{}
	err := _ISuperVaultAggregator.contract.Call(opts, &out, "validateHooks", strategy, argsArray)

	if err != nil {
		return *new([]bool), err
	}

	out0 := *abi.ConvertType(out[0], new([]bool)).(*[]bool)

	return out0, err

}

// ValidateHooks is a free data retrieval call binding the contract method 0x6cbd5796.
//
// Solidity: function validateHooks(address strategy, (address,bytes,bytes32[],bytes32[])[] argsArray) view returns(bool[] validHooks)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) ValidateHooks(strategy common.Address, argsArray []ISuperVaultAggregatorValidateHookArgs) ([]bool, error) {
	return _ISuperVaultAggregator.Contract.ValidateHooks(&_ISuperVaultAggregator.CallOpts, strategy, argsArray)
}

// ValidateHooks is a free data retrieval call binding the contract method 0x6cbd5796.
//
// Solidity: function validateHooks(address strategy, (address,bytes,bytes32[],bytes32[])[] argsArray) view returns(bool[] validHooks)
func (_ISuperVaultAggregator *ISuperVaultAggregatorCallerSession) ValidateHooks(strategy common.Address, argsArray []ISuperVaultAggregatorValidateHookArgs) ([]bool, error) {
	return _ISuperVaultAggregator.Contract.ValidateHooks(&_ISuperVaultAggregator.CallOpts, strategy, argsArray)
}

// AddAuthorizedCaller is a paid mutator transaction binding the contract method 0x6a279bb6.
//
// Solidity: function addAuthorizedCaller(address strategy, address caller) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) AddAuthorizedCaller(opts *bind.TransactOpts, strategy common.Address, caller common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "addAuthorizedCaller", strategy, caller)
}

// AddAuthorizedCaller is a paid mutator transaction binding the contract method 0x6a279bb6.
//
// Solidity: function addAuthorizedCaller(address strategy, address caller) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) AddAuthorizedCaller(strategy common.Address, caller common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.AddAuthorizedCaller(&_ISuperVaultAggregator.TransactOpts, strategy, caller)
}

// AddAuthorizedCaller is a paid mutator transaction binding the contract method 0x6a279bb6.
//
// Solidity: function addAuthorizedCaller(address strategy, address caller) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) AddAuthorizedCaller(strategy common.Address, caller common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.AddAuthorizedCaller(&_ISuperVaultAggregator.TransactOpts, strategy, caller)
}

// AddSecondaryManager is a paid mutator transaction binding the contract method 0xc0c3bbd8.
//
// Solidity: function addSecondaryManager(address strategy, address manager) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) AddSecondaryManager(opts *bind.TransactOpts, strategy common.Address, manager common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "addSecondaryManager", strategy, manager)
}

// AddSecondaryManager is a paid mutator transaction binding the contract method 0xc0c3bbd8.
//
// Solidity: function addSecondaryManager(address strategy, address manager) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) AddSecondaryManager(strategy common.Address, manager common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.AddSecondaryManager(&_ISuperVaultAggregator.TransactOpts, strategy, manager)
}

// AddSecondaryManager is a paid mutator transaction binding the contract method 0xc0c3bbd8.
//
// Solidity: function addSecondaryManager(address strategy, address manager) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) AddSecondaryManager(strategy common.Address, manager common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.AddSecondaryManager(&_ISuperVaultAggregator.TransactOpts, strategy, manager)
}

// ChangeGlobalLeavesStatus is a paid mutator transaction binding the contract method 0xf430b328.
//
// Solidity: function changeGlobalLeavesStatus(bytes32[] leaves, bool[] statuses, address strategy) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) ChangeGlobalLeavesStatus(opts *bind.TransactOpts, leaves [][32]byte, statuses []bool, strategy common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "changeGlobalLeavesStatus", leaves, statuses, strategy)
}

// ChangeGlobalLeavesStatus is a paid mutator transaction binding the contract method 0xf430b328.
//
// Solidity: function changeGlobalLeavesStatus(bytes32[] leaves, bool[] statuses, address strategy) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) ChangeGlobalLeavesStatus(leaves [][32]byte, statuses []bool, strategy common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ChangeGlobalLeavesStatus(&_ISuperVaultAggregator.TransactOpts, leaves, statuses, strategy)
}

// ChangeGlobalLeavesStatus is a paid mutator transaction binding the contract method 0xf430b328.
//
// Solidity: function changeGlobalLeavesStatus(bytes32[] leaves, bool[] statuses, address strategy) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) ChangeGlobalLeavesStatus(leaves [][32]byte, statuses []bool, strategy common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ChangeGlobalLeavesStatus(&_ISuperVaultAggregator.TransactOpts, leaves, statuses, strategy)
}

// ChangePrimaryManager is a paid mutator transaction binding the contract method 0x906811e0.
//
// Solidity: function changePrimaryManager(address strategy, address newManager) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) ChangePrimaryManager(opts *bind.TransactOpts, strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "changePrimaryManager", strategy, newManager)
}

// ChangePrimaryManager is a paid mutator transaction binding the contract method 0x906811e0.
//
// Solidity: function changePrimaryManager(address strategy, address newManager) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) ChangePrimaryManager(strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ChangePrimaryManager(&_ISuperVaultAggregator.TransactOpts, strategy, newManager)
}

// ChangePrimaryManager is a paid mutator transaction binding the contract method 0x906811e0.
//
// Solidity: function changePrimaryManager(address strategy, address newManager) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) ChangePrimaryManager(strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ChangePrimaryManager(&_ISuperVaultAggregator.TransactOpts, strategy, newManager)
}

// ClaimUpkeep is a paid mutator transaction binding the contract method 0xd4eb9083.
//
// Solidity: function claimUpkeep(uint256 amount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) ClaimUpkeep(opts *bind.TransactOpts, amount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "claimUpkeep", amount)
}

// ClaimUpkeep is a paid mutator transaction binding the contract method 0xd4eb9083.
//
// Solidity: function claimUpkeep(uint256 amount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) ClaimUpkeep(amount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ClaimUpkeep(&_ISuperVaultAggregator.TransactOpts, amount)
}

// ClaimUpkeep is a paid mutator transaction binding the contract method 0xd4eb9083.
//
// Solidity: function claimUpkeep(uint256 amount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) ClaimUpkeep(amount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ClaimUpkeep(&_ISuperVaultAggregator.TransactOpts, amount)
}

// CompleteStakeWithdrawal is a paid mutator transaction binding the contract method 0x6da16741.
//
// Solidity: function completeStakeWithdrawal() returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) CompleteStakeWithdrawal(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "completeStakeWithdrawal")
}

// CompleteStakeWithdrawal is a paid mutator transaction binding the contract method 0x6da16741.
//
// Solidity: function completeStakeWithdrawal() returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) CompleteStakeWithdrawal() (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.CompleteStakeWithdrawal(&_ISuperVaultAggregator.TransactOpts)
}

// CompleteStakeWithdrawal is a paid mutator transaction binding the contract method 0x6da16741.
//
// Solidity: function completeStakeWithdrawal() returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) CompleteStakeWithdrawal() (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.CompleteStakeWithdrawal(&_ISuperVaultAggregator.TransactOpts)
}

// CreateVault is a paid mutator transaction binding the contract method 0x0084bce7.
//
// Solidity: function createVault((address,string,string,address,address[],uint256,uint256,(uint256,uint256,address),uint256) params) returns(address superVault, address strategy, address escrow)
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) CreateVault(opts *bind.TransactOpts, params ISuperVaultAggregatorVaultCreationParams) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "createVault", params)
}

// CreateVault is a paid mutator transaction binding the contract method 0x0084bce7.
//
// Solidity: function createVault((address,string,string,address,address[],uint256,uint256,(uint256,uint256,address),uint256) params) returns(address superVault, address strategy, address escrow)
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) CreateVault(params ISuperVaultAggregatorVaultCreationParams) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.CreateVault(&_ISuperVaultAggregator.TransactOpts, params)
}

// CreateVault is a paid mutator transaction binding the contract method 0x0084bce7.
//
// Solidity: function createVault((address,string,string,address,address[],uint256,uint256,(uint256,uint256,address),uint256) params) returns(address superVault, address strategy, address escrow)
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) CreateVault(params ISuperVaultAggregatorVaultCreationParams) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.CreateVault(&_ISuperVaultAggregator.TransactOpts, params)
}

// DepositStake is a paid mutator transaction binding the contract method 0x5410f365.
//
// Solidity: function depositStake(address manager, uint256 amount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) DepositStake(opts *bind.TransactOpts, manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "depositStake", manager, amount)
}

// DepositStake is a paid mutator transaction binding the contract method 0x5410f365.
//
// Solidity: function depositStake(address manager, uint256 amount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) DepositStake(manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.DepositStake(&_ISuperVaultAggregator.TransactOpts, manager, amount)
}

// DepositStake is a paid mutator transaction binding the contract method 0x5410f365.
//
// Solidity: function depositStake(address manager, uint256 amount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) DepositStake(manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.DepositStake(&_ISuperVaultAggregator.TransactOpts, manager, amount)
}

// DepositUpkeep is a paid mutator transaction binding the contract method 0x6fe79652.
//
// Solidity: function depositUpkeep(address manager, uint256 amount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) DepositUpkeep(opts *bind.TransactOpts, manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "depositUpkeep", manager, amount)
}

// DepositUpkeep is a paid mutator transaction binding the contract method 0x6fe79652.
//
// Solidity: function depositUpkeep(address manager, uint256 amount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) DepositUpkeep(manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.DepositUpkeep(&_ISuperVaultAggregator.TransactOpts, manager, amount)
}

// DepositUpkeep is a paid mutator transaction binding the contract method 0x6fe79652.
//
// Solidity: function depositUpkeep(address manager, uint256 amount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) DepositUpkeep(manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.DepositUpkeep(&_ISuperVaultAggregator.TransactOpts, manager, amount)
}

// ExecuteChangePrimaryManager is a paid mutator transaction binding the contract method 0x9249c392.
//
// Solidity: function executeChangePrimaryManager(address strategy) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) ExecuteChangePrimaryManager(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "executeChangePrimaryManager", strategy)
}

// ExecuteChangePrimaryManager is a paid mutator transaction binding the contract method 0x9249c392.
//
// Solidity: function executeChangePrimaryManager(address strategy) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) ExecuteChangePrimaryManager(strategy common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ExecuteChangePrimaryManager(&_ISuperVaultAggregator.TransactOpts, strategy)
}

// ExecuteChangePrimaryManager is a paid mutator transaction binding the contract method 0x9249c392.
//
// Solidity: function executeChangePrimaryManager(address strategy) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) ExecuteChangePrimaryManager(strategy common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ExecuteChangePrimaryManager(&_ISuperVaultAggregator.TransactOpts, strategy)
}

// ExecuteGlobalHooksRootUpdate is a paid mutator transaction binding the contract method 0x0a48d243.
//
// Solidity: function executeGlobalHooksRootUpdate() returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) ExecuteGlobalHooksRootUpdate(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "executeGlobalHooksRootUpdate")
}

// ExecuteGlobalHooksRootUpdate is a paid mutator transaction binding the contract method 0x0a48d243.
//
// Solidity: function executeGlobalHooksRootUpdate() returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) ExecuteGlobalHooksRootUpdate() (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ExecuteGlobalHooksRootUpdate(&_ISuperVaultAggregator.TransactOpts)
}

// ExecuteGlobalHooksRootUpdate is a paid mutator transaction binding the contract method 0x0a48d243.
//
// Solidity: function executeGlobalHooksRootUpdate() returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) ExecuteGlobalHooksRootUpdate() (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ExecuteGlobalHooksRootUpdate(&_ISuperVaultAggregator.TransactOpts)
}

// ExecuteStrategyHooksRootUpdate is a paid mutator transaction binding the contract method 0x7825784b.
//
// Solidity: function executeStrategyHooksRootUpdate(address strategy) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) ExecuteStrategyHooksRootUpdate(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "executeStrategyHooksRootUpdate", strategy)
}

// ExecuteStrategyHooksRootUpdate is a paid mutator transaction binding the contract method 0x7825784b.
//
// Solidity: function executeStrategyHooksRootUpdate(address strategy) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) ExecuteStrategyHooksRootUpdate(strategy common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ExecuteStrategyHooksRootUpdate(&_ISuperVaultAggregator.TransactOpts, strategy)
}

// ExecuteStrategyHooksRootUpdate is a paid mutator transaction binding the contract method 0x7825784b.
//
// Solidity: function executeStrategyHooksRootUpdate(address strategy) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) ExecuteStrategyHooksRootUpdate(strategy common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ExecuteStrategyHooksRootUpdate(&_ISuperVaultAggregator.TransactOpts, strategy)
}

// ForwardPPS is a paid mutator transaction binding the contract method 0x4f590c02.
//
// Solidity: function forwardPPS((address[],uint256[],uint256[],uint256,uint256[],address) args) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) ForwardPPS(opts *bind.TransactOpts, args ISuperVaultAggregatorForwardPPSArgs) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "forwardPPS", args)
}

// ForwardPPS is a paid mutator transaction binding the contract method 0x4f590c02.
//
// Solidity: function forwardPPS((address[],uint256[],uint256[],uint256,uint256[],address) args) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) ForwardPPS(args ISuperVaultAggregatorForwardPPSArgs) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ForwardPPS(&_ISuperVaultAggregator.TransactOpts, args)
}

// ForwardPPS is a paid mutator transaction binding the contract method 0x4f590c02.
//
// Solidity: function forwardPPS((address[],uint256[],uint256[],uint256,uint256[],address) args) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) ForwardPPS(args ISuperVaultAggregatorForwardPPSArgs) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ForwardPPS(&_ISuperVaultAggregator.TransactOpts, args)
}

// PauseStrategy is a paid mutator transaction binding the contract method 0xd3f6b598.
//
// Solidity: function pauseStrategy(address strategy) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) PauseStrategy(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "pauseStrategy", strategy)
}

// PauseStrategy is a paid mutator transaction binding the contract method 0xd3f6b598.
//
// Solidity: function pauseStrategy(address strategy) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) PauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.PauseStrategy(&_ISuperVaultAggregator.TransactOpts, strategy)
}

// PauseStrategy is a paid mutator transaction binding the contract method 0xd3f6b598.
//
// Solidity: function pauseStrategy(address strategy) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) PauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.PauseStrategy(&_ISuperVaultAggregator.TransactOpts, strategy)
}

// ProposeChangePrimaryManager is a paid mutator transaction binding the contract method 0x20b64b64.
//
// Solidity: function proposeChangePrimaryManager(address strategy, address newManager) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) ProposeChangePrimaryManager(opts *bind.TransactOpts, strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "proposeChangePrimaryManager", strategy, newManager)
}

// ProposeChangePrimaryManager is a paid mutator transaction binding the contract method 0x20b64b64.
//
// Solidity: function proposeChangePrimaryManager(address strategy, address newManager) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) ProposeChangePrimaryManager(strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ProposeChangePrimaryManager(&_ISuperVaultAggregator.TransactOpts, strategy, newManager)
}

// ProposeChangePrimaryManager is a paid mutator transaction binding the contract method 0x20b64b64.
//
// Solidity: function proposeChangePrimaryManager(address strategy, address newManager) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) ProposeChangePrimaryManager(strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ProposeChangePrimaryManager(&_ISuperVaultAggregator.TransactOpts, strategy, newManager)
}

// ProposeGlobalHooksRoot is a paid mutator transaction binding the contract method 0xb0e5173b.
//
// Solidity: function proposeGlobalHooksRoot(bytes32 newRoot) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) ProposeGlobalHooksRoot(opts *bind.TransactOpts, newRoot [32]byte) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "proposeGlobalHooksRoot", newRoot)
}

// ProposeGlobalHooksRoot is a paid mutator transaction binding the contract method 0xb0e5173b.
//
// Solidity: function proposeGlobalHooksRoot(bytes32 newRoot) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) ProposeGlobalHooksRoot(newRoot [32]byte) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ProposeGlobalHooksRoot(&_ISuperVaultAggregator.TransactOpts, newRoot)
}

// ProposeGlobalHooksRoot is a paid mutator transaction binding the contract method 0xb0e5173b.
//
// Solidity: function proposeGlobalHooksRoot(bytes32 newRoot) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) ProposeGlobalHooksRoot(newRoot [32]byte) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ProposeGlobalHooksRoot(&_ISuperVaultAggregator.TransactOpts, newRoot)
}

// ProposeStrategyHooksRoot is a paid mutator transaction binding the contract method 0x5e12b2db.
//
// Solidity: function proposeStrategyHooksRoot(address strategy, bytes32 newRoot) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) ProposeStrategyHooksRoot(opts *bind.TransactOpts, strategy common.Address, newRoot [32]byte) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "proposeStrategyHooksRoot", strategy, newRoot)
}

// ProposeStrategyHooksRoot is a paid mutator transaction binding the contract method 0x5e12b2db.
//
// Solidity: function proposeStrategyHooksRoot(address strategy, bytes32 newRoot) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) ProposeStrategyHooksRoot(strategy common.Address, newRoot [32]byte) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ProposeStrategyHooksRoot(&_ISuperVaultAggregator.TransactOpts, strategy, newRoot)
}

// ProposeStrategyHooksRoot is a paid mutator transaction binding the contract method 0x5e12b2db.
//
// Solidity: function proposeStrategyHooksRoot(address strategy, bytes32 newRoot) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) ProposeStrategyHooksRoot(strategy common.Address, newRoot [32]byte) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.ProposeStrategyHooksRoot(&_ISuperVaultAggregator.TransactOpts, strategy, newRoot)
}

// RemoveAuthorizedCaller is a paid mutator transaction binding the contract method 0x4e179bce.
//
// Solidity: function removeAuthorizedCaller(address strategy, address caller) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) RemoveAuthorizedCaller(opts *bind.TransactOpts, strategy common.Address, caller common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "removeAuthorizedCaller", strategy, caller)
}

// RemoveAuthorizedCaller is a paid mutator transaction binding the contract method 0x4e179bce.
//
// Solidity: function removeAuthorizedCaller(address strategy, address caller) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) RemoveAuthorizedCaller(strategy common.Address, caller common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.RemoveAuthorizedCaller(&_ISuperVaultAggregator.TransactOpts, strategy, caller)
}

// RemoveAuthorizedCaller is a paid mutator transaction binding the contract method 0x4e179bce.
//
// Solidity: function removeAuthorizedCaller(address strategy, address caller) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) RemoveAuthorizedCaller(strategy common.Address, caller common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.RemoveAuthorizedCaller(&_ISuperVaultAggregator.TransactOpts, strategy, caller)
}

// RemoveSecondaryManager is a paid mutator transaction binding the contract method 0x3c248029.
//
// Solidity: function removeSecondaryManager(address strategy, address manager) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) RemoveSecondaryManager(opts *bind.TransactOpts, strategy common.Address, manager common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "removeSecondaryManager", strategy, manager)
}

// RemoveSecondaryManager is a paid mutator transaction binding the contract method 0x3c248029.
//
// Solidity: function removeSecondaryManager(address strategy, address manager) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) RemoveSecondaryManager(strategy common.Address, manager common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.RemoveSecondaryManager(&_ISuperVaultAggregator.TransactOpts, strategy, manager)
}

// RemoveSecondaryManager is a paid mutator transaction binding the contract method 0x3c248029.
//
// Solidity: function removeSecondaryManager(address strategy, address manager) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) RemoveSecondaryManager(strategy common.Address, manager common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.RemoveSecondaryManager(&_ISuperVaultAggregator.TransactOpts, strategy, manager)
}

// RequestStakeWithdrawal is a paid mutator transaction binding the contract method 0x21a081de.
//
// Solidity: function requestStakeWithdrawal(uint256 amount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) RequestStakeWithdrawal(opts *bind.TransactOpts, amount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "requestStakeWithdrawal", amount)
}

// RequestStakeWithdrawal is a paid mutator transaction binding the contract method 0x21a081de.
//
// Solidity: function requestStakeWithdrawal(uint256 amount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) RequestStakeWithdrawal(amount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.RequestStakeWithdrawal(&_ISuperVaultAggregator.TransactOpts, amount)
}

// RequestStakeWithdrawal is a paid mutator transaction binding the contract method 0x21a081de.
//
// Solidity: function requestStakeWithdrawal(uint256 amount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) RequestStakeWithdrawal(amount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.RequestStakeWithdrawal(&_ISuperVaultAggregator.TransactOpts, amount)
}

// SetGlobalHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xd5f3cd86.
//
// Solidity: function setGlobalHooksRootVetoStatus(bool vetoed) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) SetGlobalHooksRootVetoStatus(opts *bind.TransactOpts, vetoed bool) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "setGlobalHooksRootVetoStatus", vetoed)
}

// SetGlobalHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xd5f3cd86.
//
// Solidity: function setGlobalHooksRootVetoStatus(bool vetoed) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) SetGlobalHooksRootVetoStatus(vetoed bool) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.SetGlobalHooksRootVetoStatus(&_ISuperVaultAggregator.TransactOpts, vetoed)
}

// SetGlobalHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xd5f3cd86.
//
// Solidity: function setGlobalHooksRootVetoStatus(bool vetoed) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) SetGlobalHooksRootVetoStatus(vetoed bool) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.SetGlobalHooksRootVetoStatus(&_ISuperVaultAggregator.TransactOpts, vetoed)
}

// SetHooksRootUpdateTimelock is a paid mutator transaction binding the contract method 0x272b7add.
//
// Solidity: function setHooksRootUpdateTimelock(uint256 newTimelock) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) SetHooksRootUpdateTimelock(opts *bind.TransactOpts, newTimelock *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "setHooksRootUpdateTimelock", newTimelock)
}

// SetHooksRootUpdateTimelock is a paid mutator transaction binding the contract method 0x272b7add.
//
// Solidity: function setHooksRootUpdateTimelock(uint256 newTimelock) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) SetHooksRootUpdateTimelock(newTimelock *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.SetHooksRootUpdateTimelock(&_ISuperVaultAggregator.TransactOpts, newTimelock)
}

// SetHooksRootUpdateTimelock is a paid mutator transaction binding the contract method 0x272b7add.
//
// Solidity: function setHooksRootUpdateTimelock(uint256 newTimelock) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) SetHooksRootUpdateTimelock(newTimelock *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.SetHooksRootUpdateTimelock(&_ISuperVaultAggregator.TransactOpts, newTimelock)
}

// SetStrategyHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xf5297a47.
//
// Solidity: function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) SetStrategyHooksRootVetoStatus(opts *bind.TransactOpts, strategy common.Address, vetoed bool) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "setStrategyHooksRootVetoStatus", strategy, vetoed)
}

// SetStrategyHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xf5297a47.
//
// Solidity: function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) SetStrategyHooksRootVetoStatus(strategy common.Address, vetoed bool) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.SetStrategyHooksRootVetoStatus(&_ISuperVaultAggregator.TransactOpts, strategy, vetoed)
}

// SetStrategyHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xf5297a47.
//
// Solidity: function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) SetStrategyHooksRootVetoStatus(strategy common.Address, vetoed bool) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.SetStrategyHooksRootVetoStatus(&_ISuperVaultAggregator.TransactOpts, strategy, vetoed)
}

// SlashStake is a paid mutator transaction binding the contract method 0x98d1c5a8.
//
// Solidity: function slashStake(address manager, uint256 amount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) SlashStake(opts *bind.TransactOpts, manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "slashStake", manager, amount)
}

// SlashStake is a paid mutator transaction binding the contract method 0x98d1c5a8.
//
// Solidity: function slashStake(address manager, uint256 amount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) SlashStake(manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.SlashStake(&_ISuperVaultAggregator.TransactOpts, manager, amount)
}

// SlashStake is a paid mutator transaction binding the contract method 0x98d1c5a8.
//
// Solidity: function slashStake(address manager, uint256 amount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) SlashStake(manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.SlashStake(&_ISuperVaultAggregator.TransactOpts, manager, amount)
}

// UnpauseStrategy is a paid mutator transaction binding the contract method 0x0ff323a3.
//
// Solidity: function unpauseStrategy(address strategy) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) UnpauseStrategy(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "unpauseStrategy", strategy)
}

// UnpauseStrategy is a paid mutator transaction binding the contract method 0x0ff323a3.
//
// Solidity: function unpauseStrategy(address strategy) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) UnpauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.UnpauseStrategy(&_ISuperVaultAggregator.TransactOpts, strategy)
}

// UnpauseStrategy is a paid mutator transaction binding the contract method 0x0ff323a3.
//
// Solidity: function unpauseStrategy(address strategy) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) UnpauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.UnpauseStrategy(&_ISuperVaultAggregator.TransactOpts, strategy)
}

// UpdatePPSAfterSkim is a paid mutator transaction binding the contract method 0x12e1ac5a.
//
// Solidity: function updatePPSAfterSkim(uint256 newPPS, uint256 feeAmount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) UpdatePPSAfterSkim(opts *bind.TransactOpts, newPPS *big.Int, feeAmount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "updatePPSAfterSkim", newPPS, feeAmount)
}

// UpdatePPSAfterSkim is a paid mutator transaction binding the contract method 0x12e1ac5a.
//
// Solidity: function updatePPSAfterSkim(uint256 newPPS, uint256 feeAmount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) UpdatePPSAfterSkim(newPPS *big.Int, feeAmount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.UpdatePPSAfterSkim(&_ISuperVaultAggregator.TransactOpts, newPPS, feeAmount)
}

// UpdatePPSAfterSkim is a paid mutator transaction binding the contract method 0x12e1ac5a.
//
// Solidity: function updatePPSAfterSkim(uint256 newPPS, uint256 feeAmount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) UpdatePPSAfterSkim(newPPS *big.Int, feeAmount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.UpdatePPSAfterSkim(&_ISuperVaultAggregator.TransactOpts, newPPS, feeAmount)
}

// UpdatePPSVerificationThresholds is a paid mutator transaction binding the contract method 0x7e55f6a5.
//
// Solidity: function updatePPSVerificationThresholds(address strategy, uint256 deviationThreshold_, uint256 mnThreshold_) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) UpdatePPSVerificationThresholds(opts *bind.TransactOpts, strategy common.Address, deviationThreshold_ *big.Int, mnThreshold_ *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "updatePPSVerificationThresholds", strategy, deviationThreshold_, mnThreshold_)
}

// UpdatePPSVerificationThresholds is a paid mutator transaction binding the contract method 0x7e55f6a5.
//
// Solidity: function updatePPSVerificationThresholds(address strategy, uint256 deviationThreshold_, uint256 mnThreshold_) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) UpdatePPSVerificationThresholds(strategy common.Address, deviationThreshold_ *big.Int, mnThreshold_ *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.UpdatePPSVerificationThresholds(&_ISuperVaultAggregator.TransactOpts, strategy, deviationThreshold_, mnThreshold_)
}

// UpdatePPSVerificationThresholds is a paid mutator transaction binding the contract method 0x7e55f6a5.
//
// Solidity: function updatePPSVerificationThresholds(address strategy, uint256 deviationThreshold_, uint256 mnThreshold_) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) UpdatePPSVerificationThresholds(strategy common.Address, deviationThreshold_ *big.Int, mnThreshold_ *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.UpdatePPSVerificationThresholds(&_ISuperVaultAggregator.TransactOpts, strategy, deviationThreshold_, mnThreshold_)
}

// WithdrawUpkeep is a paid mutator transaction binding the contract method 0x4b0b8aa6.
//
// Solidity: function withdrawUpkeep(uint256 amount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactor) WithdrawUpkeep(opts *bind.TransactOpts, amount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.contract.Transact(opts, "withdrawUpkeep", amount)
}

// WithdrawUpkeep is a paid mutator transaction binding the contract method 0x4b0b8aa6.
//
// Solidity: function withdrawUpkeep(uint256 amount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorSession) WithdrawUpkeep(amount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.WithdrawUpkeep(&_ISuperVaultAggregator.TransactOpts, amount)
}

// WithdrawUpkeep is a paid mutator transaction binding the contract method 0x4b0b8aa6.
//
// Solidity: function withdrawUpkeep(uint256 amount) returns()
func (_ISuperVaultAggregator *ISuperVaultAggregatorTransactorSession) WithdrawUpkeep(amount *big.Int) (*types.Transaction, error) {
	return _ISuperVaultAggregator.Contract.WithdrawUpkeep(&_ISuperVaultAggregator.TransactOpts, amount)
}

// ISuperVaultAggregatorAuthorizedCallerIterator is returned from FilterAuthorizedCaller and is used to iterate over the raw logs and unpacked data for AuthorizedCaller events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorAuthorizedCallerIterator struct {
	Event *ISuperVaultAggregatorAuthorizedCaller // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorAuthorizedCallerIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorAuthorizedCaller)
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
		it.Event = new(ISuperVaultAggregatorAuthorizedCaller)
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
func (it *ISuperVaultAggregatorAuthorizedCallerIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorAuthorizedCallerIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorAuthorizedCaller represents a AuthorizedCaller event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorAuthorizedCaller struct {
	Strategy common.Address
	Caller   common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterAuthorizedCaller is a free log retrieval operation binding the contract event 0x1c9c420420e76ae7ad733b7098eb1fa04a2293da0cfbd31297ea505568760ebc.
//
// Solidity: event AuthorizedCaller(address indexed strategy, address indexed caller)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterAuthorizedCaller(opts *bind.FilterOpts, strategy []common.Address, caller []common.Address) (*ISuperVaultAggregatorAuthorizedCallerIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "AuthorizedCaller", strategyRule, callerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorAuthorizedCallerIterator{contract: _ISuperVaultAggregator.contract, event: "AuthorizedCaller", logs: logs, sub: sub}, nil
}

// WatchAuthorizedCaller is a free log subscription operation binding the contract event 0x1c9c420420e76ae7ad733b7098eb1fa04a2293da0cfbd31297ea505568760ebc.
//
// Solidity: event AuthorizedCaller(address indexed strategy, address indexed caller)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchAuthorizedCaller(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorAuthorizedCaller, strategy []common.Address, caller []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "AuthorizedCaller", strategyRule, callerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorAuthorizedCaller)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "AuthorizedCaller", log); err != nil {
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

// ParseAuthorizedCaller is a log parse operation binding the contract event 0x1c9c420420e76ae7ad733b7098eb1fa04a2293da0cfbd31297ea505568760ebc.
//
// Solidity: event AuthorizedCaller(address indexed strategy, address indexed caller)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseAuthorizedCaller(log types.Log) (*ISuperVaultAggregatorAuthorizedCaller, error) {
	event := new(ISuperVaultAggregatorAuthorizedCaller)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "AuthorizedCaller", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorAuthorizedCallerAddedIterator is returned from FilterAuthorizedCallerAdded and is used to iterate over the raw logs and unpacked data for AuthorizedCallerAdded events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorAuthorizedCallerAddedIterator struct {
	Event *ISuperVaultAggregatorAuthorizedCallerAdded // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorAuthorizedCallerAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorAuthorizedCallerAdded)
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
		it.Event = new(ISuperVaultAggregatorAuthorizedCallerAdded)
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
func (it *ISuperVaultAggregatorAuthorizedCallerAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorAuthorizedCallerAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorAuthorizedCallerAdded represents a AuthorizedCallerAdded event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorAuthorizedCallerAdded struct {
	Strategy common.Address
	Caller   common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterAuthorizedCallerAdded is a free log retrieval operation binding the contract event 0xde6b6315e31236a6504cb4a4fa3ccc32947e648ce1f188687e0711f55ec418b0.
//
// Solidity: event AuthorizedCallerAdded(address indexed strategy, address indexed caller)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterAuthorizedCallerAdded(opts *bind.FilterOpts, strategy []common.Address, caller []common.Address) (*ISuperVaultAggregatorAuthorizedCallerAddedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "AuthorizedCallerAdded", strategyRule, callerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorAuthorizedCallerAddedIterator{contract: _ISuperVaultAggregator.contract, event: "AuthorizedCallerAdded", logs: logs, sub: sub}, nil
}

// WatchAuthorizedCallerAdded is a free log subscription operation binding the contract event 0xde6b6315e31236a6504cb4a4fa3ccc32947e648ce1f188687e0711f55ec418b0.
//
// Solidity: event AuthorizedCallerAdded(address indexed strategy, address indexed caller)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchAuthorizedCallerAdded(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorAuthorizedCallerAdded, strategy []common.Address, caller []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "AuthorizedCallerAdded", strategyRule, callerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorAuthorizedCallerAdded)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "AuthorizedCallerAdded", log); err != nil {
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

// ParseAuthorizedCallerAdded is a log parse operation binding the contract event 0xde6b6315e31236a6504cb4a4fa3ccc32947e648ce1f188687e0711f55ec418b0.
//
// Solidity: event AuthorizedCallerAdded(address indexed strategy, address indexed caller)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseAuthorizedCallerAdded(log types.Log) (*ISuperVaultAggregatorAuthorizedCallerAdded, error) {
	event := new(ISuperVaultAggregatorAuthorizedCallerAdded)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "AuthorizedCallerAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorAuthorizedCallerRemovedIterator is returned from FilterAuthorizedCallerRemoved and is used to iterate over the raw logs and unpacked data for AuthorizedCallerRemoved events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorAuthorizedCallerRemovedIterator struct {
	Event *ISuperVaultAggregatorAuthorizedCallerRemoved // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorAuthorizedCallerRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorAuthorizedCallerRemoved)
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
		it.Event = new(ISuperVaultAggregatorAuthorizedCallerRemoved)
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
func (it *ISuperVaultAggregatorAuthorizedCallerRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorAuthorizedCallerRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorAuthorizedCallerRemoved represents a AuthorizedCallerRemoved event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorAuthorizedCallerRemoved struct {
	Strategy common.Address
	Caller   common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterAuthorizedCallerRemoved is a free log retrieval operation binding the contract event 0xd175903e18897b59f1dec5589010cd32eb1cb6d795239d0d79159089bfd4f52a.
//
// Solidity: event AuthorizedCallerRemoved(address indexed strategy, address indexed caller)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterAuthorizedCallerRemoved(opts *bind.FilterOpts, strategy []common.Address, caller []common.Address) (*ISuperVaultAggregatorAuthorizedCallerRemovedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "AuthorizedCallerRemoved", strategyRule, callerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorAuthorizedCallerRemovedIterator{contract: _ISuperVaultAggregator.contract, event: "AuthorizedCallerRemoved", logs: logs, sub: sub}, nil
}

// WatchAuthorizedCallerRemoved is a free log subscription operation binding the contract event 0xd175903e18897b59f1dec5589010cd32eb1cb6d795239d0d79159089bfd4f52a.
//
// Solidity: event AuthorizedCallerRemoved(address indexed strategy, address indexed caller)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchAuthorizedCallerRemoved(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorAuthorizedCallerRemoved, strategy []common.Address, caller []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "AuthorizedCallerRemoved", strategyRule, callerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorAuthorizedCallerRemoved)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "AuthorizedCallerRemoved", log); err != nil {
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

// ParseAuthorizedCallerRemoved is a log parse operation binding the contract event 0xd175903e18897b59f1dec5589010cd32eb1cb6d795239d0d79159089bfd4f52a.
//
// Solidity: event AuthorizedCallerRemoved(address indexed strategy, address indexed caller)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseAuthorizedCallerRemoved(log types.Log) (*ISuperVaultAggregatorAuthorizedCallerRemoved, error) {
	event := new(ISuperVaultAggregatorAuthorizedCallerRemoved)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "AuthorizedCallerRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorGlobalHooksRootUpdateProposedIterator is returned from FilterGlobalHooksRootUpdateProposed and is used to iterate over the raw logs and unpacked data for GlobalHooksRootUpdateProposed events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorGlobalHooksRootUpdateProposedIterator struct {
	Event *ISuperVaultAggregatorGlobalHooksRootUpdateProposed // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorGlobalHooksRootUpdateProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorGlobalHooksRootUpdateProposed)
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
		it.Event = new(ISuperVaultAggregatorGlobalHooksRootUpdateProposed)
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
func (it *ISuperVaultAggregatorGlobalHooksRootUpdateProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorGlobalHooksRootUpdateProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorGlobalHooksRootUpdateProposed represents a GlobalHooksRootUpdateProposed event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorGlobalHooksRootUpdateProposed struct {
	Root          [32]byte
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterGlobalHooksRootUpdateProposed is a free log retrieval operation binding the contract event 0x71e72baaa2bffcb51d34de71bba7ea258c9c5667a86e69b1c684f0e1ecb4f395.
//
// Solidity: event GlobalHooksRootUpdateProposed(bytes32 indexed root, uint256 effectiveTime)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterGlobalHooksRootUpdateProposed(opts *bind.FilterOpts, root [][32]byte) (*ISuperVaultAggregatorGlobalHooksRootUpdateProposedIterator, error) {

	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "GlobalHooksRootUpdateProposed", rootRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorGlobalHooksRootUpdateProposedIterator{contract: _ISuperVaultAggregator.contract, event: "GlobalHooksRootUpdateProposed", logs: logs, sub: sub}, nil
}

// WatchGlobalHooksRootUpdateProposed is a free log subscription operation binding the contract event 0x71e72baaa2bffcb51d34de71bba7ea258c9c5667a86e69b1c684f0e1ecb4f395.
//
// Solidity: event GlobalHooksRootUpdateProposed(bytes32 indexed root, uint256 effectiveTime)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchGlobalHooksRootUpdateProposed(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorGlobalHooksRootUpdateProposed, root [][32]byte) (event.Subscription, error) {

	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "GlobalHooksRootUpdateProposed", rootRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorGlobalHooksRootUpdateProposed)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootUpdateProposed", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseGlobalHooksRootUpdateProposed(log types.Log) (*ISuperVaultAggregatorGlobalHooksRootUpdateProposed, error) {
	event := new(ISuperVaultAggregatorGlobalHooksRootUpdateProposed)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootUpdateProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorGlobalHooksRootUpdatedIterator is returned from FilterGlobalHooksRootUpdated and is used to iterate over the raw logs and unpacked data for GlobalHooksRootUpdated events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorGlobalHooksRootUpdatedIterator struct {
	Event *ISuperVaultAggregatorGlobalHooksRootUpdated // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorGlobalHooksRootUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorGlobalHooksRootUpdated)
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
		it.Event = new(ISuperVaultAggregatorGlobalHooksRootUpdated)
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
func (it *ISuperVaultAggregatorGlobalHooksRootUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorGlobalHooksRootUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorGlobalHooksRootUpdated represents a GlobalHooksRootUpdated event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorGlobalHooksRootUpdated struct {
	OldRoot [32]byte
	NewRoot [32]byte
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterGlobalHooksRootUpdated is a free log retrieval operation binding the contract event 0x0360da73fad480d9a31212f8337d4a576e6b9749d68fc663acf171bb07f950ba.
//
// Solidity: event GlobalHooksRootUpdated(bytes32 indexed oldRoot, bytes32 newRoot)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterGlobalHooksRootUpdated(opts *bind.FilterOpts, oldRoot [][32]byte) (*ISuperVaultAggregatorGlobalHooksRootUpdatedIterator, error) {

	var oldRootRule []interface{}
	for _, oldRootItem := range oldRoot {
		oldRootRule = append(oldRootRule, oldRootItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "GlobalHooksRootUpdated", oldRootRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorGlobalHooksRootUpdatedIterator{contract: _ISuperVaultAggregator.contract, event: "GlobalHooksRootUpdated", logs: logs, sub: sub}, nil
}

// WatchGlobalHooksRootUpdated is a free log subscription operation binding the contract event 0x0360da73fad480d9a31212f8337d4a576e6b9749d68fc663acf171bb07f950ba.
//
// Solidity: event GlobalHooksRootUpdated(bytes32 indexed oldRoot, bytes32 newRoot)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchGlobalHooksRootUpdated(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorGlobalHooksRootUpdated, oldRoot [][32]byte) (event.Subscription, error) {

	var oldRootRule []interface{}
	for _, oldRootItem := range oldRoot {
		oldRootRule = append(oldRootRule, oldRootItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "GlobalHooksRootUpdated", oldRootRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorGlobalHooksRootUpdated)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootUpdated", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseGlobalHooksRootUpdated(log types.Log) (*ISuperVaultAggregatorGlobalHooksRootUpdated, error) {
	event := new(ISuperVaultAggregatorGlobalHooksRootUpdated)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator is returned from FilterGlobalHooksRootVetoStatusChanged and is used to iterate over the raw logs and unpacked data for GlobalHooksRootVetoStatusChanged events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator struct {
	Event *ISuperVaultAggregatorGlobalHooksRootVetoStatusChanged // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorGlobalHooksRootVetoStatusChanged)
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
		it.Event = new(ISuperVaultAggregatorGlobalHooksRootVetoStatusChanged)
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
func (it *ISuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorGlobalHooksRootVetoStatusChanged represents a GlobalHooksRootVetoStatusChanged event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorGlobalHooksRootVetoStatusChanged struct {
	Vetoed bool
	Root   [32]byte
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterGlobalHooksRootVetoStatusChanged is a free log retrieval operation binding the contract event 0xd867c555762bc6e6e6c9f80aa6c8132ccc5909f83266bc4d24489c8aa10e5e8d.
//
// Solidity: event GlobalHooksRootVetoStatusChanged(bool vetoed, bytes32 indexed root)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterGlobalHooksRootVetoStatusChanged(opts *bind.FilterOpts, root [][32]byte) (*ISuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator, error) {

	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "GlobalHooksRootVetoStatusChanged", rootRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator{contract: _ISuperVaultAggregator.contract, event: "GlobalHooksRootVetoStatusChanged", logs: logs, sub: sub}, nil
}

// WatchGlobalHooksRootVetoStatusChanged is a free log subscription operation binding the contract event 0xd867c555762bc6e6e6c9f80aa6c8132ccc5909f83266bc4d24489c8aa10e5e8d.
//
// Solidity: event GlobalHooksRootVetoStatusChanged(bool vetoed, bytes32 indexed root)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchGlobalHooksRootVetoStatusChanged(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorGlobalHooksRootVetoStatusChanged, root [][32]byte) (event.Subscription, error) {

	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "GlobalHooksRootVetoStatusChanged", rootRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorGlobalHooksRootVetoStatusChanged)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootVetoStatusChanged", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseGlobalHooksRootVetoStatusChanged(log types.Log) (*ISuperVaultAggregatorGlobalHooksRootVetoStatusChanged, error) {
	event := new(ISuperVaultAggregatorGlobalHooksRootVetoStatusChanged)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootVetoStatusChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorGlobalHooksRootVetoedIterator is returned from FilterGlobalHooksRootVetoed and is used to iterate over the raw logs and unpacked data for GlobalHooksRootVetoed events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorGlobalHooksRootVetoedIterator struct {
	Event *ISuperVaultAggregatorGlobalHooksRootVetoed // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorGlobalHooksRootVetoedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorGlobalHooksRootVetoed)
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
		it.Event = new(ISuperVaultAggregatorGlobalHooksRootVetoed)
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
func (it *ISuperVaultAggregatorGlobalHooksRootVetoedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorGlobalHooksRootVetoedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorGlobalHooksRootVetoed represents a GlobalHooksRootVetoed event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorGlobalHooksRootVetoed struct {
	Guardian common.Address
	Root     [32]byte
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterGlobalHooksRootVetoed is a free log retrieval operation binding the contract event 0x26c1ad46cb7f3649d1025e06bdbe8fc101891e84299550e6e28b5b5c62e09ec3.
//
// Solidity: event GlobalHooksRootVetoed(address indexed guardian, bytes32 indexed root)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterGlobalHooksRootVetoed(opts *bind.FilterOpts, guardian []common.Address, root [][32]byte) (*ISuperVaultAggregatorGlobalHooksRootVetoedIterator, error) {

	var guardianRule []interface{}
	for _, guardianItem := range guardian {
		guardianRule = append(guardianRule, guardianItem)
	}
	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "GlobalHooksRootVetoed", guardianRule, rootRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorGlobalHooksRootVetoedIterator{contract: _ISuperVaultAggregator.contract, event: "GlobalHooksRootVetoed", logs: logs, sub: sub}, nil
}

// WatchGlobalHooksRootVetoed is a free log subscription operation binding the contract event 0x26c1ad46cb7f3649d1025e06bdbe8fc101891e84299550e6e28b5b5c62e09ec3.
//
// Solidity: event GlobalHooksRootVetoed(address indexed guardian, bytes32 indexed root)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchGlobalHooksRootVetoed(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorGlobalHooksRootVetoed, guardian []common.Address, root [][32]byte) (event.Subscription, error) {

	var guardianRule []interface{}
	for _, guardianItem := range guardian {
		guardianRule = append(guardianRule, guardianItem)
	}
	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "GlobalHooksRootVetoed", guardianRule, rootRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorGlobalHooksRootVetoed)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootVetoed", log); err != nil {
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

// ParseGlobalHooksRootVetoed is a log parse operation binding the contract event 0x26c1ad46cb7f3649d1025e06bdbe8fc101891e84299550e6e28b5b5c62e09ec3.
//
// Solidity: event GlobalHooksRootVetoed(address indexed guardian, bytes32 indexed root)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseGlobalHooksRootVetoed(log types.Log) (*ISuperVaultAggregatorGlobalHooksRootVetoed, error) {
	event := new(ISuperVaultAggregatorGlobalHooksRootVetoed)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootVetoed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorGlobalLeavesStatusChangedIterator is returned from FilterGlobalLeavesStatusChanged and is used to iterate over the raw logs and unpacked data for GlobalLeavesStatusChanged events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorGlobalLeavesStatusChangedIterator struct {
	Event *ISuperVaultAggregatorGlobalLeavesStatusChanged // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorGlobalLeavesStatusChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorGlobalLeavesStatusChanged)
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
		it.Event = new(ISuperVaultAggregatorGlobalLeavesStatusChanged)
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
func (it *ISuperVaultAggregatorGlobalLeavesStatusChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorGlobalLeavesStatusChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorGlobalLeavesStatusChanged represents a GlobalLeavesStatusChanged event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorGlobalLeavesStatusChanged struct {
	Strategy common.Address
	Leaves   [][32]byte
	Statuses []bool
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterGlobalLeavesStatusChanged is a free log retrieval operation binding the contract event 0x671df22165975c9055ff482eedb4963e75f35ac9f3040346699bd97228a8c790.
//
// Solidity: event GlobalLeavesStatusChanged(address indexed strategy, bytes32[] leaves, bool[] statuses)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterGlobalLeavesStatusChanged(opts *bind.FilterOpts, strategy []common.Address) (*ISuperVaultAggregatorGlobalLeavesStatusChangedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "GlobalLeavesStatusChanged", strategyRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorGlobalLeavesStatusChangedIterator{contract: _ISuperVaultAggregator.contract, event: "GlobalLeavesStatusChanged", logs: logs, sub: sub}, nil
}

// WatchGlobalLeavesStatusChanged is a free log subscription operation binding the contract event 0x671df22165975c9055ff482eedb4963e75f35ac9f3040346699bd97228a8c790.
//
// Solidity: event GlobalLeavesStatusChanged(address indexed strategy, bytes32[] leaves, bool[] statuses)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchGlobalLeavesStatusChanged(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorGlobalLeavesStatusChanged, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "GlobalLeavesStatusChanged", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorGlobalLeavesStatusChanged)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "GlobalLeavesStatusChanged", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseGlobalLeavesStatusChanged(log types.Log) (*ISuperVaultAggregatorGlobalLeavesStatusChanged, error) {
	event := new(ISuperVaultAggregatorGlobalLeavesStatusChanged)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "GlobalLeavesStatusChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorHooksRootUpdateTimelockChangedIterator is returned from FilterHooksRootUpdateTimelockChanged and is used to iterate over the raw logs and unpacked data for HooksRootUpdateTimelockChanged events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorHooksRootUpdateTimelockChangedIterator struct {
	Event *ISuperVaultAggregatorHooksRootUpdateTimelockChanged // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorHooksRootUpdateTimelockChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorHooksRootUpdateTimelockChanged)
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
		it.Event = new(ISuperVaultAggregatorHooksRootUpdateTimelockChanged)
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
func (it *ISuperVaultAggregatorHooksRootUpdateTimelockChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorHooksRootUpdateTimelockChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorHooksRootUpdateTimelockChanged represents a HooksRootUpdateTimelockChanged event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorHooksRootUpdateTimelockChanged struct {
	NewTimelock *big.Int
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterHooksRootUpdateTimelockChanged is a free log retrieval operation binding the contract event 0x132309f91d275ae9cafe2088eea8945ed3b52dac1012d3be4a6e44622488a4f6.
//
// Solidity: event HooksRootUpdateTimelockChanged(uint256 newTimelock)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterHooksRootUpdateTimelockChanged(opts *bind.FilterOpts) (*ISuperVaultAggregatorHooksRootUpdateTimelockChangedIterator, error) {

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "HooksRootUpdateTimelockChanged")
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorHooksRootUpdateTimelockChangedIterator{contract: _ISuperVaultAggregator.contract, event: "HooksRootUpdateTimelockChanged", logs: logs, sub: sub}, nil
}

// WatchHooksRootUpdateTimelockChanged is a free log subscription operation binding the contract event 0x132309f91d275ae9cafe2088eea8945ed3b52dac1012d3be4a6e44622488a4f6.
//
// Solidity: event HooksRootUpdateTimelockChanged(uint256 newTimelock)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchHooksRootUpdateTimelockChanged(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorHooksRootUpdateTimelockChanged) (event.Subscription, error) {

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "HooksRootUpdateTimelockChanged")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorHooksRootUpdateTimelockChanged)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "HooksRootUpdateTimelockChanged", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseHooksRootUpdateTimelockChanged(log types.Log) (*ISuperVaultAggregatorHooksRootUpdateTimelockChanged, error) {
	event := new(ISuperVaultAggregatorHooksRootUpdateTimelockChanged)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "HooksRootUpdateTimelockChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorInsufficientUpkeepIterator is returned from FilterInsufficientUpkeep and is used to iterate over the raw logs and unpacked data for InsufficientUpkeep events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorInsufficientUpkeepIterator struct {
	Event *ISuperVaultAggregatorInsufficientUpkeep // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorInsufficientUpkeepIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorInsufficientUpkeep)
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
		it.Event = new(ISuperVaultAggregatorInsufficientUpkeep)
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
func (it *ISuperVaultAggregatorInsufficientUpkeepIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorInsufficientUpkeepIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorInsufficientUpkeep represents a InsufficientUpkeep event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorInsufficientUpkeep struct {
	Strategy common.Address
	Manager  common.Address
	Balance  *big.Int
	Cost     *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterInsufficientUpkeep is a free log retrieval operation binding the contract event 0x9f17e0625b7890f465cad6295db4c1abad9d5afeea38a1d7d64f390aef73a770.
//
// Solidity: event InsufficientUpkeep(address indexed strategy, address indexed manager, uint256 balance, uint256 cost)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterInsufficientUpkeep(opts *bind.FilterOpts, strategy []common.Address, manager []common.Address) (*ISuperVaultAggregatorInsufficientUpkeepIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "InsufficientUpkeep", strategyRule, managerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorInsufficientUpkeepIterator{contract: _ISuperVaultAggregator.contract, event: "InsufficientUpkeep", logs: logs, sub: sub}, nil
}

// WatchInsufficientUpkeep is a free log subscription operation binding the contract event 0x9f17e0625b7890f465cad6295db4c1abad9d5afeea38a1d7d64f390aef73a770.
//
// Solidity: event InsufficientUpkeep(address indexed strategy, address indexed manager, uint256 balance, uint256 cost)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchInsufficientUpkeep(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorInsufficientUpkeep, strategy []common.Address, manager []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "InsufficientUpkeep", strategyRule, managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorInsufficientUpkeep)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "InsufficientUpkeep", log); err != nil {
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
// Solidity: event InsufficientUpkeep(address indexed strategy, address indexed manager, uint256 balance, uint256 cost)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseInsufficientUpkeep(log types.Log) (*ISuperVaultAggregatorInsufficientUpkeep, error) {
	event := new(ISuperVaultAggregatorInsufficientUpkeep)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "InsufficientUpkeep", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorOldPrimaryManagerRemovedIterator is returned from FilterOldPrimaryManagerRemoved and is used to iterate over the raw logs and unpacked data for OldPrimaryManagerRemoved events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorOldPrimaryManagerRemovedIterator struct {
	Event *ISuperVaultAggregatorOldPrimaryManagerRemoved // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorOldPrimaryManagerRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorOldPrimaryManagerRemoved)
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
		it.Event = new(ISuperVaultAggregatorOldPrimaryManagerRemoved)
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
func (it *ISuperVaultAggregatorOldPrimaryManagerRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorOldPrimaryManagerRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorOldPrimaryManagerRemoved represents a OldPrimaryManagerRemoved event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorOldPrimaryManagerRemoved struct {
	Strategy   common.Address
	OldManager common.Address
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterOldPrimaryManagerRemoved is a free log retrieval operation binding the contract event 0x744302e838f7c0c35e8971c67d7229a331a29eb270e24b7ceb261658ac679f6d.
//
// Solidity: event OldPrimaryManagerRemoved(address indexed strategy, address indexed oldManager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterOldPrimaryManagerRemoved(opts *bind.FilterOpts, strategy []common.Address, oldManager []common.Address) (*ISuperVaultAggregatorOldPrimaryManagerRemovedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var oldManagerRule []interface{}
	for _, oldManagerItem := range oldManager {
		oldManagerRule = append(oldManagerRule, oldManagerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "OldPrimaryManagerRemoved", strategyRule, oldManagerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorOldPrimaryManagerRemovedIterator{contract: _ISuperVaultAggregator.contract, event: "OldPrimaryManagerRemoved", logs: logs, sub: sub}, nil
}

// WatchOldPrimaryManagerRemoved is a free log subscription operation binding the contract event 0x744302e838f7c0c35e8971c67d7229a331a29eb270e24b7ceb261658ac679f6d.
//
// Solidity: event OldPrimaryManagerRemoved(address indexed strategy, address indexed oldManager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchOldPrimaryManagerRemoved(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorOldPrimaryManagerRemoved, strategy []common.Address, oldManager []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var oldManagerRule []interface{}
	for _, oldManagerItem := range oldManager {
		oldManagerRule = append(oldManagerRule, oldManagerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "OldPrimaryManagerRemoved", strategyRule, oldManagerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorOldPrimaryManagerRemoved)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "OldPrimaryManagerRemoved", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseOldPrimaryManagerRemoved(log types.Log) (*ISuperVaultAggregatorOldPrimaryManagerRemoved, error) {
	event := new(ISuperVaultAggregatorOldPrimaryManagerRemoved)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "OldPrimaryManagerRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorPPSUpdatedIterator is returned from FilterPPSUpdated and is used to iterate over the raw logs and unpacked data for PPSUpdated events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorPPSUpdatedIterator struct {
	Event *ISuperVaultAggregatorPPSUpdated // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorPPSUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorPPSUpdated)
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
		it.Event = new(ISuperVaultAggregatorPPSUpdated)
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
func (it *ISuperVaultAggregatorPPSUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorPPSUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorPPSUpdated represents a PPSUpdated event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorPPSUpdated struct {
	Strategy        common.Address
	Pps             *big.Int
	ValidatorSet    *big.Int
	TotalValidators *big.Int
	Timestamp       *big.Int
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterPPSUpdated is a free log retrieval operation binding the contract event 0x6d34c506f5dca7955f1dc32a066710945d4bd7d9f480452cac2ff87766c280b2.
//
// Solidity: event PPSUpdated(address indexed strategy, uint256 pps, uint256 validatorSet, uint256 totalValidators, uint256 timestamp)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterPPSUpdated(opts *bind.FilterOpts, strategy []common.Address) (*ISuperVaultAggregatorPPSUpdatedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "PPSUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorPPSUpdatedIterator{contract: _ISuperVaultAggregator.contract, event: "PPSUpdated", logs: logs, sub: sub}, nil
}

// WatchPPSUpdated is a free log subscription operation binding the contract event 0x6d34c506f5dca7955f1dc32a066710945d4bd7d9f480452cac2ff87766c280b2.
//
// Solidity: event PPSUpdated(address indexed strategy, uint256 pps, uint256 validatorSet, uint256 totalValidators, uint256 timestamp)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchPPSUpdated(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorPPSUpdated, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "PPSUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorPPSUpdated)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "PPSUpdated", log); err != nil {
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

// ParsePPSUpdated is a log parse operation binding the contract event 0x6d34c506f5dca7955f1dc32a066710945d4bd7d9f480452cac2ff87766c280b2.
//
// Solidity: event PPSUpdated(address indexed strategy, uint256 pps, uint256 validatorSet, uint256 totalValidators, uint256 timestamp)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParsePPSUpdated(log types.Log) (*ISuperVaultAggregatorPPSUpdated, error) {
	event := new(ISuperVaultAggregatorPPSUpdated)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "PPSUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorPPSUpdatedAfterSkimIterator is returned from FilterPPSUpdatedAfterSkim and is used to iterate over the raw logs and unpacked data for PPSUpdatedAfterSkim events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorPPSUpdatedAfterSkimIterator struct {
	Event *ISuperVaultAggregatorPPSUpdatedAfterSkim // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorPPSUpdatedAfterSkimIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorPPSUpdatedAfterSkim)
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
		it.Event = new(ISuperVaultAggregatorPPSUpdatedAfterSkim)
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
func (it *ISuperVaultAggregatorPPSUpdatedAfterSkimIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorPPSUpdatedAfterSkimIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorPPSUpdatedAfterSkim represents a PPSUpdatedAfterSkim event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorPPSUpdatedAfterSkim struct {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterPPSUpdatedAfterSkim(opts *bind.FilterOpts, strategy []common.Address) (*ISuperVaultAggregatorPPSUpdatedAfterSkimIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "PPSUpdatedAfterSkim", strategyRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorPPSUpdatedAfterSkimIterator{contract: _ISuperVaultAggregator.contract, event: "PPSUpdatedAfterSkim", logs: logs, sub: sub}, nil
}

// WatchPPSUpdatedAfterSkim is a free log subscription operation binding the contract event 0x482a01d8e596a883e67895d310f80b2c151a445aa5e277325a6499b0be869845.
//
// Solidity: event PPSUpdatedAfterSkim(address indexed strategy, uint256 oldPPS, uint256 newPPS, uint256 feeAmount, uint256 timestamp)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchPPSUpdatedAfterSkim(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorPPSUpdatedAfterSkim, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "PPSUpdatedAfterSkim", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorPPSUpdatedAfterSkim)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "PPSUpdatedAfterSkim", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParsePPSUpdatedAfterSkim(log types.Log) (*ISuperVaultAggregatorPPSUpdatedAfterSkim, error) {
	event := new(ISuperVaultAggregatorPPSUpdatedAfterSkim)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "PPSUpdatedAfterSkim", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorPPSVerificationThresholdsUpdatedIterator is returned from FilterPPSVerificationThresholdsUpdated and is used to iterate over the raw logs and unpacked data for PPSVerificationThresholdsUpdated events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorPPSVerificationThresholdsUpdatedIterator struct {
	Event *ISuperVaultAggregatorPPSVerificationThresholdsUpdated // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorPPSVerificationThresholdsUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorPPSVerificationThresholdsUpdated)
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
		it.Event = new(ISuperVaultAggregatorPPSVerificationThresholdsUpdated)
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
func (it *ISuperVaultAggregatorPPSVerificationThresholdsUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorPPSVerificationThresholdsUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorPPSVerificationThresholdsUpdated represents a PPSVerificationThresholdsUpdated event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorPPSVerificationThresholdsUpdated struct {
	Strategy           common.Address
	DeviationThreshold *big.Int
	MnThreshold        *big.Int
	Raw                types.Log // Blockchain specific contextual infos
}

// FilterPPSVerificationThresholdsUpdated is a free log retrieval operation binding the contract event 0xff3b4a34b9b4b3592103011d68697c6bdb8b60fa282091fae92588a0d4e3562b.
//
// Solidity: event PPSVerificationThresholdsUpdated(address indexed strategy, uint256 deviationThreshold, uint256 mnThreshold)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterPPSVerificationThresholdsUpdated(opts *bind.FilterOpts, strategy []common.Address) (*ISuperVaultAggregatorPPSVerificationThresholdsUpdatedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "PPSVerificationThresholdsUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorPPSVerificationThresholdsUpdatedIterator{contract: _ISuperVaultAggregator.contract, event: "PPSVerificationThresholdsUpdated", logs: logs, sub: sub}, nil
}

// WatchPPSVerificationThresholdsUpdated is a free log subscription operation binding the contract event 0xff3b4a34b9b4b3592103011d68697c6bdb8b60fa282091fae92588a0d4e3562b.
//
// Solidity: event PPSVerificationThresholdsUpdated(address indexed strategy, uint256 deviationThreshold, uint256 mnThreshold)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchPPSVerificationThresholdsUpdated(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorPPSVerificationThresholdsUpdated, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "PPSVerificationThresholdsUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorPPSVerificationThresholdsUpdated)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "PPSVerificationThresholdsUpdated", log); err != nil {
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

// ParsePPSVerificationThresholdsUpdated is a log parse operation binding the contract event 0xff3b4a34b9b4b3592103011d68697c6bdb8b60fa282091fae92588a0d4e3562b.
//
// Solidity: event PPSVerificationThresholdsUpdated(address indexed strategy, uint256 deviationThreshold, uint256 mnThreshold)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParsePPSVerificationThresholdsUpdated(log types.Log) (*ISuperVaultAggregatorPPSVerificationThresholdsUpdated, error) {
	event := new(ISuperVaultAggregatorPPSVerificationThresholdsUpdated)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "PPSVerificationThresholdsUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorPaymentSkippedForPausedStrategyIterator is returned from FilterPaymentSkippedForPausedStrategy and is used to iterate over the raw logs and unpacked data for PaymentSkippedForPausedStrategy events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorPaymentSkippedForPausedStrategyIterator struct {
	Event *ISuperVaultAggregatorPaymentSkippedForPausedStrategy // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorPaymentSkippedForPausedStrategyIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorPaymentSkippedForPausedStrategy)
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
		it.Event = new(ISuperVaultAggregatorPaymentSkippedForPausedStrategy)
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
func (it *ISuperVaultAggregatorPaymentSkippedForPausedStrategyIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorPaymentSkippedForPausedStrategyIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorPaymentSkippedForPausedStrategy represents a PaymentSkippedForPausedStrategy event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorPaymentSkippedForPausedStrategy struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterPaymentSkippedForPausedStrategy is a free log retrieval operation binding the contract event 0x0478bb79992612bb0113eed2f11d4f517e30990d086ec12b6feaeb96067b4f1b.
//
// Solidity: event PaymentSkippedForPausedStrategy(address indexed strategy)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterPaymentSkippedForPausedStrategy(opts *bind.FilterOpts, strategy []common.Address) (*ISuperVaultAggregatorPaymentSkippedForPausedStrategyIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "PaymentSkippedForPausedStrategy", strategyRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorPaymentSkippedForPausedStrategyIterator{contract: _ISuperVaultAggregator.contract, event: "PaymentSkippedForPausedStrategy", logs: logs, sub: sub}, nil
}

// WatchPaymentSkippedForPausedStrategy is a free log subscription operation binding the contract event 0x0478bb79992612bb0113eed2f11d4f517e30990d086ec12b6feaeb96067b4f1b.
//
// Solidity: event PaymentSkippedForPausedStrategy(address indexed strategy)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchPaymentSkippedForPausedStrategy(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorPaymentSkippedForPausedStrategy, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "PaymentSkippedForPausedStrategy", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorPaymentSkippedForPausedStrategy)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "PaymentSkippedForPausedStrategy", log); err != nil {
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

// ParsePaymentSkippedForPausedStrategy is a log parse operation binding the contract event 0x0478bb79992612bb0113eed2f11d4f517e30990d086ec12b6feaeb96067b4f1b.
//
// Solidity: event PaymentSkippedForPausedStrategy(address indexed strategy)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParsePaymentSkippedForPausedStrategy(log types.Log) (*ISuperVaultAggregatorPaymentSkippedForPausedStrategy, error) {
	event := new(ISuperVaultAggregatorPaymentSkippedForPausedStrategy)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "PaymentSkippedForPausedStrategy", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorPrimaryManagerChangeProposedIterator is returned from FilterPrimaryManagerChangeProposed and is used to iterate over the raw logs and unpacked data for PrimaryManagerChangeProposed events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorPrimaryManagerChangeProposedIterator struct {
	Event *ISuperVaultAggregatorPrimaryManagerChangeProposed // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorPrimaryManagerChangeProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorPrimaryManagerChangeProposed)
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
		it.Event = new(ISuperVaultAggregatorPrimaryManagerChangeProposed)
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
func (it *ISuperVaultAggregatorPrimaryManagerChangeProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorPrimaryManagerChangeProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorPrimaryManagerChangeProposed represents a PrimaryManagerChangeProposed event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorPrimaryManagerChangeProposed struct {
	Strategy      common.Address
	Proposer      common.Address
	NewManager    common.Address
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterPrimaryManagerChangeProposed is a free log retrieval operation binding the contract event 0x4ee609fb141edc43691a25b420b8584e6ed4fb79e4d8f2063a40872160375883.
//
// Solidity: event PrimaryManagerChangeProposed(address indexed strategy, address indexed proposer, address indexed newManager, uint256 effectiveTime)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterPrimaryManagerChangeProposed(opts *bind.FilterOpts, strategy []common.Address, proposer []common.Address, newManager []common.Address) (*ISuperVaultAggregatorPrimaryManagerChangeProposedIterator, error) {

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

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "PrimaryManagerChangeProposed", strategyRule, proposerRule, newManagerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorPrimaryManagerChangeProposedIterator{contract: _ISuperVaultAggregator.contract, event: "PrimaryManagerChangeProposed", logs: logs, sub: sub}, nil
}

// WatchPrimaryManagerChangeProposed is a free log subscription operation binding the contract event 0x4ee609fb141edc43691a25b420b8584e6ed4fb79e4d8f2063a40872160375883.
//
// Solidity: event PrimaryManagerChangeProposed(address indexed strategy, address indexed proposer, address indexed newManager, uint256 effectiveTime)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchPrimaryManagerChangeProposed(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorPrimaryManagerChangeProposed, strategy []common.Address, proposer []common.Address, newManager []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "PrimaryManagerChangeProposed", strategyRule, proposerRule, newManagerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorPrimaryManagerChangeProposed)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "PrimaryManagerChangeProposed", log); err != nil {
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

// ParsePrimaryManagerChangeProposed is a log parse operation binding the contract event 0x4ee609fb141edc43691a25b420b8584e6ed4fb79e4d8f2063a40872160375883.
//
// Solidity: event PrimaryManagerChangeProposed(address indexed strategy, address indexed proposer, address indexed newManager, uint256 effectiveTime)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParsePrimaryManagerChangeProposed(log types.Log) (*ISuperVaultAggregatorPrimaryManagerChangeProposed, error) {
	event := new(ISuperVaultAggregatorPrimaryManagerChangeProposed)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "PrimaryManagerChangeProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorPrimaryManagerChangedIterator is returned from FilterPrimaryManagerChanged and is used to iterate over the raw logs and unpacked data for PrimaryManagerChanged events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorPrimaryManagerChangedIterator struct {
	Event *ISuperVaultAggregatorPrimaryManagerChanged // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorPrimaryManagerChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorPrimaryManagerChanged)
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
		it.Event = new(ISuperVaultAggregatorPrimaryManagerChanged)
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
func (it *ISuperVaultAggregatorPrimaryManagerChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorPrimaryManagerChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorPrimaryManagerChanged represents a PrimaryManagerChanged event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorPrimaryManagerChanged struct {
	Strategy   common.Address
	OldManager common.Address
	NewManager common.Address
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterPrimaryManagerChanged is a free log retrieval operation binding the contract event 0x4fabd2698f36f819418b0ded3a29b7e2572bef7ee7bd0875f5b5bb805333c6fc.
//
// Solidity: event PrimaryManagerChanged(address indexed strategy, address indexed oldManager, address indexed newManager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterPrimaryManagerChanged(opts *bind.FilterOpts, strategy []common.Address, oldManager []common.Address, newManager []common.Address) (*ISuperVaultAggregatorPrimaryManagerChangedIterator, error) {

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

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "PrimaryManagerChanged", strategyRule, oldManagerRule, newManagerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorPrimaryManagerChangedIterator{contract: _ISuperVaultAggregator.contract, event: "PrimaryManagerChanged", logs: logs, sub: sub}, nil
}

// WatchPrimaryManagerChanged is a free log subscription operation binding the contract event 0x4fabd2698f36f819418b0ded3a29b7e2572bef7ee7bd0875f5b5bb805333c6fc.
//
// Solidity: event PrimaryManagerChanged(address indexed strategy, address indexed oldManager, address indexed newManager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchPrimaryManagerChanged(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorPrimaryManagerChanged, strategy []common.Address, oldManager []common.Address, newManager []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "PrimaryManagerChanged", strategyRule, oldManagerRule, newManagerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorPrimaryManagerChanged)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "PrimaryManagerChanged", log); err != nil {
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

// ParsePrimaryManagerChanged is a log parse operation binding the contract event 0x4fabd2698f36f819418b0ded3a29b7e2572bef7ee7bd0875f5b5bb805333c6fc.
//
// Solidity: event PrimaryManagerChanged(address indexed strategy, address indexed oldManager, address indexed newManager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParsePrimaryManagerChanged(log types.Log) (*ISuperVaultAggregatorPrimaryManagerChanged, error) {
	event := new(ISuperVaultAggregatorPrimaryManagerChanged)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "PrimaryManagerChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorPrimaryManagerChangedToSuperformIterator is returned from FilterPrimaryManagerChangedToSuperform and is used to iterate over the raw logs and unpacked data for PrimaryManagerChangedToSuperform events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorPrimaryManagerChangedToSuperformIterator struct {
	Event *ISuperVaultAggregatorPrimaryManagerChangedToSuperform // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorPrimaryManagerChangedToSuperformIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorPrimaryManagerChangedToSuperform)
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
		it.Event = new(ISuperVaultAggregatorPrimaryManagerChangedToSuperform)
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
func (it *ISuperVaultAggregatorPrimaryManagerChangedToSuperformIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorPrimaryManagerChangedToSuperformIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorPrimaryManagerChangedToSuperform represents a PrimaryManagerChangedToSuperform event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorPrimaryManagerChangedToSuperform struct {
	Strategy   common.Address
	OldManager common.Address
	NewManager common.Address
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterPrimaryManagerChangedToSuperform is a free log retrieval operation binding the contract event 0x4a6c6deb2a640ff12d2cffe60e67daf16bfaad28d37d507351ec272fac1e75b2.
//
// Solidity: event PrimaryManagerChangedToSuperform(address indexed strategy, address indexed oldManager, address indexed newManager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterPrimaryManagerChangedToSuperform(opts *bind.FilterOpts, strategy []common.Address, oldManager []common.Address, newManager []common.Address) (*ISuperVaultAggregatorPrimaryManagerChangedToSuperformIterator, error) {

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

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "PrimaryManagerChangedToSuperform", strategyRule, oldManagerRule, newManagerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorPrimaryManagerChangedToSuperformIterator{contract: _ISuperVaultAggregator.contract, event: "PrimaryManagerChangedToSuperform", logs: logs, sub: sub}, nil
}

// WatchPrimaryManagerChangedToSuperform is a free log subscription operation binding the contract event 0x4a6c6deb2a640ff12d2cffe60e67daf16bfaad28d37d507351ec272fac1e75b2.
//
// Solidity: event PrimaryManagerChangedToSuperform(address indexed strategy, address indexed oldManager, address indexed newManager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchPrimaryManagerChangedToSuperform(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorPrimaryManagerChangedToSuperform, strategy []common.Address, oldManager []common.Address, newManager []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "PrimaryManagerChangedToSuperform", strategyRule, oldManagerRule, newManagerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorPrimaryManagerChangedToSuperform)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "PrimaryManagerChangedToSuperform", log); err != nil {
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

// ParsePrimaryManagerChangedToSuperform is a log parse operation binding the contract event 0x4a6c6deb2a640ff12d2cffe60e67daf16bfaad28d37d507351ec272fac1e75b2.
//
// Solidity: event PrimaryManagerChangedToSuperform(address indexed strategy, address indexed oldManager, address indexed newManager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParsePrimaryManagerChangedToSuperform(log types.Log) (*ISuperVaultAggregatorPrimaryManagerChangedToSuperform, error) {
	event := new(ISuperVaultAggregatorPrimaryManagerChangedToSuperform)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "PrimaryManagerChangedToSuperform", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator is returned from FilterProvidedTimestampExceedsBlockTimestamp and is used to iterate over the raw logs and unpacked data for ProvidedTimestampExceedsBlockTimestamp events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator struct {
	Event *ISuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp)
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
		it.Event = new(ISuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp)
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
func (it *ISuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp represents a ProvidedTimestampExceedsBlockTimestamp event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp struct {
	Strategy       common.Address
	ArgsTimestamp  *big.Int
	BlockTimestamp *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterProvidedTimestampExceedsBlockTimestamp is a free log retrieval operation binding the contract event 0x11ce21eb8049b15d3cb258f2a3e207e24b6ca2141010b9c063228faa8628b9b5.
//
// Solidity: event ProvidedTimestampExceedsBlockTimestamp(address indexed strategy, uint256 argsTimestamp, uint256 blockTimestamp)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterProvidedTimestampExceedsBlockTimestamp(opts *bind.FilterOpts, strategy []common.Address) (*ISuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "ProvidedTimestampExceedsBlockTimestamp", strategyRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator{contract: _ISuperVaultAggregator.contract, event: "ProvidedTimestampExceedsBlockTimestamp", logs: logs, sub: sub}, nil
}

// WatchProvidedTimestampExceedsBlockTimestamp is a free log subscription operation binding the contract event 0x11ce21eb8049b15d3cb258f2a3e207e24b6ca2141010b9c063228faa8628b9b5.
//
// Solidity: event ProvidedTimestampExceedsBlockTimestamp(address indexed strategy, uint256 argsTimestamp, uint256 blockTimestamp)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchProvidedTimestampExceedsBlockTimestamp(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "ProvidedTimestampExceedsBlockTimestamp", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "ProvidedTimestampExceedsBlockTimestamp", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseProvidedTimestampExceedsBlockTimestamp(log types.Log) (*ISuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp, error) {
	event := new(ISuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "ProvidedTimestampExceedsBlockTimestamp", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorSecondaryManagerAddedIterator is returned from FilterSecondaryManagerAdded and is used to iterate over the raw logs and unpacked data for SecondaryManagerAdded events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorSecondaryManagerAddedIterator struct {
	Event *ISuperVaultAggregatorSecondaryManagerAdded // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorSecondaryManagerAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorSecondaryManagerAdded)
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
		it.Event = new(ISuperVaultAggregatorSecondaryManagerAdded)
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
func (it *ISuperVaultAggregatorSecondaryManagerAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorSecondaryManagerAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorSecondaryManagerAdded represents a SecondaryManagerAdded event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorSecondaryManagerAdded struct {
	Strategy common.Address
	Manager  common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterSecondaryManagerAdded is a free log retrieval operation binding the contract event 0xb62a858ba4f3ba693ebca539c91a5c78f4514d4c1ea35b9d336ce5ce8f071f76.
//
// Solidity: event SecondaryManagerAdded(address indexed strategy, address indexed manager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterSecondaryManagerAdded(opts *bind.FilterOpts, strategy []common.Address, manager []common.Address) (*ISuperVaultAggregatorSecondaryManagerAddedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "SecondaryManagerAdded", strategyRule, managerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorSecondaryManagerAddedIterator{contract: _ISuperVaultAggregator.contract, event: "SecondaryManagerAdded", logs: logs, sub: sub}, nil
}

// WatchSecondaryManagerAdded is a free log subscription operation binding the contract event 0xb62a858ba4f3ba693ebca539c91a5c78f4514d4c1ea35b9d336ce5ce8f071f76.
//
// Solidity: event SecondaryManagerAdded(address indexed strategy, address indexed manager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchSecondaryManagerAdded(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorSecondaryManagerAdded, strategy []common.Address, manager []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "SecondaryManagerAdded", strategyRule, managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorSecondaryManagerAdded)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "SecondaryManagerAdded", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseSecondaryManagerAdded(log types.Log) (*ISuperVaultAggregatorSecondaryManagerAdded, error) {
	event := new(ISuperVaultAggregatorSecondaryManagerAdded)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "SecondaryManagerAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorSecondaryManagerRemovedIterator is returned from FilterSecondaryManagerRemoved and is used to iterate over the raw logs and unpacked data for SecondaryManagerRemoved events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorSecondaryManagerRemovedIterator struct {
	Event *ISuperVaultAggregatorSecondaryManagerRemoved // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorSecondaryManagerRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorSecondaryManagerRemoved)
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
		it.Event = new(ISuperVaultAggregatorSecondaryManagerRemoved)
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
func (it *ISuperVaultAggregatorSecondaryManagerRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorSecondaryManagerRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorSecondaryManagerRemoved represents a SecondaryManagerRemoved event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorSecondaryManagerRemoved struct {
	Strategy common.Address
	Manager  common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterSecondaryManagerRemoved is a free log retrieval operation binding the contract event 0x466dd5513a82de99caf12b8d5176cd2174dec8013f9c3ec7be7254e54b2c417c.
//
// Solidity: event SecondaryManagerRemoved(address indexed strategy, address indexed manager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterSecondaryManagerRemoved(opts *bind.FilterOpts, strategy []common.Address, manager []common.Address) (*ISuperVaultAggregatorSecondaryManagerRemovedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "SecondaryManagerRemoved", strategyRule, managerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorSecondaryManagerRemovedIterator{contract: _ISuperVaultAggregator.contract, event: "SecondaryManagerRemoved", logs: logs, sub: sub}, nil
}

// WatchSecondaryManagerRemoved is a free log subscription operation binding the contract event 0x466dd5513a82de99caf12b8d5176cd2174dec8013f9c3ec7be7254e54b2c417c.
//
// Solidity: event SecondaryManagerRemoved(address indexed strategy, address indexed manager)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchSecondaryManagerRemoved(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorSecondaryManagerRemoved, strategy []common.Address, manager []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "SecondaryManagerRemoved", strategyRule, managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorSecondaryManagerRemoved)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "SecondaryManagerRemoved", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseSecondaryManagerRemoved(log types.Log) (*ISuperVaultAggregatorSecondaryManagerRemoved, error) {
	event := new(ISuperVaultAggregatorSecondaryManagerRemoved)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "SecondaryManagerRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorStakeDepositedIterator is returned from FilterStakeDeposited and is used to iterate over the raw logs and unpacked data for StakeDeposited events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStakeDepositedIterator struct {
	Event *ISuperVaultAggregatorStakeDeposited // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorStakeDepositedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorStakeDeposited)
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
		it.Event = new(ISuperVaultAggregatorStakeDeposited)
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
func (it *ISuperVaultAggregatorStakeDepositedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorStakeDepositedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorStakeDeposited represents a StakeDeposited event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStakeDeposited struct {
	Manager common.Address
	Amount  *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterStakeDeposited is a free log retrieval operation binding the contract event 0x0a7bb2e28cc4698aac06db79cf9163bfcc20719286cf59fa7d492ceda1b8edc2.
//
// Solidity: event StakeDeposited(address indexed manager, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterStakeDeposited(opts *bind.FilterOpts, manager []common.Address) (*ISuperVaultAggregatorStakeDepositedIterator, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "StakeDeposited", managerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorStakeDepositedIterator{contract: _ISuperVaultAggregator.contract, event: "StakeDeposited", logs: logs, sub: sub}, nil
}

// WatchStakeDeposited is a free log subscription operation binding the contract event 0x0a7bb2e28cc4698aac06db79cf9163bfcc20719286cf59fa7d492ceda1b8edc2.
//
// Solidity: event StakeDeposited(address indexed manager, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchStakeDeposited(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorStakeDeposited, manager []common.Address) (event.Subscription, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "StakeDeposited", managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorStakeDeposited)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StakeDeposited", log); err != nil {
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

// ParseStakeDeposited is a log parse operation binding the contract event 0x0a7bb2e28cc4698aac06db79cf9163bfcc20719286cf59fa7d492ceda1b8edc2.
//
// Solidity: event StakeDeposited(address indexed manager, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseStakeDeposited(log types.Log) (*ISuperVaultAggregatorStakeDeposited, error) {
	event := new(ISuperVaultAggregatorStakeDeposited)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StakeDeposited", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorStakeSlashedIterator is returned from FilterStakeSlashed and is used to iterate over the raw logs and unpacked data for StakeSlashed events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStakeSlashedIterator struct {
	Event *ISuperVaultAggregatorStakeSlashed // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorStakeSlashedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorStakeSlashed)
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
		it.Event = new(ISuperVaultAggregatorStakeSlashed)
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
func (it *ISuperVaultAggregatorStakeSlashedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorStakeSlashedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorStakeSlashed represents a StakeSlashed event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStakeSlashed struct {
	Manager common.Address
	Amount  *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterStakeSlashed is a free log retrieval operation binding the contract event 0x83f5ea8bea7627d95274e94dd7e9e3d7e82cb55feab513ed49e325232dcc61e0.
//
// Solidity: event StakeSlashed(address indexed manager, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterStakeSlashed(opts *bind.FilterOpts, manager []common.Address) (*ISuperVaultAggregatorStakeSlashedIterator, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "StakeSlashed", managerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorStakeSlashedIterator{contract: _ISuperVaultAggregator.contract, event: "StakeSlashed", logs: logs, sub: sub}, nil
}

// WatchStakeSlashed is a free log subscription operation binding the contract event 0x83f5ea8bea7627d95274e94dd7e9e3d7e82cb55feab513ed49e325232dcc61e0.
//
// Solidity: event StakeSlashed(address indexed manager, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchStakeSlashed(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorStakeSlashed, manager []common.Address) (event.Subscription, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "StakeSlashed", managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorStakeSlashed)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StakeSlashed", log); err != nil {
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

// ParseStakeSlashed is a log parse operation binding the contract event 0x83f5ea8bea7627d95274e94dd7e9e3d7e82cb55feab513ed49e325232dcc61e0.
//
// Solidity: event StakeSlashed(address indexed manager, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseStakeSlashed(log types.Log) (*ISuperVaultAggregatorStakeSlashed, error) {
	event := new(ISuperVaultAggregatorStakeSlashed)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StakeSlashed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorStakeWithdrawRequestedIterator is returned from FilterStakeWithdrawRequested and is used to iterate over the raw logs and unpacked data for StakeWithdrawRequested events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStakeWithdrawRequestedIterator struct {
	Event *ISuperVaultAggregatorStakeWithdrawRequested // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorStakeWithdrawRequestedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorStakeWithdrawRequested)
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
		it.Event = new(ISuperVaultAggregatorStakeWithdrawRequested)
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
func (it *ISuperVaultAggregatorStakeWithdrawRequestedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorStakeWithdrawRequestedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorStakeWithdrawRequested represents a StakeWithdrawRequested event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStakeWithdrawRequested struct {
	Manager common.Address
	Amount  *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterStakeWithdrawRequested is a free log retrieval operation binding the contract event 0x3d8d9df4bd0172df32e557fa48e96435cd7f2cac06aaffacfaee608e6f7898ef.
//
// Solidity: event StakeWithdrawRequested(address indexed manager, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterStakeWithdrawRequested(opts *bind.FilterOpts, manager []common.Address) (*ISuperVaultAggregatorStakeWithdrawRequestedIterator, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "StakeWithdrawRequested", managerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorStakeWithdrawRequestedIterator{contract: _ISuperVaultAggregator.contract, event: "StakeWithdrawRequested", logs: logs, sub: sub}, nil
}

// WatchStakeWithdrawRequested is a free log subscription operation binding the contract event 0x3d8d9df4bd0172df32e557fa48e96435cd7f2cac06aaffacfaee608e6f7898ef.
//
// Solidity: event StakeWithdrawRequested(address indexed manager, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchStakeWithdrawRequested(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorStakeWithdrawRequested, manager []common.Address) (event.Subscription, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "StakeWithdrawRequested", managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorStakeWithdrawRequested)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StakeWithdrawRequested", log); err != nil {
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

// ParseStakeWithdrawRequested is a log parse operation binding the contract event 0x3d8d9df4bd0172df32e557fa48e96435cd7f2cac06aaffacfaee608e6f7898ef.
//
// Solidity: event StakeWithdrawRequested(address indexed manager, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseStakeWithdrawRequested(log types.Log) (*ISuperVaultAggregatorStakeWithdrawRequested, error) {
	event := new(ISuperVaultAggregatorStakeWithdrawRequested)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StakeWithdrawRequested", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorStakeWithdrawnIterator is returned from FilterStakeWithdrawn and is used to iterate over the raw logs and unpacked data for StakeWithdrawn events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStakeWithdrawnIterator struct {
	Event *ISuperVaultAggregatorStakeWithdrawn // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorStakeWithdrawnIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorStakeWithdrawn)
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
		it.Event = new(ISuperVaultAggregatorStakeWithdrawn)
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
func (it *ISuperVaultAggregatorStakeWithdrawnIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorStakeWithdrawnIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorStakeWithdrawn represents a StakeWithdrawn event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStakeWithdrawn struct {
	Manager common.Address
	Amount  *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterStakeWithdrawn is a free log retrieval operation binding the contract event 0x8108595eb6bad3acefa9da467d90cc2217686d5c5ac85460f8b7849c840645fc.
//
// Solidity: event StakeWithdrawn(address indexed manager, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterStakeWithdrawn(opts *bind.FilterOpts, manager []common.Address) (*ISuperVaultAggregatorStakeWithdrawnIterator, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "StakeWithdrawn", managerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorStakeWithdrawnIterator{contract: _ISuperVaultAggregator.contract, event: "StakeWithdrawn", logs: logs, sub: sub}, nil
}

// WatchStakeWithdrawn is a free log subscription operation binding the contract event 0x8108595eb6bad3acefa9da467d90cc2217686d5c5ac85460f8b7849c840645fc.
//
// Solidity: event StakeWithdrawn(address indexed manager, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchStakeWithdrawn(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorStakeWithdrawn, manager []common.Address) (event.Subscription, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "StakeWithdrawn", managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorStakeWithdrawn)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StakeWithdrawn", log); err != nil {
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

// ParseStakeWithdrawn is a log parse operation binding the contract event 0x8108595eb6bad3acefa9da467d90cc2217686d5c5ac85460f8b7849c840645fc.
//
// Solidity: event StakeWithdrawn(address indexed manager, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseStakeWithdrawn(log types.Log) (*ISuperVaultAggregatorStakeWithdrawn, error) {
	event := new(ISuperVaultAggregatorStakeWithdrawn)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StakeWithdrawn", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorStaleUpdateIterator is returned from FilterStaleUpdate and is used to iterate over the raw logs and unpacked data for StaleUpdate events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStaleUpdateIterator struct {
	Event *ISuperVaultAggregatorStaleUpdate // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorStaleUpdateIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorStaleUpdate)
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
		it.Event = new(ISuperVaultAggregatorStaleUpdate)
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
func (it *ISuperVaultAggregatorStaleUpdateIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorStaleUpdateIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorStaleUpdate represents a StaleUpdate event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStaleUpdate struct {
	Strategy        common.Address
	UpdateAuthority common.Address
	Timestamp       *big.Int
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterStaleUpdate is a free log retrieval operation binding the contract event 0x5413368ef0fd371d352762fd42f794381bdd66d2b2c3860549bc61f12f6ab2ba.
//
// Solidity: event StaleUpdate(address indexed strategy, address indexed updateAuthority, uint256 timestamp)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterStaleUpdate(opts *bind.FilterOpts, strategy []common.Address, updateAuthority []common.Address) (*ISuperVaultAggregatorStaleUpdateIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var updateAuthorityRule []interface{}
	for _, updateAuthorityItem := range updateAuthority {
		updateAuthorityRule = append(updateAuthorityRule, updateAuthorityItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "StaleUpdate", strategyRule, updateAuthorityRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorStaleUpdateIterator{contract: _ISuperVaultAggregator.contract, event: "StaleUpdate", logs: logs, sub: sub}, nil
}

// WatchStaleUpdate is a free log subscription operation binding the contract event 0x5413368ef0fd371d352762fd42f794381bdd66d2b2c3860549bc61f12f6ab2ba.
//
// Solidity: event StaleUpdate(address indexed strategy, address indexed updateAuthority, uint256 timestamp)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchStaleUpdate(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorStaleUpdate, strategy []common.Address, updateAuthority []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var updateAuthorityRule []interface{}
	for _, updateAuthorityItem := range updateAuthority {
		updateAuthorityRule = append(updateAuthorityRule, updateAuthorityItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "StaleUpdate", strategyRule, updateAuthorityRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorStaleUpdate)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StaleUpdate", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseStaleUpdate(log types.Log) (*ISuperVaultAggregatorStaleUpdate, error) {
	event := new(ISuperVaultAggregatorStaleUpdate)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StaleUpdate", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorStrategyCheckFailedIterator is returned from FilterStrategyCheckFailed and is used to iterate over the raw logs and unpacked data for StrategyCheckFailed events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyCheckFailedIterator struct {
	Event *ISuperVaultAggregatorStrategyCheckFailed // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorStrategyCheckFailedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorStrategyCheckFailed)
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
		it.Event = new(ISuperVaultAggregatorStrategyCheckFailed)
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
func (it *ISuperVaultAggregatorStrategyCheckFailedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorStrategyCheckFailedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorStrategyCheckFailed represents a StrategyCheckFailed event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyCheckFailed struct {
	Strategy common.Address
	Reason   string
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyCheckFailed is a free log retrieval operation binding the contract event 0xe364669b114d8ecba48ed1742526a04c78dd506cd3af6beb910f6622a928cbdb.
//
// Solidity: event StrategyCheckFailed(address indexed strategy, string reason)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterStrategyCheckFailed(opts *bind.FilterOpts, strategy []common.Address) (*ISuperVaultAggregatorStrategyCheckFailedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "StrategyCheckFailed", strategyRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorStrategyCheckFailedIterator{contract: _ISuperVaultAggregator.contract, event: "StrategyCheckFailed", logs: logs, sub: sub}, nil
}

// WatchStrategyCheckFailed is a free log subscription operation binding the contract event 0xe364669b114d8ecba48ed1742526a04c78dd506cd3af6beb910f6622a928cbdb.
//
// Solidity: event StrategyCheckFailed(address indexed strategy, string reason)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchStrategyCheckFailed(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorStrategyCheckFailed, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "StrategyCheckFailed", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorStrategyCheckFailed)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyCheckFailed", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseStrategyCheckFailed(log types.Log) (*ISuperVaultAggregatorStrategyCheckFailed, error) {
	event := new(ISuperVaultAggregatorStrategyCheckFailed)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyCheckFailed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorStrategyHooksRootUpdateProposedIterator is returned from FilterStrategyHooksRootUpdateProposed and is used to iterate over the raw logs and unpacked data for StrategyHooksRootUpdateProposed events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyHooksRootUpdateProposedIterator struct {
	Event *ISuperVaultAggregatorStrategyHooksRootUpdateProposed // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorStrategyHooksRootUpdateProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorStrategyHooksRootUpdateProposed)
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
		it.Event = new(ISuperVaultAggregatorStrategyHooksRootUpdateProposed)
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
func (it *ISuperVaultAggregatorStrategyHooksRootUpdateProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorStrategyHooksRootUpdateProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorStrategyHooksRootUpdateProposed represents a StrategyHooksRootUpdateProposed event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyHooksRootUpdateProposed struct {
	Strategy      common.Address
	Proposer      common.Address
	Root          [32]byte
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterStrategyHooksRootUpdateProposed is a free log retrieval operation binding the contract event 0x3c67f914ba911b08519fae976b442675afa7d36b96bab1276ca2ab142c1b1714.
//
// Solidity: event StrategyHooksRootUpdateProposed(address indexed strategy, address indexed proposer, bytes32 root, uint256 effectiveTime)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterStrategyHooksRootUpdateProposed(opts *bind.FilterOpts, strategy []common.Address, proposer []common.Address) (*ISuperVaultAggregatorStrategyHooksRootUpdateProposedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var proposerRule []interface{}
	for _, proposerItem := range proposer {
		proposerRule = append(proposerRule, proposerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "StrategyHooksRootUpdateProposed", strategyRule, proposerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorStrategyHooksRootUpdateProposedIterator{contract: _ISuperVaultAggregator.contract, event: "StrategyHooksRootUpdateProposed", logs: logs, sub: sub}, nil
}

// WatchStrategyHooksRootUpdateProposed is a free log subscription operation binding the contract event 0x3c67f914ba911b08519fae976b442675afa7d36b96bab1276ca2ab142c1b1714.
//
// Solidity: event StrategyHooksRootUpdateProposed(address indexed strategy, address indexed proposer, bytes32 root, uint256 effectiveTime)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchStrategyHooksRootUpdateProposed(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorStrategyHooksRootUpdateProposed, strategy []common.Address, proposer []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var proposerRule []interface{}
	for _, proposerItem := range proposer {
		proposerRule = append(proposerRule, proposerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "StrategyHooksRootUpdateProposed", strategyRule, proposerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorStrategyHooksRootUpdateProposed)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootUpdateProposed", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseStrategyHooksRootUpdateProposed(log types.Log) (*ISuperVaultAggregatorStrategyHooksRootUpdateProposed, error) {
	event := new(ISuperVaultAggregatorStrategyHooksRootUpdateProposed)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootUpdateProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorStrategyHooksRootUpdatedIterator is returned from FilterStrategyHooksRootUpdated and is used to iterate over the raw logs and unpacked data for StrategyHooksRootUpdated events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyHooksRootUpdatedIterator struct {
	Event *ISuperVaultAggregatorStrategyHooksRootUpdated // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorStrategyHooksRootUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorStrategyHooksRootUpdated)
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
		it.Event = new(ISuperVaultAggregatorStrategyHooksRootUpdated)
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
func (it *ISuperVaultAggregatorStrategyHooksRootUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorStrategyHooksRootUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorStrategyHooksRootUpdated represents a StrategyHooksRootUpdated event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyHooksRootUpdated struct {
	Strategy common.Address
	OldRoot  [32]byte
	NewRoot  [32]byte
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyHooksRootUpdated is a free log retrieval operation binding the contract event 0x50db1dc8f2cc634e637edbe632acec34656994c29a699c817c89e8de694035f6.
//
// Solidity: event StrategyHooksRootUpdated(address indexed strategy, bytes32 oldRoot, bytes32 newRoot)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterStrategyHooksRootUpdated(opts *bind.FilterOpts, strategy []common.Address) (*ISuperVaultAggregatorStrategyHooksRootUpdatedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "StrategyHooksRootUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorStrategyHooksRootUpdatedIterator{contract: _ISuperVaultAggregator.contract, event: "StrategyHooksRootUpdated", logs: logs, sub: sub}, nil
}

// WatchStrategyHooksRootUpdated is a free log subscription operation binding the contract event 0x50db1dc8f2cc634e637edbe632acec34656994c29a699c817c89e8de694035f6.
//
// Solidity: event StrategyHooksRootUpdated(address indexed strategy, bytes32 oldRoot, bytes32 newRoot)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchStrategyHooksRootUpdated(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorStrategyHooksRootUpdated, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "StrategyHooksRootUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorStrategyHooksRootUpdated)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootUpdated", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseStrategyHooksRootUpdated(log types.Log) (*ISuperVaultAggregatorStrategyHooksRootUpdated, error) {
	event := new(ISuperVaultAggregatorStrategyHooksRootUpdated)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator is returned from FilterStrategyHooksRootVetoStatusChanged and is used to iterate over the raw logs and unpacked data for StrategyHooksRootVetoStatusChanged events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator struct {
	Event *ISuperVaultAggregatorStrategyHooksRootVetoStatusChanged // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorStrategyHooksRootVetoStatusChanged)
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
		it.Event = new(ISuperVaultAggregatorStrategyHooksRootVetoStatusChanged)
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
func (it *ISuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorStrategyHooksRootVetoStatusChanged represents a StrategyHooksRootVetoStatusChanged event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyHooksRootVetoStatusChanged struct {
	Strategy common.Address
	Vetoed   bool
	Root     [32]byte
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyHooksRootVetoStatusChanged is a free log retrieval operation binding the contract event 0x927440ad59e90a7b01af1effd4191955ea9e6ef812fc415e7f8e71eadbc5bc35.
//
// Solidity: event StrategyHooksRootVetoStatusChanged(address indexed strategy, bool vetoed, bytes32 indexed root)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterStrategyHooksRootVetoStatusChanged(opts *bind.FilterOpts, strategy []common.Address, root [][32]byte) (*ISuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "StrategyHooksRootVetoStatusChanged", strategyRule, rootRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator{contract: _ISuperVaultAggregator.contract, event: "StrategyHooksRootVetoStatusChanged", logs: logs, sub: sub}, nil
}

// WatchStrategyHooksRootVetoStatusChanged is a free log subscription operation binding the contract event 0x927440ad59e90a7b01af1effd4191955ea9e6ef812fc415e7f8e71eadbc5bc35.
//
// Solidity: event StrategyHooksRootVetoStatusChanged(address indexed strategy, bool vetoed, bytes32 indexed root)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchStrategyHooksRootVetoStatusChanged(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorStrategyHooksRootVetoStatusChanged, strategy []common.Address, root [][32]byte) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "StrategyHooksRootVetoStatusChanged", strategyRule, rootRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorStrategyHooksRootVetoStatusChanged)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootVetoStatusChanged", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseStrategyHooksRootVetoStatusChanged(log types.Log) (*ISuperVaultAggregatorStrategyHooksRootVetoStatusChanged, error) {
	event := new(ISuperVaultAggregatorStrategyHooksRootVetoStatusChanged)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootVetoStatusChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorStrategyHooksRootVetoedIterator is returned from FilterStrategyHooksRootVetoed and is used to iterate over the raw logs and unpacked data for StrategyHooksRootVetoed events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyHooksRootVetoedIterator struct {
	Event *ISuperVaultAggregatorStrategyHooksRootVetoed // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorStrategyHooksRootVetoedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorStrategyHooksRootVetoed)
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
		it.Event = new(ISuperVaultAggregatorStrategyHooksRootVetoed)
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
func (it *ISuperVaultAggregatorStrategyHooksRootVetoedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorStrategyHooksRootVetoedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorStrategyHooksRootVetoed represents a StrategyHooksRootVetoed event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyHooksRootVetoed struct {
	Guardian common.Address
	Strategy common.Address
	Root     [32]byte
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyHooksRootVetoed is a free log retrieval operation binding the contract event 0x13fb75f412cd7275ea6c0c59de6d99dd291eddab76417824e0edc385e5d75561.
//
// Solidity: event StrategyHooksRootVetoed(address indexed guardian, address indexed strategy, bytes32 indexed root)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterStrategyHooksRootVetoed(opts *bind.FilterOpts, guardian []common.Address, strategy []common.Address, root [][32]byte) (*ISuperVaultAggregatorStrategyHooksRootVetoedIterator, error) {

	var guardianRule []interface{}
	for _, guardianItem := range guardian {
		guardianRule = append(guardianRule, guardianItem)
	}
	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "StrategyHooksRootVetoed", guardianRule, strategyRule, rootRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorStrategyHooksRootVetoedIterator{contract: _ISuperVaultAggregator.contract, event: "StrategyHooksRootVetoed", logs: logs, sub: sub}, nil
}

// WatchStrategyHooksRootVetoed is a free log subscription operation binding the contract event 0x13fb75f412cd7275ea6c0c59de6d99dd291eddab76417824e0edc385e5d75561.
//
// Solidity: event StrategyHooksRootVetoed(address indexed guardian, address indexed strategy, bytes32 indexed root)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchStrategyHooksRootVetoed(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorStrategyHooksRootVetoed, guardian []common.Address, strategy []common.Address, root [][32]byte) (event.Subscription, error) {

	var guardianRule []interface{}
	for _, guardianItem := range guardian {
		guardianRule = append(guardianRule, guardianItem)
	}
	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "StrategyHooksRootVetoed", guardianRule, strategyRule, rootRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorStrategyHooksRootVetoed)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootVetoed", log); err != nil {
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

// ParseStrategyHooksRootVetoed is a log parse operation binding the contract event 0x13fb75f412cd7275ea6c0c59de6d99dd291eddab76417824e0edc385e5d75561.
//
// Solidity: event StrategyHooksRootVetoed(address indexed guardian, address indexed strategy, bytes32 indexed root)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseStrategyHooksRootVetoed(log types.Log) (*ISuperVaultAggregatorStrategyHooksRootVetoed, error) {
	event := new(ISuperVaultAggregatorStrategyHooksRootVetoed)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootVetoed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorStrategyPPSStaleIterator is returned from FilterStrategyPPSStale and is used to iterate over the raw logs and unpacked data for StrategyPPSStale events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyPPSStaleIterator struct {
	Event *ISuperVaultAggregatorStrategyPPSStale // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorStrategyPPSStaleIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorStrategyPPSStale)
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
		it.Event = new(ISuperVaultAggregatorStrategyPPSStale)
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
func (it *ISuperVaultAggregatorStrategyPPSStaleIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorStrategyPPSStaleIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorStrategyPPSStale represents a StrategyPPSStale event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyPPSStale struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyPPSStale is a free log retrieval operation binding the contract event 0x80796c8d1dc90790262881896e3680e577f032ca370f16b8dccd1cd4cef254f1.
//
// Solidity: event StrategyPPSStale(address indexed strategy)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterStrategyPPSStale(opts *bind.FilterOpts, strategy []common.Address) (*ISuperVaultAggregatorStrategyPPSStaleIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "StrategyPPSStale", strategyRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorStrategyPPSStaleIterator{contract: _ISuperVaultAggregator.contract, event: "StrategyPPSStale", logs: logs, sub: sub}, nil
}

// WatchStrategyPPSStale is a free log subscription operation binding the contract event 0x80796c8d1dc90790262881896e3680e577f032ca370f16b8dccd1cd4cef254f1.
//
// Solidity: event StrategyPPSStale(address indexed strategy)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchStrategyPPSStale(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorStrategyPPSStale, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "StrategyPPSStale", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorStrategyPPSStale)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyPPSStale", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseStrategyPPSStale(log types.Log) (*ISuperVaultAggregatorStrategyPPSStale, error) {
	event := new(ISuperVaultAggregatorStrategyPPSStale)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyPPSStale", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorStrategyPPSStaleResetIterator is returned from FilterStrategyPPSStaleReset and is used to iterate over the raw logs and unpacked data for StrategyPPSStaleReset events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyPPSStaleResetIterator struct {
	Event *ISuperVaultAggregatorStrategyPPSStaleReset // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorStrategyPPSStaleResetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorStrategyPPSStaleReset)
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
		it.Event = new(ISuperVaultAggregatorStrategyPPSStaleReset)
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
func (it *ISuperVaultAggregatorStrategyPPSStaleResetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorStrategyPPSStaleResetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorStrategyPPSStaleReset represents a StrategyPPSStaleReset event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyPPSStaleReset struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyPPSStaleReset is a free log retrieval operation binding the contract event 0x87afbf71df10b23be48535f5f7689b97e949bf5b76a67c76e79fd0f10db005d8.
//
// Solidity: event StrategyPPSStaleReset(address indexed strategy)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterStrategyPPSStaleReset(opts *bind.FilterOpts, strategy []common.Address) (*ISuperVaultAggregatorStrategyPPSStaleResetIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "StrategyPPSStaleReset", strategyRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorStrategyPPSStaleResetIterator{contract: _ISuperVaultAggregator.contract, event: "StrategyPPSStaleReset", logs: logs, sub: sub}, nil
}

// WatchStrategyPPSStaleReset is a free log subscription operation binding the contract event 0x87afbf71df10b23be48535f5f7689b97e949bf5b76a67c76e79fd0f10db005d8.
//
// Solidity: event StrategyPPSStaleReset(address indexed strategy)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchStrategyPPSStaleReset(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorStrategyPPSStaleReset, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "StrategyPPSStaleReset", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorStrategyPPSStaleReset)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyPPSStaleReset", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseStrategyPPSStaleReset(log types.Log) (*ISuperVaultAggregatorStrategyPPSStaleReset, error) {
	event := new(ISuperVaultAggregatorStrategyPPSStaleReset)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyPPSStaleReset", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorStrategyPausedIterator is returned from FilterStrategyPaused and is used to iterate over the raw logs and unpacked data for StrategyPaused events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyPausedIterator struct {
	Event *ISuperVaultAggregatorStrategyPaused // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorStrategyPausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorStrategyPaused)
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
		it.Event = new(ISuperVaultAggregatorStrategyPaused)
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
func (it *ISuperVaultAggregatorStrategyPausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorStrategyPausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorStrategyPaused represents a StrategyPaused event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyPaused struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyPaused is a free log retrieval operation binding the contract event 0xc2897a3765ea6cd9ed9ce463d3bc9c9cf968f21f8664b62684e1254d3b0f9ee5.
//
// Solidity: event StrategyPaused(address indexed strategy)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterStrategyPaused(opts *bind.FilterOpts, strategy []common.Address) (*ISuperVaultAggregatorStrategyPausedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "StrategyPaused", strategyRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorStrategyPausedIterator{contract: _ISuperVaultAggregator.contract, event: "StrategyPaused", logs: logs, sub: sub}, nil
}

// WatchStrategyPaused is a free log subscription operation binding the contract event 0xc2897a3765ea6cd9ed9ce463d3bc9c9cf968f21f8664b62684e1254d3b0f9ee5.
//
// Solidity: event StrategyPaused(address indexed strategy)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchStrategyPaused(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorStrategyPaused, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "StrategyPaused", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorStrategyPaused)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyPaused", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseStrategyPaused(log types.Log) (*ISuperVaultAggregatorStrategyPaused, error) {
	event := new(ISuperVaultAggregatorStrategyPaused)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyPaused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorStrategyUnpausePPSTimelockUpdatedIterator is returned from FilterStrategyUnpausePPSTimelockUpdated and is used to iterate over the raw logs and unpacked data for StrategyUnpausePPSTimelockUpdated events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyUnpausePPSTimelockUpdatedIterator struct {
	Event *ISuperVaultAggregatorStrategyUnpausePPSTimelockUpdated // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorStrategyUnpausePPSTimelockUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorStrategyUnpausePPSTimelockUpdated)
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
		it.Event = new(ISuperVaultAggregatorStrategyUnpausePPSTimelockUpdated)
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
func (it *ISuperVaultAggregatorStrategyUnpausePPSTimelockUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorStrategyUnpausePPSTimelockUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorStrategyUnpausePPSTimelockUpdated represents a StrategyUnpausePPSTimelockUpdated event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyUnpausePPSTimelockUpdated struct {
	Strategy    common.Address
	NewTimelock *big.Int
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterStrategyUnpausePPSTimelockUpdated is a free log retrieval operation binding the contract event 0xcaa1beb16816b2a2a6d26301cfbde569da7a04748029f8b0239f2f23c1a7681d.
//
// Solidity: event StrategyUnpausePPSTimelockUpdated(address indexed strategy, uint256 newTimelock)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterStrategyUnpausePPSTimelockUpdated(opts *bind.FilterOpts, strategy []common.Address) (*ISuperVaultAggregatorStrategyUnpausePPSTimelockUpdatedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "StrategyUnpausePPSTimelockUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorStrategyUnpausePPSTimelockUpdatedIterator{contract: _ISuperVaultAggregator.contract, event: "StrategyUnpausePPSTimelockUpdated", logs: logs, sub: sub}, nil
}

// WatchStrategyUnpausePPSTimelockUpdated is a free log subscription operation binding the contract event 0xcaa1beb16816b2a2a6d26301cfbde569da7a04748029f8b0239f2f23c1a7681d.
//
// Solidity: event StrategyUnpausePPSTimelockUpdated(address indexed strategy, uint256 newTimelock)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchStrategyUnpausePPSTimelockUpdated(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorStrategyUnpausePPSTimelockUpdated, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "StrategyUnpausePPSTimelockUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorStrategyUnpausePPSTimelockUpdated)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyUnpausePPSTimelockUpdated", log); err != nil {
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

// ParseStrategyUnpausePPSTimelockUpdated is a log parse operation binding the contract event 0xcaa1beb16816b2a2a6d26301cfbde569da7a04748029f8b0239f2f23c1a7681d.
//
// Solidity: event StrategyUnpausePPSTimelockUpdated(address indexed strategy, uint256 newTimelock)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseStrategyUnpausePPSTimelockUpdated(log types.Log) (*ISuperVaultAggregatorStrategyUnpausePPSTimelockUpdated, error) {
	event := new(ISuperVaultAggregatorStrategyUnpausePPSTimelockUpdated)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyUnpausePPSTimelockUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorStrategyUnpausedIterator is returned from FilterStrategyUnpaused and is used to iterate over the raw logs and unpacked data for StrategyUnpaused events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyUnpausedIterator struct {
	Event *ISuperVaultAggregatorStrategyUnpaused // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorStrategyUnpausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorStrategyUnpaused)
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
		it.Event = new(ISuperVaultAggregatorStrategyUnpaused)
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
func (it *ISuperVaultAggregatorStrategyUnpausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorStrategyUnpausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorStrategyUnpaused represents a StrategyUnpaused event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorStrategyUnpaused struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyUnpaused is a free log retrieval operation binding the contract event 0x9de75c520457842eb5fe159114348bf5358100a1acaf1bcb5052f64f347503df.
//
// Solidity: event StrategyUnpaused(address indexed strategy)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterStrategyUnpaused(opts *bind.FilterOpts, strategy []common.Address) (*ISuperVaultAggregatorStrategyUnpausedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "StrategyUnpaused", strategyRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorStrategyUnpausedIterator{contract: _ISuperVaultAggregator.contract, event: "StrategyUnpaused", logs: logs, sub: sub}, nil
}

// WatchStrategyUnpaused is a free log subscription operation binding the contract event 0x9de75c520457842eb5fe159114348bf5358100a1acaf1bcb5052f64f347503df.
//
// Solidity: event StrategyUnpaused(address indexed strategy)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchStrategyUnpaused(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorStrategyUnpaused, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "StrategyUnpaused", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorStrategyUnpaused)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyUnpaused", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseStrategyUnpaused(log types.Log) (*ISuperVaultAggregatorStrategyUnpaused, error) {
	event := new(ISuperVaultAggregatorStrategyUnpaused)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "StrategyUnpaused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorTimestampNotMonotonicIterator is returned from FilterTimestampNotMonotonic and is used to iterate over the raw logs and unpacked data for TimestampNotMonotonic events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorTimestampNotMonotonicIterator struct {
	Event *ISuperVaultAggregatorTimestampNotMonotonic // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorTimestampNotMonotonicIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorTimestampNotMonotonic)
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
		it.Event = new(ISuperVaultAggregatorTimestampNotMonotonic)
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
func (it *ISuperVaultAggregatorTimestampNotMonotonicIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorTimestampNotMonotonicIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorTimestampNotMonotonic represents a TimestampNotMonotonic event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorTimestampNotMonotonic struct {
	Raw types.Log // Blockchain specific contextual infos
}

// FilterTimestampNotMonotonic is a free log retrieval operation binding the contract event 0x2e78c6ab27a29f5c1471d797dd0809527031b55c91aa70143ffa36ceecfab75f.
//
// Solidity: event TimestampNotMonotonic()
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterTimestampNotMonotonic(opts *bind.FilterOpts) (*ISuperVaultAggregatorTimestampNotMonotonicIterator, error) {

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "TimestampNotMonotonic")
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorTimestampNotMonotonicIterator{contract: _ISuperVaultAggregator.contract, event: "TimestampNotMonotonic", logs: logs, sub: sub}, nil
}

// WatchTimestampNotMonotonic is a free log subscription operation binding the contract event 0x2e78c6ab27a29f5c1471d797dd0809527031b55c91aa70143ffa36ceecfab75f.
//
// Solidity: event TimestampNotMonotonic()
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchTimestampNotMonotonic(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorTimestampNotMonotonic) (event.Subscription, error) {

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "TimestampNotMonotonic")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorTimestampNotMonotonic)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "TimestampNotMonotonic", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseTimestampNotMonotonic(log types.Log) (*ISuperVaultAggregatorTimestampNotMonotonic, error) {
	event := new(ISuperVaultAggregatorTimestampNotMonotonic)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "TimestampNotMonotonic", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorUnknownStrategyIterator is returned from FilterUnknownStrategy and is used to iterate over the raw logs and unpacked data for UnknownStrategy events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorUnknownStrategyIterator struct {
	Event *ISuperVaultAggregatorUnknownStrategy // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorUnknownStrategyIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorUnknownStrategy)
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
		it.Event = new(ISuperVaultAggregatorUnknownStrategy)
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
func (it *ISuperVaultAggregatorUnknownStrategyIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorUnknownStrategyIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorUnknownStrategy represents a UnknownStrategy event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorUnknownStrategy struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterUnknownStrategy is a free log retrieval operation binding the contract event 0xde5abf6fb8e50b9c44ca7d6b0b47660db6158640044348124a98dbb8c94d6524.
//
// Solidity: event UnknownStrategy(address indexed strategy)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterUnknownStrategy(opts *bind.FilterOpts, strategy []common.Address) (*ISuperVaultAggregatorUnknownStrategyIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "UnknownStrategy", strategyRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorUnknownStrategyIterator{contract: _ISuperVaultAggregator.contract, event: "UnknownStrategy", logs: logs, sub: sub}, nil
}

// WatchUnknownStrategy is a free log subscription operation binding the contract event 0xde5abf6fb8e50b9c44ca7d6b0b47660db6158640044348124a98dbb8c94d6524.
//
// Solidity: event UnknownStrategy(address indexed strategy)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchUnknownStrategy(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorUnknownStrategy, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "UnknownStrategy", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorUnknownStrategy)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "UnknownStrategy", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseUnknownStrategy(log types.Log) (*ISuperVaultAggregatorUnknownStrategy, error) {
	event := new(ISuperVaultAggregatorUnknownStrategy)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "UnknownStrategy", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorUpdateTooFrequentIterator is returned from FilterUpdateTooFrequent and is used to iterate over the raw logs and unpacked data for UpdateTooFrequent events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorUpdateTooFrequentIterator struct {
	Event *ISuperVaultAggregatorUpdateTooFrequent // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorUpdateTooFrequentIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorUpdateTooFrequent)
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
		it.Event = new(ISuperVaultAggregatorUpdateTooFrequent)
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
func (it *ISuperVaultAggregatorUpdateTooFrequentIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorUpdateTooFrequentIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorUpdateTooFrequent represents a UpdateTooFrequent event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorUpdateTooFrequent struct {
	Raw types.Log // Blockchain specific contextual infos
}

// FilterUpdateTooFrequent is a free log retrieval operation binding the contract event 0x53f7a6ee85aab0f20869755601a6424676aa3807e9ef249627fa11a39e9a0e0c.
//
// Solidity: event UpdateTooFrequent()
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterUpdateTooFrequent(opts *bind.FilterOpts) (*ISuperVaultAggregatorUpdateTooFrequentIterator, error) {

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "UpdateTooFrequent")
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorUpdateTooFrequentIterator{contract: _ISuperVaultAggregator.contract, event: "UpdateTooFrequent", logs: logs, sub: sub}, nil
}

// WatchUpdateTooFrequent is a free log subscription operation binding the contract event 0x53f7a6ee85aab0f20869755601a6424676aa3807e9ef249627fa11a39e9a0e0c.
//
// Solidity: event UpdateTooFrequent()
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchUpdateTooFrequent(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorUpdateTooFrequent) (event.Subscription, error) {

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "UpdateTooFrequent")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorUpdateTooFrequent)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "UpdateTooFrequent", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseUpdateTooFrequent(log types.Log) (*ISuperVaultAggregatorUpdateTooFrequent, error) {
	event := new(ISuperVaultAggregatorUpdateTooFrequent)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "UpdateTooFrequent", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorUpkeepClaimedIterator is returned from FilterUpkeepClaimed and is used to iterate over the raw logs and unpacked data for UpkeepClaimed events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorUpkeepClaimedIterator struct {
	Event *ISuperVaultAggregatorUpkeepClaimed // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorUpkeepClaimedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorUpkeepClaimed)
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
		it.Event = new(ISuperVaultAggregatorUpkeepClaimed)
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
func (it *ISuperVaultAggregatorUpkeepClaimedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorUpkeepClaimedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorUpkeepClaimed represents a UpkeepClaimed event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorUpkeepClaimed struct {
	SuperBank common.Address
	Amount    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterUpkeepClaimed is a free log retrieval operation binding the contract event 0x43214536812d90daa91186dfb744049f5e3c6f3379765892f0f41b204a87e0ee.
//
// Solidity: event UpkeepClaimed(address indexed superBank, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterUpkeepClaimed(opts *bind.FilterOpts, superBank []common.Address) (*ISuperVaultAggregatorUpkeepClaimedIterator, error) {

	var superBankRule []interface{}
	for _, superBankItem := range superBank {
		superBankRule = append(superBankRule, superBankItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "UpkeepClaimed", superBankRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorUpkeepClaimedIterator{contract: _ISuperVaultAggregator.contract, event: "UpkeepClaimed", logs: logs, sub: sub}, nil
}

// WatchUpkeepClaimed is a free log subscription operation binding the contract event 0x43214536812d90daa91186dfb744049f5e3c6f3379765892f0f41b204a87e0ee.
//
// Solidity: event UpkeepClaimed(address indexed superBank, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchUpkeepClaimed(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorUpkeepClaimed, superBank []common.Address) (event.Subscription, error) {

	var superBankRule []interface{}
	for _, superBankItem := range superBank {
		superBankRule = append(superBankRule, superBankItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "UpkeepClaimed", superBankRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorUpkeepClaimed)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "UpkeepClaimed", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseUpkeepClaimed(log types.Log) (*ISuperVaultAggregatorUpkeepClaimed, error) {
	event := new(ISuperVaultAggregatorUpkeepClaimed)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "UpkeepClaimed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorUpkeepCostUpdatedIterator is returned from FilterUpkeepCostUpdated and is used to iterate over the raw logs and unpacked data for UpkeepCostUpdated events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorUpkeepCostUpdatedIterator struct {
	Event *ISuperVaultAggregatorUpkeepCostUpdated // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorUpkeepCostUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorUpkeepCostUpdated)
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
		it.Event = new(ISuperVaultAggregatorUpkeepCostUpdated)
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
func (it *ISuperVaultAggregatorUpkeepCostUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorUpkeepCostUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorUpkeepCostUpdated represents a UpkeepCostUpdated event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorUpkeepCostUpdated struct {
	OldCost *big.Int
	NewCost *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterUpkeepCostUpdated is a free log retrieval operation binding the contract event 0x39bca166dfce33a0df0f6a53e61159a307a9cf65e4c4982a9d025df35b60e746.
//
// Solidity: event UpkeepCostUpdated(uint256 oldCost, uint256 newCost)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterUpkeepCostUpdated(opts *bind.FilterOpts) (*ISuperVaultAggregatorUpkeepCostUpdatedIterator, error) {

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "UpkeepCostUpdated")
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorUpkeepCostUpdatedIterator{contract: _ISuperVaultAggregator.contract, event: "UpkeepCostUpdated", logs: logs, sub: sub}, nil
}

// WatchUpkeepCostUpdated is a free log subscription operation binding the contract event 0x39bca166dfce33a0df0f6a53e61159a307a9cf65e4c4982a9d025df35b60e746.
//
// Solidity: event UpkeepCostUpdated(uint256 oldCost, uint256 newCost)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchUpkeepCostUpdated(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorUpkeepCostUpdated) (event.Subscription, error) {

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "UpkeepCostUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorUpkeepCostUpdated)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "UpkeepCostUpdated", log); err != nil {
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

// ParseUpkeepCostUpdated is a log parse operation binding the contract event 0x39bca166dfce33a0df0f6a53e61159a307a9cf65e4c4982a9d025df35b60e746.
//
// Solidity: event UpkeepCostUpdated(uint256 oldCost, uint256 newCost)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseUpkeepCostUpdated(log types.Log) (*ISuperVaultAggregatorUpkeepCostUpdated, error) {
	event := new(ISuperVaultAggregatorUpkeepCostUpdated)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "UpkeepCostUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorUpkeepDepositedIterator is returned from FilterUpkeepDeposited and is used to iterate over the raw logs and unpacked data for UpkeepDeposited events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorUpkeepDepositedIterator struct {
	Event *ISuperVaultAggregatorUpkeepDeposited // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorUpkeepDepositedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorUpkeepDeposited)
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
		it.Event = new(ISuperVaultAggregatorUpkeepDeposited)
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
func (it *ISuperVaultAggregatorUpkeepDepositedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorUpkeepDepositedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorUpkeepDeposited represents a UpkeepDeposited event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorUpkeepDeposited struct {
	Manager common.Address
	Amount  *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterUpkeepDeposited is a free log retrieval operation binding the contract event 0xf0616af70d35af23c32610a6397a036a898c088ade99b972a26dc56e54798865.
//
// Solidity: event UpkeepDeposited(address indexed manager, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterUpkeepDeposited(opts *bind.FilterOpts, manager []common.Address) (*ISuperVaultAggregatorUpkeepDepositedIterator, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "UpkeepDeposited", managerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorUpkeepDepositedIterator{contract: _ISuperVaultAggregator.contract, event: "UpkeepDeposited", logs: logs, sub: sub}, nil
}

// WatchUpkeepDeposited is a free log subscription operation binding the contract event 0xf0616af70d35af23c32610a6397a036a898c088ade99b972a26dc56e54798865.
//
// Solidity: event UpkeepDeposited(address indexed manager, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchUpkeepDeposited(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorUpkeepDeposited, manager []common.Address) (event.Subscription, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "UpkeepDeposited", managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorUpkeepDeposited)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "UpkeepDeposited", log); err != nil {
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

// ParseUpkeepDeposited is a log parse operation binding the contract event 0xf0616af70d35af23c32610a6397a036a898c088ade99b972a26dc56e54798865.
//
// Solidity: event UpkeepDeposited(address indexed manager, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseUpkeepDeposited(log types.Log) (*ISuperVaultAggregatorUpkeepDeposited, error) {
	event := new(ISuperVaultAggregatorUpkeepDeposited)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "UpkeepDeposited", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorUpkeepSpentIterator is returned from FilterUpkeepSpent and is used to iterate over the raw logs and unpacked data for UpkeepSpent events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorUpkeepSpentIterator struct {
	Event *ISuperVaultAggregatorUpkeepSpent // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorUpkeepSpentIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorUpkeepSpent)
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
		it.Event = new(ISuperVaultAggregatorUpkeepSpent)
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
func (it *ISuperVaultAggregatorUpkeepSpentIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorUpkeepSpentIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorUpkeepSpent represents a UpkeepSpent event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorUpkeepSpent struct {
	Manager         common.Address
	Amount          *big.Int
	Balance         *big.Int
	ClaimableUpkeep *big.Int
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterUpkeepSpent is a free log retrieval operation binding the contract event 0x70485ec1c1ebd5a2176ff9969ef90917bbeca387cb89fee9a5fac5840d7253d9.
//
// Solidity: event UpkeepSpent(address indexed manager, uint256 amount, uint256 balance, uint256 claimableUpkeep)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterUpkeepSpent(opts *bind.FilterOpts, manager []common.Address) (*ISuperVaultAggregatorUpkeepSpentIterator, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "UpkeepSpent", managerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorUpkeepSpentIterator{contract: _ISuperVaultAggregator.contract, event: "UpkeepSpent", logs: logs, sub: sub}, nil
}

// WatchUpkeepSpent is a free log subscription operation binding the contract event 0x70485ec1c1ebd5a2176ff9969ef90917bbeca387cb89fee9a5fac5840d7253d9.
//
// Solidity: event UpkeepSpent(address indexed manager, uint256 amount, uint256 balance, uint256 claimableUpkeep)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchUpkeepSpent(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorUpkeepSpent, manager []common.Address) (event.Subscription, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "UpkeepSpent", managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorUpkeepSpent)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "UpkeepSpent", log); err != nil {
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
// Solidity: event UpkeepSpent(address indexed manager, uint256 amount, uint256 balance, uint256 claimableUpkeep)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseUpkeepSpent(log types.Log) (*ISuperVaultAggregatorUpkeepSpent, error) {
	event := new(ISuperVaultAggregatorUpkeepSpent)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "UpkeepSpent", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorUpkeepWithdrawnIterator is returned from FilterUpkeepWithdrawn and is used to iterate over the raw logs and unpacked data for UpkeepWithdrawn events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorUpkeepWithdrawnIterator struct {
	Event *ISuperVaultAggregatorUpkeepWithdrawn // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorUpkeepWithdrawnIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorUpkeepWithdrawn)
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
		it.Event = new(ISuperVaultAggregatorUpkeepWithdrawn)
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
func (it *ISuperVaultAggregatorUpkeepWithdrawnIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorUpkeepWithdrawnIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorUpkeepWithdrawn represents a UpkeepWithdrawn event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorUpkeepWithdrawn struct {
	Manager common.Address
	Amount  *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterUpkeepWithdrawn is a free log retrieval operation binding the contract event 0x4a588cb81e6e407560dfbf48e566f684e0b6b791bd8ced912e4f9c58aa99e3d2.
//
// Solidity: event UpkeepWithdrawn(address indexed manager, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterUpkeepWithdrawn(opts *bind.FilterOpts, manager []common.Address) (*ISuperVaultAggregatorUpkeepWithdrawnIterator, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "UpkeepWithdrawn", managerRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorUpkeepWithdrawnIterator{contract: _ISuperVaultAggregator.contract, event: "UpkeepWithdrawn", logs: logs, sub: sub}, nil
}

// WatchUpkeepWithdrawn is a free log subscription operation binding the contract event 0x4a588cb81e6e407560dfbf48e566f684e0b6b791bd8ced912e4f9c58aa99e3d2.
//
// Solidity: event UpkeepWithdrawn(address indexed manager, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchUpkeepWithdrawn(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorUpkeepWithdrawn, manager []common.Address) (event.Subscription, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "UpkeepWithdrawn", managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorUpkeepWithdrawn)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "UpkeepWithdrawn", log); err != nil {
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

// ParseUpkeepWithdrawn is a log parse operation binding the contract event 0x4a588cb81e6e407560dfbf48e566f684e0b6b791bd8ced912e4f9c58aa99e3d2.
//
// Solidity: event UpkeepWithdrawn(address indexed manager, uint256 amount)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseUpkeepWithdrawn(log types.Log) (*ISuperVaultAggregatorUpkeepWithdrawn, error) {
	event := new(ISuperVaultAggregatorUpkeepWithdrawn)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "UpkeepWithdrawn", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperVaultAggregatorVaultDeployedIterator is returned from FilterVaultDeployed and is used to iterate over the raw logs and unpacked data for VaultDeployed events raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorVaultDeployedIterator struct {
	Event *ISuperVaultAggregatorVaultDeployed // Event containing the contract specifics and raw log

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
func (it *ISuperVaultAggregatorVaultDeployedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperVaultAggregatorVaultDeployed)
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
		it.Event = new(ISuperVaultAggregatorVaultDeployed)
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
func (it *ISuperVaultAggregatorVaultDeployedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperVaultAggregatorVaultDeployedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperVaultAggregatorVaultDeployed represents a VaultDeployed event raised by the ISuperVaultAggregator contract.
type ISuperVaultAggregatorVaultDeployed struct {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) FilterVaultDeployed(opts *bind.FilterOpts, vault []common.Address, strategy []common.Address, nonce []*big.Int) (*ISuperVaultAggregatorVaultDeployedIterator, error) {

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

	logs, sub, err := _ISuperVaultAggregator.contract.FilterLogs(opts, "VaultDeployed", vaultRule, strategyRule, nonceRule)
	if err != nil {
		return nil, err
	}
	return &ISuperVaultAggregatorVaultDeployedIterator{contract: _ISuperVaultAggregator.contract, event: "VaultDeployed", logs: logs, sub: sub}, nil
}

// WatchVaultDeployed is a free log subscription operation binding the contract event 0xb71e4c3b886bfa372037021505c466d28e41fc077044f0f8be29eeff13713347.
//
// Solidity: event VaultDeployed(address indexed vault, address indexed strategy, address escrow, address asset, string name, string symbol, uint256 indexed nonce)
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) WatchVaultDeployed(opts *bind.WatchOpts, sink chan<- *ISuperVaultAggregatorVaultDeployed, vault []common.Address, strategy []common.Address, nonce []*big.Int) (event.Subscription, error) {

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

	logs, sub, err := _ISuperVaultAggregator.contract.WatchLogs(opts, "VaultDeployed", vaultRule, strategyRule, nonceRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperVaultAggregatorVaultDeployed)
				if err := _ISuperVaultAggregator.contract.UnpackLog(event, "VaultDeployed", log); err != nil {
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
func (_ISuperVaultAggregator *ISuperVaultAggregatorFilterer) ParseVaultDeployed(log types.Log) (*ISuperVaultAggregatorVaultDeployed, error) {
	event := new(ISuperVaultAggregatorVaultDeployed)
	if err := _ISuperVaultAggregator.contract.UnpackLog(event, "VaultDeployed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
