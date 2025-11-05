// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package SuperVaultAggregator

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

// SuperVaultAggregatorMetaData contains all meta data concerning the SuperVaultAggregator contract.
var SuperVaultAggregatorMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"superGovernor_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"vaultImpl_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"strategyImpl_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"escrowImpl_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"ESCROW_IMPLEMENTATION\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"MAX_SECONDARY_MANAGERS\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"PPS_DECIMALS\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"STRATEGY_IMPLEMENTATION\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_GOVERNOR\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISuperGovernor\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"VAULT_IMPLEMENTATION\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"WITHDRAWAL_REQUEST_TIMEOUT\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"WITHDRAW_STAKE_TIMELOCK\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addAuthorizedCaller\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"caller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addSecondaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"changeGlobalLeavesStatus\",\"inputs\":[{\"name\":\"leaves\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"},{\"name\":\"statuses\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"changePrimaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newManager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"claimUpkeep\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"claimableUpkeep\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"completeStakeWithdrawal\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"createVault\",\"inputs\":[{\"name\":\"params\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultAggregator.VaultCreationParams\",\"components\":[{\"name\":\"asset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"symbol\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"mainManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"secondaryManagers\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"minUpdateInterval\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxStaleness\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"feeConfig\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultStrategy.FeeConfig\",\"components\":[{\"name\":\"performanceFeeBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"managementFeeBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"recipient\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"name\":\"maxUnpauseTimeLock\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"outputs\":[{\"name\":\"superVault\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"escrow\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"depositStake\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"depositUpkeep\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeChangePrimaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeGlobalHooksRootUpdate\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeStrategyHooksRootUpdate\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"forwardPPS\",\"inputs\":[{\"name\":\"args\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultAggregator.ForwardPPSArgs\",\"components\":[{\"name\":\"strategies\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"ppss\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"validatorSets\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"totalValidator\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"timestamps\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"updateAuthority\",\"type\":\"address\",\"internalType\":\"address\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getAllSuperVaultEscrows\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAllSuperVaultStrategies\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAllSuperVaults\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAuthorizedCallers\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"callers\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCurrentNonce\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getGlobalHooksRoot\",\"inputs\":[],\"outputs\":[{\"name\":\"root\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getHooksRootUpdateTimelock\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getLastUpdateTimestamp\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMainManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMaxStaleness\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"staleness\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMinUpdateInterval\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"interval\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getPPS\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"pps\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getPPSVerificationThresholds\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"deviationThreshold\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"mnThreshold\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedGlobalHooksRoot\",\"inputs\":[],\"outputs\":[{\"name\":\"root\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getProposedStrategyHooksRoot\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"root\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSecondaryManagers\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getStakeBalance\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getStrategyHooksRoot\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"root\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getUpkeepBalance\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isAnyManager\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isGlobalHooksRootActive\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isGlobalHooksRootVetoed\",\"inputs\":[],\"outputs\":[{\"name\":\"vetoed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isMainManager\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isPPSStale\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"isStale\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isSecondaryManager\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isStrategyHooksRootVetoed\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"vetoed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isStrategyPaused\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"isPaused\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"managerWithdrawalRequests\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pauseStrategy\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeChangePrimaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newManager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeGlobalHooksRoot\",\"inputs\":[{\"name\":\"newRoot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposeStrategyHooksRoot\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newRoot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeAuthorizedCaller\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"caller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeSecondaryManager\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"requestStakeWithdrawal\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setGlobalHooksRootVetoStatus\",\"inputs\":[{\"name\":\"vetoed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setHooksRootUpdateTimelock\",\"inputs\":[{\"name\":\"newTimelock\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setStrategyHooksRootVetoStatus\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"vetoed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"slashStake\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"superVaultEscrows\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"superVaultStrategies\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"superVaults\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"unpauseStrategy\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"updatePPSAfterSkim\",\"inputs\":[{\"name\":\"newPPS\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"feeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"updatePPSVerificationThresholds\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"deviationThreshold_\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"mnThreshold_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"validateHook\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"args\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultAggregator.ValidateHookArgs\",\"components\":[{\"name\":\"hookAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"hookArgs\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"globalProof\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"},{\"name\":\"strategyProof\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"}]}],\"outputs\":[{\"name\":\"isValid\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validateHooks\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"argsArray\",\"type\":\"tuple[]\",\"internalType\":\"structISuperVaultAggregator.ValidateHookArgs[]\",\"components\":[{\"name\":\"hookAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"hookArgs\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"globalProof\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"},{\"name\":\"strategyProof\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"}]}],\"outputs\":[{\"name\":\"validHooks\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"withdrawUpkeep\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"AuthorizedCaller\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"caller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AuthorizedCallerAdded\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"caller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AuthorizedCallerRemoved\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"caller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"GlobalHooksRootUpdateProposed\",\"inputs\":[{\"name\":\"root\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"GlobalHooksRootUpdated\",\"inputs\":[{\"name\":\"oldRoot\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newRoot\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"GlobalHooksRootVetoStatusChanged\",\"inputs\":[{\"name\":\"vetoed\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"},{\"name\":\"root\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"GlobalHooksRootVetoed\",\"inputs\":[{\"name\":\"guardian\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"root\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"GlobalLeavesStatusChanged\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"leaves\",\"type\":\"bytes32[]\",\"indexed\":false,\"internalType\":\"bytes32[]\"},{\"name\":\"statuses\",\"type\":\"bool[]\",\"indexed\":false,\"internalType\":\"bool[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"HooksRootUpdateTimelockChanged\",\"inputs\":[{\"name\":\"newTimelock\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"InsufficientUpkeep\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"balance\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"cost\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OldPrimaryManagerRemoved\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"oldManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSUpdated\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"pps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"validatorSet\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"totalValidators\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSUpdatedAfterSkim\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"oldPPS\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"newPPS\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"feeAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSVerificationThresholdsUpdated\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"deviationThreshold\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"mnThreshold\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PaymentSkippedForPausedStrategy\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PrimaryManagerChangeProposed\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"proposer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PrimaryManagerChanged\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"oldManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PrimaryManagerChangedToSuperform\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"oldManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ProvidedTimestampExceedsBlockTimestamp\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"argsTimestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"blockTimestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SecondaryManagerAdded\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SecondaryManagerRemoved\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StakeDeposited\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StakeSlashed\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StakeWithdrawRequested\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StakeWithdrawn\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StaleUpdate\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"updateAuthority\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyCheckFailed\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"reason\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyHooksRootUpdateProposed\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"proposer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"root\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyHooksRootUpdated\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"oldRoot\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"newRoot\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyHooksRootVetoStatusChanged\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"vetoed\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"},{\"name\":\"root\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyHooksRootVetoed\",\"inputs\":[{\"name\":\"guardian\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"root\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyPPSStale\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyPPSStaleReset\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyPaused\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyUnpausePPSTimelockUpdated\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newTimelock\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StrategyUnpaused\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TimestampNotMonotonic\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UnknownStrategy\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpdateTooFrequent\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepClaimed\",\"inputs\":[{\"name\":\"superBank\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepCostUpdated\",\"inputs\":[{\"name\":\"oldCost\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"newCost\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepDeposited\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepSpent\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"balance\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"claimableUpkeep\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UpkeepWithdrawn\",\"inputs\":[{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"VaultDeployed\",\"inputs\":[{\"name\":\"vault\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"escrow\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"asset\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"name\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"symbol\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ARRAY_LENGTH_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CALLER_ALREADY_AUTHORIZED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CALLER_NOT_AUTHORIZED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CANNOT_ADD_PROTECTED_KEEPER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CANNOT_REMOVE_LAST_MANAGER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FailedDeployment\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"HOOK_VALIDATION_FAILED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INDEX_OUT_OF_BOUNDS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_STAKE_BALANCE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_UPKEEP\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_UPKEEP_BALANCE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_ARRAY_LENGTH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_ASSET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_ASSET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_TIMESTAMP\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"InsufficientBalance\",\"inputs\":[{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"needed\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"MANAGER_ALREADY_EXISTS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MANAGER_CHANGE_NOT_READY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MANAGER_NOT_FOUND\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MAX_STALENESS_TOO_LOW\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MISMATCHED_ARRAY_LENGTHS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_A_GUARDIAN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_PENDING_GLOBAL_ROOT_CHANGE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_PENDING_MANAGER_CHANGE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_PENDING_ROOT_UPDATE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PPS_DEDUCTION_TOO_LARGE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PPS_MUST_DECREASE_AFTER_SKIM\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ROOT_UPDATE_NOT_READY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"STRATEGY_ALREADY_PAUSED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"STRATEGY_NOT_PAUSED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"TIMELOCK_NOT_EXPIRED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"TOO_MANY_SECONDARY_MANAGERS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UNAUTHORIZED_CALLER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UNAUTHORIZED_PPS_ORACLE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UNAUTHORIZED_UPDATE_AUTHORITY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UNKNOWN_STRATEGY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UNPAUSE_TIMELOCK_NOT_MET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UPDATE_TOO_STALE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"VAULT_PAUSED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"WITHDRAWAL_REQUEST_EXPIRED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"WITHDRAW_STAKE_REQUEST_NOT_FOUND\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"WITHDRAW_STAKE_REQUEST_NOT_READY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_AMOUNT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_ARRAY_LENGTH\",\"inputs\":[]}]",
}

// SuperVaultAggregatorABI is the input ABI used to generate the binding from.
// Deprecated: Use SuperVaultAggregatorMetaData.ABI instead.
var SuperVaultAggregatorABI = SuperVaultAggregatorMetaData.ABI

// SuperVaultAggregator is an auto generated Go binding around an Ethereum contract.
type SuperVaultAggregator struct {
	SuperVaultAggregatorCaller     // Read-only binding to the contract
	SuperVaultAggregatorTransactor // Write-only binding to the contract
	SuperVaultAggregatorFilterer   // Log filterer for contract events
}

// SuperVaultAggregatorCaller is an auto generated read-only Go binding around an Ethereum contract.
type SuperVaultAggregatorCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultAggregatorTransactor is an auto generated write-only Go binding around an Ethereum contract.
type SuperVaultAggregatorTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultAggregatorFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type SuperVaultAggregatorFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultAggregatorSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type SuperVaultAggregatorSession struct {
	Contract     *SuperVaultAggregator // Generic contract binding to set the session for
	CallOpts     bind.CallOpts         // Call options to use throughout this session
	TransactOpts bind.TransactOpts     // Transaction auth options to use throughout this session
}

// SuperVaultAggregatorCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type SuperVaultAggregatorCallerSession struct {
	Contract *SuperVaultAggregatorCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts               // Call options to use throughout this session
}

// SuperVaultAggregatorTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type SuperVaultAggregatorTransactorSession struct {
	Contract     *SuperVaultAggregatorTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts               // Transaction auth options to use throughout this session
}

// SuperVaultAggregatorRaw is an auto generated low-level Go binding around an Ethereum contract.
type SuperVaultAggregatorRaw struct {
	Contract *SuperVaultAggregator // Generic contract binding to access the raw methods on
}

// SuperVaultAggregatorCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type SuperVaultAggregatorCallerRaw struct {
	Contract *SuperVaultAggregatorCaller // Generic read-only contract binding to access the raw methods on
}

// SuperVaultAggregatorTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type SuperVaultAggregatorTransactorRaw struct {
	Contract *SuperVaultAggregatorTransactor // Generic write-only contract binding to access the raw methods on
}

// NewSuperVaultAggregator creates a new instance of SuperVaultAggregator, bound to a specific deployed contract.
func NewSuperVaultAggregator(address common.Address, backend bind.ContractBackend) (*SuperVaultAggregator, error) {
	contract, err := bindSuperVaultAggregator(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregator{SuperVaultAggregatorCaller: SuperVaultAggregatorCaller{contract: contract}, SuperVaultAggregatorTransactor: SuperVaultAggregatorTransactor{contract: contract}, SuperVaultAggregatorFilterer: SuperVaultAggregatorFilterer{contract: contract}}, nil
}

// NewSuperVaultAggregatorCaller creates a new read-only instance of SuperVaultAggregator, bound to a specific deployed contract.
func NewSuperVaultAggregatorCaller(address common.Address, caller bind.ContractCaller) (*SuperVaultAggregatorCaller, error) {
	contract, err := bindSuperVaultAggregator(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorCaller{contract: contract}, nil
}

// NewSuperVaultAggregatorTransactor creates a new write-only instance of SuperVaultAggregator, bound to a specific deployed contract.
func NewSuperVaultAggregatorTransactor(address common.Address, transactor bind.ContractTransactor) (*SuperVaultAggregatorTransactor, error) {
	contract, err := bindSuperVaultAggregator(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorTransactor{contract: contract}, nil
}

// NewSuperVaultAggregatorFilterer creates a new log filterer instance of SuperVaultAggregator, bound to a specific deployed contract.
func NewSuperVaultAggregatorFilterer(address common.Address, filterer bind.ContractFilterer) (*SuperVaultAggregatorFilterer, error) {
	contract, err := bindSuperVaultAggregator(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorFilterer{contract: contract}, nil
}

// bindSuperVaultAggregator binds a generic wrapper to an already deployed contract.
func bindSuperVaultAggregator(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := SuperVaultAggregatorMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperVaultAggregator *SuperVaultAggregatorRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperVaultAggregator.Contract.SuperVaultAggregatorCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperVaultAggregator *SuperVaultAggregatorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.SuperVaultAggregatorTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperVaultAggregator *SuperVaultAggregatorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.SuperVaultAggregatorTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperVaultAggregator *SuperVaultAggregatorCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperVaultAggregator.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.contract.Transact(opts, method, params...)
}

// ESCROWIMPLEMENTATION is a free data retrieval call binding the contract method 0x1de18ae6.
//
// Solidity: function ESCROW_IMPLEMENTATION() view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) ESCROWIMPLEMENTATION(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "ESCROW_IMPLEMENTATION")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ESCROWIMPLEMENTATION is a free data retrieval call binding the contract method 0x1de18ae6.
//
// Solidity: function ESCROW_IMPLEMENTATION() view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) ESCROWIMPLEMENTATION() (common.Address, error) {
	return _SuperVaultAggregator.Contract.ESCROWIMPLEMENTATION(&_SuperVaultAggregator.CallOpts)
}

// ESCROWIMPLEMENTATION is a free data retrieval call binding the contract method 0x1de18ae6.
//
// Solidity: function ESCROW_IMPLEMENTATION() view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) ESCROWIMPLEMENTATION() (common.Address, error) {
	return _SuperVaultAggregator.Contract.ESCROWIMPLEMENTATION(&_SuperVaultAggregator.CallOpts)
}

// MAXSECONDARYMANAGERS is a free data retrieval call binding the contract method 0x08db8901.
//
// Solidity: function MAX_SECONDARY_MANAGERS() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) MAXSECONDARYMANAGERS(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "MAX_SECONDARY_MANAGERS")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MAXSECONDARYMANAGERS is a free data retrieval call binding the contract method 0x08db8901.
//
// Solidity: function MAX_SECONDARY_MANAGERS() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) MAXSECONDARYMANAGERS() (*big.Int, error) {
	return _SuperVaultAggregator.Contract.MAXSECONDARYMANAGERS(&_SuperVaultAggregator.CallOpts)
}

// MAXSECONDARYMANAGERS is a free data retrieval call binding the contract method 0x08db8901.
//
// Solidity: function MAX_SECONDARY_MANAGERS() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) MAXSECONDARYMANAGERS() (*big.Int, error) {
	return _SuperVaultAggregator.Contract.MAXSECONDARYMANAGERS(&_SuperVaultAggregator.CallOpts)
}

// PPSDECIMALS is a free data retrieval call binding the contract method 0x13b56ce7.
//
// Solidity: function PPS_DECIMALS() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) PPSDECIMALS(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "PPS_DECIMALS")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PPSDECIMALS is a free data retrieval call binding the contract method 0x13b56ce7.
//
// Solidity: function PPS_DECIMALS() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) PPSDECIMALS() (*big.Int, error) {
	return _SuperVaultAggregator.Contract.PPSDECIMALS(&_SuperVaultAggregator.CallOpts)
}

// PPSDECIMALS is a free data retrieval call binding the contract method 0x13b56ce7.
//
// Solidity: function PPS_DECIMALS() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) PPSDECIMALS() (*big.Int, error) {
	return _SuperVaultAggregator.Contract.PPSDECIMALS(&_SuperVaultAggregator.CallOpts)
}

// STRATEGYIMPLEMENTATION is a free data retrieval call binding the contract method 0xf301061d.
//
// Solidity: function STRATEGY_IMPLEMENTATION() view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) STRATEGYIMPLEMENTATION(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "STRATEGY_IMPLEMENTATION")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// STRATEGYIMPLEMENTATION is a free data retrieval call binding the contract method 0xf301061d.
//
// Solidity: function STRATEGY_IMPLEMENTATION() view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) STRATEGYIMPLEMENTATION() (common.Address, error) {
	return _SuperVaultAggregator.Contract.STRATEGYIMPLEMENTATION(&_SuperVaultAggregator.CallOpts)
}

// STRATEGYIMPLEMENTATION is a free data retrieval call binding the contract method 0xf301061d.
//
// Solidity: function STRATEGY_IMPLEMENTATION() view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) STRATEGYIMPLEMENTATION() (common.Address, error) {
	return _SuperVaultAggregator.Contract.STRATEGYIMPLEMENTATION(&_SuperVaultAggregator.CallOpts)
}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) SUPERGOVERNOR(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "SUPER_GOVERNOR")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) SUPERGOVERNOR() (common.Address, error) {
	return _SuperVaultAggregator.Contract.SUPERGOVERNOR(&_SuperVaultAggregator.CallOpts)
}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) SUPERGOVERNOR() (common.Address, error) {
	return _SuperVaultAggregator.Contract.SUPERGOVERNOR(&_SuperVaultAggregator.CallOpts)
}

// VAULTIMPLEMENTATION is a free data retrieval call binding the contract method 0x1f9b5aaf.
//
// Solidity: function VAULT_IMPLEMENTATION() view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) VAULTIMPLEMENTATION(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "VAULT_IMPLEMENTATION")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// VAULTIMPLEMENTATION is a free data retrieval call binding the contract method 0x1f9b5aaf.
//
// Solidity: function VAULT_IMPLEMENTATION() view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) VAULTIMPLEMENTATION() (common.Address, error) {
	return _SuperVaultAggregator.Contract.VAULTIMPLEMENTATION(&_SuperVaultAggregator.CallOpts)
}

// VAULTIMPLEMENTATION is a free data retrieval call binding the contract method 0x1f9b5aaf.
//
// Solidity: function VAULT_IMPLEMENTATION() view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) VAULTIMPLEMENTATION() (common.Address, error) {
	return _SuperVaultAggregator.Contract.VAULTIMPLEMENTATION(&_SuperVaultAggregator.CallOpts)
}

// WITHDRAWALREQUESTTIMEOUT is a free data retrieval call binding the contract method 0xc3664eca.
//
// Solidity: function WITHDRAWAL_REQUEST_TIMEOUT() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) WITHDRAWALREQUESTTIMEOUT(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "WITHDRAWAL_REQUEST_TIMEOUT")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// WITHDRAWALREQUESTTIMEOUT is a free data retrieval call binding the contract method 0xc3664eca.
//
// Solidity: function WITHDRAWAL_REQUEST_TIMEOUT() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) WITHDRAWALREQUESTTIMEOUT() (*big.Int, error) {
	return _SuperVaultAggregator.Contract.WITHDRAWALREQUESTTIMEOUT(&_SuperVaultAggregator.CallOpts)
}

// WITHDRAWALREQUESTTIMEOUT is a free data retrieval call binding the contract method 0xc3664eca.
//
// Solidity: function WITHDRAWAL_REQUEST_TIMEOUT() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) WITHDRAWALREQUESTTIMEOUT() (*big.Int, error) {
	return _SuperVaultAggregator.Contract.WITHDRAWALREQUESTTIMEOUT(&_SuperVaultAggregator.CallOpts)
}

// WITHDRAWSTAKETIMELOCK is a free data retrieval call binding the contract method 0xa66167fa.
//
// Solidity: function WITHDRAW_STAKE_TIMELOCK() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) WITHDRAWSTAKETIMELOCK(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "WITHDRAW_STAKE_TIMELOCK")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// WITHDRAWSTAKETIMELOCK is a free data retrieval call binding the contract method 0xa66167fa.
//
// Solidity: function WITHDRAW_STAKE_TIMELOCK() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) WITHDRAWSTAKETIMELOCK() (*big.Int, error) {
	return _SuperVaultAggregator.Contract.WITHDRAWSTAKETIMELOCK(&_SuperVaultAggregator.CallOpts)
}

// WITHDRAWSTAKETIMELOCK is a free data retrieval call binding the contract method 0xa66167fa.
//
// Solidity: function WITHDRAW_STAKE_TIMELOCK() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) WITHDRAWSTAKETIMELOCK() (*big.Int, error) {
	return _SuperVaultAggregator.Contract.WITHDRAWSTAKETIMELOCK(&_SuperVaultAggregator.CallOpts)
}

// ClaimableUpkeep is a free data retrieval call binding the contract method 0x05027eee.
//
// Solidity: function claimableUpkeep() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) ClaimableUpkeep(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "claimableUpkeep")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ClaimableUpkeep is a free data retrieval call binding the contract method 0x05027eee.
//
// Solidity: function claimableUpkeep() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) ClaimableUpkeep() (*big.Int, error) {
	return _SuperVaultAggregator.Contract.ClaimableUpkeep(&_SuperVaultAggregator.CallOpts)
}

// ClaimableUpkeep is a free data retrieval call binding the contract method 0x05027eee.
//
// Solidity: function claimableUpkeep() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) ClaimableUpkeep() (*big.Int, error) {
	return _SuperVaultAggregator.Contract.ClaimableUpkeep(&_SuperVaultAggregator.CallOpts)
}

// GetAllSuperVaultEscrows is a free data retrieval call binding the contract method 0x154fd23f.
//
// Solidity: function getAllSuperVaultEscrows() view returns(address[])
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetAllSuperVaultEscrows(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getAllSuperVaultEscrows")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetAllSuperVaultEscrows is a free data retrieval call binding the contract method 0x154fd23f.
//
// Solidity: function getAllSuperVaultEscrows() view returns(address[])
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetAllSuperVaultEscrows() ([]common.Address, error) {
	return _SuperVaultAggregator.Contract.GetAllSuperVaultEscrows(&_SuperVaultAggregator.CallOpts)
}

// GetAllSuperVaultEscrows is a free data retrieval call binding the contract method 0x154fd23f.
//
// Solidity: function getAllSuperVaultEscrows() view returns(address[])
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetAllSuperVaultEscrows() ([]common.Address, error) {
	return _SuperVaultAggregator.Contract.GetAllSuperVaultEscrows(&_SuperVaultAggregator.CallOpts)
}

// GetAllSuperVaultStrategies is a free data retrieval call binding the contract method 0x8e9615c9.
//
// Solidity: function getAllSuperVaultStrategies() view returns(address[])
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetAllSuperVaultStrategies(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getAllSuperVaultStrategies")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetAllSuperVaultStrategies is a free data retrieval call binding the contract method 0x8e9615c9.
//
// Solidity: function getAllSuperVaultStrategies() view returns(address[])
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetAllSuperVaultStrategies() ([]common.Address, error) {
	return _SuperVaultAggregator.Contract.GetAllSuperVaultStrategies(&_SuperVaultAggregator.CallOpts)
}

// GetAllSuperVaultStrategies is a free data retrieval call binding the contract method 0x8e9615c9.
//
// Solidity: function getAllSuperVaultStrategies() view returns(address[])
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetAllSuperVaultStrategies() ([]common.Address, error) {
	return _SuperVaultAggregator.Contract.GetAllSuperVaultStrategies(&_SuperVaultAggregator.CallOpts)
}

// GetAllSuperVaults is a free data retrieval call binding the contract method 0xa5256bf2.
//
// Solidity: function getAllSuperVaults() view returns(address[])
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetAllSuperVaults(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getAllSuperVaults")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetAllSuperVaults is a free data retrieval call binding the contract method 0xa5256bf2.
//
// Solidity: function getAllSuperVaults() view returns(address[])
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetAllSuperVaults() ([]common.Address, error) {
	return _SuperVaultAggregator.Contract.GetAllSuperVaults(&_SuperVaultAggregator.CallOpts)
}

// GetAllSuperVaults is a free data retrieval call binding the contract method 0xa5256bf2.
//
// Solidity: function getAllSuperVaults() view returns(address[])
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetAllSuperVaults() ([]common.Address, error) {
	return _SuperVaultAggregator.Contract.GetAllSuperVaults(&_SuperVaultAggregator.CallOpts)
}

// GetAuthorizedCallers is a free data retrieval call binding the contract method 0xceb18ce4.
//
// Solidity: function getAuthorizedCallers(address strategy) view returns(address[] callers)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetAuthorizedCallers(opts *bind.CallOpts, strategy common.Address) ([]common.Address, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getAuthorizedCallers", strategy)

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetAuthorizedCallers is a free data retrieval call binding the contract method 0xceb18ce4.
//
// Solidity: function getAuthorizedCallers(address strategy) view returns(address[] callers)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetAuthorizedCallers(strategy common.Address) ([]common.Address, error) {
	return _SuperVaultAggregator.Contract.GetAuthorizedCallers(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetAuthorizedCallers is a free data retrieval call binding the contract method 0xceb18ce4.
//
// Solidity: function getAuthorizedCallers(address strategy) view returns(address[] callers)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetAuthorizedCallers(strategy common.Address) ([]common.Address, error) {
	return _SuperVaultAggregator.Contract.GetAuthorizedCallers(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetCurrentNonce is a free data retrieval call binding the contract method 0x3a60c386.
//
// Solidity: function getCurrentNonce() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetCurrentNonce(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getCurrentNonce")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetCurrentNonce is a free data retrieval call binding the contract method 0x3a60c386.
//
// Solidity: function getCurrentNonce() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetCurrentNonce() (*big.Int, error) {
	return _SuperVaultAggregator.Contract.GetCurrentNonce(&_SuperVaultAggregator.CallOpts)
}

// GetCurrentNonce is a free data retrieval call binding the contract method 0x3a60c386.
//
// Solidity: function getCurrentNonce() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetCurrentNonce() (*big.Int, error) {
	return _SuperVaultAggregator.Contract.GetCurrentNonce(&_SuperVaultAggregator.CallOpts)
}

// GetGlobalHooksRoot is a free data retrieval call binding the contract method 0x2a90a055.
//
// Solidity: function getGlobalHooksRoot() view returns(bytes32 root)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetGlobalHooksRoot(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getGlobalHooksRoot")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetGlobalHooksRoot is a free data retrieval call binding the contract method 0x2a90a055.
//
// Solidity: function getGlobalHooksRoot() view returns(bytes32 root)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetGlobalHooksRoot() ([32]byte, error) {
	return _SuperVaultAggregator.Contract.GetGlobalHooksRoot(&_SuperVaultAggregator.CallOpts)
}

// GetGlobalHooksRoot is a free data retrieval call binding the contract method 0x2a90a055.
//
// Solidity: function getGlobalHooksRoot() view returns(bytes32 root)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetGlobalHooksRoot() ([32]byte, error) {
	return _SuperVaultAggregator.Contract.GetGlobalHooksRoot(&_SuperVaultAggregator.CallOpts)
}

// GetHooksRootUpdateTimelock is a free data retrieval call binding the contract method 0x7be3d10f.
//
// Solidity: function getHooksRootUpdateTimelock() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetHooksRootUpdateTimelock(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getHooksRootUpdateTimelock")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetHooksRootUpdateTimelock is a free data retrieval call binding the contract method 0x7be3d10f.
//
// Solidity: function getHooksRootUpdateTimelock() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetHooksRootUpdateTimelock() (*big.Int, error) {
	return _SuperVaultAggregator.Contract.GetHooksRootUpdateTimelock(&_SuperVaultAggregator.CallOpts)
}

// GetHooksRootUpdateTimelock is a free data retrieval call binding the contract method 0x7be3d10f.
//
// Solidity: function getHooksRootUpdateTimelock() view returns(uint256)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetHooksRootUpdateTimelock() (*big.Int, error) {
	return _SuperVaultAggregator.Contract.GetHooksRootUpdateTimelock(&_SuperVaultAggregator.CallOpts)
}

// GetLastUpdateTimestamp is a free data retrieval call binding the contract method 0x1a351d62.
//
// Solidity: function getLastUpdateTimestamp(address strategy) view returns(uint256 timestamp)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetLastUpdateTimestamp(opts *bind.CallOpts, strategy common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getLastUpdateTimestamp", strategy)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetLastUpdateTimestamp is a free data retrieval call binding the contract method 0x1a351d62.
//
// Solidity: function getLastUpdateTimestamp(address strategy) view returns(uint256 timestamp)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetLastUpdateTimestamp(strategy common.Address) (*big.Int, error) {
	return _SuperVaultAggregator.Contract.GetLastUpdateTimestamp(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetLastUpdateTimestamp is a free data retrieval call binding the contract method 0x1a351d62.
//
// Solidity: function getLastUpdateTimestamp(address strategy) view returns(uint256 timestamp)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetLastUpdateTimestamp(strategy common.Address) (*big.Int, error) {
	return _SuperVaultAggregator.Contract.GetLastUpdateTimestamp(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetMainManager is a free data retrieval call binding the contract method 0xceb7b7a3.
//
// Solidity: function getMainManager(address strategy) view returns(address manager)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetMainManager(opts *bind.CallOpts, strategy common.Address) (common.Address, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getMainManager", strategy)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetMainManager is a free data retrieval call binding the contract method 0xceb7b7a3.
//
// Solidity: function getMainManager(address strategy) view returns(address manager)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetMainManager(strategy common.Address) (common.Address, error) {
	return _SuperVaultAggregator.Contract.GetMainManager(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetMainManager is a free data retrieval call binding the contract method 0xceb7b7a3.
//
// Solidity: function getMainManager(address strategy) view returns(address manager)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetMainManager(strategy common.Address) (common.Address, error) {
	return _SuperVaultAggregator.Contract.GetMainManager(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetMaxStaleness is a free data retrieval call binding the contract method 0xc25b784f.
//
// Solidity: function getMaxStaleness(address strategy) view returns(uint256 staleness)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetMaxStaleness(opts *bind.CallOpts, strategy common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getMaxStaleness", strategy)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetMaxStaleness is a free data retrieval call binding the contract method 0xc25b784f.
//
// Solidity: function getMaxStaleness(address strategy) view returns(uint256 staleness)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetMaxStaleness(strategy common.Address) (*big.Int, error) {
	return _SuperVaultAggregator.Contract.GetMaxStaleness(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetMaxStaleness is a free data retrieval call binding the contract method 0xc25b784f.
//
// Solidity: function getMaxStaleness(address strategy) view returns(uint256 staleness)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetMaxStaleness(strategy common.Address) (*big.Int, error) {
	return _SuperVaultAggregator.Contract.GetMaxStaleness(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetMinUpdateInterval is a free data retrieval call binding the contract method 0x3ab973a3.
//
// Solidity: function getMinUpdateInterval(address strategy) view returns(uint256 interval)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetMinUpdateInterval(opts *bind.CallOpts, strategy common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getMinUpdateInterval", strategy)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetMinUpdateInterval is a free data retrieval call binding the contract method 0x3ab973a3.
//
// Solidity: function getMinUpdateInterval(address strategy) view returns(uint256 interval)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetMinUpdateInterval(strategy common.Address) (*big.Int, error) {
	return _SuperVaultAggregator.Contract.GetMinUpdateInterval(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetMinUpdateInterval is a free data retrieval call binding the contract method 0x3ab973a3.
//
// Solidity: function getMinUpdateInterval(address strategy) view returns(uint256 interval)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetMinUpdateInterval(strategy common.Address) (*big.Int, error) {
	return _SuperVaultAggregator.Contract.GetMinUpdateInterval(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetPPS is a free data retrieval call binding the contract method 0xbef02b8c.
//
// Solidity: function getPPS(address strategy) view returns(uint256 pps)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetPPS(opts *bind.CallOpts, strategy common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getPPS", strategy)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetPPS is a free data retrieval call binding the contract method 0xbef02b8c.
//
// Solidity: function getPPS(address strategy) view returns(uint256 pps)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetPPS(strategy common.Address) (*big.Int, error) {
	return _SuperVaultAggregator.Contract.GetPPS(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetPPS is a free data retrieval call binding the contract method 0xbef02b8c.
//
// Solidity: function getPPS(address strategy) view returns(uint256 pps)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetPPS(strategy common.Address) (*big.Int, error) {
	return _SuperVaultAggregator.Contract.GetPPS(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetPPSVerificationThresholds is a free data retrieval call binding the contract method 0x322ae311.
//
// Solidity: function getPPSVerificationThresholds(address strategy) view returns(uint256 deviationThreshold, uint256 mnThreshold)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetPPSVerificationThresholds(opts *bind.CallOpts, strategy common.Address) (struct {
	DeviationThreshold *big.Int
	MnThreshold        *big.Int
}, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getPPSVerificationThresholds", strategy)

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
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetPPSVerificationThresholds(strategy common.Address) (struct {
	DeviationThreshold *big.Int
	MnThreshold        *big.Int
}, error) {
	return _SuperVaultAggregator.Contract.GetPPSVerificationThresholds(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetPPSVerificationThresholds is a free data retrieval call binding the contract method 0x322ae311.
//
// Solidity: function getPPSVerificationThresholds(address strategy) view returns(uint256 deviationThreshold, uint256 mnThreshold)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetPPSVerificationThresholds(strategy common.Address) (struct {
	DeviationThreshold *big.Int
	MnThreshold        *big.Int
}, error) {
	return _SuperVaultAggregator.Contract.GetPPSVerificationThresholds(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetProposedGlobalHooksRoot is a free data retrieval call binding the contract method 0x9ab4e37b.
//
// Solidity: function getProposedGlobalHooksRoot() view returns(bytes32 root, uint256 effectiveTime)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetProposedGlobalHooksRoot(opts *bind.CallOpts) (struct {
	Root          [32]byte
	EffectiveTime *big.Int
}, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getProposedGlobalHooksRoot")

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
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetProposedGlobalHooksRoot() (struct {
	Root          [32]byte
	EffectiveTime *big.Int
}, error) {
	return _SuperVaultAggregator.Contract.GetProposedGlobalHooksRoot(&_SuperVaultAggregator.CallOpts)
}

// GetProposedGlobalHooksRoot is a free data retrieval call binding the contract method 0x9ab4e37b.
//
// Solidity: function getProposedGlobalHooksRoot() view returns(bytes32 root, uint256 effectiveTime)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetProposedGlobalHooksRoot() (struct {
	Root          [32]byte
	EffectiveTime *big.Int
}, error) {
	return _SuperVaultAggregator.Contract.GetProposedGlobalHooksRoot(&_SuperVaultAggregator.CallOpts)
}

// GetProposedStrategyHooksRoot is a free data retrieval call binding the contract method 0x2b4bb841.
//
// Solidity: function getProposedStrategyHooksRoot(address strategy) view returns(bytes32 root, uint256 effectiveTime)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetProposedStrategyHooksRoot(opts *bind.CallOpts, strategy common.Address) (struct {
	Root          [32]byte
	EffectiveTime *big.Int
}, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getProposedStrategyHooksRoot", strategy)

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
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetProposedStrategyHooksRoot(strategy common.Address) (struct {
	Root          [32]byte
	EffectiveTime *big.Int
}, error) {
	return _SuperVaultAggregator.Contract.GetProposedStrategyHooksRoot(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetProposedStrategyHooksRoot is a free data retrieval call binding the contract method 0x2b4bb841.
//
// Solidity: function getProposedStrategyHooksRoot(address strategy) view returns(bytes32 root, uint256 effectiveTime)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetProposedStrategyHooksRoot(strategy common.Address) (struct {
	Root          [32]byte
	EffectiveTime *big.Int
}, error) {
	return _SuperVaultAggregator.Contract.GetProposedStrategyHooksRoot(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetSecondaryManagers is a free data retrieval call binding the contract method 0x5f853d40.
//
// Solidity: function getSecondaryManagers(address strategy) view returns(address[])
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetSecondaryManagers(opts *bind.CallOpts, strategy common.Address) ([]common.Address, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getSecondaryManagers", strategy)

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetSecondaryManagers is a free data retrieval call binding the contract method 0x5f853d40.
//
// Solidity: function getSecondaryManagers(address strategy) view returns(address[])
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetSecondaryManagers(strategy common.Address) ([]common.Address, error) {
	return _SuperVaultAggregator.Contract.GetSecondaryManagers(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetSecondaryManagers is a free data retrieval call binding the contract method 0x5f853d40.
//
// Solidity: function getSecondaryManagers(address strategy) view returns(address[])
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetSecondaryManagers(strategy common.Address) ([]common.Address, error) {
	return _SuperVaultAggregator.Contract.GetSecondaryManagers(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetStakeBalance is a free data retrieval call binding the contract method 0xef869773.
//
// Solidity: function getStakeBalance(address manager) view returns(uint256 balance)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetStakeBalance(opts *bind.CallOpts, manager common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getStakeBalance", manager)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetStakeBalance is a free data retrieval call binding the contract method 0xef869773.
//
// Solidity: function getStakeBalance(address manager) view returns(uint256 balance)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetStakeBalance(manager common.Address) (*big.Int, error) {
	return _SuperVaultAggregator.Contract.GetStakeBalance(&_SuperVaultAggregator.CallOpts, manager)
}

// GetStakeBalance is a free data retrieval call binding the contract method 0xef869773.
//
// Solidity: function getStakeBalance(address manager) view returns(uint256 balance)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetStakeBalance(manager common.Address) (*big.Int, error) {
	return _SuperVaultAggregator.Contract.GetStakeBalance(&_SuperVaultAggregator.CallOpts, manager)
}

// GetStrategyHooksRoot is a free data retrieval call binding the contract method 0xc99d2c89.
//
// Solidity: function getStrategyHooksRoot(address strategy) view returns(bytes32 root)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetStrategyHooksRoot(opts *bind.CallOpts, strategy common.Address) ([32]byte, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getStrategyHooksRoot", strategy)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetStrategyHooksRoot is a free data retrieval call binding the contract method 0xc99d2c89.
//
// Solidity: function getStrategyHooksRoot(address strategy) view returns(bytes32 root)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetStrategyHooksRoot(strategy common.Address) ([32]byte, error) {
	return _SuperVaultAggregator.Contract.GetStrategyHooksRoot(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetStrategyHooksRoot is a free data retrieval call binding the contract method 0xc99d2c89.
//
// Solidity: function getStrategyHooksRoot(address strategy) view returns(bytes32 root)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetStrategyHooksRoot(strategy common.Address) ([32]byte, error) {
	return _SuperVaultAggregator.Contract.GetStrategyHooksRoot(&_SuperVaultAggregator.CallOpts, strategy)
}

// GetUpkeepBalance is a free data retrieval call binding the contract method 0x1aef3510.
//
// Solidity: function getUpkeepBalance(address manager) view returns(uint256 balance)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) GetUpkeepBalance(opts *bind.CallOpts, manager common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "getUpkeepBalance", manager)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetUpkeepBalance is a free data retrieval call binding the contract method 0x1aef3510.
//
// Solidity: function getUpkeepBalance(address manager) view returns(uint256 balance)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) GetUpkeepBalance(manager common.Address) (*big.Int, error) {
	return _SuperVaultAggregator.Contract.GetUpkeepBalance(&_SuperVaultAggregator.CallOpts, manager)
}

// GetUpkeepBalance is a free data retrieval call binding the contract method 0x1aef3510.
//
// Solidity: function getUpkeepBalance(address manager) view returns(uint256 balance)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) GetUpkeepBalance(manager common.Address) (*big.Int, error) {
	return _SuperVaultAggregator.Contract.GetUpkeepBalance(&_SuperVaultAggregator.CallOpts, manager)
}

// IsAnyManager is a free data retrieval call binding the contract method 0x9e87cb3f.
//
// Solidity: function isAnyManager(address manager, address strategy) view returns(bool)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) IsAnyManager(opts *bind.CallOpts, manager common.Address, strategy common.Address) (bool, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "isAnyManager", manager, strategy)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsAnyManager is a free data retrieval call binding the contract method 0x9e87cb3f.
//
// Solidity: function isAnyManager(address manager, address strategy) view returns(bool)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) IsAnyManager(manager common.Address, strategy common.Address) (bool, error) {
	return _SuperVaultAggregator.Contract.IsAnyManager(&_SuperVaultAggregator.CallOpts, manager, strategy)
}

// IsAnyManager is a free data retrieval call binding the contract method 0x9e87cb3f.
//
// Solidity: function isAnyManager(address manager, address strategy) view returns(bool)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) IsAnyManager(manager common.Address, strategy common.Address) (bool, error) {
	return _SuperVaultAggregator.Contract.IsAnyManager(&_SuperVaultAggregator.CallOpts, manager, strategy)
}

// IsGlobalHooksRootActive is a free data retrieval call binding the contract method 0x28f36ff0.
//
// Solidity: function isGlobalHooksRootActive() view returns(bool)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) IsGlobalHooksRootActive(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "isGlobalHooksRootActive")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsGlobalHooksRootActive is a free data retrieval call binding the contract method 0x28f36ff0.
//
// Solidity: function isGlobalHooksRootActive() view returns(bool)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) IsGlobalHooksRootActive() (bool, error) {
	return _SuperVaultAggregator.Contract.IsGlobalHooksRootActive(&_SuperVaultAggregator.CallOpts)
}

// IsGlobalHooksRootActive is a free data retrieval call binding the contract method 0x28f36ff0.
//
// Solidity: function isGlobalHooksRootActive() view returns(bool)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) IsGlobalHooksRootActive() (bool, error) {
	return _SuperVaultAggregator.Contract.IsGlobalHooksRootActive(&_SuperVaultAggregator.CallOpts)
}

// IsGlobalHooksRootVetoed is a free data retrieval call binding the contract method 0x81ed8df4.
//
// Solidity: function isGlobalHooksRootVetoed() view returns(bool vetoed)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) IsGlobalHooksRootVetoed(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "isGlobalHooksRootVetoed")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsGlobalHooksRootVetoed is a free data retrieval call binding the contract method 0x81ed8df4.
//
// Solidity: function isGlobalHooksRootVetoed() view returns(bool vetoed)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) IsGlobalHooksRootVetoed() (bool, error) {
	return _SuperVaultAggregator.Contract.IsGlobalHooksRootVetoed(&_SuperVaultAggregator.CallOpts)
}

// IsGlobalHooksRootVetoed is a free data retrieval call binding the contract method 0x81ed8df4.
//
// Solidity: function isGlobalHooksRootVetoed() view returns(bool vetoed)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) IsGlobalHooksRootVetoed() (bool, error) {
	return _SuperVaultAggregator.Contract.IsGlobalHooksRootVetoed(&_SuperVaultAggregator.CallOpts)
}

// IsMainManager is a free data retrieval call binding the contract method 0xeb91a9b2.
//
// Solidity: function isMainManager(address manager, address strategy) view returns(bool)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) IsMainManager(opts *bind.CallOpts, manager common.Address, strategy common.Address) (bool, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "isMainManager", manager, strategy)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsMainManager is a free data retrieval call binding the contract method 0xeb91a9b2.
//
// Solidity: function isMainManager(address manager, address strategy) view returns(bool)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) IsMainManager(manager common.Address, strategy common.Address) (bool, error) {
	return _SuperVaultAggregator.Contract.IsMainManager(&_SuperVaultAggregator.CallOpts, manager, strategy)
}

// IsMainManager is a free data retrieval call binding the contract method 0xeb91a9b2.
//
// Solidity: function isMainManager(address manager, address strategy) view returns(bool)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) IsMainManager(manager common.Address, strategy common.Address) (bool, error) {
	return _SuperVaultAggregator.Contract.IsMainManager(&_SuperVaultAggregator.CallOpts, manager, strategy)
}

// IsPPSStale is a free data retrieval call binding the contract method 0x7e8c1517.
//
// Solidity: function isPPSStale(address strategy) view returns(bool isStale)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) IsPPSStale(opts *bind.CallOpts, strategy common.Address) (bool, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "isPPSStale", strategy)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsPPSStale is a free data retrieval call binding the contract method 0x7e8c1517.
//
// Solidity: function isPPSStale(address strategy) view returns(bool isStale)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) IsPPSStale(strategy common.Address) (bool, error) {
	return _SuperVaultAggregator.Contract.IsPPSStale(&_SuperVaultAggregator.CallOpts, strategy)
}

// IsPPSStale is a free data retrieval call binding the contract method 0x7e8c1517.
//
// Solidity: function isPPSStale(address strategy) view returns(bool isStale)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) IsPPSStale(strategy common.Address) (bool, error) {
	return _SuperVaultAggregator.Contract.IsPPSStale(&_SuperVaultAggregator.CallOpts, strategy)
}

// IsSecondaryManager is a free data retrieval call binding the contract method 0x83aa6836.
//
// Solidity: function isSecondaryManager(address manager, address strategy) view returns(bool)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) IsSecondaryManager(opts *bind.CallOpts, manager common.Address, strategy common.Address) (bool, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "isSecondaryManager", manager, strategy)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsSecondaryManager is a free data retrieval call binding the contract method 0x83aa6836.
//
// Solidity: function isSecondaryManager(address manager, address strategy) view returns(bool)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) IsSecondaryManager(manager common.Address, strategy common.Address) (bool, error) {
	return _SuperVaultAggregator.Contract.IsSecondaryManager(&_SuperVaultAggregator.CallOpts, manager, strategy)
}

// IsSecondaryManager is a free data retrieval call binding the contract method 0x83aa6836.
//
// Solidity: function isSecondaryManager(address manager, address strategy) view returns(bool)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) IsSecondaryManager(manager common.Address, strategy common.Address) (bool, error) {
	return _SuperVaultAggregator.Contract.IsSecondaryManager(&_SuperVaultAggregator.CallOpts, manager, strategy)
}

// IsStrategyHooksRootVetoed is a free data retrieval call binding the contract method 0xa8485b73.
//
// Solidity: function isStrategyHooksRootVetoed(address strategy) view returns(bool vetoed)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) IsStrategyHooksRootVetoed(opts *bind.CallOpts, strategy common.Address) (bool, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "isStrategyHooksRootVetoed", strategy)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsStrategyHooksRootVetoed is a free data retrieval call binding the contract method 0xa8485b73.
//
// Solidity: function isStrategyHooksRootVetoed(address strategy) view returns(bool vetoed)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) IsStrategyHooksRootVetoed(strategy common.Address) (bool, error) {
	return _SuperVaultAggregator.Contract.IsStrategyHooksRootVetoed(&_SuperVaultAggregator.CallOpts, strategy)
}

// IsStrategyHooksRootVetoed is a free data retrieval call binding the contract method 0xa8485b73.
//
// Solidity: function isStrategyHooksRootVetoed(address strategy) view returns(bool vetoed)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) IsStrategyHooksRootVetoed(strategy common.Address) (bool, error) {
	return _SuperVaultAggregator.Contract.IsStrategyHooksRootVetoed(&_SuperVaultAggregator.CallOpts, strategy)
}

// IsStrategyPaused is a free data retrieval call binding the contract method 0xc06a02e8.
//
// Solidity: function isStrategyPaused(address strategy) view returns(bool isPaused)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) IsStrategyPaused(opts *bind.CallOpts, strategy common.Address) (bool, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "isStrategyPaused", strategy)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsStrategyPaused is a free data retrieval call binding the contract method 0xc06a02e8.
//
// Solidity: function isStrategyPaused(address strategy) view returns(bool isPaused)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) IsStrategyPaused(strategy common.Address) (bool, error) {
	return _SuperVaultAggregator.Contract.IsStrategyPaused(&_SuperVaultAggregator.CallOpts, strategy)
}

// IsStrategyPaused is a free data retrieval call binding the contract method 0xc06a02e8.
//
// Solidity: function isStrategyPaused(address strategy) view returns(bool isPaused)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) IsStrategyPaused(strategy common.Address) (bool, error) {
	return _SuperVaultAggregator.Contract.IsStrategyPaused(&_SuperVaultAggregator.CallOpts, strategy)
}

// ManagerWithdrawalRequests is a free data retrieval call binding the contract method 0x711bfec9.
//
// Solidity: function managerWithdrawalRequests(address manager) view returns(uint256 amount, uint256 timestamp)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) ManagerWithdrawalRequests(opts *bind.CallOpts, manager common.Address) (struct {
	Amount    *big.Int
	Timestamp *big.Int
}, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "managerWithdrawalRequests", manager)

	outstruct := new(struct {
		Amount    *big.Int
		Timestamp *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Amount = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.Timestamp = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// ManagerWithdrawalRequests is a free data retrieval call binding the contract method 0x711bfec9.
//
// Solidity: function managerWithdrawalRequests(address manager) view returns(uint256 amount, uint256 timestamp)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) ManagerWithdrawalRequests(manager common.Address) (struct {
	Amount    *big.Int
	Timestamp *big.Int
}, error) {
	return _SuperVaultAggregator.Contract.ManagerWithdrawalRequests(&_SuperVaultAggregator.CallOpts, manager)
}

// ManagerWithdrawalRequests is a free data retrieval call binding the contract method 0x711bfec9.
//
// Solidity: function managerWithdrawalRequests(address manager) view returns(uint256 amount, uint256 timestamp)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) ManagerWithdrawalRequests(manager common.Address) (struct {
	Amount    *big.Int
	Timestamp *big.Int
}, error) {
	return _SuperVaultAggregator.Contract.ManagerWithdrawalRequests(&_SuperVaultAggregator.CallOpts, manager)
}

// SuperVaultEscrows is a free data retrieval call binding the contract method 0xbda262d7.
//
// Solidity: function superVaultEscrows(uint256 index) view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) SuperVaultEscrows(opts *bind.CallOpts, index *big.Int) (common.Address, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "superVaultEscrows", index)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SuperVaultEscrows is a free data retrieval call binding the contract method 0xbda262d7.
//
// Solidity: function superVaultEscrows(uint256 index) view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) SuperVaultEscrows(index *big.Int) (common.Address, error) {
	return _SuperVaultAggregator.Contract.SuperVaultEscrows(&_SuperVaultAggregator.CallOpts, index)
}

// SuperVaultEscrows is a free data retrieval call binding the contract method 0xbda262d7.
//
// Solidity: function superVaultEscrows(uint256 index) view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) SuperVaultEscrows(index *big.Int) (common.Address, error) {
	return _SuperVaultAggregator.Contract.SuperVaultEscrows(&_SuperVaultAggregator.CallOpts, index)
}

// SuperVaultStrategies is a free data retrieval call binding the contract method 0x9dc0ad84.
//
// Solidity: function superVaultStrategies(uint256 index) view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) SuperVaultStrategies(opts *bind.CallOpts, index *big.Int) (common.Address, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "superVaultStrategies", index)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SuperVaultStrategies is a free data retrieval call binding the contract method 0x9dc0ad84.
//
// Solidity: function superVaultStrategies(uint256 index) view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) SuperVaultStrategies(index *big.Int) (common.Address, error) {
	return _SuperVaultAggregator.Contract.SuperVaultStrategies(&_SuperVaultAggregator.CallOpts, index)
}

// SuperVaultStrategies is a free data retrieval call binding the contract method 0x9dc0ad84.
//
// Solidity: function superVaultStrategies(uint256 index) view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) SuperVaultStrategies(index *big.Int) (common.Address, error) {
	return _SuperVaultAggregator.Contract.SuperVaultStrategies(&_SuperVaultAggregator.CallOpts, index)
}

// SuperVaults is a free data retrieval call binding the contract method 0x44648c76.
//
// Solidity: function superVaults(uint256 index) view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) SuperVaults(opts *bind.CallOpts, index *big.Int) (common.Address, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "superVaults", index)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SuperVaults is a free data retrieval call binding the contract method 0x44648c76.
//
// Solidity: function superVaults(uint256 index) view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) SuperVaults(index *big.Int) (common.Address, error) {
	return _SuperVaultAggregator.Contract.SuperVaults(&_SuperVaultAggregator.CallOpts, index)
}

// SuperVaults is a free data retrieval call binding the contract method 0x44648c76.
//
// Solidity: function superVaults(uint256 index) view returns(address)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) SuperVaults(index *big.Int) (common.Address, error) {
	return _SuperVaultAggregator.Contract.SuperVaults(&_SuperVaultAggregator.CallOpts, index)
}

// ValidateHook is a free data retrieval call binding the contract method 0x9e7b8c3a.
//
// Solidity: function validateHook(address strategy, (address,bytes,bytes32[],bytes32[]) args) view returns(bool isValid)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) ValidateHook(opts *bind.CallOpts, strategy common.Address, args ISuperVaultAggregatorValidateHookArgs) (bool, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "validateHook", strategy, args)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// ValidateHook is a free data retrieval call binding the contract method 0x9e7b8c3a.
//
// Solidity: function validateHook(address strategy, (address,bytes,bytes32[],bytes32[]) args) view returns(bool isValid)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) ValidateHook(strategy common.Address, args ISuperVaultAggregatorValidateHookArgs) (bool, error) {
	return _SuperVaultAggregator.Contract.ValidateHook(&_SuperVaultAggregator.CallOpts, strategy, args)
}

// ValidateHook is a free data retrieval call binding the contract method 0x9e7b8c3a.
//
// Solidity: function validateHook(address strategy, (address,bytes,bytes32[],bytes32[]) args) view returns(bool isValid)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) ValidateHook(strategy common.Address, args ISuperVaultAggregatorValidateHookArgs) (bool, error) {
	return _SuperVaultAggregator.Contract.ValidateHook(&_SuperVaultAggregator.CallOpts, strategy, args)
}

// ValidateHooks is a free data retrieval call binding the contract method 0x6cbd5796.
//
// Solidity: function validateHooks(address strategy, (address,bytes,bytes32[],bytes32[])[] argsArray) view returns(bool[] validHooks)
func (_SuperVaultAggregator *SuperVaultAggregatorCaller) ValidateHooks(opts *bind.CallOpts, strategy common.Address, argsArray []ISuperVaultAggregatorValidateHookArgs) ([]bool, error) {
	var out []interface{}
	err := _SuperVaultAggregator.contract.Call(opts, &out, "validateHooks", strategy, argsArray)

	if err != nil {
		return *new([]bool), err
	}

	out0 := *abi.ConvertType(out[0], new([]bool)).(*[]bool)

	return out0, err

}

// ValidateHooks is a free data retrieval call binding the contract method 0x6cbd5796.
//
// Solidity: function validateHooks(address strategy, (address,bytes,bytes32[],bytes32[])[] argsArray) view returns(bool[] validHooks)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) ValidateHooks(strategy common.Address, argsArray []ISuperVaultAggregatorValidateHookArgs) ([]bool, error) {
	return _SuperVaultAggregator.Contract.ValidateHooks(&_SuperVaultAggregator.CallOpts, strategy, argsArray)
}

// ValidateHooks is a free data retrieval call binding the contract method 0x6cbd5796.
//
// Solidity: function validateHooks(address strategy, (address,bytes,bytes32[],bytes32[])[] argsArray) view returns(bool[] validHooks)
func (_SuperVaultAggregator *SuperVaultAggregatorCallerSession) ValidateHooks(strategy common.Address, argsArray []ISuperVaultAggregatorValidateHookArgs) ([]bool, error) {
	return _SuperVaultAggregator.Contract.ValidateHooks(&_SuperVaultAggregator.CallOpts, strategy, argsArray)
}

// AddAuthorizedCaller is a paid mutator transaction binding the contract method 0x6a279bb6.
//
// Solidity: function addAuthorizedCaller(address strategy, address caller) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) AddAuthorizedCaller(opts *bind.TransactOpts, strategy common.Address, caller common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "addAuthorizedCaller", strategy, caller)
}

// AddAuthorizedCaller is a paid mutator transaction binding the contract method 0x6a279bb6.
//
// Solidity: function addAuthorizedCaller(address strategy, address caller) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) AddAuthorizedCaller(strategy common.Address, caller common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.AddAuthorizedCaller(&_SuperVaultAggregator.TransactOpts, strategy, caller)
}

// AddAuthorizedCaller is a paid mutator transaction binding the contract method 0x6a279bb6.
//
// Solidity: function addAuthorizedCaller(address strategy, address caller) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) AddAuthorizedCaller(strategy common.Address, caller common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.AddAuthorizedCaller(&_SuperVaultAggregator.TransactOpts, strategy, caller)
}

// AddSecondaryManager is a paid mutator transaction binding the contract method 0xc0c3bbd8.
//
// Solidity: function addSecondaryManager(address strategy, address manager) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) AddSecondaryManager(opts *bind.TransactOpts, strategy common.Address, manager common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "addSecondaryManager", strategy, manager)
}

// AddSecondaryManager is a paid mutator transaction binding the contract method 0xc0c3bbd8.
//
// Solidity: function addSecondaryManager(address strategy, address manager) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) AddSecondaryManager(strategy common.Address, manager common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.AddSecondaryManager(&_SuperVaultAggregator.TransactOpts, strategy, manager)
}

// AddSecondaryManager is a paid mutator transaction binding the contract method 0xc0c3bbd8.
//
// Solidity: function addSecondaryManager(address strategy, address manager) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) AddSecondaryManager(strategy common.Address, manager common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.AddSecondaryManager(&_SuperVaultAggregator.TransactOpts, strategy, manager)
}

// ChangeGlobalLeavesStatus is a paid mutator transaction binding the contract method 0xf430b328.
//
// Solidity: function changeGlobalLeavesStatus(bytes32[] leaves, bool[] statuses, address strategy) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) ChangeGlobalLeavesStatus(opts *bind.TransactOpts, leaves [][32]byte, statuses []bool, strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "changeGlobalLeavesStatus", leaves, statuses, strategy)
}

// ChangeGlobalLeavesStatus is a paid mutator transaction binding the contract method 0xf430b328.
//
// Solidity: function changeGlobalLeavesStatus(bytes32[] leaves, bool[] statuses, address strategy) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) ChangeGlobalLeavesStatus(leaves [][32]byte, statuses []bool, strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ChangeGlobalLeavesStatus(&_SuperVaultAggregator.TransactOpts, leaves, statuses, strategy)
}

// ChangeGlobalLeavesStatus is a paid mutator transaction binding the contract method 0xf430b328.
//
// Solidity: function changeGlobalLeavesStatus(bytes32[] leaves, bool[] statuses, address strategy) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) ChangeGlobalLeavesStatus(leaves [][32]byte, statuses []bool, strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ChangeGlobalLeavesStatus(&_SuperVaultAggregator.TransactOpts, leaves, statuses, strategy)
}

// ChangePrimaryManager is a paid mutator transaction binding the contract method 0x906811e0.
//
// Solidity: function changePrimaryManager(address strategy, address newManager) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) ChangePrimaryManager(opts *bind.TransactOpts, strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "changePrimaryManager", strategy, newManager)
}

// ChangePrimaryManager is a paid mutator transaction binding the contract method 0x906811e0.
//
// Solidity: function changePrimaryManager(address strategy, address newManager) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) ChangePrimaryManager(strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ChangePrimaryManager(&_SuperVaultAggregator.TransactOpts, strategy, newManager)
}

// ChangePrimaryManager is a paid mutator transaction binding the contract method 0x906811e0.
//
// Solidity: function changePrimaryManager(address strategy, address newManager) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) ChangePrimaryManager(strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ChangePrimaryManager(&_SuperVaultAggregator.TransactOpts, strategy, newManager)
}

// ClaimUpkeep is a paid mutator transaction binding the contract method 0xd4eb9083.
//
// Solidity: function claimUpkeep(uint256 amount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) ClaimUpkeep(opts *bind.TransactOpts, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "claimUpkeep", amount)
}

// ClaimUpkeep is a paid mutator transaction binding the contract method 0xd4eb9083.
//
// Solidity: function claimUpkeep(uint256 amount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) ClaimUpkeep(amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ClaimUpkeep(&_SuperVaultAggregator.TransactOpts, amount)
}

// ClaimUpkeep is a paid mutator transaction binding the contract method 0xd4eb9083.
//
// Solidity: function claimUpkeep(uint256 amount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) ClaimUpkeep(amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ClaimUpkeep(&_SuperVaultAggregator.TransactOpts, amount)
}

// CompleteStakeWithdrawal is a paid mutator transaction binding the contract method 0x6da16741.
//
// Solidity: function completeStakeWithdrawal() returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) CompleteStakeWithdrawal(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "completeStakeWithdrawal")
}

// CompleteStakeWithdrawal is a paid mutator transaction binding the contract method 0x6da16741.
//
// Solidity: function completeStakeWithdrawal() returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) CompleteStakeWithdrawal() (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.CompleteStakeWithdrawal(&_SuperVaultAggregator.TransactOpts)
}

// CompleteStakeWithdrawal is a paid mutator transaction binding the contract method 0x6da16741.
//
// Solidity: function completeStakeWithdrawal() returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) CompleteStakeWithdrawal() (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.CompleteStakeWithdrawal(&_SuperVaultAggregator.TransactOpts)
}

// CreateVault is a paid mutator transaction binding the contract method 0x0084bce7.
//
// Solidity: function createVault((address,string,string,address,address[],uint256,uint256,(uint256,uint256,address),uint256) params) returns(address superVault, address strategy, address escrow)
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) CreateVault(opts *bind.TransactOpts, params ISuperVaultAggregatorVaultCreationParams) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "createVault", params)
}

// CreateVault is a paid mutator transaction binding the contract method 0x0084bce7.
//
// Solidity: function createVault((address,string,string,address,address[],uint256,uint256,(uint256,uint256,address),uint256) params) returns(address superVault, address strategy, address escrow)
func (_SuperVaultAggregator *SuperVaultAggregatorSession) CreateVault(params ISuperVaultAggregatorVaultCreationParams) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.CreateVault(&_SuperVaultAggregator.TransactOpts, params)
}

// CreateVault is a paid mutator transaction binding the contract method 0x0084bce7.
//
// Solidity: function createVault((address,string,string,address,address[],uint256,uint256,(uint256,uint256,address),uint256) params) returns(address superVault, address strategy, address escrow)
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) CreateVault(params ISuperVaultAggregatorVaultCreationParams) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.CreateVault(&_SuperVaultAggregator.TransactOpts, params)
}

// DepositStake is a paid mutator transaction binding the contract method 0x5410f365.
//
// Solidity: function depositStake(address manager, uint256 amount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) DepositStake(opts *bind.TransactOpts, manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "depositStake", manager, amount)
}

// DepositStake is a paid mutator transaction binding the contract method 0x5410f365.
//
// Solidity: function depositStake(address manager, uint256 amount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) DepositStake(manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.DepositStake(&_SuperVaultAggregator.TransactOpts, manager, amount)
}

// DepositStake is a paid mutator transaction binding the contract method 0x5410f365.
//
// Solidity: function depositStake(address manager, uint256 amount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) DepositStake(manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.DepositStake(&_SuperVaultAggregator.TransactOpts, manager, amount)
}

// DepositUpkeep is a paid mutator transaction binding the contract method 0x6fe79652.
//
// Solidity: function depositUpkeep(address manager, uint256 amount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) DepositUpkeep(opts *bind.TransactOpts, manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "depositUpkeep", manager, amount)
}

// DepositUpkeep is a paid mutator transaction binding the contract method 0x6fe79652.
//
// Solidity: function depositUpkeep(address manager, uint256 amount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) DepositUpkeep(manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.DepositUpkeep(&_SuperVaultAggregator.TransactOpts, manager, amount)
}

// DepositUpkeep is a paid mutator transaction binding the contract method 0x6fe79652.
//
// Solidity: function depositUpkeep(address manager, uint256 amount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) DepositUpkeep(manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.DepositUpkeep(&_SuperVaultAggregator.TransactOpts, manager, amount)
}

// ExecuteChangePrimaryManager is a paid mutator transaction binding the contract method 0x9249c392.
//
// Solidity: function executeChangePrimaryManager(address strategy) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) ExecuteChangePrimaryManager(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "executeChangePrimaryManager", strategy)
}

// ExecuteChangePrimaryManager is a paid mutator transaction binding the contract method 0x9249c392.
//
// Solidity: function executeChangePrimaryManager(address strategy) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) ExecuteChangePrimaryManager(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ExecuteChangePrimaryManager(&_SuperVaultAggregator.TransactOpts, strategy)
}

// ExecuteChangePrimaryManager is a paid mutator transaction binding the contract method 0x9249c392.
//
// Solidity: function executeChangePrimaryManager(address strategy) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) ExecuteChangePrimaryManager(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ExecuteChangePrimaryManager(&_SuperVaultAggregator.TransactOpts, strategy)
}

// ExecuteGlobalHooksRootUpdate is a paid mutator transaction binding the contract method 0x0a48d243.
//
// Solidity: function executeGlobalHooksRootUpdate() returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) ExecuteGlobalHooksRootUpdate(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "executeGlobalHooksRootUpdate")
}

// ExecuteGlobalHooksRootUpdate is a paid mutator transaction binding the contract method 0x0a48d243.
//
// Solidity: function executeGlobalHooksRootUpdate() returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) ExecuteGlobalHooksRootUpdate() (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ExecuteGlobalHooksRootUpdate(&_SuperVaultAggregator.TransactOpts)
}

// ExecuteGlobalHooksRootUpdate is a paid mutator transaction binding the contract method 0x0a48d243.
//
// Solidity: function executeGlobalHooksRootUpdate() returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) ExecuteGlobalHooksRootUpdate() (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ExecuteGlobalHooksRootUpdate(&_SuperVaultAggregator.TransactOpts)
}

// ExecuteStrategyHooksRootUpdate is a paid mutator transaction binding the contract method 0x7825784b.
//
// Solidity: function executeStrategyHooksRootUpdate(address strategy) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) ExecuteStrategyHooksRootUpdate(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "executeStrategyHooksRootUpdate", strategy)
}

// ExecuteStrategyHooksRootUpdate is a paid mutator transaction binding the contract method 0x7825784b.
//
// Solidity: function executeStrategyHooksRootUpdate(address strategy) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) ExecuteStrategyHooksRootUpdate(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ExecuteStrategyHooksRootUpdate(&_SuperVaultAggregator.TransactOpts, strategy)
}

// ExecuteStrategyHooksRootUpdate is a paid mutator transaction binding the contract method 0x7825784b.
//
// Solidity: function executeStrategyHooksRootUpdate(address strategy) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) ExecuteStrategyHooksRootUpdate(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ExecuteStrategyHooksRootUpdate(&_SuperVaultAggregator.TransactOpts, strategy)
}

// ForwardPPS is a paid mutator transaction binding the contract method 0x4f590c02.
//
// Solidity: function forwardPPS((address[],uint256[],uint256[],uint256,uint256[],address) args) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) ForwardPPS(opts *bind.TransactOpts, args ISuperVaultAggregatorForwardPPSArgs) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "forwardPPS", args)
}

// ForwardPPS is a paid mutator transaction binding the contract method 0x4f590c02.
//
// Solidity: function forwardPPS((address[],uint256[],uint256[],uint256,uint256[],address) args) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) ForwardPPS(args ISuperVaultAggregatorForwardPPSArgs) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ForwardPPS(&_SuperVaultAggregator.TransactOpts, args)
}

// ForwardPPS is a paid mutator transaction binding the contract method 0x4f590c02.
//
// Solidity: function forwardPPS((address[],uint256[],uint256[],uint256,uint256[],address) args) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) ForwardPPS(args ISuperVaultAggregatorForwardPPSArgs) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ForwardPPS(&_SuperVaultAggregator.TransactOpts, args)
}

// PauseStrategy is a paid mutator transaction binding the contract method 0xd3f6b598.
//
// Solidity: function pauseStrategy(address strategy) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) PauseStrategy(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "pauseStrategy", strategy)
}

// PauseStrategy is a paid mutator transaction binding the contract method 0xd3f6b598.
//
// Solidity: function pauseStrategy(address strategy) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) PauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.PauseStrategy(&_SuperVaultAggregator.TransactOpts, strategy)
}

// PauseStrategy is a paid mutator transaction binding the contract method 0xd3f6b598.
//
// Solidity: function pauseStrategy(address strategy) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) PauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.PauseStrategy(&_SuperVaultAggregator.TransactOpts, strategy)
}

// ProposeChangePrimaryManager is a paid mutator transaction binding the contract method 0x20b64b64.
//
// Solidity: function proposeChangePrimaryManager(address strategy, address newManager) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) ProposeChangePrimaryManager(opts *bind.TransactOpts, strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "proposeChangePrimaryManager", strategy, newManager)
}

// ProposeChangePrimaryManager is a paid mutator transaction binding the contract method 0x20b64b64.
//
// Solidity: function proposeChangePrimaryManager(address strategy, address newManager) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) ProposeChangePrimaryManager(strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ProposeChangePrimaryManager(&_SuperVaultAggregator.TransactOpts, strategy, newManager)
}

// ProposeChangePrimaryManager is a paid mutator transaction binding the contract method 0x20b64b64.
//
// Solidity: function proposeChangePrimaryManager(address strategy, address newManager) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) ProposeChangePrimaryManager(strategy common.Address, newManager common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ProposeChangePrimaryManager(&_SuperVaultAggregator.TransactOpts, strategy, newManager)
}

// ProposeGlobalHooksRoot is a paid mutator transaction binding the contract method 0xb0e5173b.
//
// Solidity: function proposeGlobalHooksRoot(bytes32 newRoot) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) ProposeGlobalHooksRoot(opts *bind.TransactOpts, newRoot [32]byte) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "proposeGlobalHooksRoot", newRoot)
}

// ProposeGlobalHooksRoot is a paid mutator transaction binding the contract method 0xb0e5173b.
//
// Solidity: function proposeGlobalHooksRoot(bytes32 newRoot) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) ProposeGlobalHooksRoot(newRoot [32]byte) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ProposeGlobalHooksRoot(&_SuperVaultAggregator.TransactOpts, newRoot)
}

// ProposeGlobalHooksRoot is a paid mutator transaction binding the contract method 0xb0e5173b.
//
// Solidity: function proposeGlobalHooksRoot(bytes32 newRoot) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) ProposeGlobalHooksRoot(newRoot [32]byte) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ProposeGlobalHooksRoot(&_SuperVaultAggregator.TransactOpts, newRoot)
}

// ProposeStrategyHooksRoot is a paid mutator transaction binding the contract method 0x5e12b2db.
//
// Solidity: function proposeStrategyHooksRoot(address strategy, bytes32 newRoot) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) ProposeStrategyHooksRoot(opts *bind.TransactOpts, strategy common.Address, newRoot [32]byte) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "proposeStrategyHooksRoot", strategy, newRoot)
}

// ProposeStrategyHooksRoot is a paid mutator transaction binding the contract method 0x5e12b2db.
//
// Solidity: function proposeStrategyHooksRoot(address strategy, bytes32 newRoot) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) ProposeStrategyHooksRoot(strategy common.Address, newRoot [32]byte) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ProposeStrategyHooksRoot(&_SuperVaultAggregator.TransactOpts, strategy, newRoot)
}

// ProposeStrategyHooksRoot is a paid mutator transaction binding the contract method 0x5e12b2db.
//
// Solidity: function proposeStrategyHooksRoot(address strategy, bytes32 newRoot) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) ProposeStrategyHooksRoot(strategy common.Address, newRoot [32]byte) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.ProposeStrategyHooksRoot(&_SuperVaultAggregator.TransactOpts, strategy, newRoot)
}

// RemoveAuthorizedCaller is a paid mutator transaction binding the contract method 0x4e179bce.
//
// Solidity: function removeAuthorizedCaller(address strategy, address caller) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) RemoveAuthorizedCaller(opts *bind.TransactOpts, strategy common.Address, caller common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "removeAuthorizedCaller", strategy, caller)
}

// RemoveAuthorizedCaller is a paid mutator transaction binding the contract method 0x4e179bce.
//
// Solidity: function removeAuthorizedCaller(address strategy, address caller) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) RemoveAuthorizedCaller(strategy common.Address, caller common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.RemoveAuthorizedCaller(&_SuperVaultAggregator.TransactOpts, strategy, caller)
}

// RemoveAuthorizedCaller is a paid mutator transaction binding the contract method 0x4e179bce.
//
// Solidity: function removeAuthorizedCaller(address strategy, address caller) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) RemoveAuthorizedCaller(strategy common.Address, caller common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.RemoveAuthorizedCaller(&_SuperVaultAggregator.TransactOpts, strategy, caller)
}

// RemoveSecondaryManager is a paid mutator transaction binding the contract method 0x3c248029.
//
// Solidity: function removeSecondaryManager(address strategy, address manager) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) RemoveSecondaryManager(opts *bind.TransactOpts, strategy common.Address, manager common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "removeSecondaryManager", strategy, manager)
}

// RemoveSecondaryManager is a paid mutator transaction binding the contract method 0x3c248029.
//
// Solidity: function removeSecondaryManager(address strategy, address manager) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) RemoveSecondaryManager(strategy common.Address, manager common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.RemoveSecondaryManager(&_SuperVaultAggregator.TransactOpts, strategy, manager)
}

// RemoveSecondaryManager is a paid mutator transaction binding the contract method 0x3c248029.
//
// Solidity: function removeSecondaryManager(address strategy, address manager) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) RemoveSecondaryManager(strategy common.Address, manager common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.RemoveSecondaryManager(&_SuperVaultAggregator.TransactOpts, strategy, manager)
}

// RequestStakeWithdrawal is a paid mutator transaction binding the contract method 0x21a081de.
//
// Solidity: function requestStakeWithdrawal(uint256 amount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) RequestStakeWithdrawal(opts *bind.TransactOpts, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "requestStakeWithdrawal", amount)
}

// RequestStakeWithdrawal is a paid mutator transaction binding the contract method 0x21a081de.
//
// Solidity: function requestStakeWithdrawal(uint256 amount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) RequestStakeWithdrawal(amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.RequestStakeWithdrawal(&_SuperVaultAggregator.TransactOpts, amount)
}

// RequestStakeWithdrawal is a paid mutator transaction binding the contract method 0x21a081de.
//
// Solidity: function requestStakeWithdrawal(uint256 amount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) RequestStakeWithdrawal(amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.RequestStakeWithdrawal(&_SuperVaultAggregator.TransactOpts, amount)
}

// SetGlobalHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xd5f3cd86.
//
// Solidity: function setGlobalHooksRootVetoStatus(bool vetoed) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) SetGlobalHooksRootVetoStatus(opts *bind.TransactOpts, vetoed bool) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "setGlobalHooksRootVetoStatus", vetoed)
}

// SetGlobalHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xd5f3cd86.
//
// Solidity: function setGlobalHooksRootVetoStatus(bool vetoed) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) SetGlobalHooksRootVetoStatus(vetoed bool) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.SetGlobalHooksRootVetoStatus(&_SuperVaultAggregator.TransactOpts, vetoed)
}

// SetGlobalHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xd5f3cd86.
//
// Solidity: function setGlobalHooksRootVetoStatus(bool vetoed) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) SetGlobalHooksRootVetoStatus(vetoed bool) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.SetGlobalHooksRootVetoStatus(&_SuperVaultAggregator.TransactOpts, vetoed)
}

// SetHooksRootUpdateTimelock is a paid mutator transaction binding the contract method 0x272b7add.
//
// Solidity: function setHooksRootUpdateTimelock(uint256 newTimelock) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) SetHooksRootUpdateTimelock(opts *bind.TransactOpts, newTimelock *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "setHooksRootUpdateTimelock", newTimelock)
}

// SetHooksRootUpdateTimelock is a paid mutator transaction binding the contract method 0x272b7add.
//
// Solidity: function setHooksRootUpdateTimelock(uint256 newTimelock) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) SetHooksRootUpdateTimelock(newTimelock *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.SetHooksRootUpdateTimelock(&_SuperVaultAggregator.TransactOpts, newTimelock)
}

// SetHooksRootUpdateTimelock is a paid mutator transaction binding the contract method 0x272b7add.
//
// Solidity: function setHooksRootUpdateTimelock(uint256 newTimelock) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) SetHooksRootUpdateTimelock(newTimelock *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.SetHooksRootUpdateTimelock(&_SuperVaultAggregator.TransactOpts, newTimelock)
}

// SetStrategyHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xf5297a47.
//
// Solidity: function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) SetStrategyHooksRootVetoStatus(opts *bind.TransactOpts, strategy common.Address, vetoed bool) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "setStrategyHooksRootVetoStatus", strategy, vetoed)
}

// SetStrategyHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xf5297a47.
//
// Solidity: function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) SetStrategyHooksRootVetoStatus(strategy common.Address, vetoed bool) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.SetStrategyHooksRootVetoStatus(&_SuperVaultAggregator.TransactOpts, strategy, vetoed)
}

// SetStrategyHooksRootVetoStatus is a paid mutator transaction binding the contract method 0xf5297a47.
//
// Solidity: function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) SetStrategyHooksRootVetoStatus(strategy common.Address, vetoed bool) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.SetStrategyHooksRootVetoStatus(&_SuperVaultAggregator.TransactOpts, strategy, vetoed)
}

// SlashStake is a paid mutator transaction binding the contract method 0x98d1c5a8.
//
// Solidity: function slashStake(address manager, uint256 amount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) SlashStake(opts *bind.TransactOpts, manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "slashStake", manager, amount)
}

// SlashStake is a paid mutator transaction binding the contract method 0x98d1c5a8.
//
// Solidity: function slashStake(address manager, uint256 amount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) SlashStake(manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.SlashStake(&_SuperVaultAggregator.TransactOpts, manager, amount)
}

// SlashStake is a paid mutator transaction binding the contract method 0x98d1c5a8.
//
// Solidity: function slashStake(address manager, uint256 amount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) SlashStake(manager common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.SlashStake(&_SuperVaultAggregator.TransactOpts, manager, amount)
}

// UnpauseStrategy is a paid mutator transaction binding the contract method 0x0ff323a3.
//
// Solidity: function unpauseStrategy(address strategy) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) UnpauseStrategy(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "unpauseStrategy", strategy)
}

// UnpauseStrategy is a paid mutator transaction binding the contract method 0x0ff323a3.
//
// Solidity: function unpauseStrategy(address strategy) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) UnpauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.UnpauseStrategy(&_SuperVaultAggregator.TransactOpts, strategy)
}

// UnpauseStrategy is a paid mutator transaction binding the contract method 0x0ff323a3.
//
// Solidity: function unpauseStrategy(address strategy) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) UnpauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.UnpauseStrategy(&_SuperVaultAggregator.TransactOpts, strategy)
}

// UpdatePPSAfterSkim is a paid mutator transaction binding the contract method 0x12e1ac5a.
//
// Solidity: function updatePPSAfterSkim(uint256 newPPS, uint256 feeAmount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) UpdatePPSAfterSkim(opts *bind.TransactOpts, newPPS *big.Int, feeAmount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "updatePPSAfterSkim", newPPS, feeAmount)
}

// UpdatePPSAfterSkim is a paid mutator transaction binding the contract method 0x12e1ac5a.
//
// Solidity: function updatePPSAfterSkim(uint256 newPPS, uint256 feeAmount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) UpdatePPSAfterSkim(newPPS *big.Int, feeAmount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.UpdatePPSAfterSkim(&_SuperVaultAggregator.TransactOpts, newPPS, feeAmount)
}

// UpdatePPSAfterSkim is a paid mutator transaction binding the contract method 0x12e1ac5a.
//
// Solidity: function updatePPSAfterSkim(uint256 newPPS, uint256 feeAmount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) UpdatePPSAfterSkim(newPPS *big.Int, feeAmount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.UpdatePPSAfterSkim(&_SuperVaultAggregator.TransactOpts, newPPS, feeAmount)
}

// UpdatePPSVerificationThresholds is a paid mutator transaction binding the contract method 0x7e55f6a5.
//
// Solidity: function updatePPSVerificationThresholds(address strategy, uint256 deviationThreshold_, uint256 mnThreshold_) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) UpdatePPSVerificationThresholds(opts *bind.TransactOpts, strategy common.Address, deviationThreshold_ *big.Int, mnThreshold_ *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "updatePPSVerificationThresholds", strategy, deviationThreshold_, mnThreshold_)
}

// UpdatePPSVerificationThresholds is a paid mutator transaction binding the contract method 0x7e55f6a5.
//
// Solidity: function updatePPSVerificationThresholds(address strategy, uint256 deviationThreshold_, uint256 mnThreshold_) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) UpdatePPSVerificationThresholds(strategy common.Address, deviationThreshold_ *big.Int, mnThreshold_ *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.UpdatePPSVerificationThresholds(&_SuperVaultAggregator.TransactOpts, strategy, deviationThreshold_, mnThreshold_)
}

// UpdatePPSVerificationThresholds is a paid mutator transaction binding the contract method 0x7e55f6a5.
//
// Solidity: function updatePPSVerificationThresholds(address strategy, uint256 deviationThreshold_, uint256 mnThreshold_) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) UpdatePPSVerificationThresholds(strategy common.Address, deviationThreshold_ *big.Int, mnThreshold_ *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.UpdatePPSVerificationThresholds(&_SuperVaultAggregator.TransactOpts, strategy, deviationThreshold_, mnThreshold_)
}

// WithdrawUpkeep is a paid mutator transaction binding the contract method 0x4b0b8aa6.
//
// Solidity: function withdrawUpkeep(uint256 amount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactor) WithdrawUpkeep(opts *bind.TransactOpts, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.contract.Transact(opts, "withdrawUpkeep", amount)
}

// WithdrawUpkeep is a paid mutator transaction binding the contract method 0x4b0b8aa6.
//
// Solidity: function withdrawUpkeep(uint256 amount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorSession) WithdrawUpkeep(amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.WithdrawUpkeep(&_SuperVaultAggregator.TransactOpts, amount)
}

// WithdrawUpkeep is a paid mutator transaction binding the contract method 0x4b0b8aa6.
//
// Solidity: function withdrawUpkeep(uint256 amount) returns()
func (_SuperVaultAggregator *SuperVaultAggregatorTransactorSession) WithdrawUpkeep(amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultAggregator.Contract.WithdrawUpkeep(&_SuperVaultAggregator.TransactOpts, amount)
}

// SuperVaultAggregatorAuthorizedCallerIterator is returned from FilterAuthorizedCaller and is used to iterate over the raw logs and unpacked data for AuthorizedCaller events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorAuthorizedCallerIterator struct {
	Event *SuperVaultAggregatorAuthorizedCaller // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorAuthorizedCallerIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorAuthorizedCaller)
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
		it.Event = new(SuperVaultAggregatorAuthorizedCaller)
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
func (it *SuperVaultAggregatorAuthorizedCallerIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorAuthorizedCallerIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorAuthorizedCaller represents a AuthorizedCaller event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorAuthorizedCaller struct {
	Strategy common.Address
	Caller   common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterAuthorizedCaller is a free log retrieval operation binding the contract event 0x1c9c420420e76ae7ad733b7098eb1fa04a2293da0cfbd31297ea505568760ebc.
//
// Solidity: event AuthorizedCaller(address indexed strategy, address indexed caller)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterAuthorizedCaller(opts *bind.FilterOpts, strategy []common.Address, caller []common.Address) (*SuperVaultAggregatorAuthorizedCallerIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "AuthorizedCaller", strategyRule, callerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorAuthorizedCallerIterator{contract: _SuperVaultAggregator.contract, event: "AuthorizedCaller", logs: logs, sub: sub}, nil
}

// WatchAuthorizedCaller is a free log subscription operation binding the contract event 0x1c9c420420e76ae7ad733b7098eb1fa04a2293da0cfbd31297ea505568760ebc.
//
// Solidity: event AuthorizedCaller(address indexed strategy, address indexed caller)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchAuthorizedCaller(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorAuthorizedCaller, strategy []common.Address, caller []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "AuthorizedCaller", strategyRule, callerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorAuthorizedCaller)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "AuthorizedCaller", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseAuthorizedCaller(log types.Log) (*SuperVaultAggregatorAuthorizedCaller, error) {
	event := new(SuperVaultAggregatorAuthorizedCaller)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "AuthorizedCaller", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorAuthorizedCallerAddedIterator is returned from FilterAuthorizedCallerAdded and is used to iterate over the raw logs and unpacked data for AuthorizedCallerAdded events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorAuthorizedCallerAddedIterator struct {
	Event *SuperVaultAggregatorAuthorizedCallerAdded // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorAuthorizedCallerAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorAuthorizedCallerAdded)
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
		it.Event = new(SuperVaultAggregatorAuthorizedCallerAdded)
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
func (it *SuperVaultAggregatorAuthorizedCallerAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorAuthorizedCallerAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorAuthorizedCallerAdded represents a AuthorizedCallerAdded event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorAuthorizedCallerAdded struct {
	Strategy common.Address
	Caller   common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterAuthorizedCallerAdded is a free log retrieval operation binding the contract event 0xde6b6315e31236a6504cb4a4fa3ccc32947e648ce1f188687e0711f55ec418b0.
//
// Solidity: event AuthorizedCallerAdded(address indexed strategy, address indexed caller)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterAuthorizedCallerAdded(opts *bind.FilterOpts, strategy []common.Address, caller []common.Address) (*SuperVaultAggregatorAuthorizedCallerAddedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "AuthorizedCallerAdded", strategyRule, callerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorAuthorizedCallerAddedIterator{contract: _SuperVaultAggregator.contract, event: "AuthorizedCallerAdded", logs: logs, sub: sub}, nil
}

// WatchAuthorizedCallerAdded is a free log subscription operation binding the contract event 0xde6b6315e31236a6504cb4a4fa3ccc32947e648ce1f188687e0711f55ec418b0.
//
// Solidity: event AuthorizedCallerAdded(address indexed strategy, address indexed caller)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchAuthorizedCallerAdded(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorAuthorizedCallerAdded, strategy []common.Address, caller []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "AuthorizedCallerAdded", strategyRule, callerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorAuthorizedCallerAdded)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "AuthorizedCallerAdded", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseAuthorizedCallerAdded(log types.Log) (*SuperVaultAggregatorAuthorizedCallerAdded, error) {
	event := new(SuperVaultAggregatorAuthorizedCallerAdded)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "AuthorizedCallerAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorAuthorizedCallerRemovedIterator is returned from FilterAuthorizedCallerRemoved and is used to iterate over the raw logs and unpacked data for AuthorizedCallerRemoved events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorAuthorizedCallerRemovedIterator struct {
	Event *SuperVaultAggregatorAuthorizedCallerRemoved // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorAuthorizedCallerRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorAuthorizedCallerRemoved)
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
		it.Event = new(SuperVaultAggregatorAuthorizedCallerRemoved)
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
func (it *SuperVaultAggregatorAuthorizedCallerRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorAuthorizedCallerRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorAuthorizedCallerRemoved represents a AuthorizedCallerRemoved event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorAuthorizedCallerRemoved struct {
	Strategy common.Address
	Caller   common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterAuthorizedCallerRemoved is a free log retrieval operation binding the contract event 0xd175903e18897b59f1dec5589010cd32eb1cb6d795239d0d79159089bfd4f52a.
//
// Solidity: event AuthorizedCallerRemoved(address indexed strategy, address indexed caller)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterAuthorizedCallerRemoved(opts *bind.FilterOpts, strategy []common.Address, caller []common.Address) (*SuperVaultAggregatorAuthorizedCallerRemovedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "AuthorizedCallerRemoved", strategyRule, callerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorAuthorizedCallerRemovedIterator{contract: _SuperVaultAggregator.contract, event: "AuthorizedCallerRemoved", logs: logs, sub: sub}, nil
}

// WatchAuthorizedCallerRemoved is a free log subscription operation binding the contract event 0xd175903e18897b59f1dec5589010cd32eb1cb6d795239d0d79159089bfd4f52a.
//
// Solidity: event AuthorizedCallerRemoved(address indexed strategy, address indexed caller)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchAuthorizedCallerRemoved(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorAuthorizedCallerRemoved, strategy []common.Address, caller []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "AuthorizedCallerRemoved", strategyRule, callerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorAuthorizedCallerRemoved)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "AuthorizedCallerRemoved", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseAuthorizedCallerRemoved(log types.Log) (*SuperVaultAggregatorAuthorizedCallerRemoved, error) {
	event := new(SuperVaultAggregatorAuthorizedCallerRemoved)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "AuthorizedCallerRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorGlobalHooksRootUpdateProposedIterator is returned from FilterGlobalHooksRootUpdateProposed and is used to iterate over the raw logs and unpacked data for GlobalHooksRootUpdateProposed events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorGlobalHooksRootUpdateProposedIterator struct {
	Event *SuperVaultAggregatorGlobalHooksRootUpdateProposed // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorGlobalHooksRootUpdateProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorGlobalHooksRootUpdateProposed)
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
		it.Event = new(SuperVaultAggregatorGlobalHooksRootUpdateProposed)
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
func (it *SuperVaultAggregatorGlobalHooksRootUpdateProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorGlobalHooksRootUpdateProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorGlobalHooksRootUpdateProposed represents a GlobalHooksRootUpdateProposed event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorGlobalHooksRootUpdateProposed struct {
	Root          [32]byte
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterGlobalHooksRootUpdateProposed is a free log retrieval operation binding the contract event 0x71e72baaa2bffcb51d34de71bba7ea258c9c5667a86e69b1c684f0e1ecb4f395.
//
// Solidity: event GlobalHooksRootUpdateProposed(bytes32 indexed root, uint256 effectiveTime)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterGlobalHooksRootUpdateProposed(opts *bind.FilterOpts, root [][32]byte) (*SuperVaultAggregatorGlobalHooksRootUpdateProposedIterator, error) {

	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "GlobalHooksRootUpdateProposed", rootRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorGlobalHooksRootUpdateProposedIterator{contract: _SuperVaultAggregator.contract, event: "GlobalHooksRootUpdateProposed", logs: logs, sub: sub}, nil
}

// WatchGlobalHooksRootUpdateProposed is a free log subscription operation binding the contract event 0x71e72baaa2bffcb51d34de71bba7ea258c9c5667a86e69b1c684f0e1ecb4f395.
//
// Solidity: event GlobalHooksRootUpdateProposed(bytes32 indexed root, uint256 effectiveTime)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchGlobalHooksRootUpdateProposed(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorGlobalHooksRootUpdateProposed, root [][32]byte) (event.Subscription, error) {

	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "GlobalHooksRootUpdateProposed", rootRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorGlobalHooksRootUpdateProposed)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootUpdateProposed", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseGlobalHooksRootUpdateProposed(log types.Log) (*SuperVaultAggregatorGlobalHooksRootUpdateProposed, error) {
	event := new(SuperVaultAggregatorGlobalHooksRootUpdateProposed)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootUpdateProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorGlobalHooksRootUpdatedIterator is returned from FilterGlobalHooksRootUpdated and is used to iterate over the raw logs and unpacked data for GlobalHooksRootUpdated events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorGlobalHooksRootUpdatedIterator struct {
	Event *SuperVaultAggregatorGlobalHooksRootUpdated // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorGlobalHooksRootUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorGlobalHooksRootUpdated)
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
		it.Event = new(SuperVaultAggregatorGlobalHooksRootUpdated)
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
func (it *SuperVaultAggregatorGlobalHooksRootUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorGlobalHooksRootUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorGlobalHooksRootUpdated represents a GlobalHooksRootUpdated event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorGlobalHooksRootUpdated struct {
	OldRoot [32]byte
	NewRoot [32]byte
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterGlobalHooksRootUpdated is a free log retrieval operation binding the contract event 0x0360da73fad480d9a31212f8337d4a576e6b9749d68fc663acf171bb07f950ba.
//
// Solidity: event GlobalHooksRootUpdated(bytes32 indexed oldRoot, bytes32 newRoot)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterGlobalHooksRootUpdated(opts *bind.FilterOpts, oldRoot [][32]byte) (*SuperVaultAggregatorGlobalHooksRootUpdatedIterator, error) {

	var oldRootRule []interface{}
	for _, oldRootItem := range oldRoot {
		oldRootRule = append(oldRootRule, oldRootItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "GlobalHooksRootUpdated", oldRootRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorGlobalHooksRootUpdatedIterator{contract: _SuperVaultAggregator.contract, event: "GlobalHooksRootUpdated", logs: logs, sub: sub}, nil
}

// WatchGlobalHooksRootUpdated is a free log subscription operation binding the contract event 0x0360da73fad480d9a31212f8337d4a576e6b9749d68fc663acf171bb07f950ba.
//
// Solidity: event GlobalHooksRootUpdated(bytes32 indexed oldRoot, bytes32 newRoot)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchGlobalHooksRootUpdated(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorGlobalHooksRootUpdated, oldRoot [][32]byte) (event.Subscription, error) {

	var oldRootRule []interface{}
	for _, oldRootItem := range oldRoot {
		oldRootRule = append(oldRootRule, oldRootItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "GlobalHooksRootUpdated", oldRootRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorGlobalHooksRootUpdated)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootUpdated", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseGlobalHooksRootUpdated(log types.Log) (*SuperVaultAggregatorGlobalHooksRootUpdated, error) {
	event := new(SuperVaultAggregatorGlobalHooksRootUpdated)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator is returned from FilterGlobalHooksRootVetoStatusChanged and is used to iterate over the raw logs and unpacked data for GlobalHooksRootVetoStatusChanged events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator struct {
	Event *SuperVaultAggregatorGlobalHooksRootVetoStatusChanged // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorGlobalHooksRootVetoStatusChanged)
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
		it.Event = new(SuperVaultAggregatorGlobalHooksRootVetoStatusChanged)
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
func (it *SuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorGlobalHooksRootVetoStatusChanged represents a GlobalHooksRootVetoStatusChanged event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorGlobalHooksRootVetoStatusChanged struct {
	Vetoed bool
	Root   [32]byte
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterGlobalHooksRootVetoStatusChanged is a free log retrieval operation binding the contract event 0xd867c555762bc6e6e6c9f80aa6c8132ccc5909f83266bc4d24489c8aa10e5e8d.
//
// Solidity: event GlobalHooksRootVetoStatusChanged(bool vetoed, bytes32 indexed root)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterGlobalHooksRootVetoStatusChanged(opts *bind.FilterOpts, root [][32]byte) (*SuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator, error) {

	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "GlobalHooksRootVetoStatusChanged", rootRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorGlobalHooksRootVetoStatusChangedIterator{contract: _SuperVaultAggregator.contract, event: "GlobalHooksRootVetoStatusChanged", logs: logs, sub: sub}, nil
}

// WatchGlobalHooksRootVetoStatusChanged is a free log subscription operation binding the contract event 0xd867c555762bc6e6e6c9f80aa6c8132ccc5909f83266bc4d24489c8aa10e5e8d.
//
// Solidity: event GlobalHooksRootVetoStatusChanged(bool vetoed, bytes32 indexed root)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchGlobalHooksRootVetoStatusChanged(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorGlobalHooksRootVetoStatusChanged, root [][32]byte) (event.Subscription, error) {

	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "GlobalHooksRootVetoStatusChanged", rootRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorGlobalHooksRootVetoStatusChanged)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootVetoStatusChanged", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseGlobalHooksRootVetoStatusChanged(log types.Log) (*SuperVaultAggregatorGlobalHooksRootVetoStatusChanged, error) {
	event := new(SuperVaultAggregatorGlobalHooksRootVetoStatusChanged)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootVetoStatusChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorGlobalHooksRootVetoedIterator is returned from FilterGlobalHooksRootVetoed and is used to iterate over the raw logs and unpacked data for GlobalHooksRootVetoed events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorGlobalHooksRootVetoedIterator struct {
	Event *SuperVaultAggregatorGlobalHooksRootVetoed // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorGlobalHooksRootVetoedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorGlobalHooksRootVetoed)
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
		it.Event = new(SuperVaultAggregatorGlobalHooksRootVetoed)
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
func (it *SuperVaultAggregatorGlobalHooksRootVetoedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorGlobalHooksRootVetoedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorGlobalHooksRootVetoed represents a GlobalHooksRootVetoed event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorGlobalHooksRootVetoed struct {
	Guardian common.Address
	Root     [32]byte
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterGlobalHooksRootVetoed is a free log retrieval operation binding the contract event 0x26c1ad46cb7f3649d1025e06bdbe8fc101891e84299550e6e28b5b5c62e09ec3.
//
// Solidity: event GlobalHooksRootVetoed(address indexed guardian, bytes32 indexed root)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterGlobalHooksRootVetoed(opts *bind.FilterOpts, guardian []common.Address, root [][32]byte) (*SuperVaultAggregatorGlobalHooksRootVetoedIterator, error) {

	var guardianRule []interface{}
	for _, guardianItem := range guardian {
		guardianRule = append(guardianRule, guardianItem)
	}
	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "GlobalHooksRootVetoed", guardianRule, rootRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorGlobalHooksRootVetoedIterator{contract: _SuperVaultAggregator.contract, event: "GlobalHooksRootVetoed", logs: logs, sub: sub}, nil
}

// WatchGlobalHooksRootVetoed is a free log subscription operation binding the contract event 0x26c1ad46cb7f3649d1025e06bdbe8fc101891e84299550e6e28b5b5c62e09ec3.
//
// Solidity: event GlobalHooksRootVetoed(address indexed guardian, bytes32 indexed root)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchGlobalHooksRootVetoed(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorGlobalHooksRootVetoed, guardian []common.Address, root [][32]byte) (event.Subscription, error) {

	var guardianRule []interface{}
	for _, guardianItem := range guardian {
		guardianRule = append(guardianRule, guardianItem)
	}
	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "GlobalHooksRootVetoed", guardianRule, rootRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorGlobalHooksRootVetoed)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootVetoed", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseGlobalHooksRootVetoed(log types.Log) (*SuperVaultAggregatorGlobalHooksRootVetoed, error) {
	event := new(SuperVaultAggregatorGlobalHooksRootVetoed)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "GlobalHooksRootVetoed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorGlobalLeavesStatusChangedIterator is returned from FilterGlobalLeavesStatusChanged and is used to iterate over the raw logs and unpacked data for GlobalLeavesStatusChanged events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorGlobalLeavesStatusChangedIterator struct {
	Event *SuperVaultAggregatorGlobalLeavesStatusChanged // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorGlobalLeavesStatusChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorGlobalLeavesStatusChanged)
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
		it.Event = new(SuperVaultAggregatorGlobalLeavesStatusChanged)
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
func (it *SuperVaultAggregatorGlobalLeavesStatusChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorGlobalLeavesStatusChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorGlobalLeavesStatusChanged represents a GlobalLeavesStatusChanged event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorGlobalLeavesStatusChanged struct {
	Strategy common.Address
	Leaves   [][32]byte
	Statuses []bool
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterGlobalLeavesStatusChanged is a free log retrieval operation binding the contract event 0x671df22165975c9055ff482eedb4963e75f35ac9f3040346699bd97228a8c790.
//
// Solidity: event GlobalLeavesStatusChanged(address indexed strategy, bytes32[] leaves, bool[] statuses)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterGlobalLeavesStatusChanged(opts *bind.FilterOpts, strategy []common.Address) (*SuperVaultAggregatorGlobalLeavesStatusChangedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "GlobalLeavesStatusChanged", strategyRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorGlobalLeavesStatusChangedIterator{contract: _SuperVaultAggregator.contract, event: "GlobalLeavesStatusChanged", logs: logs, sub: sub}, nil
}

// WatchGlobalLeavesStatusChanged is a free log subscription operation binding the contract event 0x671df22165975c9055ff482eedb4963e75f35ac9f3040346699bd97228a8c790.
//
// Solidity: event GlobalLeavesStatusChanged(address indexed strategy, bytes32[] leaves, bool[] statuses)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchGlobalLeavesStatusChanged(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorGlobalLeavesStatusChanged, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "GlobalLeavesStatusChanged", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorGlobalLeavesStatusChanged)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "GlobalLeavesStatusChanged", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseGlobalLeavesStatusChanged(log types.Log) (*SuperVaultAggregatorGlobalLeavesStatusChanged, error) {
	event := new(SuperVaultAggregatorGlobalLeavesStatusChanged)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "GlobalLeavesStatusChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorHooksRootUpdateTimelockChangedIterator is returned from FilterHooksRootUpdateTimelockChanged and is used to iterate over the raw logs and unpacked data for HooksRootUpdateTimelockChanged events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorHooksRootUpdateTimelockChangedIterator struct {
	Event *SuperVaultAggregatorHooksRootUpdateTimelockChanged // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorHooksRootUpdateTimelockChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorHooksRootUpdateTimelockChanged)
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
		it.Event = new(SuperVaultAggregatorHooksRootUpdateTimelockChanged)
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
func (it *SuperVaultAggregatorHooksRootUpdateTimelockChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorHooksRootUpdateTimelockChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorHooksRootUpdateTimelockChanged represents a HooksRootUpdateTimelockChanged event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorHooksRootUpdateTimelockChanged struct {
	NewTimelock *big.Int
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterHooksRootUpdateTimelockChanged is a free log retrieval operation binding the contract event 0x132309f91d275ae9cafe2088eea8945ed3b52dac1012d3be4a6e44622488a4f6.
//
// Solidity: event HooksRootUpdateTimelockChanged(uint256 newTimelock)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterHooksRootUpdateTimelockChanged(opts *bind.FilterOpts) (*SuperVaultAggregatorHooksRootUpdateTimelockChangedIterator, error) {

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "HooksRootUpdateTimelockChanged")
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorHooksRootUpdateTimelockChangedIterator{contract: _SuperVaultAggregator.contract, event: "HooksRootUpdateTimelockChanged", logs: logs, sub: sub}, nil
}

// WatchHooksRootUpdateTimelockChanged is a free log subscription operation binding the contract event 0x132309f91d275ae9cafe2088eea8945ed3b52dac1012d3be4a6e44622488a4f6.
//
// Solidity: event HooksRootUpdateTimelockChanged(uint256 newTimelock)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchHooksRootUpdateTimelockChanged(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorHooksRootUpdateTimelockChanged) (event.Subscription, error) {

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "HooksRootUpdateTimelockChanged")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorHooksRootUpdateTimelockChanged)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "HooksRootUpdateTimelockChanged", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseHooksRootUpdateTimelockChanged(log types.Log) (*SuperVaultAggregatorHooksRootUpdateTimelockChanged, error) {
	event := new(SuperVaultAggregatorHooksRootUpdateTimelockChanged)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "HooksRootUpdateTimelockChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorInsufficientUpkeepIterator is returned from FilterInsufficientUpkeep and is used to iterate over the raw logs and unpacked data for InsufficientUpkeep events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorInsufficientUpkeepIterator struct {
	Event *SuperVaultAggregatorInsufficientUpkeep // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorInsufficientUpkeepIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorInsufficientUpkeep)
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
		it.Event = new(SuperVaultAggregatorInsufficientUpkeep)
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
func (it *SuperVaultAggregatorInsufficientUpkeepIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorInsufficientUpkeepIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorInsufficientUpkeep represents a InsufficientUpkeep event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorInsufficientUpkeep struct {
	Strategy common.Address
	Manager  common.Address
	Balance  *big.Int
	Cost     *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterInsufficientUpkeep is a free log retrieval operation binding the contract event 0x9f17e0625b7890f465cad6295db4c1abad9d5afeea38a1d7d64f390aef73a770.
//
// Solidity: event InsufficientUpkeep(address indexed strategy, address indexed manager, uint256 balance, uint256 cost)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterInsufficientUpkeep(opts *bind.FilterOpts, strategy []common.Address, manager []common.Address) (*SuperVaultAggregatorInsufficientUpkeepIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "InsufficientUpkeep", strategyRule, managerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorInsufficientUpkeepIterator{contract: _SuperVaultAggregator.contract, event: "InsufficientUpkeep", logs: logs, sub: sub}, nil
}

// WatchInsufficientUpkeep is a free log subscription operation binding the contract event 0x9f17e0625b7890f465cad6295db4c1abad9d5afeea38a1d7d64f390aef73a770.
//
// Solidity: event InsufficientUpkeep(address indexed strategy, address indexed manager, uint256 balance, uint256 cost)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchInsufficientUpkeep(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorInsufficientUpkeep, strategy []common.Address, manager []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "InsufficientUpkeep", strategyRule, managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorInsufficientUpkeep)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "InsufficientUpkeep", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseInsufficientUpkeep(log types.Log) (*SuperVaultAggregatorInsufficientUpkeep, error) {
	event := new(SuperVaultAggregatorInsufficientUpkeep)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "InsufficientUpkeep", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorOldPrimaryManagerRemovedIterator is returned from FilterOldPrimaryManagerRemoved and is used to iterate over the raw logs and unpacked data for OldPrimaryManagerRemoved events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorOldPrimaryManagerRemovedIterator struct {
	Event *SuperVaultAggregatorOldPrimaryManagerRemoved // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorOldPrimaryManagerRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorOldPrimaryManagerRemoved)
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
		it.Event = new(SuperVaultAggregatorOldPrimaryManagerRemoved)
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
func (it *SuperVaultAggregatorOldPrimaryManagerRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorOldPrimaryManagerRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorOldPrimaryManagerRemoved represents a OldPrimaryManagerRemoved event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorOldPrimaryManagerRemoved struct {
	Strategy   common.Address
	OldManager common.Address
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterOldPrimaryManagerRemoved is a free log retrieval operation binding the contract event 0x744302e838f7c0c35e8971c67d7229a331a29eb270e24b7ceb261658ac679f6d.
//
// Solidity: event OldPrimaryManagerRemoved(address indexed strategy, address indexed oldManager)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterOldPrimaryManagerRemoved(opts *bind.FilterOpts, strategy []common.Address, oldManager []common.Address) (*SuperVaultAggregatorOldPrimaryManagerRemovedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var oldManagerRule []interface{}
	for _, oldManagerItem := range oldManager {
		oldManagerRule = append(oldManagerRule, oldManagerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "OldPrimaryManagerRemoved", strategyRule, oldManagerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorOldPrimaryManagerRemovedIterator{contract: _SuperVaultAggregator.contract, event: "OldPrimaryManagerRemoved", logs: logs, sub: sub}, nil
}

// WatchOldPrimaryManagerRemoved is a free log subscription operation binding the contract event 0x744302e838f7c0c35e8971c67d7229a331a29eb270e24b7ceb261658ac679f6d.
//
// Solidity: event OldPrimaryManagerRemoved(address indexed strategy, address indexed oldManager)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchOldPrimaryManagerRemoved(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorOldPrimaryManagerRemoved, strategy []common.Address, oldManager []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var oldManagerRule []interface{}
	for _, oldManagerItem := range oldManager {
		oldManagerRule = append(oldManagerRule, oldManagerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "OldPrimaryManagerRemoved", strategyRule, oldManagerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorOldPrimaryManagerRemoved)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "OldPrimaryManagerRemoved", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseOldPrimaryManagerRemoved(log types.Log) (*SuperVaultAggregatorOldPrimaryManagerRemoved, error) {
	event := new(SuperVaultAggregatorOldPrimaryManagerRemoved)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "OldPrimaryManagerRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorPPSUpdatedIterator is returned from FilterPPSUpdated and is used to iterate over the raw logs and unpacked data for PPSUpdated events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorPPSUpdatedIterator struct {
	Event *SuperVaultAggregatorPPSUpdated // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorPPSUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorPPSUpdated)
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
		it.Event = new(SuperVaultAggregatorPPSUpdated)
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
func (it *SuperVaultAggregatorPPSUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorPPSUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorPPSUpdated represents a PPSUpdated event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorPPSUpdated struct {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterPPSUpdated(opts *bind.FilterOpts, strategy []common.Address) (*SuperVaultAggregatorPPSUpdatedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "PPSUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorPPSUpdatedIterator{contract: _SuperVaultAggregator.contract, event: "PPSUpdated", logs: logs, sub: sub}, nil
}

// WatchPPSUpdated is a free log subscription operation binding the contract event 0x6d34c506f5dca7955f1dc32a066710945d4bd7d9f480452cac2ff87766c280b2.
//
// Solidity: event PPSUpdated(address indexed strategy, uint256 pps, uint256 validatorSet, uint256 totalValidators, uint256 timestamp)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchPPSUpdated(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorPPSUpdated, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "PPSUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorPPSUpdated)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "PPSUpdated", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParsePPSUpdated(log types.Log) (*SuperVaultAggregatorPPSUpdated, error) {
	event := new(SuperVaultAggregatorPPSUpdated)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "PPSUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorPPSUpdatedAfterSkimIterator is returned from FilterPPSUpdatedAfterSkim and is used to iterate over the raw logs and unpacked data for PPSUpdatedAfterSkim events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorPPSUpdatedAfterSkimIterator struct {
	Event *SuperVaultAggregatorPPSUpdatedAfterSkim // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorPPSUpdatedAfterSkimIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorPPSUpdatedAfterSkim)
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
		it.Event = new(SuperVaultAggregatorPPSUpdatedAfterSkim)
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
func (it *SuperVaultAggregatorPPSUpdatedAfterSkimIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorPPSUpdatedAfterSkimIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorPPSUpdatedAfterSkim represents a PPSUpdatedAfterSkim event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorPPSUpdatedAfterSkim struct {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterPPSUpdatedAfterSkim(opts *bind.FilterOpts, strategy []common.Address) (*SuperVaultAggregatorPPSUpdatedAfterSkimIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "PPSUpdatedAfterSkim", strategyRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorPPSUpdatedAfterSkimIterator{contract: _SuperVaultAggregator.contract, event: "PPSUpdatedAfterSkim", logs: logs, sub: sub}, nil
}

// WatchPPSUpdatedAfterSkim is a free log subscription operation binding the contract event 0x482a01d8e596a883e67895d310f80b2c151a445aa5e277325a6499b0be869845.
//
// Solidity: event PPSUpdatedAfterSkim(address indexed strategy, uint256 oldPPS, uint256 newPPS, uint256 feeAmount, uint256 timestamp)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchPPSUpdatedAfterSkim(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorPPSUpdatedAfterSkim, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "PPSUpdatedAfterSkim", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorPPSUpdatedAfterSkim)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "PPSUpdatedAfterSkim", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParsePPSUpdatedAfterSkim(log types.Log) (*SuperVaultAggregatorPPSUpdatedAfterSkim, error) {
	event := new(SuperVaultAggregatorPPSUpdatedAfterSkim)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "PPSUpdatedAfterSkim", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorPPSVerificationThresholdsUpdatedIterator is returned from FilterPPSVerificationThresholdsUpdated and is used to iterate over the raw logs and unpacked data for PPSVerificationThresholdsUpdated events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorPPSVerificationThresholdsUpdatedIterator struct {
	Event *SuperVaultAggregatorPPSVerificationThresholdsUpdated // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorPPSVerificationThresholdsUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorPPSVerificationThresholdsUpdated)
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
		it.Event = new(SuperVaultAggregatorPPSVerificationThresholdsUpdated)
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
func (it *SuperVaultAggregatorPPSVerificationThresholdsUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorPPSVerificationThresholdsUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorPPSVerificationThresholdsUpdated represents a PPSVerificationThresholdsUpdated event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorPPSVerificationThresholdsUpdated struct {
	Strategy           common.Address
	DeviationThreshold *big.Int
	MnThreshold        *big.Int
	Raw                types.Log // Blockchain specific contextual infos
}

// FilterPPSVerificationThresholdsUpdated is a free log retrieval operation binding the contract event 0xff3b4a34b9b4b3592103011d68697c6bdb8b60fa282091fae92588a0d4e3562b.
//
// Solidity: event PPSVerificationThresholdsUpdated(address indexed strategy, uint256 deviationThreshold, uint256 mnThreshold)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterPPSVerificationThresholdsUpdated(opts *bind.FilterOpts, strategy []common.Address) (*SuperVaultAggregatorPPSVerificationThresholdsUpdatedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "PPSVerificationThresholdsUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorPPSVerificationThresholdsUpdatedIterator{contract: _SuperVaultAggregator.contract, event: "PPSVerificationThresholdsUpdated", logs: logs, sub: sub}, nil
}

// WatchPPSVerificationThresholdsUpdated is a free log subscription operation binding the contract event 0xff3b4a34b9b4b3592103011d68697c6bdb8b60fa282091fae92588a0d4e3562b.
//
// Solidity: event PPSVerificationThresholdsUpdated(address indexed strategy, uint256 deviationThreshold, uint256 mnThreshold)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchPPSVerificationThresholdsUpdated(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorPPSVerificationThresholdsUpdated, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "PPSVerificationThresholdsUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorPPSVerificationThresholdsUpdated)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "PPSVerificationThresholdsUpdated", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParsePPSVerificationThresholdsUpdated(log types.Log) (*SuperVaultAggregatorPPSVerificationThresholdsUpdated, error) {
	event := new(SuperVaultAggregatorPPSVerificationThresholdsUpdated)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "PPSVerificationThresholdsUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorPaymentSkippedForPausedStrategyIterator is returned from FilterPaymentSkippedForPausedStrategy and is used to iterate over the raw logs and unpacked data for PaymentSkippedForPausedStrategy events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorPaymentSkippedForPausedStrategyIterator struct {
	Event *SuperVaultAggregatorPaymentSkippedForPausedStrategy // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorPaymentSkippedForPausedStrategyIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorPaymentSkippedForPausedStrategy)
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
		it.Event = new(SuperVaultAggregatorPaymentSkippedForPausedStrategy)
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
func (it *SuperVaultAggregatorPaymentSkippedForPausedStrategyIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorPaymentSkippedForPausedStrategyIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorPaymentSkippedForPausedStrategy represents a PaymentSkippedForPausedStrategy event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorPaymentSkippedForPausedStrategy struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterPaymentSkippedForPausedStrategy is a free log retrieval operation binding the contract event 0x0478bb79992612bb0113eed2f11d4f517e30990d086ec12b6feaeb96067b4f1b.
//
// Solidity: event PaymentSkippedForPausedStrategy(address indexed strategy)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterPaymentSkippedForPausedStrategy(opts *bind.FilterOpts, strategy []common.Address) (*SuperVaultAggregatorPaymentSkippedForPausedStrategyIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "PaymentSkippedForPausedStrategy", strategyRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorPaymentSkippedForPausedStrategyIterator{contract: _SuperVaultAggregator.contract, event: "PaymentSkippedForPausedStrategy", logs: logs, sub: sub}, nil
}

// WatchPaymentSkippedForPausedStrategy is a free log subscription operation binding the contract event 0x0478bb79992612bb0113eed2f11d4f517e30990d086ec12b6feaeb96067b4f1b.
//
// Solidity: event PaymentSkippedForPausedStrategy(address indexed strategy)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchPaymentSkippedForPausedStrategy(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorPaymentSkippedForPausedStrategy, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "PaymentSkippedForPausedStrategy", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorPaymentSkippedForPausedStrategy)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "PaymentSkippedForPausedStrategy", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParsePaymentSkippedForPausedStrategy(log types.Log) (*SuperVaultAggregatorPaymentSkippedForPausedStrategy, error) {
	event := new(SuperVaultAggregatorPaymentSkippedForPausedStrategy)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "PaymentSkippedForPausedStrategy", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorPrimaryManagerChangeProposedIterator is returned from FilterPrimaryManagerChangeProposed and is used to iterate over the raw logs and unpacked data for PrimaryManagerChangeProposed events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorPrimaryManagerChangeProposedIterator struct {
	Event *SuperVaultAggregatorPrimaryManagerChangeProposed // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorPrimaryManagerChangeProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorPrimaryManagerChangeProposed)
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
		it.Event = new(SuperVaultAggregatorPrimaryManagerChangeProposed)
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
func (it *SuperVaultAggregatorPrimaryManagerChangeProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorPrimaryManagerChangeProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorPrimaryManagerChangeProposed represents a PrimaryManagerChangeProposed event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorPrimaryManagerChangeProposed struct {
	Strategy      common.Address
	Proposer      common.Address
	NewManager    common.Address
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterPrimaryManagerChangeProposed is a free log retrieval operation binding the contract event 0x4ee609fb141edc43691a25b420b8584e6ed4fb79e4d8f2063a40872160375883.
//
// Solidity: event PrimaryManagerChangeProposed(address indexed strategy, address indexed proposer, address indexed newManager, uint256 effectiveTime)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterPrimaryManagerChangeProposed(opts *bind.FilterOpts, strategy []common.Address, proposer []common.Address, newManager []common.Address) (*SuperVaultAggregatorPrimaryManagerChangeProposedIterator, error) {

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

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "PrimaryManagerChangeProposed", strategyRule, proposerRule, newManagerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorPrimaryManagerChangeProposedIterator{contract: _SuperVaultAggregator.contract, event: "PrimaryManagerChangeProposed", logs: logs, sub: sub}, nil
}

// WatchPrimaryManagerChangeProposed is a free log subscription operation binding the contract event 0x4ee609fb141edc43691a25b420b8584e6ed4fb79e4d8f2063a40872160375883.
//
// Solidity: event PrimaryManagerChangeProposed(address indexed strategy, address indexed proposer, address indexed newManager, uint256 effectiveTime)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchPrimaryManagerChangeProposed(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorPrimaryManagerChangeProposed, strategy []common.Address, proposer []common.Address, newManager []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "PrimaryManagerChangeProposed", strategyRule, proposerRule, newManagerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorPrimaryManagerChangeProposed)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "PrimaryManagerChangeProposed", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParsePrimaryManagerChangeProposed(log types.Log) (*SuperVaultAggregatorPrimaryManagerChangeProposed, error) {
	event := new(SuperVaultAggregatorPrimaryManagerChangeProposed)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "PrimaryManagerChangeProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorPrimaryManagerChangedIterator is returned from FilterPrimaryManagerChanged and is used to iterate over the raw logs and unpacked data for PrimaryManagerChanged events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorPrimaryManagerChangedIterator struct {
	Event *SuperVaultAggregatorPrimaryManagerChanged // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorPrimaryManagerChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorPrimaryManagerChanged)
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
		it.Event = new(SuperVaultAggregatorPrimaryManagerChanged)
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
func (it *SuperVaultAggregatorPrimaryManagerChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorPrimaryManagerChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorPrimaryManagerChanged represents a PrimaryManagerChanged event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorPrimaryManagerChanged struct {
	Strategy   common.Address
	OldManager common.Address
	NewManager common.Address
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterPrimaryManagerChanged is a free log retrieval operation binding the contract event 0x4fabd2698f36f819418b0ded3a29b7e2572bef7ee7bd0875f5b5bb805333c6fc.
//
// Solidity: event PrimaryManagerChanged(address indexed strategy, address indexed oldManager, address indexed newManager)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterPrimaryManagerChanged(opts *bind.FilterOpts, strategy []common.Address, oldManager []common.Address, newManager []common.Address) (*SuperVaultAggregatorPrimaryManagerChangedIterator, error) {

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

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "PrimaryManagerChanged", strategyRule, oldManagerRule, newManagerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorPrimaryManagerChangedIterator{contract: _SuperVaultAggregator.contract, event: "PrimaryManagerChanged", logs: logs, sub: sub}, nil
}

// WatchPrimaryManagerChanged is a free log subscription operation binding the contract event 0x4fabd2698f36f819418b0ded3a29b7e2572bef7ee7bd0875f5b5bb805333c6fc.
//
// Solidity: event PrimaryManagerChanged(address indexed strategy, address indexed oldManager, address indexed newManager)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchPrimaryManagerChanged(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorPrimaryManagerChanged, strategy []common.Address, oldManager []common.Address, newManager []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "PrimaryManagerChanged", strategyRule, oldManagerRule, newManagerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorPrimaryManagerChanged)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "PrimaryManagerChanged", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParsePrimaryManagerChanged(log types.Log) (*SuperVaultAggregatorPrimaryManagerChanged, error) {
	event := new(SuperVaultAggregatorPrimaryManagerChanged)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "PrimaryManagerChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorPrimaryManagerChangedToSuperformIterator is returned from FilterPrimaryManagerChangedToSuperform and is used to iterate over the raw logs and unpacked data for PrimaryManagerChangedToSuperform events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorPrimaryManagerChangedToSuperformIterator struct {
	Event *SuperVaultAggregatorPrimaryManagerChangedToSuperform // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorPrimaryManagerChangedToSuperformIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorPrimaryManagerChangedToSuperform)
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
		it.Event = new(SuperVaultAggregatorPrimaryManagerChangedToSuperform)
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
func (it *SuperVaultAggregatorPrimaryManagerChangedToSuperformIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorPrimaryManagerChangedToSuperformIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorPrimaryManagerChangedToSuperform represents a PrimaryManagerChangedToSuperform event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorPrimaryManagerChangedToSuperform struct {
	Strategy   common.Address
	OldManager common.Address
	NewManager common.Address
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterPrimaryManagerChangedToSuperform is a free log retrieval operation binding the contract event 0x4a6c6deb2a640ff12d2cffe60e67daf16bfaad28d37d507351ec272fac1e75b2.
//
// Solidity: event PrimaryManagerChangedToSuperform(address indexed strategy, address indexed oldManager, address indexed newManager)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterPrimaryManagerChangedToSuperform(opts *bind.FilterOpts, strategy []common.Address, oldManager []common.Address, newManager []common.Address) (*SuperVaultAggregatorPrimaryManagerChangedToSuperformIterator, error) {

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

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "PrimaryManagerChangedToSuperform", strategyRule, oldManagerRule, newManagerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorPrimaryManagerChangedToSuperformIterator{contract: _SuperVaultAggregator.contract, event: "PrimaryManagerChangedToSuperform", logs: logs, sub: sub}, nil
}

// WatchPrimaryManagerChangedToSuperform is a free log subscription operation binding the contract event 0x4a6c6deb2a640ff12d2cffe60e67daf16bfaad28d37d507351ec272fac1e75b2.
//
// Solidity: event PrimaryManagerChangedToSuperform(address indexed strategy, address indexed oldManager, address indexed newManager)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchPrimaryManagerChangedToSuperform(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorPrimaryManagerChangedToSuperform, strategy []common.Address, oldManager []common.Address, newManager []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "PrimaryManagerChangedToSuperform", strategyRule, oldManagerRule, newManagerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorPrimaryManagerChangedToSuperform)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "PrimaryManagerChangedToSuperform", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParsePrimaryManagerChangedToSuperform(log types.Log) (*SuperVaultAggregatorPrimaryManagerChangedToSuperform, error) {
	event := new(SuperVaultAggregatorPrimaryManagerChangedToSuperform)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "PrimaryManagerChangedToSuperform", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator is returned from FilterProvidedTimestampExceedsBlockTimestamp and is used to iterate over the raw logs and unpacked data for ProvidedTimestampExceedsBlockTimestamp events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator struct {
	Event *SuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp)
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
		it.Event = new(SuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp)
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
func (it *SuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp represents a ProvidedTimestampExceedsBlockTimestamp event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp struct {
	Strategy       common.Address
	ArgsTimestamp  *big.Int
	BlockTimestamp *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterProvidedTimestampExceedsBlockTimestamp is a free log retrieval operation binding the contract event 0x11ce21eb8049b15d3cb258f2a3e207e24b6ca2141010b9c063228faa8628b9b5.
//
// Solidity: event ProvidedTimestampExceedsBlockTimestamp(address indexed strategy, uint256 argsTimestamp, uint256 blockTimestamp)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterProvidedTimestampExceedsBlockTimestamp(opts *bind.FilterOpts, strategy []common.Address) (*SuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "ProvidedTimestampExceedsBlockTimestamp", strategyRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorProvidedTimestampExceedsBlockTimestampIterator{contract: _SuperVaultAggregator.contract, event: "ProvidedTimestampExceedsBlockTimestamp", logs: logs, sub: sub}, nil
}

// WatchProvidedTimestampExceedsBlockTimestamp is a free log subscription operation binding the contract event 0x11ce21eb8049b15d3cb258f2a3e207e24b6ca2141010b9c063228faa8628b9b5.
//
// Solidity: event ProvidedTimestampExceedsBlockTimestamp(address indexed strategy, uint256 argsTimestamp, uint256 blockTimestamp)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchProvidedTimestampExceedsBlockTimestamp(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "ProvidedTimestampExceedsBlockTimestamp", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "ProvidedTimestampExceedsBlockTimestamp", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseProvidedTimestampExceedsBlockTimestamp(log types.Log) (*SuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp, error) {
	event := new(SuperVaultAggregatorProvidedTimestampExceedsBlockTimestamp)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "ProvidedTimestampExceedsBlockTimestamp", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorSecondaryManagerAddedIterator is returned from FilterSecondaryManagerAdded and is used to iterate over the raw logs and unpacked data for SecondaryManagerAdded events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorSecondaryManagerAddedIterator struct {
	Event *SuperVaultAggregatorSecondaryManagerAdded // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorSecondaryManagerAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorSecondaryManagerAdded)
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
		it.Event = new(SuperVaultAggregatorSecondaryManagerAdded)
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
func (it *SuperVaultAggregatorSecondaryManagerAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorSecondaryManagerAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorSecondaryManagerAdded represents a SecondaryManagerAdded event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorSecondaryManagerAdded struct {
	Strategy common.Address
	Manager  common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterSecondaryManagerAdded is a free log retrieval operation binding the contract event 0xb62a858ba4f3ba693ebca539c91a5c78f4514d4c1ea35b9d336ce5ce8f071f76.
//
// Solidity: event SecondaryManagerAdded(address indexed strategy, address indexed manager)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterSecondaryManagerAdded(opts *bind.FilterOpts, strategy []common.Address, manager []common.Address) (*SuperVaultAggregatorSecondaryManagerAddedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "SecondaryManagerAdded", strategyRule, managerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorSecondaryManagerAddedIterator{contract: _SuperVaultAggregator.contract, event: "SecondaryManagerAdded", logs: logs, sub: sub}, nil
}

// WatchSecondaryManagerAdded is a free log subscription operation binding the contract event 0xb62a858ba4f3ba693ebca539c91a5c78f4514d4c1ea35b9d336ce5ce8f071f76.
//
// Solidity: event SecondaryManagerAdded(address indexed strategy, address indexed manager)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchSecondaryManagerAdded(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorSecondaryManagerAdded, strategy []common.Address, manager []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "SecondaryManagerAdded", strategyRule, managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorSecondaryManagerAdded)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "SecondaryManagerAdded", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseSecondaryManagerAdded(log types.Log) (*SuperVaultAggregatorSecondaryManagerAdded, error) {
	event := new(SuperVaultAggregatorSecondaryManagerAdded)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "SecondaryManagerAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorSecondaryManagerRemovedIterator is returned from FilterSecondaryManagerRemoved and is used to iterate over the raw logs and unpacked data for SecondaryManagerRemoved events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorSecondaryManagerRemovedIterator struct {
	Event *SuperVaultAggregatorSecondaryManagerRemoved // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorSecondaryManagerRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorSecondaryManagerRemoved)
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
		it.Event = new(SuperVaultAggregatorSecondaryManagerRemoved)
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
func (it *SuperVaultAggregatorSecondaryManagerRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorSecondaryManagerRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorSecondaryManagerRemoved represents a SecondaryManagerRemoved event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorSecondaryManagerRemoved struct {
	Strategy common.Address
	Manager  common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterSecondaryManagerRemoved is a free log retrieval operation binding the contract event 0x466dd5513a82de99caf12b8d5176cd2174dec8013f9c3ec7be7254e54b2c417c.
//
// Solidity: event SecondaryManagerRemoved(address indexed strategy, address indexed manager)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterSecondaryManagerRemoved(opts *bind.FilterOpts, strategy []common.Address, manager []common.Address) (*SuperVaultAggregatorSecondaryManagerRemovedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "SecondaryManagerRemoved", strategyRule, managerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorSecondaryManagerRemovedIterator{contract: _SuperVaultAggregator.contract, event: "SecondaryManagerRemoved", logs: logs, sub: sub}, nil
}

// WatchSecondaryManagerRemoved is a free log subscription operation binding the contract event 0x466dd5513a82de99caf12b8d5176cd2174dec8013f9c3ec7be7254e54b2c417c.
//
// Solidity: event SecondaryManagerRemoved(address indexed strategy, address indexed manager)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchSecondaryManagerRemoved(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorSecondaryManagerRemoved, strategy []common.Address, manager []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "SecondaryManagerRemoved", strategyRule, managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorSecondaryManagerRemoved)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "SecondaryManagerRemoved", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseSecondaryManagerRemoved(log types.Log) (*SuperVaultAggregatorSecondaryManagerRemoved, error) {
	event := new(SuperVaultAggregatorSecondaryManagerRemoved)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "SecondaryManagerRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorStakeDepositedIterator is returned from FilterStakeDeposited and is used to iterate over the raw logs and unpacked data for StakeDeposited events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStakeDepositedIterator struct {
	Event *SuperVaultAggregatorStakeDeposited // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorStakeDepositedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorStakeDeposited)
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
		it.Event = new(SuperVaultAggregatorStakeDeposited)
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
func (it *SuperVaultAggregatorStakeDepositedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorStakeDepositedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorStakeDeposited represents a StakeDeposited event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStakeDeposited struct {
	Manager common.Address
	Amount  *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterStakeDeposited is a free log retrieval operation binding the contract event 0x0a7bb2e28cc4698aac06db79cf9163bfcc20719286cf59fa7d492ceda1b8edc2.
//
// Solidity: event StakeDeposited(address indexed manager, uint256 amount)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterStakeDeposited(opts *bind.FilterOpts, manager []common.Address) (*SuperVaultAggregatorStakeDepositedIterator, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "StakeDeposited", managerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorStakeDepositedIterator{contract: _SuperVaultAggregator.contract, event: "StakeDeposited", logs: logs, sub: sub}, nil
}

// WatchStakeDeposited is a free log subscription operation binding the contract event 0x0a7bb2e28cc4698aac06db79cf9163bfcc20719286cf59fa7d492ceda1b8edc2.
//
// Solidity: event StakeDeposited(address indexed manager, uint256 amount)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchStakeDeposited(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorStakeDeposited, manager []common.Address) (event.Subscription, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "StakeDeposited", managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorStakeDeposited)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "StakeDeposited", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseStakeDeposited(log types.Log) (*SuperVaultAggregatorStakeDeposited, error) {
	event := new(SuperVaultAggregatorStakeDeposited)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "StakeDeposited", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorStakeSlashedIterator is returned from FilterStakeSlashed and is used to iterate over the raw logs and unpacked data for StakeSlashed events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStakeSlashedIterator struct {
	Event *SuperVaultAggregatorStakeSlashed // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorStakeSlashedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorStakeSlashed)
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
		it.Event = new(SuperVaultAggregatorStakeSlashed)
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
func (it *SuperVaultAggregatorStakeSlashedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorStakeSlashedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorStakeSlashed represents a StakeSlashed event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStakeSlashed struct {
	Manager common.Address
	Amount  *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterStakeSlashed is a free log retrieval operation binding the contract event 0x83f5ea8bea7627d95274e94dd7e9e3d7e82cb55feab513ed49e325232dcc61e0.
//
// Solidity: event StakeSlashed(address indexed manager, uint256 amount)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterStakeSlashed(opts *bind.FilterOpts, manager []common.Address) (*SuperVaultAggregatorStakeSlashedIterator, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "StakeSlashed", managerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorStakeSlashedIterator{contract: _SuperVaultAggregator.contract, event: "StakeSlashed", logs: logs, sub: sub}, nil
}

// WatchStakeSlashed is a free log subscription operation binding the contract event 0x83f5ea8bea7627d95274e94dd7e9e3d7e82cb55feab513ed49e325232dcc61e0.
//
// Solidity: event StakeSlashed(address indexed manager, uint256 amount)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchStakeSlashed(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorStakeSlashed, manager []common.Address) (event.Subscription, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "StakeSlashed", managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorStakeSlashed)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "StakeSlashed", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseStakeSlashed(log types.Log) (*SuperVaultAggregatorStakeSlashed, error) {
	event := new(SuperVaultAggregatorStakeSlashed)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "StakeSlashed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorStakeWithdrawRequestedIterator is returned from FilterStakeWithdrawRequested and is used to iterate over the raw logs and unpacked data for StakeWithdrawRequested events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStakeWithdrawRequestedIterator struct {
	Event *SuperVaultAggregatorStakeWithdrawRequested // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorStakeWithdrawRequestedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorStakeWithdrawRequested)
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
		it.Event = new(SuperVaultAggregatorStakeWithdrawRequested)
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
func (it *SuperVaultAggregatorStakeWithdrawRequestedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorStakeWithdrawRequestedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorStakeWithdrawRequested represents a StakeWithdrawRequested event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStakeWithdrawRequested struct {
	Manager common.Address
	Amount  *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterStakeWithdrawRequested is a free log retrieval operation binding the contract event 0x3d8d9df4bd0172df32e557fa48e96435cd7f2cac06aaffacfaee608e6f7898ef.
//
// Solidity: event StakeWithdrawRequested(address indexed manager, uint256 amount)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterStakeWithdrawRequested(opts *bind.FilterOpts, manager []common.Address) (*SuperVaultAggregatorStakeWithdrawRequestedIterator, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "StakeWithdrawRequested", managerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorStakeWithdrawRequestedIterator{contract: _SuperVaultAggregator.contract, event: "StakeWithdrawRequested", logs: logs, sub: sub}, nil
}

// WatchStakeWithdrawRequested is a free log subscription operation binding the contract event 0x3d8d9df4bd0172df32e557fa48e96435cd7f2cac06aaffacfaee608e6f7898ef.
//
// Solidity: event StakeWithdrawRequested(address indexed manager, uint256 amount)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchStakeWithdrawRequested(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorStakeWithdrawRequested, manager []common.Address) (event.Subscription, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "StakeWithdrawRequested", managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorStakeWithdrawRequested)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "StakeWithdrawRequested", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseStakeWithdrawRequested(log types.Log) (*SuperVaultAggregatorStakeWithdrawRequested, error) {
	event := new(SuperVaultAggregatorStakeWithdrawRequested)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "StakeWithdrawRequested", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorStakeWithdrawnIterator is returned from FilterStakeWithdrawn and is used to iterate over the raw logs and unpacked data for StakeWithdrawn events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStakeWithdrawnIterator struct {
	Event *SuperVaultAggregatorStakeWithdrawn // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorStakeWithdrawnIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorStakeWithdrawn)
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
		it.Event = new(SuperVaultAggregatorStakeWithdrawn)
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
func (it *SuperVaultAggregatorStakeWithdrawnIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorStakeWithdrawnIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorStakeWithdrawn represents a StakeWithdrawn event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStakeWithdrawn struct {
	Manager common.Address
	Amount  *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterStakeWithdrawn is a free log retrieval operation binding the contract event 0x8108595eb6bad3acefa9da467d90cc2217686d5c5ac85460f8b7849c840645fc.
//
// Solidity: event StakeWithdrawn(address indexed manager, uint256 amount)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterStakeWithdrawn(opts *bind.FilterOpts, manager []common.Address) (*SuperVaultAggregatorStakeWithdrawnIterator, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "StakeWithdrawn", managerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorStakeWithdrawnIterator{contract: _SuperVaultAggregator.contract, event: "StakeWithdrawn", logs: logs, sub: sub}, nil
}

// WatchStakeWithdrawn is a free log subscription operation binding the contract event 0x8108595eb6bad3acefa9da467d90cc2217686d5c5ac85460f8b7849c840645fc.
//
// Solidity: event StakeWithdrawn(address indexed manager, uint256 amount)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchStakeWithdrawn(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorStakeWithdrawn, manager []common.Address) (event.Subscription, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "StakeWithdrawn", managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorStakeWithdrawn)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "StakeWithdrawn", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseStakeWithdrawn(log types.Log) (*SuperVaultAggregatorStakeWithdrawn, error) {
	event := new(SuperVaultAggregatorStakeWithdrawn)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "StakeWithdrawn", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorStaleUpdateIterator is returned from FilterStaleUpdate and is used to iterate over the raw logs and unpacked data for StaleUpdate events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStaleUpdateIterator struct {
	Event *SuperVaultAggregatorStaleUpdate // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorStaleUpdateIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorStaleUpdate)
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
		it.Event = new(SuperVaultAggregatorStaleUpdate)
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
func (it *SuperVaultAggregatorStaleUpdateIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorStaleUpdateIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorStaleUpdate represents a StaleUpdate event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStaleUpdate struct {
	Strategy        common.Address
	UpdateAuthority common.Address
	Timestamp       *big.Int
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterStaleUpdate is a free log retrieval operation binding the contract event 0x5413368ef0fd371d352762fd42f794381bdd66d2b2c3860549bc61f12f6ab2ba.
//
// Solidity: event StaleUpdate(address indexed strategy, address indexed updateAuthority, uint256 timestamp)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterStaleUpdate(opts *bind.FilterOpts, strategy []common.Address, updateAuthority []common.Address) (*SuperVaultAggregatorStaleUpdateIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var updateAuthorityRule []interface{}
	for _, updateAuthorityItem := range updateAuthority {
		updateAuthorityRule = append(updateAuthorityRule, updateAuthorityItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "StaleUpdate", strategyRule, updateAuthorityRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorStaleUpdateIterator{contract: _SuperVaultAggregator.contract, event: "StaleUpdate", logs: logs, sub: sub}, nil
}

// WatchStaleUpdate is a free log subscription operation binding the contract event 0x5413368ef0fd371d352762fd42f794381bdd66d2b2c3860549bc61f12f6ab2ba.
//
// Solidity: event StaleUpdate(address indexed strategy, address indexed updateAuthority, uint256 timestamp)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchStaleUpdate(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorStaleUpdate, strategy []common.Address, updateAuthority []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var updateAuthorityRule []interface{}
	for _, updateAuthorityItem := range updateAuthority {
		updateAuthorityRule = append(updateAuthorityRule, updateAuthorityItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "StaleUpdate", strategyRule, updateAuthorityRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorStaleUpdate)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "StaleUpdate", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseStaleUpdate(log types.Log) (*SuperVaultAggregatorStaleUpdate, error) {
	event := new(SuperVaultAggregatorStaleUpdate)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "StaleUpdate", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorStrategyCheckFailedIterator is returned from FilterStrategyCheckFailed and is used to iterate over the raw logs and unpacked data for StrategyCheckFailed events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyCheckFailedIterator struct {
	Event *SuperVaultAggregatorStrategyCheckFailed // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorStrategyCheckFailedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorStrategyCheckFailed)
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
		it.Event = new(SuperVaultAggregatorStrategyCheckFailed)
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
func (it *SuperVaultAggregatorStrategyCheckFailedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorStrategyCheckFailedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorStrategyCheckFailed represents a StrategyCheckFailed event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyCheckFailed struct {
	Strategy common.Address
	Reason   string
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyCheckFailed is a free log retrieval operation binding the contract event 0xe364669b114d8ecba48ed1742526a04c78dd506cd3af6beb910f6622a928cbdb.
//
// Solidity: event StrategyCheckFailed(address indexed strategy, string reason)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterStrategyCheckFailed(opts *bind.FilterOpts, strategy []common.Address) (*SuperVaultAggregatorStrategyCheckFailedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "StrategyCheckFailed", strategyRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorStrategyCheckFailedIterator{contract: _SuperVaultAggregator.contract, event: "StrategyCheckFailed", logs: logs, sub: sub}, nil
}

// WatchStrategyCheckFailed is a free log subscription operation binding the contract event 0xe364669b114d8ecba48ed1742526a04c78dd506cd3af6beb910f6622a928cbdb.
//
// Solidity: event StrategyCheckFailed(address indexed strategy, string reason)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchStrategyCheckFailed(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorStrategyCheckFailed, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "StrategyCheckFailed", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorStrategyCheckFailed)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyCheckFailed", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseStrategyCheckFailed(log types.Log) (*SuperVaultAggregatorStrategyCheckFailed, error) {
	event := new(SuperVaultAggregatorStrategyCheckFailed)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyCheckFailed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorStrategyHooksRootUpdateProposedIterator is returned from FilterStrategyHooksRootUpdateProposed and is used to iterate over the raw logs and unpacked data for StrategyHooksRootUpdateProposed events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyHooksRootUpdateProposedIterator struct {
	Event *SuperVaultAggregatorStrategyHooksRootUpdateProposed // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorStrategyHooksRootUpdateProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorStrategyHooksRootUpdateProposed)
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
		it.Event = new(SuperVaultAggregatorStrategyHooksRootUpdateProposed)
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
func (it *SuperVaultAggregatorStrategyHooksRootUpdateProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorStrategyHooksRootUpdateProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorStrategyHooksRootUpdateProposed represents a StrategyHooksRootUpdateProposed event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyHooksRootUpdateProposed struct {
	Strategy      common.Address
	Proposer      common.Address
	Root          [32]byte
	EffectiveTime *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterStrategyHooksRootUpdateProposed is a free log retrieval operation binding the contract event 0x3c67f914ba911b08519fae976b442675afa7d36b96bab1276ca2ab142c1b1714.
//
// Solidity: event StrategyHooksRootUpdateProposed(address indexed strategy, address indexed proposer, bytes32 root, uint256 effectiveTime)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterStrategyHooksRootUpdateProposed(opts *bind.FilterOpts, strategy []common.Address, proposer []common.Address) (*SuperVaultAggregatorStrategyHooksRootUpdateProposedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var proposerRule []interface{}
	for _, proposerItem := range proposer {
		proposerRule = append(proposerRule, proposerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "StrategyHooksRootUpdateProposed", strategyRule, proposerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorStrategyHooksRootUpdateProposedIterator{contract: _SuperVaultAggregator.contract, event: "StrategyHooksRootUpdateProposed", logs: logs, sub: sub}, nil
}

// WatchStrategyHooksRootUpdateProposed is a free log subscription operation binding the contract event 0x3c67f914ba911b08519fae976b442675afa7d36b96bab1276ca2ab142c1b1714.
//
// Solidity: event StrategyHooksRootUpdateProposed(address indexed strategy, address indexed proposer, bytes32 root, uint256 effectiveTime)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchStrategyHooksRootUpdateProposed(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorStrategyHooksRootUpdateProposed, strategy []common.Address, proposer []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var proposerRule []interface{}
	for _, proposerItem := range proposer {
		proposerRule = append(proposerRule, proposerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "StrategyHooksRootUpdateProposed", strategyRule, proposerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorStrategyHooksRootUpdateProposed)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootUpdateProposed", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseStrategyHooksRootUpdateProposed(log types.Log) (*SuperVaultAggregatorStrategyHooksRootUpdateProposed, error) {
	event := new(SuperVaultAggregatorStrategyHooksRootUpdateProposed)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootUpdateProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorStrategyHooksRootUpdatedIterator is returned from FilterStrategyHooksRootUpdated and is used to iterate over the raw logs and unpacked data for StrategyHooksRootUpdated events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyHooksRootUpdatedIterator struct {
	Event *SuperVaultAggregatorStrategyHooksRootUpdated // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorStrategyHooksRootUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorStrategyHooksRootUpdated)
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
		it.Event = new(SuperVaultAggregatorStrategyHooksRootUpdated)
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
func (it *SuperVaultAggregatorStrategyHooksRootUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorStrategyHooksRootUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorStrategyHooksRootUpdated represents a StrategyHooksRootUpdated event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyHooksRootUpdated struct {
	Strategy common.Address
	OldRoot  [32]byte
	NewRoot  [32]byte
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyHooksRootUpdated is a free log retrieval operation binding the contract event 0x50db1dc8f2cc634e637edbe632acec34656994c29a699c817c89e8de694035f6.
//
// Solidity: event StrategyHooksRootUpdated(address indexed strategy, bytes32 oldRoot, bytes32 newRoot)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterStrategyHooksRootUpdated(opts *bind.FilterOpts, strategy []common.Address) (*SuperVaultAggregatorStrategyHooksRootUpdatedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "StrategyHooksRootUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorStrategyHooksRootUpdatedIterator{contract: _SuperVaultAggregator.contract, event: "StrategyHooksRootUpdated", logs: logs, sub: sub}, nil
}

// WatchStrategyHooksRootUpdated is a free log subscription operation binding the contract event 0x50db1dc8f2cc634e637edbe632acec34656994c29a699c817c89e8de694035f6.
//
// Solidity: event StrategyHooksRootUpdated(address indexed strategy, bytes32 oldRoot, bytes32 newRoot)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchStrategyHooksRootUpdated(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorStrategyHooksRootUpdated, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "StrategyHooksRootUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorStrategyHooksRootUpdated)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootUpdated", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseStrategyHooksRootUpdated(log types.Log) (*SuperVaultAggregatorStrategyHooksRootUpdated, error) {
	event := new(SuperVaultAggregatorStrategyHooksRootUpdated)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator is returned from FilterStrategyHooksRootVetoStatusChanged and is used to iterate over the raw logs and unpacked data for StrategyHooksRootVetoStatusChanged events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator struct {
	Event *SuperVaultAggregatorStrategyHooksRootVetoStatusChanged // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorStrategyHooksRootVetoStatusChanged)
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
		it.Event = new(SuperVaultAggregatorStrategyHooksRootVetoStatusChanged)
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
func (it *SuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorStrategyHooksRootVetoStatusChanged represents a StrategyHooksRootVetoStatusChanged event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyHooksRootVetoStatusChanged struct {
	Strategy common.Address
	Vetoed   bool
	Root     [32]byte
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyHooksRootVetoStatusChanged is a free log retrieval operation binding the contract event 0x927440ad59e90a7b01af1effd4191955ea9e6ef812fc415e7f8e71eadbc5bc35.
//
// Solidity: event StrategyHooksRootVetoStatusChanged(address indexed strategy, bool vetoed, bytes32 indexed root)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterStrategyHooksRootVetoStatusChanged(opts *bind.FilterOpts, strategy []common.Address, root [][32]byte) (*SuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "StrategyHooksRootVetoStatusChanged", strategyRule, rootRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorStrategyHooksRootVetoStatusChangedIterator{contract: _SuperVaultAggregator.contract, event: "StrategyHooksRootVetoStatusChanged", logs: logs, sub: sub}, nil
}

// WatchStrategyHooksRootVetoStatusChanged is a free log subscription operation binding the contract event 0x927440ad59e90a7b01af1effd4191955ea9e6ef812fc415e7f8e71eadbc5bc35.
//
// Solidity: event StrategyHooksRootVetoStatusChanged(address indexed strategy, bool vetoed, bytes32 indexed root)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchStrategyHooksRootVetoStatusChanged(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorStrategyHooksRootVetoStatusChanged, strategy []common.Address, root [][32]byte) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	var rootRule []interface{}
	for _, rootItem := range root {
		rootRule = append(rootRule, rootItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "StrategyHooksRootVetoStatusChanged", strategyRule, rootRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorStrategyHooksRootVetoStatusChanged)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootVetoStatusChanged", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseStrategyHooksRootVetoStatusChanged(log types.Log) (*SuperVaultAggregatorStrategyHooksRootVetoStatusChanged, error) {
	event := new(SuperVaultAggregatorStrategyHooksRootVetoStatusChanged)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootVetoStatusChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorStrategyHooksRootVetoedIterator is returned from FilterStrategyHooksRootVetoed and is used to iterate over the raw logs and unpacked data for StrategyHooksRootVetoed events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyHooksRootVetoedIterator struct {
	Event *SuperVaultAggregatorStrategyHooksRootVetoed // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorStrategyHooksRootVetoedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorStrategyHooksRootVetoed)
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
		it.Event = new(SuperVaultAggregatorStrategyHooksRootVetoed)
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
func (it *SuperVaultAggregatorStrategyHooksRootVetoedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorStrategyHooksRootVetoedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorStrategyHooksRootVetoed represents a StrategyHooksRootVetoed event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyHooksRootVetoed struct {
	Guardian common.Address
	Strategy common.Address
	Root     [32]byte
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyHooksRootVetoed is a free log retrieval operation binding the contract event 0x13fb75f412cd7275ea6c0c59de6d99dd291eddab76417824e0edc385e5d75561.
//
// Solidity: event StrategyHooksRootVetoed(address indexed guardian, address indexed strategy, bytes32 indexed root)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterStrategyHooksRootVetoed(opts *bind.FilterOpts, guardian []common.Address, strategy []common.Address, root [][32]byte) (*SuperVaultAggregatorStrategyHooksRootVetoedIterator, error) {

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

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "StrategyHooksRootVetoed", guardianRule, strategyRule, rootRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorStrategyHooksRootVetoedIterator{contract: _SuperVaultAggregator.contract, event: "StrategyHooksRootVetoed", logs: logs, sub: sub}, nil
}

// WatchStrategyHooksRootVetoed is a free log subscription operation binding the contract event 0x13fb75f412cd7275ea6c0c59de6d99dd291eddab76417824e0edc385e5d75561.
//
// Solidity: event StrategyHooksRootVetoed(address indexed guardian, address indexed strategy, bytes32 indexed root)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchStrategyHooksRootVetoed(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorStrategyHooksRootVetoed, guardian []common.Address, strategy []common.Address, root [][32]byte) (event.Subscription, error) {

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

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "StrategyHooksRootVetoed", guardianRule, strategyRule, rootRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorStrategyHooksRootVetoed)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootVetoed", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseStrategyHooksRootVetoed(log types.Log) (*SuperVaultAggregatorStrategyHooksRootVetoed, error) {
	event := new(SuperVaultAggregatorStrategyHooksRootVetoed)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyHooksRootVetoed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorStrategyPPSStaleIterator is returned from FilterStrategyPPSStale and is used to iterate over the raw logs and unpacked data for StrategyPPSStale events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyPPSStaleIterator struct {
	Event *SuperVaultAggregatorStrategyPPSStale // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorStrategyPPSStaleIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorStrategyPPSStale)
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
		it.Event = new(SuperVaultAggregatorStrategyPPSStale)
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
func (it *SuperVaultAggregatorStrategyPPSStaleIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorStrategyPPSStaleIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorStrategyPPSStale represents a StrategyPPSStale event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyPPSStale struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyPPSStale is a free log retrieval operation binding the contract event 0x80796c8d1dc90790262881896e3680e577f032ca370f16b8dccd1cd4cef254f1.
//
// Solidity: event StrategyPPSStale(address indexed strategy)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterStrategyPPSStale(opts *bind.FilterOpts, strategy []common.Address) (*SuperVaultAggregatorStrategyPPSStaleIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "StrategyPPSStale", strategyRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorStrategyPPSStaleIterator{contract: _SuperVaultAggregator.contract, event: "StrategyPPSStale", logs: logs, sub: sub}, nil
}

// WatchStrategyPPSStale is a free log subscription operation binding the contract event 0x80796c8d1dc90790262881896e3680e577f032ca370f16b8dccd1cd4cef254f1.
//
// Solidity: event StrategyPPSStale(address indexed strategy)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchStrategyPPSStale(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorStrategyPPSStale, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "StrategyPPSStale", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorStrategyPPSStale)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyPPSStale", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseStrategyPPSStale(log types.Log) (*SuperVaultAggregatorStrategyPPSStale, error) {
	event := new(SuperVaultAggregatorStrategyPPSStale)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyPPSStale", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorStrategyPPSStaleResetIterator is returned from FilterStrategyPPSStaleReset and is used to iterate over the raw logs and unpacked data for StrategyPPSStaleReset events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyPPSStaleResetIterator struct {
	Event *SuperVaultAggregatorStrategyPPSStaleReset // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorStrategyPPSStaleResetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorStrategyPPSStaleReset)
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
		it.Event = new(SuperVaultAggregatorStrategyPPSStaleReset)
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
func (it *SuperVaultAggregatorStrategyPPSStaleResetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorStrategyPPSStaleResetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorStrategyPPSStaleReset represents a StrategyPPSStaleReset event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyPPSStaleReset struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyPPSStaleReset is a free log retrieval operation binding the contract event 0x87afbf71df10b23be48535f5f7689b97e949bf5b76a67c76e79fd0f10db005d8.
//
// Solidity: event StrategyPPSStaleReset(address indexed strategy)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterStrategyPPSStaleReset(opts *bind.FilterOpts, strategy []common.Address) (*SuperVaultAggregatorStrategyPPSStaleResetIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "StrategyPPSStaleReset", strategyRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorStrategyPPSStaleResetIterator{contract: _SuperVaultAggregator.contract, event: "StrategyPPSStaleReset", logs: logs, sub: sub}, nil
}

// WatchStrategyPPSStaleReset is a free log subscription operation binding the contract event 0x87afbf71df10b23be48535f5f7689b97e949bf5b76a67c76e79fd0f10db005d8.
//
// Solidity: event StrategyPPSStaleReset(address indexed strategy)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchStrategyPPSStaleReset(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorStrategyPPSStaleReset, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "StrategyPPSStaleReset", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorStrategyPPSStaleReset)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyPPSStaleReset", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseStrategyPPSStaleReset(log types.Log) (*SuperVaultAggregatorStrategyPPSStaleReset, error) {
	event := new(SuperVaultAggregatorStrategyPPSStaleReset)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyPPSStaleReset", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorStrategyPausedIterator is returned from FilterStrategyPaused and is used to iterate over the raw logs and unpacked data for StrategyPaused events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyPausedIterator struct {
	Event *SuperVaultAggregatorStrategyPaused // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorStrategyPausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorStrategyPaused)
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
		it.Event = new(SuperVaultAggregatorStrategyPaused)
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
func (it *SuperVaultAggregatorStrategyPausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorStrategyPausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorStrategyPaused represents a StrategyPaused event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyPaused struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyPaused is a free log retrieval operation binding the contract event 0xc2897a3765ea6cd9ed9ce463d3bc9c9cf968f21f8664b62684e1254d3b0f9ee5.
//
// Solidity: event StrategyPaused(address indexed strategy)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterStrategyPaused(opts *bind.FilterOpts, strategy []common.Address) (*SuperVaultAggregatorStrategyPausedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "StrategyPaused", strategyRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorStrategyPausedIterator{contract: _SuperVaultAggregator.contract, event: "StrategyPaused", logs: logs, sub: sub}, nil
}

// WatchStrategyPaused is a free log subscription operation binding the contract event 0xc2897a3765ea6cd9ed9ce463d3bc9c9cf968f21f8664b62684e1254d3b0f9ee5.
//
// Solidity: event StrategyPaused(address indexed strategy)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchStrategyPaused(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorStrategyPaused, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "StrategyPaused", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorStrategyPaused)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyPaused", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseStrategyPaused(log types.Log) (*SuperVaultAggregatorStrategyPaused, error) {
	event := new(SuperVaultAggregatorStrategyPaused)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyPaused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorStrategyUnpausePPSTimelockUpdatedIterator is returned from FilterStrategyUnpausePPSTimelockUpdated and is used to iterate over the raw logs and unpacked data for StrategyUnpausePPSTimelockUpdated events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyUnpausePPSTimelockUpdatedIterator struct {
	Event *SuperVaultAggregatorStrategyUnpausePPSTimelockUpdated // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorStrategyUnpausePPSTimelockUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorStrategyUnpausePPSTimelockUpdated)
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
		it.Event = new(SuperVaultAggregatorStrategyUnpausePPSTimelockUpdated)
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
func (it *SuperVaultAggregatorStrategyUnpausePPSTimelockUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorStrategyUnpausePPSTimelockUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorStrategyUnpausePPSTimelockUpdated represents a StrategyUnpausePPSTimelockUpdated event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyUnpausePPSTimelockUpdated struct {
	Strategy    common.Address
	NewTimelock *big.Int
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterStrategyUnpausePPSTimelockUpdated is a free log retrieval operation binding the contract event 0xcaa1beb16816b2a2a6d26301cfbde569da7a04748029f8b0239f2f23c1a7681d.
//
// Solidity: event StrategyUnpausePPSTimelockUpdated(address indexed strategy, uint256 newTimelock)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterStrategyUnpausePPSTimelockUpdated(opts *bind.FilterOpts, strategy []common.Address) (*SuperVaultAggregatorStrategyUnpausePPSTimelockUpdatedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "StrategyUnpausePPSTimelockUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorStrategyUnpausePPSTimelockUpdatedIterator{contract: _SuperVaultAggregator.contract, event: "StrategyUnpausePPSTimelockUpdated", logs: logs, sub: sub}, nil
}

// WatchStrategyUnpausePPSTimelockUpdated is a free log subscription operation binding the contract event 0xcaa1beb16816b2a2a6d26301cfbde569da7a04748029f8b0239f2f23c1a7681d.
//
// Solidity: event StrategyUnpausePPSTimelockUpdated(address indexed strategy, uint256 newTimelock)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchStrategyUnpausePPSTimelockUpdated(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorStrategyUnpausePPSTimelockUpdated, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "StrategyUnpausePPSTimelockUpdated", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorStrategyUnpausePPSTimelockUpdated)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyUnpausePPSTimelockUpdated", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseStrategyUnpausePPSTimelockUpdated(log types.Log) (*SuperVaultAggregatorStrategyUnpausePPSTimelockUpdated, error) {
	event := new(SuperVaultAggregatorStrategyUnpausePPSTimelockUpdated)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyUnpausePPSTimelockUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorStrategyUnpausedIterator is returned from FilterStrategyUnpaused and is used to iterate over the raw logs and unpacked data for StrategyUnpaused events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyUnpausedIterator struct {
	Event *SuperVaultAggregatorStrategyUnpaused // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorStrategyUnpausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorStrategyUnpaused)
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
		it.Event = new(SuperVaultAggregatorStrategyUnpaused)
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
func (it *SuperVaultAggregatorStrategyUnpausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorStrategyUnpausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorStrategyUnpaused represents a StrategyUnpaused event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorStrategyUnpaused struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterStrategyUnpaused is a free log retrieval operation binding the contract event 0x9de75c520457842eb5fe159114348bf5358100a1acaf1bcb5052f64f347503df.
//
// Solidity: event StrategyUnpaused(address indexed strategy)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterStrategyUnpaused(opts *bind.FilterOpts, strategy []common.Address) (*SuperVaultAggregatorStrategyUnpausedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "StrategyUnpaused", strategyRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorStrategyUnpausedIterator{contract: _SuperVaultAggregator.contract, event: "StrategyUnpaused", logs: logs, sub: sub}, nil
}

// WatchStrategyUnpaused is a free log subscription operation binding the contract event 0x9de75c520457842eb5fe159114348bf5358100a1acaf1bcb5052f64f347503df.
//
// Solidity: event StrategyUnpaused(address indexed strategy)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchStrategyUnpaused(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorStrategyUnpaused, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "StrategyUnpaused", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorStrategyUnpaused)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyUnpaused", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseStrategyUnpaused(log types.Log) (*SuperVaultAggregatorStrategyUnpaused, error) {
	event := new(SuperVaultAggregatorStrategyUnpaused)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "StrategyUnpaused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorTimestampNotMonotonicIterator is returned from FilterTimestampNotMonotonic and is used to iterate over the raw logs and unpacked data for TimestampNotMonotonic events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorTimestampNotMonotonicIterator struct {
	Event *SuperVaultAggregatorTimestampNotMonotonic // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorTimestampNotMonotonicIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorTimestampNotMonotonic)
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
		it.Event = new(SuperVaultAggregatorTimestampNotMonotonic)
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
func (it *SuperVaultAggregatorTimestampNotMonotonicIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorTimestampNotMonotonicIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorTimestampNotMonotonic represents a TimestampNotMonotonic event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorTimestampNotMonotonic struct {
	Raw types.Log // Blockchain specific contextual infos
}

// FilterTimestampNotMonotonic is a free log retrieval operation binding the contract event 0x2e78c6ab27a29f5c1471d797dd0809527031b55c91aa70143ffa36ceecfab75f.
//
// Solidity: event TimestampNotMonotonic()
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterTimestampNotMonotonic(opts *bind.FilterOpts) (*SuperVaultAggregatorTimestampNotMonotonicIterator, error) {

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "TimestampNotMonotonic")
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorTimestampNotMonotonicIterator{contract: _SuperVaultAggregator.contract, event: "TimestampNotMonotonic", logs: logs, sub: sub}, nil
}

// WatchTimestampNotMonotonic is a free log subscription operation binding the contract event 0x2e78c6ab27a29f5c1471d797dd0809527031b55c91aa70143ffa36ceecfab75f.
//
// Solidity: event TimestampNotMonotonic()
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchTimestampNotMonotonic(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorTimestampNotMonotonic) (event.Subscription, error) {

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "TimestampNotMonotonic")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorTimestampNotMonotonic)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "TimestampNotMonotonic", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseTimestampNotMonotonic(log types.Log) (*SuperVaultAggregatorTimestampNotMonotonic, error) {
	event := new(SuperVaultAggregatorTimestampNotMonotonic)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "TimestampNotMonotonic", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorUnknownStrategyIterator is returned from FilterUnknownStrategy and is used to iterate over the raw logs and unpacked data for UnknownStrategy events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorUnknownStrategyIterator struct {
	Event *SuperVaultAggregatorUnknownStrategy // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorUnknownStrategyIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorUnknownStrategy)
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
		it.Event = new(SuperVaultAggregatorUnknownStrategy)
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
func (it *SuperVaultAggregatorUnknownStrategyIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorUnknownStrategyIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorUnknownStrategy represents a UnknownStrategy event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorUnknownStrategy struct {
	Strategy common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterUnknownStrategy is a free log retrieval operation binding the contract event 0xde5abf6fb8e50b9c44ca7d6b0b47660db6158640044348124a98dbb8c94d6524.
//
// Solidity: event UnknownStrategy(address indexed strategy)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterUnknownStrategy(opts *bind.FilterOpts, strategy []common.Address) (*SuperVaultAggregatorUnknownStrategyIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "UnknownStrategy", strategyRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorUnknownStrategyIterator{contract: _SuperVaultAggregator.contract, event: "UnknownStrategy", logs: logs, sub: sub}, nil
}

// WatchUnknownStrategy is a free log subscription operation binding the contract event 0xde5abf6fb8e50b9c44ca7d6b0b47660db6158640044348124a98dbb8c94d6524.
//
// Solidity: event UnknownStrategy(address indexed strategy)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchUnknownStrategy(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorUnknownStrategy, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "UnknownStrategy", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorUnknownStrategy)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "UnknownStrategy", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseUnknownStrategy(log types.Log) (*SuperVaultAggregatorUnknownStrategy, error) {
	event := new(SuperVaultAggregatorUnknownStrategy)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "UnknownStrategy", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorUpdateTooFrequentIterator is returned from FilterUpdateTooFrequent and is used to iterate over the raw logs and unpacked data for UpdateTooFrequent events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorUpdateTooFrequentIterator struct {
	Event *SuperVaultAggregatorUpdateTooFrequent // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorUpdateTooFrequentIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorUpdateTooFrequent)
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
		it.Event = new(SuperVaultAggregatorUpdateTooFrequent)
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
func (it *SuperVaultAggregatorUpdateTooFrequentIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorUpdateTooFrequentIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorUpdateTooFrequent represents a UpdateTooFrequent event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorUpdateTooFrequent struct {
	Raw types.Log // Blockchain specific contextual infos
}

// FilterUpdateTooFrequent is a free log retrieval operation binding the contract event 0x53f7a6ee85aab0f20869755601a6424676aa3807e9ef249627fa11a39e9a0e0c.
//
// Solidity: event UpdateTooFrequent()
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterUpdateTooFrequent(opts *bind.FilterOpts) (*SuperVaultAggregatorUpdateTooFrequentIterator, error) {

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "UpdateTooFrequent")
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorUpdateTooFrequentIterator{contract: _SuperVaultAggregator.contract, event: "UpdateTooFrequent", logs: logs, sub: sub}, nil
}

// WatchUpdateTooFrequent is a free log subscription operation binding the contract event 0x53f7a6ee85aab0f20869755601a6424676aa3807e9ef249627fa11a39e9a0e0c.
//
// Solidity: event UpdateTooFrequent()
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchUpdateTooFrequent(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorUpdateTooFrequent) (event.Subscription, error) {

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "UpdateTooFrequent")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorUpdateTooFrequent)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "UpdateTooFrequent", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseUpdateTooFrequent(log types.Log) (*SuperVaultAggregatorUpdateTooFrequent, error) {
	event := new(SuperVaultAggregatorUpdateTooFrequent)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "UpdateTooFrequent", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorUpkeepClaimedIterator is returned from FilterUpkeepClaimed and is used to iterate over the raw logs and unpacked data for UpkeepClaimed events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorUpkeepClaimedIterator struct {
	Event *SuperVaultAggregatorUpkeepClaimed // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorUpkeepClaimedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorUpkeepClaimed)
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
		it.Event = new(SuperVaultAggregatorUpkeepClaimed)
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
func (it *SuperVaultAggregatorUpkeepClaimedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorUpkeepClaimedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorUpkeepClaimed represents a UpkeepClaimed event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorUpkeepClaimed struct {
	SuperBank common.Address
	Amount    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterUpkeepClaimed is a free log retrieval operation binding the contract event 0x43214536812d90daa91186dfb744049f5e3c6f3379765892f0f41b204a87e0ee.
//
// Solidity: event UpkeepClaimed(address indexed superBank, uint256 amount)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterUpkeepClaimed(opts *bind.FilterOpts, superBank []common.Address) (*SuperVaultAggregatorUpkeepClaimedIterator, error) {

	var superBankRule []interface{}
	for _, superBankItem := range superBank {
		superBankRule = append(superBankRule, superBankItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "UpkeepClaimed", superBankRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorUpkeepClaimedIterator{contract: _SuperVaultAggregator.contract, event: "UpkeepClaimed", logs: logs, sub: sub}, nil
}

// WatchUpkeepClaimed is a free log subscription operation binding the contract event 0x43214536812d90daa91186dfb744049f5e3c6f3379765892f0f41b204a87e0ee.
//
// Solidity: event UpkeepClaimed(address indexed superBank, uint256 amount)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchUpkeepClaimed(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorUpkeepClaimed, superBank []common.Address) (event.Subscription, error) {

	var superBankRule []interface{}
	for _, superBankItem := range superBank {
		superBankRule = append(superBankRule, superBankItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "UpkeepClaimed", superBankRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorUpkeepClaimed)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "UpkeepClaimed", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseUpkeepClaimed(log types.Log) (*SuperVaultAggregatorUpkeepClaimed, error) {
	event := new(SuperVaultAggregatorUpkeepClaimed)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "UpkeepClaimed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorUpkeepCostUpdatedIterator is returned from FilterUpkeepCostUpdated and is used to iterate over the raw logs and unpacked data for UpkeepCostUpdated events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorUpkeepCostUpdatedIterator struct {
	Event *SuperVaultAggregatorUpkeepCostUpdated // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorUpkeepCostUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorUpkeepCostUpdated)
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
		it.Event = new(SuperVaultAggregatorUpkeepCostUpdated)
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
func (it *SuperVaultAggregatorUpkeepCostUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorUpkeepCostUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorUpkeepCostUpdated represents a UpkeepCostUpdated event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorUpkeepCostUpdated struct {
	OldCost *big.Int
	NewCost *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterUpkeepCostUpdated is a free log retrieval operation binding the contract event 0x39bca166dfce33a0df0f6a53e61159a307a9cf65e4c4982a9d025df35b60e746.
//
// Solidity: event UpkeepCostUpdated(uint256 oldCost, uint256 newCost)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterUpkeepCostUpdated(opts *bind.FilterOpts) (*SuperVaultAggregatorUpkeepCostUpdatedIterator, error) {

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "UpkeepCostUpdated")
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorUpkeepCostUpdatedIterator{contract: _SuperVaultAggregator.contract, event: "UpkeepCostUpdated", logs: logs, sub: sub}, nil
}

// WatchUpkeepCostUpdated is a free log subscription operation binding the contract event 0x39bca166dfce33a0df0f6a53e61159a307a9cf65e4c4982a9d025df35b60e746.
//
// Solidity: event UpkeepCostUpdated(uint256 oldCost, uint256 newCost)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchUpkeepCostUpdated(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorUpkeepCostUpdated) (event.Subscription, error) {

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "UpkeepCostUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorUpkeepCostUpdated)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "UpkeepCostUpdated", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseUpkeepCostUpdated(log types.Log) (*SuperVaultAggregatorUpkeepCostUpdated, error) {
	event := new(SuperVaultAggregatorUpkeepCostUpdated)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "UpkeepCostUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorUpkeepDepositedIterator is returned from FilterUpkeepDeposited and is used to iterate over the raw logs and unpacked data for UpkeepDeposited events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorUpkeepDepositedIterator struct {
	Event *SuperVaultAggregatorUpkeepDeposited // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorUpkeepDepositedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorUpkeepDeposited)
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
		it.Event = new(SuperVaultAggregatorUpkeepDeposited)
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
func (it *SuperVaultAggregatorUpkeepDepositedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorUpkeepDepositedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorUpkeepDeposited represents a UpkeepDeposited event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorUpkeepDeposited struct {
	Manager common.Address
	Amount  *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterUpkeepDeposited is a free log retrieval operation binding the contract event 0xf0616af70d35af23c32610a6397a036a898c088ade99b972a26dc56e54798865.
//
// Solidity: event UpkeepDeposited(address indexed manager, uint256 amount)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterUpkeepDeposited(opts *bind.FilterOpts, manager []common.Address) (*SuperVaultAggregatorUpkeepDepositedIterator, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "UpkeepDeposited", managerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorUpkeepDepositedIterator{contract: _SuperVaultAggregator.contract, event: "UpkeepDeposited", logs: logs, sub: sub}, nil
}

// WatchUpkeepDeposited is a free log subscription operation binding the contract event 0xf0616af70d35af23c32610a6397a036a898c088ade99b972a26dc56e54798865.
//
// Solidity: event UpkeepDeposited(address indexed manager, uint256 amount)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchUpkeepDeposited(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorUpkeepDeposited, manager []common.Address) (event.Subscription, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "UpkeepDeposited", managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorUpkeepDeposited)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "UpkeepDeposited", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseUpkeepDeposited(log types.Log) (*SuperVaultAggregatorUpkeepDeposited, error) {
	event := new(SuperVaultAggregatorUpkeepDeposited)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "UpkeepDeposited", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorUpkeepSpentIterator is returned from FilterUpkeepSpent and is used to iterate over the raw logs and unpacked data for UpkeepSpent events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorUpkeepSpentIterator struct {
	Event *SuperVaultAggregatorUpkeepSpent // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorUpkeepSpentIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorUpkeepSpent)
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
		it.Event = new(SuperVaultAggregatorUpkeepSpent)
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
func (it *SuperVaultAggregatorUpkeepSpentIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorUpkeepSpentIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorUpkeepSpent represents a UpkeepSpent event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorUpkeepSpent struct {
	Manager         common.Address
	Amount          *big.Int
	Balance         *big.Int
	ClaimableUpkeep *big.Int
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterUpkeepSpent is a free log retrieval operation binding the contract event 0x70485ec1c1ebd5a2176ff9969ef90917bbeca387cb89fee9a5fac5840d7253d9.
//
// Solidity: event UpkeepSpent(address indexed manager, uint256 amount, uint256 balance, uint256 claimableUpkeep)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterUpkeepSpent(opts *bind.FilterOpts, manager []common.Address) (*SuperVaultAggregatorUpkeepSpentIterator, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "UpkeepSpent", managerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorUpkeepSpentIterator{contract: _SuperVaultAggregator.contract, event: "UpkeepSpent", logs: logs, sub: sub}, nil
}

// WatchUpkeepSpent is a free log subscription operation binding the contract event 0x70485ec1c1ebd5a2176ff9969ef90917bbeca387cb89fee9a5fac5840d7253d9.
//
// Solidity: event UpkeepSpent(address indexed manager, uint256 amount, uint256 balance, uint256 claimableUpkeep)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchUpkeepSpent(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorUpkeepSpent, manager []common.Address) (event.Subscription, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "UpkeepSpent", managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorUpkeepSpent)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "UpkeepSpent", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseUpkeepSpent(log types.Log) (*SuperVaultAggregatorUpkeepSpent, error) {
	event := new(SuperVaultAggregatorUpkeepSpent)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "UpkeepSpent", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorUpkeepWithdrawnIterator is returned from FilterUpkeepWithdrawn and is used to iterate over the raw logs and unpacked data for UpkeepWithdrawn events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorUpkeepWithdrawnIterator struct {
	Event *SuperVaultAggregatorUpkeepWithdrawn // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorUpkeepWithdrawnIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorUpkeepWithdrawn)
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
		it.Event = new(SuperVaultAggregatorUpkeepWithdrawn)
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
func (it *SuperVaultAggregatorUpkeepWithdrawnIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorUpkeepWithdrawnIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorUpkeepWithdrawn represents a UpkeepWithdrawn event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorUpkeepWithdrawn struct {
	Manager common.Address
	Amount  *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterUpkeepWithdrawn is a free log retrieval operation binding the contract event 0x4a588cb81e6e407560dfbf48e566f684e0b6b791bd8ced912e4f9c58aa99e3d2.
//
// Solidity: event UpkeepWithdrawn(address indexed manager, uint256 amount)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterUpkeepWithdrawn(opts *bind.FilterOpts, manager []common.Address) (*SuperVaultAggregatorUpkeepWithdrawnIterator, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "UpkeepWithdrawn", managerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorUpkeepWithdrawnIterator{contract: _SuperVaultAggregator.contract, event: "UpkeepWithdrawn", logs: logs, sub: sub}, nil
}

// WatchUpkeepWithdrawn is a free log subscription operation binding the contract event 0x4a588cb81e6e407560dfbf48e566f684e0b6b791bd8ced912e4f9c58aa99e3d2.
//
// Solidity: event UpkeepWithdrawn(address indexed manager, uint256 amount)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchUpkeepWithdrawn(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorUpkeepWithdrawn, manager []common.Address) (event.Subscription, error) {

	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "UpkeepWithdrawn", managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorUpkeepWithdrawn)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "UpkeepWithdrawn", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseUpkeepWithdrawn(log types.Log) (*SuperVaultAggregatorUpkeepWithdrawn, error) {
	event := new(SuperVaultAggregatorUpkeepWithdrawn)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "UpkeepWithdrawn", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultAggregatorVaultDeployedIterator is returned from FilterVaultDeployed and is used to iterate over the raw logs and unpacked data for VaultDeployed events raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorVaultDeployedIterator struct {
	Event *SuperVaultAggregatorVaultDeployed // Event containing the contract specifics and raw log

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
func (it *SuperVaultAggregatorVaultDeployedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultAggregatorVaultDeployed)
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
		it.Event = new(SuperVaultAggregatorVaultDeployed)
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
func (it *SuperVaultAggregatorVaultDeployedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultAggregatorVaultDeployedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultAggregatorVaultDeployed represents a VaultDeployed event raised by the SuperVaultAggregator contract.
type SuperVaultAggregatorVaultDeployed struct {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) FilterVaultDeployed(opts *bind.FilterOpts, vault []common.Address, strategy []common.Address, nonce []*big.Int) (*SuperVaultAggregatorVaultDeployedIterator, error) {

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

	logs, sub, err := _SuperVaultAggregator.contract.FilterLogs(opts, "VaultDeployed", vaultRule, strategyRule, nonceRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultAggregatorVaultDeployedIterator{contract: _SuperVaultAggregator.contract, event: "VaultDeployed", logs: logs, sub: sub}, nil
}

// WatchVaultDeployed is a free log subscription operation binding the contract event 0xb71e4c3b886bfa372037021505c466d28e41fc077044f0f8be29eeff13713347.
//
// Solidity: event VaultDeployed(address indexed vault, address indexed strategy, address escrow, address asset, string name, string symbol, uint256 indexed nonce)
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) WatchVaultDeployed(opts *bind.WatchOpts, sink chan<- *SuperVaultAggregatorVaultDeployed, vault []common.Address, strategy []common.Address, nonce []*big.Int) (event.Subscription, error) {

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

	logs, sub, err := _SuperVaultAggregator.contract.WatchLogs(opts, "VaultDeployed", vaultRule, strategyRule, nonceRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultAggregatorVaultDeployed)
				if err := _SuperVaultAggregator.contract.UnpackLog(event, "VaultDeployed", log); err != nil {
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
func (_SuperVaultAggregator *SuperVaultAggregatorFilterer) ParseVaultDeployed(log types.Log) (*SuperVaultAggregatorVaultDeployed, error) {
	event := new(SuperVaultAggregatorVaultDeployed)
	if err := _SuperVaultAggregator.contract.UnpackLog(event, "VaultDeployed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
