// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package SuperVaultStrategy

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

// ISuperVaultStrategyExecuteArgs is an auto generated low-level Go binding around an user-defined struct.
type ISuperVaultStrategyExecuteArgs struct {
	Hooks                     []common.Address
	HookCalldata              [][]byte
	ExpectedAssetsOrSharesOut []*big.Int
	GlobalProofs              [][][32]byte
	StrategyProofs            [][][32]byte
}

// ISuperVaultStrategyFeeConfig is an auto generated low-level Go binding around an user-defined struct.
type ISuperVaultStrategyFeeConfig struct {
	PerformanceFeeBps *big.Int
	ManagementFeeBps  *big.Int
	Recipient         common.Address
}

// ISuperVaultStrategySuperVaultState is an auto generated low-level Go binding around an user-defined struct.
type ISuperVaultStrategySuperVaultState struct {
	PendingCancelRedeemRequest   bool
	ClaimableCancelRedeemRequest *big.Int
	PendingRedeemRequest         *big.Int
	MaxWithdraw                  *big.Int
	AverageRequestPPS            *big.Int
	AverageWithdrawPrice         *big.Int
	RedeemSlippageBps            uint16
}

// ISuperVaultStrategyYieldSource is an auto generated low-level Go binding around an user-defined struct.
type ISuperVaultStrategyYieldSource struct {
	Oracle common.Address
}

// ISuperVaultStrategyYieldSourceInfo is an auto generated low-level Go binding around an user-defined struct.
type ISuperVaultStrategyYieldSourceInfo struct {
	SourceAddress common.Address
	Oracle        common.Address
}

// SuperVaultStrategyMetaData contains all meta data concerning the SuperVaultStrategy contract.
var SuperVaultStrategyMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"superGovernor_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"receive\",\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"DEFAULT_REDEEM_SLIPPAGE_BPS\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint16\",\"internalType\":\"uint16\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"PRECISION\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_GOVERNOR\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISuperGovernor\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"changeFeeRecipient\",\"inputs\":[{\"name\":\"newRecipient\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"claimableCancelRedeemRequest\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"claimableShares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"claimableWithdraw\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"claimableAssets\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"containsYieldSource\",\"inputs\":[{\"name\":\"source\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"executeHooks\",\"inputs\":[{\"name\":\"args\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultStrategy.ExecuteArgs\",\"components\":[{\"name\":\"hooks\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"hookCalldata\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"},{\"name\":\"expectedAssetsOrSharesOut\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"globalProofs\",\"type\":\"bytes32[][]\",\"internalType\":\"bytes32[][]\"},{\"name\":\"strategyProofs\",\"type\":\"bytes32[][]\",\"internalType\":\"bytes32[][]\"}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"executeVaultFeeConfigUpdate\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"fulfillCancelRedeemRequests\",\"inputs\":[{\"name\":\"controllers\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"fulfillRedeemRequests\",\"inputs\":[{\"name\":\"controllers\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"totalAssetsOut\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getAverageWithdrawPrice\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"averageWithdrawPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getConfigInfo\",\"inputs\":[],\"outputs\":[{\"name\":\"feeConfig_\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultStrategy.FeeConfig\",\"components\":[{\"name\":\"performanceFeeBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"managementFeeBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"recipient\",\"type\":\"address\",\"internalType\":\"address\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getStoredPPS\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSuperVaultState\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"state\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultStrategy.SuperVaultState\",\"components\":[{\"name\":\"pendingCancelRedeemRequest\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"claimableCancelRedeemRequest\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"pendingRedeemRequest\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxWithdraw\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"averageRequestPPS\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"averageWithdrawPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"redeemSlippageBps\",\"type\":\"uint16\",\"internalType\":\"uint16\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getVaultInfo\",\"inputs\":[],\"outputs\":[{\"name\":\"vault\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"asset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"vaultDecimals\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getYieldSource\",\"inputs\":[{\"name\":\"source\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultStrategy.YieldSource\",\"components\":[{\"name\":\"oracle\",\"type\":\"address\",\"internalType\":\"address\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getYieldSources\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getYieldSourcesCount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getYieldSourcesList\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"tuple[]\",\"internalType\":\"structISuperVaultStrategy.YieldSourceInfo[]\",\"components\":[{\"name\":\"sourceAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"oracle\",\"type\":\"address\",\"internalType\":\"address\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"handleOperations4626Deposit\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"assetsGross\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"sharesNet\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"handleOperations4626Mint\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"sharesNet\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"assetsGross\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"assetsNet\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"handleOperations7540\",\"inputs\":[{\"name\":\"operation\",\"type\":\"uint8\",\"internalType\":\"enumISuperVaultStrategy.Operation\"},{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"initialize\",\"inputs\":[{\"name\":\"vaultAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"feeConfigData\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultStrategy.FeeConfig\",\"components\":[{\"name\":\"performanceFeeBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"managementFeeBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"recipient\",\"type\":\"address\",\"internalType\":\"address\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"managePPSExpiration\",\"inputs\":[{\"name\":\"action\",\"type\":\"uint8\",\"internalType\":\"enumISuperVaultStrategy.PPSExpirationAction\"},{\"name\":\"staleness_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"manageYieldSource\",\"inputs\":[{\"name\":\"source\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"oracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"actionType\",\"type\":\"uint8\",\"internalType\":\"enumISuperVaultStrategy.YieldSourceAction\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"manageYieldSources\",\"inputs\":[{\"name\":\"sources\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"oracles\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"actionTypes\",\"type\":\"uint8[]\",\"internalType\":\"enumISuperVaultStrategy.YieldSourceAction[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"pendingCancelRedeemRequest\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pendingRedeemRequest\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"pendingShares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ppsExpiration\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ppsExpiryThresholdEffectiveTime\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"previewExactRedeem\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"theoreticalAssets\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"minAssets\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"previewExactRedeemBatch\",\"inputs\":[{\"name\":\"controllers\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[{\"name\":\"totalTheoAssets\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"individualAssets\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proposeVaultFeeConfigUpdate\",\"inputs\":[{\"name\":\"performanceFeeBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"managementFeeBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"recipient\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"proposedPPSExpiryThreshold\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"quoteMintAssetsGross\",\"inputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"assetsGross\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"assetsNet\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"resetHighWaterMark\",\"inputs\":[{\"name\":\"newHwmPps\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setRedeemSlippage\",\"inputs\":[{\"name\":\"slippageBps\",\"type\":\"uint16\",\"internalType\":\"uint16\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"skimPerformanceFee\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"vaultHwmPps\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"vaultUnrealizedProfit\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"DepositHandled\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"assets\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FeeRecipientChanged\",\"inputs\":[{\"name\":\"newRecipient\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"HWMPPSUpdated\",\"inputs\":[{\"name\":\"newHwmPps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"previousPps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"profit\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"feeCollected\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"HighWaterMarkReset\",\"inputs\":[{\"name\":\"newHwmPps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"HookExecuted\",\"inputs\":[{\"name\":\"hook\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"prevHook\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"targetedYieldSource\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"usePrevHookAmount\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"},{\"name\":\"hookCalldata\",\"type\":\"bytes\",\"indexed\":false,\"internalType\":\"bytes\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"HooksExecuted\",\"inputs\":[{\"name\":\"hooks\",\"type\":\"address[]\",\"indexed\":false,\"internalType\":\"address[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Initialized\",\"inputs\":[{\"name\":\"version\",\"type\":\"uint64\",\"indexed\":false,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Initialized\",\"inputs\":[{\"name\":\"vault\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ManagementFeePaid\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"recipient\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"feeAssets\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"feeBps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSExpirationProposed\",\"inputs\":[{\"name\":\"currentProposedThreshold\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"ppsExpiration\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSExpiryThresholdProposalCanceled\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSExpiryThresholdUpdated\",\"inputs\":[{\"name\":\"ppsExpiration\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSUpdated\",\"inputs\":[{\"name\":\"newPPS\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"calculationBlock\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PerformanceFeeSkimmed\",\"inputs\":[{\"name\":\"totalFee\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"superformFee\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RedeemCancelRequestFulfilled\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RedeemCancelRequestPlaced\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RedeemClaimable\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"assetsFulfilled\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"sharesFulfilled\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"averageWithdrawPrice\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RedeemRequestCanceled\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RedeemRequestClaimed\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"receiver\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"assets\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RedeemRequestPlaced\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RedeemRequestsFulfilled\",\"inputs\":[{\"name\":\"controllers\",\"type\":\"address[]\",\"indexed\":false,\"internalType\":\"address[]\"},{\"name\":\"processedShares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"currentPPS\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RedeemSlippageSet\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"slippageBps\",\"type\":\"uint16\",\"indexed\":false,\"internalType\":\"uint16\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SuperGovernorSet\",\"inputs\":[{\"name\":\"superGovernor\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"VaultFeeConfigProposed\",\"inputs\":[{\"name\":\"performanceFeeBps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"managementFeeBps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"recipient\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"effectiveTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"VaultFeeConfigUpdated\",\"inputs\":[{\"name\":\"performanceFeeBps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"managementFeeBps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"recipient\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"YieldSourceAdded\",\"inputs\":[{\"name\":\"source\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"oracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"YieldSourceOracleUpdated\",\"inputs\":[{\"name\":\"source\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"oldOracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"YieldSourceRemoved\",\"inputs\":[{\"name\":\"source\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ACCESS_DENIED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ACTION_TYPE_DISALLOWED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BOUNDS_EXCEEDED\",\"inputs\":[{\"name\":\"minAllowed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxAllowed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"actual\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"CANCELLATION_REDEEM_REQUEST_PENDING\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CONTROLLERS_NOT_SORTED_UNIQUE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"HOOK_VALIDATION_FAILED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_LIQUIDITY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_AMOUNT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_ARRAY_LENGTH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_ASSET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_ASSET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_HOOK\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_PERFORMANCE_FEE_BPS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_PPS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_PPS_EXPIRY_THRESHOLD\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_REDEEM_SLIPPAGE_BPS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_TIMESTAMP\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_VAULT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidInitialization\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MANAGER_NOT_AUTHORIZED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MINIMUM_OUTPUT_AMOUNT_ASSETS_NOT_MET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_ENOUGH_FREE_ASSETS_FEE_SKIM\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_PROPOSAL\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NotInitializing\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"OPERATIONS_BLOCKED_BY_VETO\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"OPERATION_FAILED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PPS_EXPIRED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"REQUEST_NOT_FOUND\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ReentrancyGuardReentrantCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SKIM_TIMELOCK_ACTIVE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"STALE_PPS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"STRATEGY_PAUSED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"YIELD_SOURCE_ALREADY_EXISTS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"YIELD_SOURCE_NOT_FOUND\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_LENGTH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_SHARE_FULFILLMENT_DISALLOWED\",\"inputs\":[]}]",
}

// SuperVaultStrategyABI is the input ABI used to generate the binding from.
// Deprecated: Use SuperVaultStrategyMetaData.ABI instead.
var SuperVaultStrategyABI = SuperVaultStrategyMetaData.ABI

// SuperVaultStrategy is an auto generated Go binding around an Ethereum contract.
type SuperVaultStrategy struct {
	SuperVaultStrategyCaller     // Read-only binding to the contract
	SuperVaultStrategyTransactor // Write-only binding to the contract
	SuperVaultStrategyFilterer   // Log filterer for contract events
}

// SuperVaultStrategyCaller is an auto generated read-only Go binding around an Ethereum contract.
type SuperVaultStrategyCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultStrategyTransactor is an auto generated write-only Go binding around an Ethereum contract.
type SuperVaultStrategyTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultStrategyFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type SuperVaultStrategyFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultStrategySession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type SuperVaultStrategySession struct {
	Contract     *SuperVaultStrategy // Generic contract binding to set the session for
	CallOpts     bind.CallOpts       // Call options to use throughout this session
	TransactOpts bind.TransactOpts   // Transaction auth options to use throughout this session
}

// SuperVaultStrategyCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type SuperVaultStrategyCallerSession struct {
	Contract *SuperVaultStrategyCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts             // Call options to use throughout this session
}

// SuperVaultStrategyTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type SuperVaultStrategyTransactorSession struct {
	Contract     *SuperVaultStrategyTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts             // Transaction auth options to use throughout this session
}

// SuperVaultStrategyRaw is an auto generated low-level Go binding around an Ethereum contract.
type SuperVaultStrategyRaw struct {
	Contract *SuperVaultStrategy // Generic contract binding to access the raw methods on
}

// SuperVaultStrategyCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type SuperVaultStrategyCallerRaw struct {
	Contract *SuperVaultStrategyCaller // Generic read-only contract binding to access the raw methods on
}

// SuperVaultStrategyTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type SuperVaultStrategyTransactorRaw struct {
	Contract *SuperVaultStrategyTransactor // Generic write-only contract binding to access the raw methods on
}

// NewSuperVaultStrategy creates a new instance of SuperVaultStrategy, bound to a specific deployed contract.
func NewSuperVaultStrategy(address common.Address, backend bind.ContractBackend) (*SuperVaultStrategy, error) {
	contract, err := bindSuperVaultStrategy(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategy{SuperVaultStrategyCaller: SuperVaultStrategyCaller{contract: contract}, SuperVaultStrategyTransactor: SuperVaultStrategyTransactor{contract: contract}, SuperVaultStrategyFilterer: SuperVaultStrategyFilterer{contract: contract}}, nil
}

// NewSuperVaultStrategyCaller creates a new read-only instance of SuperVaultStrategy, bound to a specific deployed contract.
func NewSuperVaultStrategyCaller(address common.Address, caller bind.ContractCaller) (*SuperVaultStrategyCaller, error) {
	contract, err := bindSuperVaultStrategy(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyCaller{contract: contract}, nil
}

// NewSuperVaultStrategyTransactor creates a new write-only instance of SuperVaultStrategy, bound to a specific deployed contract.
func NewSuperVaultStrategyTransactor(address common.Address, transactor bind.ContractTransactor) (*SuperVaultStrategyTransactor, error) {
	contract, err := bindSuperVaultStrategy(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyTransactor{contract: contract}, nil
}

// NewSuperVaultStrategyFilterer creates a new log filterer instance of SuperVaultStrategy, bound to a specific deployed contract.
func NewSuperVaultStrategyFilterer(address common.Address, filterer bind.ContractFilterer) (*SuperVaultStrategyFilterer, error) {
	contract, err := bindSuperVaultStrategy(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyFilterer{contract: contract}, nil
}

// bindSuperVaultStrategy binds a generic wrapper to an already deployed contract.
func bindSuperVaultStrategy(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := SuperVaultStrategyMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperVaultStrategy *SuperVaultStrategyRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperVaultStrategy.Contract.SuperVaultStrategyCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperVaultStrategy *SuperVaultStrategyRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.SuperVaultStrategyTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperVaultStrategy *SuperVaultStrategyRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.SuperVaultStrategyTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperVaultStrategy *SuperVaultStrategyCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperVaultStrategy.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperVaultStrategy *SuperVaultStrategyTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperVaultStrategy *SuperVaultStrategyTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.contract.Transact(opts, method, params...)
}

// DEFAULTREDEEMSLIPPAGEBPS is a free data retrieval call binding the contract method 0x45892a76.
//
// Solidity: function DEFAULT_REDEEM_SLIPPAGE_BPS() view returns(uint16)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) DEFAULTREDEEMSLIPPAGEBPS(opts *bind.CallOpts) (uint16, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "DEFAULT_REDEEM_SLIPPAGE_BPS")

	if err != nil {
		return *new(uint16), err
	}

	out0 := *abi.ConvertType(out[0], new(uint16)).(*uint16)

	return out0, err

}

// DEFAULTREDEEMSLIPPAGEBPS is a free data retrieval call binding the contract method 0x45892a76.
//
// Solidity: function DEFAULT_REDEEM_SLIPPAGE_BPS() view returns(uint16)
func (_SuperVaultStrategy *SuperVaultStrategySession) DEFAULTREDEEMSLIPPAGEBPS() (uint16, error) {
	return _SuperVaultStrategy.Contract.DEFAULTREDEEMSLIPPAGEBPS(&_SuperVaultStrategy.CallOpts)
}

// DEFAULTREDEEMSLIPPAGEBPS is a free data retrieval call binding the contract method 0x45892a76.
//
// Solidity: function DEFAULT_REDEEM_SLIPPAGE_BPS() view returns(uint16)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) DEFAULTREDEEMSLIPPAGEBPS() (uint16, error) {
	return _SuperVaultStrategy.Contract.DEFAULTREDEEMSLIPPAGEBPS(&_SuperVaultStrategy.CallOpts)
}

// PRECISION is a free data retrieval call binding the contract method 0xaaf5eb68.
//
// Solidity: function PRECISION() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) PRECISION(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "PRECISION")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PRECISION is a free data retrieval call binding the contract method 0xaaf5eb68.
//
// Solidity: function PRECISION() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategySession) PRECISION() (*big.Int, error) {
	return _SuperVaultStrategy.Contract.PRECISION(&_SuperVaultStrategy.CallOpts)
}

// PRECISION is a free data retrieval call binding the contract method 0xaaf5eb68.
//
// Solidity: function PRECISION() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) PRECISION() (*big.Int, error) {
	return _SuperVaultStrategy.Contract.PRECISION(&_SuperVaultStrategy.CallOpts)
}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) SUPERGOVERNOR(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "SUPER_GOVERNOR")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_SuperVaultStrategy *SuperVaultStrategySession) SUPERGOVERNOR() (common.Address, error) {
	return _SuperVaultStrategy.Contract.SUPERGOVERNOR(&_SuperVaultStrategy.CallOpts)
}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) SUPERGOVERNOR() (common.Address, error) {
	return _SuperVaultStrategy.Contract.SUPERGOVERNOR(&_SuperVaultStrategy.CallOpts)
}

// ClaimableCancelRedeemRequest is a free data retrieval call binding the contract method 0xc67e1368.
//
// Solidity: function claimableCancelRedeemRequest(address controller) view returns(uint256 claimableShares)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) ClaimableCancelRedeemRequest(opts *bind.CallOpts, controller common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "claimableCancelRedeemRequest", controller)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ClaimableCancelRedeemRequest is a free data retrieval call binding the contract method 0xc67e1368.
//
// Solidity: function claimableCancelRedeemRequest(address controller) view returns(uint256 claimableShares)
func (_SuperVaultStrategy *SuperVaultStrategySession) ClaimableCancelRedeemRequest(controller common.Address) (*big.Int, error) {
	return _SuperVaultStrategy.Contract.ClaimableCancelRedeemRequest(&_SuperVaultStrategy.CallOpts, controller)
}

// ClaimableCancelRedeemRequest is a free data retrieval call binding the contract method 0xc67e1368.
//
// Solidity: function claimableCancelRedeemRequest(address controller) view returns(uint256 claimableShares)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) ClaimableCancelRedeemRequest(controller common.Address) (*big.Int, error) {
	return _SuperVaultStrategy.Contract.ClaimableCancelRedeemRequest(&_SuperVaultStrategy.CallOpts, controller)
}

// ClaimableWithdraw is a free data retrieval call binding the contract method 0xdc697818.
//
// Solidity: function claimableWithdraw(address controller) view returns(uint256 claimableAssets)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) ClaimableWithdraw(opts *bind.CallOpts, controller common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "claimableWithdraw", controller)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ClaimableWithdraw is a free data retrieval call binding the contract method 0xdc697818.
//
// Solidity: function claimableWithdraw(address controller) view returns(uint256 claimableAssets)
func (_SuperVaultStrategy *SuperVaultStrategySession) ClaimableWithdraw(controller common.Address) (*big.Int, error) {
	return _SuperVaultStrategy.Contract.ClaimableWithdraw(&_SuperVaultStrategy.CallOpts, controller)
}

// ClaimableWithdraw is a free data retrieval call binding the contract method 0xdc697818.
//
// Solidity: function claimableWithdraw(address controller) view returns(uint256 claimableAssets)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) ClaimableWithdraw(controller common.Address) (*big.Int, error) {
	return _SuperVaultStrategy.Contract.ClaimableWithdraw(&_SuperVaultStrategy.CallOpts, controller)
}

// ContainsYieldSource is a free data retrieval call binding the contract method 0x63ee53de.
//
// Solidity: function containsYieldSource(address source) view returns(bool)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) ContainsYieldSource(opts *bind.CallOpts, source common.Address) (bool, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "containsYieldSource", source)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// ContainsYieldSource is a free data retrieval call binding the contract method 0x63ee53de.
//
// Solidity: function containsYieldSource(address source) view returns(bool)
func (_SuperVaultStrategy *SuperVaultStrategySession) ContainsYieldSource(source common.Address) (bool, error) {
	return _SuperVaultStrategy.Contract.ContainsYieldSource(&_SuperVaultStrategy.CallOpts, source)
}

// ContainsYieldSource is a free data retrieval call binding the contract method 0x63ee53de.
//
// Solidity: function containsYieldSource(address source) view returns(bool)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) ContainsYieldSource(source common.Address) (bool, error) {
	return _SuperVaultStrategy.Contract.ContainsYieldSource(&_SuperVaultStrategy.CallOpts, source)
}

// GetAverageWithdrawPrice is a free data retrieval call binding the contract method 0xcd773844.
//
// Solidity: function getAverageWithdrawPrice(address controller) view returns(uint256 averageWithdrawPrice)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) GetAverageWithdrawPrice(opts *bind.CallOpts, controller common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "getAverageWithdrawPrice", controller)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetAverageWithdrawPrice is a free data retrieval call binding the contract method 0xcd773844.
//
// Solidity: function getAverageWithdrawPrice(address controller) view returns(uint256 averageWithdrawPrice)
func (_SuperVaultStrategy *SuperVaultStrategySession) GetAverageWithdrawPrice(controller common.Address) (*big.Int, error) {
	return _SuperVaultStrategy.Contract.GetAverageWithdrawPrice(&_SuperVaultStrategy.CallOpts, controller)
}

// GetAverageWithdrawPrice is a free data retrieval call binding the contract method 0xcd773844.
//
// Solidity: function getAverageWithdrawPrice(address controller) view returns(uint256 averageWithdrawPrice)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) GetAverageWithdrawPrice(controller common.Address) (*big.Int, error) {
	return _SuperVaultStrategy.Contract.GetAverageWithdrawPrice(&_SuperVaultStrategy.CallOpts, controller)
}

// GetConfigInfo is a free data retrieval call binding the contract method 0x78a1bf05.
//
// Solidity: function getConfigInfo() view returns((uint256,uint256,address) feeConfig_)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) GetConfigInfo(opts *bind.CallOpts) (ISuperVaultStrategyFeeConfig, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "getConfigInfo")

	if err != nil {
		return *new(ISuperVaultStrategyFeeConfig), err
	}

	out0 := *abi.ConvertType(out[0], new(ISuperVaultStrategyFeeConfig)).(*ISuperVaultStrategyFeeConfig)

	return out0, err

}

// GetConfigInfo is a free data retrieval call binding the contract method 0x78a1bf05.
//
// Solidity: function getConfigInfo() view returns((uint256,uint256,address) feeConfig_)
func (_SuperVaultStrategy *SuperVaultStrategySession) GetConfigInfo() (ISuperVaultStrategyFeeConfig, error) {
	return _SuperVaultStrategy.Contract.GetConfigInfo(&_SuperVaultStrategy.CallOpts)
}

// GetConfigInfo is a free data retrieval call binding the contract method 0x78a1bf05.
//
// Solidity: function getConfigInfo() view returns((uint256,uint256,address) feeConfig_)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) GetConfigInfo() (ISuperVaultStrategyFeeConfig, error) {
	return _SuperVaultStrategy.Contract.GetConfigInfo(&_SuperVaultStrategy.CallOpts)
}

// GetStoredPPS is a free data retrieval call binding the contract method 0x2653517d.
//
// Solidity: function getStoredPPS() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) GetStoredPPS(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "getStoredPPS")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetStoredPPS is a free data retrieval call binding the contract method 0x2653517d.
//
// Solidity: function getStoredPPS() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategySession) GetStoredPPS() (*big.Int, error) {
	return _SuperVaultStrategy.Contract.GetStoredPPS(&_SuperVaultStrategy.CallOpts)
}

// GetStoredPPS is a free data retrieval call binding the contract method 0x2653517d.
//
// Solidity: function getStoredPPS() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) GetStoredPPS() (*big.Int, error) {
	return _SuperVaultStrategy.Contract.GetStoredPPS(&_SuperVaultStrategy.CallOpts)
}

// GetSuperVaultState is a free data retrieval call binding the contract method 0xd48c7bf9.
//
// Solidity: function getSuperVaultState(address controller) view returns((bool,uint256,uint256,uint256,uint256,uint256,uint16) state)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) GetSuperVaultState(opts *bind.CallOpts, controller common.Address) (ISuperVaultStrategySuperVaultState, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "getSuperVaultState", controller)

	if err != nil {
		return *new(ISuperVaultStrategySuperVaultState), err
	}

	out0 := *abi.ConvertType(out[0], new(ISuperVaultStrategySuperVaultState)).(*ISuperVaultStrategySuperVaultState)

	return out0, err

}

// GetSuperVaultState is a free data retrieval call binding the contract method 0xd48c7bf9.
//
// Solidity: function getSuperVaultState(address controller) view returns((bool,uint256,uint256,uint256,uint256,uint256,uint16) state)
func (_SuperVaultStrategy *SuperVaultStrategySession) GetSuperVaultState(controller common.Address) (ISuperVaultStrategySuperVaultState, error) {
	return _SuperVaultStrategy.Contract.GetSuperVaultState(&_SuperVaultStrategy.CallOpts, controller)
}

// GetSuperVaultState is a free data retrieval call binding the contract method 0xd48c7bf9.
//
// Solidity: function getSuperVaultState(address controller) view returns((bool,uint256,uint256,uint256,uint256,uint256,uint16) state)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) GetSuperVaultState(controller common.Address) (ISuperVaultStrategySuperVaultState, error) {
	return _SuperVaultStrategy.Contract.GetSuperVaultState(&_SuperVaultStrategy.CallOpts, controller)
}

// GetVaultInfo is a free data retrieval call binding the contract method 0x7f98aa71.
//
// Solidity: function getVaultInfo() view returns(address vault, address asset, uint8 vaultDecimals)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) GetVaultInfo(opts *bind.CallOpts) (struct {
	Vault         common.Address
	Asset         common.Address
	VaultDecimals uint8
}, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "getVaultInfo")

	outstruct := new(struct {
		Vault         common.Address
		Asset         common.Address
		VaultDecimals uint8
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Vault = *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	outstruct.Asset = *abi.ConvertType(out[1], new(common.Address)).(*common.Address)
	outstruct.VaultDecimals = *abi.ConvertType(out[2], new(uint8)).(*uint8)

	return *outstruct, err

}

// GetVaultInfo is a free data retrieval call binding the contract method 0x7f98aa71.
//
// Solidity: function getVaultInfo() view returns(address vault, address asset, uint8 vaultDecimals)
func (_SuperVaultStrategy *SuperVaultStrategySession) GetVaultInfo() (struct {
	Vault         common.Address
	Asset         common.Address
	VaultDecimals uint8
}, error) {
	return _SuperVaultStrategy.Contract.GetVaultInfo(&_SuperVaultStrategy.CallOpts)
}

// GetVaultInfo is a free data retrieval call binding the contract method 0x7f98aa71.
//
// Solidity: function getVaultInfo() view returns(address vault, address asset, uint8 vaultDecimals)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) GetVaultInfo() (struct {
	Vault         common.Address
	Asset         common.Address
	VaultDecimals uint8
}, error) {
	return _SuperVaultStrategy.Contract.GetVaultInfo(&_SuperVaultStrategy.CallOpts)
}

// GetYieldSource is a free data retrieval call binding the contract method 0x6bccefbd.
//
// Solidity: function getYieldSource(address source) view returns((address))
func (_SuperVaultStrategy *SuperVaultStrategyCaller) GetYieldSource(opts *bind.CallOpts, source common.Address) (ISuperVaultStrategyYieldSource, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "getYieldSource", source)

	if err != nil {
		return *new(ISuperVaultStrategyYieldSource), err
	}

	out0 := *abi.ConvertType(out[0], new(ISuperVaultStrategyYieldSource)).(*ISuperVaultStrategyYieldSource)

	return out0, err

}

// GetYieldSource is a free data retrieval call binding the contract method 0x6bccefbd.
//
// Solidity: function getYieldSource(address source) view returns((address))
func (_SuperVaultStrategy *SuperVaultStrategySession) GetYieldSource(source common.Address) (ISuperVaultStrategyYieldSource, error) {
	return _SuperVaultStrategy.Contract.GetYieldSource(&_SuperVaultStrategy.CallOpts, source)
}

// GetYieldSource is a free data retrieval call binding the contract method 0x6bccefbd.
//
// Solidity: function getYieldSource(address source) view returns((address))
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) GetYieldSource(source common.Address) (ISuperVaultStrategyYieldSource, error) {
	return _SuperVaultStrategy.Contract.GetYieldSource(&_SuperVaultStrategy.CallOpts, source)
}

// GetYieldSources is a free data retrieval call binding the contract method 0xc1249ab1.
//
// Solidity: function getYieldSources() view returns(address[])
func (_SuperVaultStrategy *SuperVaultStrategyCaller) GetYieldSources(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "getYieldSources")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetYieldSources is a free data retrieval call binding the contract method 0xc1249ab1.
//
// Solidity: function getYieldSources() view returns(address[])
func (_SuperVaultStrategy *SuperVaultStrategySession) GetYieldSources() ([]common.Address, error) {
	return _SuperVaultStrategy.Contract.GetYieldSources(&_SuperVaultStrategy.CallOpts)
}

// GetYieldSources is a free data retrieval call binding the contract method 0xc1249ab1.
//
// Solidity: function getYieldSources() view returns(address[])
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) GetYieldSources() ([]common.Address, error) {
	return _SuperVaultStrategy.Contract.GetYieldSources(&_SuperVaultStrategy.CallOpts)
}

// GetYieldSourcesCount is a free data retrieval call binding the contract method 0x70edf859.
//
// Solidity: function getYieldSourcesCount() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) GetYieldSourcesCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "getYieldSourcesCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetYieldSourcesCount is a free data retrieval call binding the contract method 0x70edf859.
//
// Solidity: function getYieldSourcesCount() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategySession) GetYieldSourcesCount() (*big.Int, error) {
	return _SuperVaultStrategy.Contract.GetYieldSourcesCount(&_SuperVaultStrategy.CallOpts)
}

// GetYieldSourcesCount is a free data retrieval call binding the contract method 0x70edf859.
//
// Solidity: function getYieldSourcesCount() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) GetYieldSourcesCount() (*big.Int, error) {
	return _SuperVaultStrategy.Contract.GetYieldSourcesCount(&_SuperVaultStrategy.CallOpts)
}

// GetYieldSourcesList is a free data retrieval call binding the contract method 0x7b26e709.
//
// Solidity: function getYieldSourcesList() view returns((address,address)[])
func (_SuperVaultStrategy *SuperVaultStrategyCaller) GetYieldSourcesList(opts *bind.CallOpts) ([]ISuperVaultStrategyYieldSourceInfo, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "getYieldSourcesList")

	if err != nil {
		return *new([]ISuperVaultStrategyYieldSourceInfo), err
	}

	out0 := *abi.ConvertType(out[0], new([]ISuperVaultStrategyYieldSourceInfo)).(*[]ISuperVaultStrategyYieldSourceInfo)

	return out0, err

}

// GetYieldSourcesList is a free data retrieval call binding the contract method 0x7b26e709.
//
// Solidity: function getYieldSourcesList() view returns((address,address)[])
func (_SuperVaultStrategy *SuperVaultStrategySession) GetYieldSourcesList() ([]ISuperVaultStrategyYieldSourceInfo, error) {
	return _SuperVaultStrategy.Contract.GetYieldSourcesList(&_SuperVaultStrategy.CallOpts)
}

// GetYieldSourcesList is a free data retrieval call binding the contract method 0x7b26e709.
//
// Solidity: function getYieldSourcesList() view returns((address,address)[])
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) GetYieldSourcesList() ([]ISuperVaultStrategyYieldSourceInfo, error) {
	return _SuperVaultStrategy.Contract.GetYieldSourcesList(&_SuperVaultStrategy.CallOpts)
}

// PendingCancelRedeemRequest is a free data retrieval call binding the contract method 0x74a2c606.
//
// Solidity: function pendingCancelRedeemRequest(address controller) view returns(bool)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) PendingCancelRedeemRequest(opts *bind.CallOpts, controller common.Address) (bool, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "pendingCancelRedeemRequest", controller)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// PendingCancelRedeemRequest is a free data retrieval call binding the contract method 0x74a2c606.
//
// Solidity: function pendingCancelRedeemRequest(address controller) view returns(bool)
func (_SuperVaultStrategy *SuperVaultStrategySession) PendingCancelRedeemRequest(controller common.Address) (bool, error) {
	return _SuperVaultStrategy.Contract.PendingCancelRedeemRequest(&_SuperVaultStrategy.CallOpts, controller)
}

// PendingCancelRedeemRequest is a free data retrieval call binding the contract method 0x74a2c606.
//
// Solidity: function pendingCancelRedeemRequest(address controller) view returns(bool)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) PendingCancelRedeemRequest(controller common.Address) (bool, error) {
	return _SuperVaultStrategy.Contract.PendingCancelRedeemRequest(&_SuperVaultStrategy.CallOpts, controller)
}

// PendingRedeemRequest is a free data retrieval call binding the contract method 0x53dc1dd3.
//
// Solidity: function pendingRedeemRequest(address controller) view returns(uint256 pendingShares)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) PendingRedeemRequest(opts *bind.CallOpts, controller common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "pendingRedeemRequest", controller)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PendingRedeemRequest is a free data retrieval call binding the contract method 0x53dc1dd3.
//
// Solidity: function pendingRedeemRequest(address controller) view returns(uint256 pendingShares)
func (_SuperVaultStrategy *SuperVaultStrategySession) PendingRedeemRequest(controller common.Address) (*big.Int, error) {
	return _SuperVaultStrategy.Contract.PendingRedeemRequest(&_SuperVaultStrategy.CallOpts, controller)
}

// PendingRedeemRequest is a free data retrieval call binding the contract method 0x53dc1dd3.
//
// Solidity: function pendingRedeemRequest(address controller) view returns(uint256 pendingShares)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) PendingRedeemRequest(controller common.Address) (*big.Int, error) {
	return _SuperVaultStrategy.Contract.PendingRedeemRequest(&_SuperVaultStrategy.CallOpts, controller)
}

// PpsExpiration is a free data retrieval call binding the contract method 0xf21a6c1f.
//
// Solidity: function ppsExpiration() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) PpsExpiration(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "ppsExpiration")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PpsExpiration is a free data retrieval call binding the contract method 0xf21a6c1f.
//
// Solidity: function ppsExpiration() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategySession) PpsExpiration() (*big.Int, error) {
	return _SuperVaultStrategy.Contract.PpsExpiration(&_SuperVaultStrategy.CallOpts)
}

// PpsExpiration is a free data retrieval call binding the contract method 0xf21a6c1f.
//
// Solidity: function ppsExpiration() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) PpsExpiration() (*big.Int, error) {
	return _SuperVaultStrategy.Contract.PpsExpiration(&_SuperVaultStrategy.CallOpts)
}

// PpsExpiryThresholdEffectiveTime is a free data retrieval call binding the contract method 0xac9a2dec.
//
// Solidity: function ppsExpiryThresholdEffectiveTime() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) PpsExpiryThresholdEffectiveTime(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "ppsExpiryThresholdEffectiveTime")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PpsExpiryThresholdEffectiveTime is a free data retrieval call binding the contract method 0xac9a2dec.
//
// Solidity: function ppsExpiryThresholdEffectiveTime() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategySession) PpsExpiryThresholdEffectiveTime() (*big.Int, error) {
	return _SuperVaultStrategy.Contract.PpsExpiryThresholdEffectiveTime(&_SuperVaultStrategy.CallOpts)
}

// PpsExpiryThresholdEffectiveTime is a free data retrieval call binding the contract method 0xac9a2dec.
//
// Solidity: function ppsExpiryThresholdEffectiveTime() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) PpsExpiryThresholdEffectiveTime() (*big.Int, error) {
	return _SuperVaultStrategy.Contract.PpsExpiryThresholdEffectiveTime(&_SuperVaultStrategy.CallOpts)
}

// PreviewExactRedeem is a free data retrieval call binding the contract method 0x590b0ec0.
//
// Solidity: function previewExactRedeem(address controller) view returns(uint256 shares, uint256 theoreticalAssets, uint256 minAssets)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) PreviewExactRedeem(opts *bind.CallOpts, controller common.Address) (struct {
	Shares            *big.Int
	TheoreticalAssets *big.Int
	MinAssets         *big.Int
}, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "previewExactRedeem", controller)

	outstruct := new(struct {
		Shares            *big.Int
		TheoreticalAssets *big.Int
		MinAssets         *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Shares = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.TheoreticalAssets = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.MinAssets = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// PreviewExactRedeem is a free data retrieval call binding the contract method 0x590b0ec0.
//
// Solidity: function previewExactRedeem(address controller) view returns(uint256 shares, uint256 theoreticalAssets, uint256 minAssets)
func (_SuperVaultStrategy *SuperVaultStrategySession) PreviewExactRedeem(controller common.Address) (struct {
	Shares            *big.Int
	TheoreticalAssets *big.Int
	MinAssets         *big.Int
}, error) {
	return _SuperVaultStrategy.Contract.PreviewExactRedeem(&_SuperVaultStrategy.CallOpts, controller)
}

// PreviewExactRedeem is a free data retrieval call binding the contract method 0x590b0ec0.
//
// Solidity: function previewExactRedeem(address controller) view returns(uint256 shares, uint256 theoreticalAssets, uint256 minAssets)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) PreviewExactRedeem(controller common.Address) (struct {
	Shares            *big.Int
	TheoreticalAssets *big.Int
	MinAssets         *big.Int
}, error) {
	return _SuperVaultStrategy.Contract.PreviewExactRedeem(&_SuperVaultStrategy.CallOpts, controller)
}

// PreviewExactRedeemBatch is a free data retrieval call binding the contract method 0x6f284b02.
//
// Solidity: function previewExactRedeemBatch(address[] controllers) view returns(uint256 totalTheoAssets, uint256[] individualAssets)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) PreviewExactRedeemBatch(opts *bind.CallOpts, controllers []common.Address) (struct {
	TotalTheoAssets  *big.Int
	IndividualAssets []*big.Int
}, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "previewExactRedeemBatch", controllers)

	outstruct := new(struct {
		TotalTheoAssets  *big.Int
		IndividualAssets []*big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.TotalTheoAssets = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.IndividualAssets = *abi.ConvertType(out[1], new([]*big.Int)).(*[]*big.Int)

	return *outstruct, err

}

// PreviewExactRedeemBatch is a free data retrieval call binding the contract method 0x6f284b02.
//
// Solidity: function previewExactRedeemBatch(address[] controllers) view returns(uint256 totalTheoAssets, uint256[] individualAssets)
func (_SuperVaultStrategy *SuperVaultStrategySession) PreviewExactRedeemBatch(controllers []common.Address) (struct {
	TotalTheoAssets  *big.Int
	IndividualAssets []*big.Int
}, error) {
	return _SuperVaultStrategy.Contract.PreviewExactRedeemBatch(&_SuperVaultStrategy.CallOpts, controllers)
}

// PreviewExactRedeemBatch is a free data retrieval call binding the contract method 0x6f284b02.
//
// Solidity: function previewExactRedeemBatch(address[] controllers) view returns(uint256 totalTheoAssets, uint256[] individualAssets)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) PreviewExactRedeemBatch(controllers []common.Address) (struct {
	TotalTheoAssets  *big.Int
	IndividualAssets []*big.Int
}, error) {
	return _SuperVaultStrategy.Contract.PreviewExactRedeemBatch(&_SuperVaultStrategy.CallOpts, controllers)
}

// ProposedPPSExpiryThreshold is a free data retrieval call binding the contract method 0x73bad05a.
//
// Solidity: function proposedPPSExpiryThreshold() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) ProposedPPSExpiryThreshold(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "proposedPPSExpiryThreshold")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ProposedPPSExpiryThreshold is a free data retrieval call binding the contract method 0x73bad05a.
//
// Solidity: function proposedPPSExpiryThreshold() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategySession) ProposedPPSExpiryThreshold() (*big.Int, error) {
	return _SuperVaultStrategy.Contract.ProposedPPSExpiryThreshold(&_SuperVaultStrategy.CallOpts)
}

// ProposedPPSExpiryThreshold is a free data retrieval call binding the contract method 0x73bad05a.
//
// Solidity: function proposedPPSExpiryThreshold() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) ProposedPPSExpiryThreshold() (*big.Int, error) {
	return _SuperVaultStrategy.Contract.ProposedPPSExpiryThreshold(&_SuperVaultStrategy.CallOpts)
}

// QuoteMintAssetsGross is a free data retrieval call binding the contract method 0x49de7afb.
//
// Solidity: function quoteMintAssetsGross(uint256 shares) view returns(uint256 assetsGross, uint256 assetsNet)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) QuoteMintAssetsGross(opts *bind.CallOpts, shares *big.Int) (struct {
	AssetsGross *big.Int
	AssetsNet   *big.Int
}, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "quoteMintAssetsGross", shares)

	outstruct := new(struct {
		AssetsGross *big.Int
		AssetsNet   *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.AssetsGross = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.AssetsNet = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// QuoteMintAssetsGross is a free data retrieval call binding the contract method 0x49de7afb.
//
// Solidity: function quoteMintAssetsGross(uint256 shares) view returns(uint256 assetsGross, uint256 assetsNet)
func (_SuperVaultStrategy *SuperVaultStrategySession) QuoteMintAssetsGross(shares *big.Int) (struct {
	AssetsGross *big.Int
	AssetsNet   *big.Int
}, error) {
	return _SuperVaultStrategy.Contract.QuoteMintAssetsGross(&_SuperVaultStrategy.CallOpts, shares)
}

// QuoteMintAssetsGross is a free data retrieval call binding the contract method 0x49de7afb.
//
// Solidity: function quoteMintAssetsGross(uint256 shares) view returns(uint256 assetsGross, uint256 assetsNet)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) QuoteMintAssetsGross(shares *big.Int) (struct {
	AssetsGross *big.Int
	AssetsNet   *big.Int
}, error) {
	return _SuperVaultStrategy.Contract.QuoteMintAssetsGross(&_SuperVaultStrategy.CallOpts, shares)
}

// VaultHwmPps is a free data retrieval call binding the contract method 0x910c60ad.
//
// Solidity: function vaultHwmPps() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) VaultHwmPps(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "vaultHwmPps")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// VaultHwmPps is a free data retrieval call binding the contract method 0x910c60ad.
//
// Solidity: function vaultHwmPps() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategySession) VaultHwmPps() (*big.Int, error) {
	return _SuperVaultStrategy.Contract.VaultHwmPps(&_SuperVaultStrategy.CallOpts)
}

// VaultHwmPps is a free data retrieval call binding the contract method 0x910c60ad.
//
// Solidity: function vaultHwmPps() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) VaultHwmPps() (*big.Int, error) {
	return _SuperVaultStrategy.Contract.VaultHwmPps(&_SuperVaultStrategy.CallOpts)
}

// VaultUnrealizedProfit is a free data retrieval call binding the contract method 0xaecf997e.
//
// Solidity: function vaultUnrealizedProfit() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategyCaller) VaultUnrealizedProfit(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultStrategy.contract.Call(opts, &out, "vaultUnrealizedProfit")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// VaultUnrealizedProfit is a free data retrieval call binding the contract method 0xaecf997e.
//
// Solidity: function vaultUnrealizedProfit() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategySession) VaultUnrealizedProfit() (*big.Int, error) {
	return _SuperVaultStrategy.Contract.VaultUnrealizedProfit(&_SuperVaultStrategy.CallOpts)
}

// VaultUnrealizedProfit is a free data retrieval call binding the contract method 0xaecf997e.
//
// Solidity: function vaultUnrealizedProfit() view returns(uint256)
func (_SuperVaultStrategy *SuperVaultStrategyCallerSession) VaultUnrealizedProfit() (*big.Int, error) {
	return _SuperVaultStrategy.Contract.VaultUnrealizedProfit(&_SuperVaultStrategy.CallOpts)
}

// ChangeFeeRecipient is a paid mutator transaction binding the contract method 0x23604071.
//
// Solidity: function changeFeeRecipient(address newRecipient) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactor) ChangeFeeRecipient(opts *bind.TransactOpts, newRecipient common.Address) (*types.Transaction, error) {
	return _SuperVaultStrategy.contract.Transact(opts, "changeFeeRecipient", newRecipient)
}

// ChangeFeeRecipient is a paid mutator transaction binding the contract method 0x23604071.
//
// Solidity: function changeFeeRecipient(address newRecipient) returns()
func (_SuperVaultStrategy *SuperVaultStrategySession) ChangeFeeRecipient(newRecipient common.Address) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.ChangeFeeRecipient(&_SuperVaultStrategy.TransactOpts, newRecipient)
}

// ChangeFeeRecipient is a paid mutator transaction binding the contract method 0x23604071.
//
// Solidity: function changeFeeRecipient(address newRecipient) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactorSession) ChangeFeeRecipient(newRecipient common.Address) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.ChangeFeeRecipient(&_SuperVaultStrategy.TransactOpts, newRecipient)
}

// ExecuteHooks is a paid mutator transaction binding the contract method 0x2f82b89a.
//
// Solidity: function executeHooks((address[],bytes[],uint256[],bytes32[][],bytes32[][]) args) payable returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactor) ExecuteHooks(opts *bind.TransactOpts, args ISuperVaultStrategyExecuteArgs) (*types.Transaction, error) {
	return _SuperVaultStrategy.contract.Transact(opts, "executeHooks", args)
}

// ExecuteHooks is a paid mutator transaction binding the contract method 0x2f82b89a.
//
// Solidity: function executeHooks((address[],bytes[],uint256[],bytes32[][],bytes32[][]) args) payable returns()
func (_SuperVaultStrategy *SuperVaultStrategySession) ExecuteHooks(args ISuperVaultStrategyExecuteArgs) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.ExecuteHooks(&_SuperVaultStrategy.TransactOpts, args)
}

// ExecuteHooks is a paid mutator transaction binding the contract method 0x2f82b89a.
//
// Solidity: function executeHooks((address[],bytes[],uint256[],bytes32[][],bytes32[][]) args) payable returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactorSession) ExecuteHooks(args ISuperVaultStrategyExecuteArgs) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.ExecuteHooks(&_SuperVaultStrategy.TransactOpts, args)
}

// ExecuteVaultFeeConfigUpdate is a paid mutator transaction binding the contract method 0x1aa7d751.
//
// Solidity: function executeVaultFeeConfigUpdate() returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactor) ExecuteVaultFeeConfigUpdate(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultStrategy.contract.Transact(opts, "executeVaultFeeConfigUpdate")
}

// ExecuteVaultFeeConfigUpdate is a paid mutator transaction binding the contract method 0x1aa7d751.
//
// Solidity: function executeVaultFeeConfigUpdate() returns()
func (_SuperVaultStrategy *SuperVaultStrategySession) ExecuteVaultFeeConfigUpdate() (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.ExecuteVaultFeeConfigUpdate(&_SuperVaultStrategy.TransactOpts)
}

// ExecuteVaultFeeConfigUpdate is a paid mutator transaction binding the contract method 0x1aa7d751.
//
// Solidity: function executeVaultFeeConfigUpdate() returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactorSession) ExecuteVaultFeeConfigUpdate() (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.ExecuteVaultFeeConfigUpdate(&_SuperVaultStrategy.TransactOpts)
}

// FulfillCancelRedeemRequests is a paid mutator transaction binding the contract method 0x5523cd2d.
//
// Solidity: function fulfillCancelRedeemRequests(address[] controllers) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactor) FulfillCancelRedeemRequests(opts *bind.TransactOpts, controllers []common.Address) (*types.Transaction, error) {
	return _SuperVaultStrategy.contract.Transact(opts, "fulfillCancelRedeemRequests", controllers)
}

// FulfillCancelRedeemRequests is a paid mutator transaction binding the contract method 0x5523cd2d.
//
// Solidity: function fulfillCancelRedeemRequests(address[] controllers) returns()
func (_SuperVaultStrategy *SuperVaultStrategySession) FulfillCancelRedeemRequests(controllers []common.Address) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.FulfillCancelRedeemRequests(&_SuperVaultStrategy.TransactOpts, controllers)
}

// FulfillCancelRedeemRequests is a paid mutator transaction binding the contract method 0x5523cd2d.
//
// Solidity: function fulfillCancelRedeemRequests(address[] controllers) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactorSession) FulfillCancelRedeemRequests(controllers []common.Address) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.FulfillCancelRedeemRequests(&_SuperVaultStrategy.TransactOpts, controllers)
}

// FulfillRedeemRequests is a paid mutator transaction binding the contract method 0x48785dc3.
//
// Solidity: function fulfillRedeemRequests(address[] controllers, uint256[] totalAssetsOut) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactor) FulfillRedeemRequests(opts *bind.TransactOpts, controllers []common.Address, totalAssetsOut []*big.Int) (*types.Transaction, error) {
	return _SuperVaultStrategy.contract.Transact(opts, "fulfillRedeemRequests", controllers, totalAssetsOut)
}

// FulfillRedeemRequests is a paid mutator transaction binding the contract method 0x48785dc3.
//
// Solidity: function fulfillRedeemRequests(address[] controllers, uint256[] totalAssetsOut) returns()
func (_SuperVaultStrategy *SuperVaultStrategySession) FulfillRedeemRequests(controllers []common.Address, totalAssetsOut []*big.Int) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.FulfillRedeemRequests(&_SuperVaultStrategy.TransactOpts, controllers, totalAssetsOut)
}

// FulfillRedeemRequests is a paid mutator transaction binding the contract method 0x48785dc3.
//
// Solidity: function fulfillRedeemRequests(address[] controllers, uint256[] totalAssetsOut) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactorSession) FulfillRedeemRequests(controllers []common.Address, totalAssetsOut []*big.Int) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.FulfillRedeemRequests(&_SuperVaultStrategy.TransactOpts, controllers, totalAssetsOut)
}

// HandleOperations4626Deposit is a paid mutator transaction binding the contract method 0x1744700a.
//
// Solidity: function handleOperations4626Deposit(address controller, uint256 assetsGross) returns(uint256 sharesNet)
func (_SuperVaultStrategy *SuperVaultStrategyTransactor) HandleOperations4626Deposit(opts *bind.TransactOpts, controller common.Address, assetsGross *big.Int) (*types.Transaction, error) {
	return _SuperVaultStrategy.contract.Transact(opts, "handleOperations4626Deposit", controller, assetsGross)
}

// HandleOperations4626Deposit is a paid mutator transaction binding the contract method 0x1744700a.
//
// Solidity: function handleOperations4626Deposit(address controller, uint256 assetsGross) returns(uint256 sharesNet)
func (_SuperVaultStrategy *SuperVaultStrategySession) HandleOperations4626Deposit(controller common.Address, assetsGross *big.Int) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.HandleOperations4626Deposit(&_SuperVaultStrategy.TransactOpts, controller, assetsGross)
}

// HandleOperations4626Deposit is a paid mutator transaction binding the contract method 0x1744700a.
//
// Solidity: function handleOperations4626Deposit(address controller, uint256 assetsGross) returns(uint256 sharesNet)
func (_SuperVaultStrategy *SuperVaultStrategyTransactorSession) HandleOperations4626Deposit(controller common.Address, assetsGross *big.Int) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.HandleOperations4626Deposit(&_SuperVaultStrategy.TransactOpts, controller, assetsGross)
}

// HandleOperations4626Mint is a paid mutator transaction binding the contract method 0xe7a5befa.
//
// Solidity: function handleOperations4626Mint(address controller, uint256 sharesNet, uint256 assetsGross, uint256 assetsNet) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactor) HandleOperations4626Mint(opts *bind.TransactOpts, controller common.Address, sharesNet *big.Int, assetsGross *big.Int, assetsNet *big.Int) (*types.Transaction, error) {
	return _SuperVaultStrategy.contract.Transact(opts, "handleOperations4626Mint", controller, sharesNet, assetsGross, assetsNet)
}

// HandleOperations4626Mint is a paid mutator transaction binding the contract method 0xe7a5befa.
//
// Solidity: function handleOperations4626Mint(address controller, uint256 sharesNet, uint256 assetsGross, uint256 assetsNet) returns()
func (_SuperVaultStrategy *SuperVaultStrategySession) HandleOperations4626Mint(controller common.Address, sharesNet *big.Int, assetsGross *big.Int, assetsNet *big.Int) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.HandleOperations4626Mint(&_SuperVaultStrategy.TransactOpts, controller, sharesNet, assetsGross, assetsNet)
}

// HandleOperations4626Mint is a paid mutator transaction binding the contract method 0xe7a5befa.
//
// Solidity: function handleOperations4626Mint(address controller, uint256 sharesNet, uint256 assetsGross, uint256 assetsNet) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactorSession) HandleOperations4626Mint(controller common.Address, sharesNet *big.Int, assetsGross *big.Int, assetsNet *big.Int) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.HandleOperations4626Mint(&_SuperVaultStrategy.TransactOpts, controller, sharesNet, assetsGross, assetsNet)
}

// HandleOperations7540 is a paid mutator transaction binding the contract method 0x90b386ef.
//
// Solidity: function handleOperations7540(uint8 operation, address controller, address receiver, uint256 amount) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactor) HandleOperations7540(opts *bind.TransactOpts, operation uint8, controller common.Address, receiver common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultStrategy.contract.Transact(opts, "handleOperations7540", operation, controller, receiver, amount)
}

// HandleOperations7540 is a paid mutator transaction binding the contract method 0x90b386ef.
//
// Solidity: function handleOperations7540(uint8 operation, address controller, address receiver, uint256 amount) returns()
func (_SuperVaultStrategy *SuperVaultStrategySession) HandleOperations7540(operation uint8, controller common.Address, receiver common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.HandleOperations7540(&_SuperVaultStrategy.TransactOpts, operation, controller, receiver, amount)
}

// HandleOperations7540 is a paid mutator transaction binding the contract method 0x90b386ef.
//
// Solidity: function handleOperations7540(uint8 operation, address controller, address receiver, uint256 amount) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactorSession) HandleOperations7540(operation uint8, controller common.Address, receiver common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.HandleOperations7540(&_SuperVaultStrategy.TransactOpts, operation, controller, receiver, amount)
}

// Initialize is a paid mutator transaction binding the contract method 0xc9dd181e.
//
// Solidity: function initialize(address vaultAddress, (uint256,uint256,address) feeConfigData) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactor) Initialize(opts *bind.TransactOpts, vaultAddress common.Address, feeConfigData ISuperVaultStrategyFeeConfig) (*types.Transaction, error) {
	return _SuperVaultStrategy.contract.Transact(opts, "initialize", vaultAddress, feeConfigData)
}

// Initialize is a paid mutator transaction binding the contract method 0xc9dd181e.
//
// Solidity: function initialize(address vaultAddress, (uint256,uint256,address) feeConfigData) returns()
func (_SuperVaultStrategy *SuperVaultStrategySession) Initialize(vaultAddress common.Address, feeConfigData ISuperVaultStrategyFeeConfig) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.Initialize(&_SuperVaultStrategy.TransactOpts, vaultAddress, feeConfigData)
}

// Initialize is a paid mutator transaction binding the contract method 0xc9dd181e.
//
// Solidity: function initialize(address vaultAddress, (uint256,uint256,address) feeConfigData) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactorSession) Initialize(vaultAddress common.Address, feeConfigData ISuperVaultStrategyFeeConfig) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.Initialize(&_SuperVaultStrategy.TransactOpts, vaultAddress, feeConfigData)
}

// ManagePPSExpiration is a paid mutator transaction binding the contract method 0x596c0385.
//
// Solidity: function managePPSExpiration(uint8 action, uint256 staleness_) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactor) ManagePPSExpiration(opts *bind.TransactOpts, action uint8, staleness_ *big.Int) (*types.Transaction, error) {
	return _SuperVaultStrategy.contract.Transact(opts, "managePPSExpiration", action, staleness_)
}

// ManagePPSExpiration is a paid mutator transaction binding the contract method 0x596c0385.
//
// Solidity: function managePPSExpiration(uint8 action, uint256 staleness_) returns()
func (_SuperVaultStrategy *SuperVaultStrategySession) ManagePPSExpiration(action uint8, staleness_ *big.Int) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.ManagePPSExpiration(&_SuperVaultStrategy.TransactOpts, action, staleness_)
}

// ManagePPSExpiration is a paid mutator transaction binding the contract method 0x596c0385.
//
// Solidity: function managePPSExpiration(uint8 action, uint256 staleness_) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactorSession) ManagePPSExpiration(action uint8, staleness_ *big.Int) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.ManagePPSExpiration(&_SuperVaultStrategy.TransactOpts, action, staleness_)
}

// ManageYieldSource is a paid mutator transaction binding the contract method 0x4da6172a.
//
// Solidity: function manageYieldSource(address source, address oracle, uint8 actionType) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactor) ManageYieldSource(opts *bind.TransactOpts, source common.Address, oracle common.Address, actionType uint8) (*types.Transaction, error) {
	return _SuperVaultStrategy.contract.Transact(opts, "manageYieldSource", source, oracle, actionType)
}

// ManageYieldSource is a paid mutator transaction binding the contract method 0x4da6172a.
//
// Solidity: function manageYieldSource(address source, address oracle, uint8 actionType) returns()
func (_SuperVaultStrategy *SuperVaultStrategySession) ManageYieldSource(source common.Address, oracle common.Address, actionType uint8) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.ManageYieldSource(&_SuperVaultStrategy.TransactOpts, source, oracle, actionType)
}

// ManageYieldSource is a paid mutator transaction binding the contract method 0x4da6172a.
//
// Solidity: function manageYieldSource(address source, address oracle, uint8 actionType) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactorSession) ManageYieldSource(source common.Address, oracle common.Address, actionType uint8) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.ManageYieldSource(&_SuperVaultStrategy.TransactOpts, source, oracle, actionType)
}

// ManageYieldSources is a paid mutator transaction binding the contract method 0x1eaed011.
//
// Solidity: function manageYieldSources(address[] sources, address[] oracles, uint8[] actionTypes) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactor) ManageYieldSources(opts *bind.TransactOpts, sources []common.Address, oracles []common.Address, actionTypes []uint8) (*types.Transaction, error) {
	return _SuperVaultStrategy.contract.Transact(opts, "manageYieldSources", sources, oracles, actionTypes)
}

// ManageYieldSources is a paid mutator transaction binding the contract method 0x1eaed011.
//
// Solidity: function manageYieldSources(address[] sources, address[] oracles, uint8[] actionTypes) returns()
func (_SuperVaultStrategy *SuperVaultStrategySession) ManageYieldSources(sources []common.Address, oracles []common.Address, actionTypes []uint8) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.ManageYieldSources(&_SuperVaultStrategy.TransactOpts, sources, oracles, actionTypes)
}

// ManageYieldSources is a paid mutator transaction binding the contract method 0x1eaed011.
//
// Solidity: function manageYieldSources(address[] sources, address[] oracles, uint8[] actionTypes) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactorSession) ManageYieldSources(sources []common.Address, oracles []common.Address, actionTypes []uint8) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.ManageYieldSources(&_SuperVaultStrategy.TransactOpts, sources, oracles, actionTypes)
}

// ProposeVaultFeeConfigUpdate is a paid mutator transaction binding the contract method 0xd324e15b.
//
// Solidity: function proposeVaultFeeConfigUpdate(uint256 performanceFeeBps, uint256 managementFeeBps, address recipient) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactor) ProposeVaultFeeConfigUpdate(opts *bind.TransactOpts, performanceFeeBps *big.Int, managementFeeBps *big.Int, recipient common.Address) (*types.Transaction, error) {
	return _SuperVaultStrategy.contract.Transact(opts, "proposeVaultFeeConfigUpdate", performanceFeeBps, managementFeeBps, recipient)
}

// ProposeVaultFeeConfigUpdate is a paid mutator transaction binding the contract method 0xd324e15b.
//
// Solidity: function proposeVaultFeeConfigUpdate(uint256 performanceFeeBps, uint256 managementFeeBps, address recipient) returns()
func (_SuperVaultStrategy *SuperVaultStrategySession) ProposeVaultFeeConfigUpdate(performanceFeeBps *big.Int, managementFeeBps *big.Int, recipient common.Address) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.ProposeVaultFeeConfigUpdate(&_SuperVaultStrategy.TransactOpts, performanceFeeBps, managementFeeBps, recipient)
}

// ProposeVaultFeeConfigUpdate is a paid mutator transaction binding the contract method 0xd324e15b.
//
// Solidity: function proposeVaultFeeConfigUpdate(uint256 performanceFeeBps, uint256 managementFeeBps, address recipient) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactorSession) ProposeVaultFeeConfigUpdate(performanceFeeBps *big.Int, managementFeeBps *big.Int, recipient common.Address) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.ProposeVaultFeeConfigUpdate(&_SuperVaultStrategy.TransactOpts, performanceFeeBps, managementFeeBps, recipient)
}

// ResetHighWaterMark is a paid mutator transaction binding the contract method 0x200a32e8.
//
// Solidity: function resetHighWaterMark(uint256 newHwmPps) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactor) ResetHighWaterMark(opts *bind.TransactOpts, newHwmPps *big.Int) (*types.Transaction, error) {
	return _SuperVaultStrategy.contract.Transact(opts, "resetHighWaterMark", newHwmPps)
}

// ResetHighWaterMark is a paid mutator transaction binding the contract method 0x200a32e8.
//
// Solidity: function resetHighWaterMark(uint256 newHwmPps) returns()
func (_SuperVaultStrategy *SuperVaultStrategySession) ResetHighWaterMark(newHwmPps *big.Int) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.ResetHighWaterMark(&_SuperVaultStrategy.TransactOpts, newHwmPps)
}

// ResetHighWaterMark is a paid mutator transaction binding the contract method 0x200a32e8.
//
// Solidity: function resetHighWaterMark(uint256 newHwmPps) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactorSession) ResetHighWaterMark(newHwmPps *big.Int) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.ResetHighWaterMark(&_SuperVaultStrategy.TransactOpts, newHwmPps)
}

// SetRedeemSlippage is a paid mutator transaction binding the contract method 0xde650059.
//
// Solidity: function setRedeemSlippage(uint16 slippageBps) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactor) SetRedeemSlippage(opts *bind.TransactOpts, slippageBps uint16) (*types.Transaction, error) {
	return _SuperVaultStrategy.contract.Transact(opts, "setRedeemSlippage", slippageBps)
}

// SetRedeemSlippage is a paid mutator transaction binding the contract method 0xde650059.
//
// Solidity: function setRedeemSlippage(uint16 slippageBps) returns()
func (_SuperVaultStrategy *SuperVaultStrategySession) SetRedeemSlippage(slippageBps uint16) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.SetRedeemSlippage(&_SuperVaultStrategy.TransactOpts, slippageBps)
}

// SetRedeemSlippage is a paid mutator transaction binding the contract method 0xde650059.
//
// Solidity: function setRedeemSlippage(uint16 slippageBps) returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactorSession) SetRedeemSlippage(slippageBps uint16) (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.SetRedeemSlippage(&_SuperVaultStrategy.TransactOpts, slippageBps)
}

// SkimPerformanceFee is a paid mutator transaction binding the contract method 0x772ecfb7.
//
// Solidity: function skimPerformanceFee() returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactor) SkimPerformanceFee(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultStrategy.contract.Transact(opts, "skimPerformanceFee")
}

// SkimPerformanceFee is a paid mutator transaction binding the contract method 0x772ecfb7.
//
// Solidity: function skimPerformanceFee() returns()
func (_SuperVaultStrategy *SuperVaultStrategySession) SkimPerformanceFee() (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.SkimPerformanceFee(&_SuperVaultStrategy.TransactOpts)
}

// SkimPerformanceFee is a paid mutator transaction binding the contract method 0x772ecfb7.
//
// Solidity: function skimPerformanceFee() returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactorSession) SkimPerformanceFee() (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.SkimPerformanceFee(&_SuperVaultStrategy.TransactOpts)
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactor) Receive(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultStrategy.contract.RawTransact(opts, nil) // calldata is disallowed for receive function
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_SuperVaultStrategy *SuperVaultStrategySession) Receive() (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.Receive(&_SuperVaultStrategy.TransactOpts)
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_SuperVaultStrategy *SuperVaultStrategyTransactorSession) Receive() (*types.Transaction, error) {
	return _SuperVaultStrategy.Contract.Receive(&_SuperVaultStrategy.TransactOpts)
}

// SuperVaultStrategyDepositHandledIterator is returned from FilterDepositHandled and is used to iterate over the raw logs and unpacked data for DepositHandled events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyDepositHandledIterator struct {
	Event *SuperVaultStrategyDepositHandled // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyDepositHandledIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyDepositHandled)
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
		it.Event = new(SuperVaultStrategyDepositHandled)
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
func (it *SuperVaultStrategyDepositHandledIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyDepositHandledIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyDepositHandled represents a DepositHandled event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyDepositHandled struct {
	Controller common.Address
	Assets     *big.Int
	Shares     *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterDepositHandled is a free log retrieval operation binding the contract event 0xa7a45ea372219103bc7d0bb545ac15937334185abf185241b18414600ed19110.
//
// Solidity: event DepositHandled(address indexed controller, uint256 assets, uint256 shares)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterDepositHandled(opts *bind.FilterOpts, controller []common.Address) (*SuperVaultStrategyDepositHandledIterator, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "DepositHandled", controllerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyDepositHandledIterator{contract: _SuperVaultStrategy.contract, event: "DepositHandled", logs: logs, sub: sub}, nil
}

// WatchDepositHandled is a free log subscription operation binding the contract event 0xa7a45ea372219103bc7d0bb545ac15937334185abf185241b18414600ed19110.
//
// Solidity: event DepositHandled(address indexed controller, uint256 assets, uint256 shares)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchDepositHandled(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyDepositHandled, controller []common.Address) (event.Subscription, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "DepositHandled", controllerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyDepositHandled)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "DepositHandled", log); err != nil {
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

// ParseDepositHandled is a log parse operation binding the contract event 0xa7a45ea372219103bc7d0bb545ac15937334185abf185241b18414600ed19110.
//
// Solidity: event DepositHandled(address indexed controller, uint256 assets, uint256 shares)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseDepositHandled(log types.Log) (*SuperVaultStrategyDepositHandled, error) {
	event := new(SuperVaultStrategyDepositHandled)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "DepositHandled", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyFeeRecipientChangedIterator is returned from FilterFeeRecipientChanged and is used to iterate over the raw logs and unpacked data for FeeRecipientChanged events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyFeeRecipientChangedIterator struct {
	Event *SuperVaultStrategyFeeRecipientChanged // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyFeeRecipientChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyFeeRecipientChanged)
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
		it.Event = new(SuperVaultStrategyFeeRecipientChanged)
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
func (it *SuperVaultStrategyFeeRecipientChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyFeeRecipientChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyFeeRecipientChanged represents a FeeRecipientChanged event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyFeeRecipientChanged struct {
	NewRecipient common.Address
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterFeeRecipientChanged is a free log retrieval operation binding the contract event 0x167cccccc6e9b2892a740ec13fc1e51d3de8ea384f25bd87fee7412d588637e2.
//
// Solidity: event FeeRecipientChanged(address indexed newRecipient)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterFeeRecipientChanged(opts *bind.FilterOpts, newRecipient []common.Address) (*SuperVaultStrategyFeeRecipientChangedIterator, error) {

	var newRecipientRule []interface{}
	for _, newRecipientItem := range newRecipient {
		newRecipientRule = append(newRecipientRule, newRecipientItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "FeeRecipientChanged", newRecipientRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyFeeRecipientChangedIterator{contract: _SuperVaultStrategy.contract, event: "FeeRecipientChanged", logs: logs, sub: sub}, nil
}

// WatchFeeRecipientChanged is a free log subscription operation binding the contract event 0x167cccccc6e9b2892a740ec13fc1e51d3de8ea384f25bd87fee7412d588637e2.
//
// Solidity: event FeeRecipientChanged(address indexed newRecipient)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchFeeRecipientChanged(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyFeeRecipientChanged, newRecipient []common.Address) (event.Subscription, error) {

	var newRecipientRule []interface{}
	for _, newRecipientItem := range newRecipient {
		newRecipientRule = append(newRecipientRule, newRecipientItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "FeeRecipientChanged", newRecipientRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyFeeRecipientChanged)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "FeeRecipientChanged", log); err != nil {
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

// ParseFeeRecipientChanged is a log parse operation binding the contract event 0x167cccccc6e9b2892a740ec13fc1e51d3de8ea384f25bd87fee7412d588637e2.
//
// Solidity: event FeeRecipientChanged(address indexed newRecipient)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseFeeRecipientChanged(log types.Log) (*SuperVaultStrategyFeeRecipientChanged, error) {
	event := new(SuperVaultStrategyFeeRecipientChanged)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "FeeRecipientChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyHWMPPSUpdatedIterator is returned from FilterHWMPPSUpdated and is used to iterate over the raw logs and unpacked data for HWMPPSUpdated events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyHWMPPSUpdatedIterator struct {
	Event *SuperVaultStrategyHWMPPSUpdated // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyHWMPPSUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyHWMPPSUpdated)
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
		it.Event = new(SuperVaultStrategyHWMPPSUpdated)
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
func (it *SuperVaultStrategyHWMPPSUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyHWMPPSUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyHWMPPSUpdated represents a HWMPPSUpdated event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyHWMPPSUpdated struct {
	NewHwmPps    *big.Int
	PreviousPps  *big.Int
	Profit       *big.Int
	FeeCollected *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterHWMPPSUpdated is a free log retrieval operation binding the contract event 0x5c354a35306fdb3f7732fe5164798488004f201adfcf00a618ee1a28c0c0be32.
//
// Solidity: event HWMPPSUpdated(uint256 newHwmPps, uint256 previousPps, uint256 profit, uint256 feeCollected)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterHWMPPSUpdated(opts *bind.FilterOpts) (*SuperVaultStrategyHWMPPSUpdatedIterator, error) {

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "HWMPPSUpdated")
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyHWMPPSUpdatedIterator{contract: _SuperVaultStrategy.contract, event: "HWMPPSUpdated", logs: logs, sub: sub}, nil
}

// WatchHWMPPSUpdated is a free log subscription operation binding the contract event 0x5c354a35306fdb3f7732fe5164798488004f201adfcf00a618ee1a28c0c0be32.
//
// Solidity: event HWMPPSUpdated(uint256 newHwmPps, uint256 previousPps, uint256 profit, uint256 feeCollected)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchHWMPPSUpdated(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyHWMPPSUpdated) (event.Subscription, error) {

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "HWMPPSUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyHWMPPSUpdated)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "HWMPPSUpdated", log); err != nil {
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

// ParseHWMPPSUpdated is a log parse operation binding the contract event 0x5c354a35306fdb3f7732fe5164798488004f201adfcf00a618ee1a28c0c0be32.
//
// Solidity: event HWMPPSUpdated(uint256 newHwmPps, uint256 previousPps, uint256 profit, uint256 feeCollected)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseHWMPPSUpdated(log types.Log) (*SuperVaultStrategyHWMPPSUpdated, error) {
	event := new(SuperVaultStrategyHWMPPSUpdated)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "HWMPPSUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyHighWaterMarkResetIterator is returned from FilterHighWaterMarkReset and is used to iterate over the raw logs and unpacked data for HighWaterMarkReset events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyHighWaterMarkResetIterator struct {
	Event *SuperVaultStrategyHighWaterMarkReset // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyHighWaterMarkResetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyHighWaterMarkReset)
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
		it.Event = new(SuperVaultStrategyHighWaterMarkReset)
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
func (it *SuperVaultStrategyHighWaterMarkResetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyHighWaterMarkResetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyHighWaterMarkReset represents a HighWaterMarkReset event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyHighWaterMarkReset struct {
	NewHwmPps *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterHighWaterMarkReset is a free log retrieval operation binding the contract event 0x0ba86a52ff5ffcf20e6829c8de5df77f7927366e7c94b787a99e29bdce00be70.
//
// Solidity: event HighWaterMarkReset(uint256 newHwmPps)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterHighWaterMarkReset(opts *bind.FilterOpts) (*SuperVaultStrategyHighWaterMarkResetIterator, error) {

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "HighWaterMarkReset")
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyHighWaterMarkResetIterator{contract: _SuperVaultStrategy.contract, event: "HighWaterMarkReset", logs: logs, sub: sub}, nil
}

// WatchHighWaterMarkReset is a free log subscription operation binding the contract event 0x0ba86a52ff5ffcf20e6829c8de5df77f7927366e7c94b787a99e29bdce00be70.
//
// Solidity: event HighWaterMarkReset(uint256 newHwmPps)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchHighWaterMarkReset(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyHighWaterMarkReset) (event.Subscription, error) {

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "HighWaterMarkReset")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyHighWaterMarkReset)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "HighWaterMarkReset", log); err != nil {
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

// ParseHighWaterMarkReset is a log parse operation binding the contract event 0x0ba86a52ff5ffcf20e6829c8de5df77f7927366e7c94b787a99e29bdce00be70.
//
// Solidity: event HighWaterMarkReset(uint256 newHwmPps)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseHighWaterMarkReset(log types.Log) (*SuperVaultStrategyHighWaterMarkReset, error) {
	event := new(SuperVaultStrategyHighWaterMarkReset)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "HighWaterMarkReset", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyHookExecutedIterator is returned from FilterHookExecuted and is used to iterate over the raw logs and unpacked data for HookExecuted events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyHookExecutedIterator struct {
	Event *SuperVaultStrategyHookExecuted // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyHookExecutedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyHookExecuted)
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
		it.Event = new(SuperVaultStrategyHookExecuted)
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
func (it *SuperVaultStrategyHookExecutedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyHookExecutedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyHookExecuted represents a HookExecuted event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyHookExecuted struct {
	Hook                common.Address
	PrevHook            common.Address
	TargetedYieldSource common.Address
	UsePrevHookAmount   bool
	HookCalldata        []byte
	Raw                 types.Log // Blockchain specific contextual infos
}

// FilterHookExecuted is a free log retrieval operation binding the contract event 0xedec66be61a678e975773689d9e1b08597890550d0a45c11e6e4014a7a67c713.
//
// Solidity: event HookExecuted(address indexed hook, address indexed prevHook, address indexed targetedYieldSource, bool usePrevHookAmount, bytes hookCalldata)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterHookExecuted(opts *bind.FilterOpts, hook []common.Address, prevHook []common.Address, targetedYieldSource []common.Address) (*SuperVaultStrategyHookExecutedIterator, error) {

	var hookRule []interface{}
	for _, hookItem := range hook {
		hookRule = append(hookRule, hookItem)
	}
	var prevHookRule []interface{}
	for _, prevHookItem := range prevHook {
		prevHookRule = append(prevHookRule, prevHookItem)
	}
	var targetedYieldSourceRule []interface{}
	for _, targetedYieldSourceItem := range targetedYieldSource {
		targetedYieldSourceRule = append(targetedYieldSourceRule, targetedYieldSourceItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "HookExecuted", hookRule, prevHookRule, targetedYieldSourceRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyHookExecutedIterator{contract: _SuperVaultStrategy.contract, event: "HookExecuted", logs: logs, sub: sub}, nil
}

// WatchHookExecuted is a free log subscription operation binding the contract event 0xedec66be61a678e975773689d9e1b08597890550d0a45c11e6e4014a7a67c713.
//
// Solidity: event HookExecuted(address indexed hook, address indexed prevHook, address indexed targetedYieldSource, bool usePrevHookAmount, bytes hookCalldata)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchHookExecuted(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyHookExecuted, hook []common.Address, prevHook []common.Address, targetedYieldSource []common.Address) (event.Subscription, error) {

	var hookRule []interface{}
	for _, hookItem := range hook {
		hookRule = append(hookRule, hookItem)
	}
	var prevHookRule []interface{}
	for _, prevHookItem := range prevHook {
		prevHookRule = append(prevHookRule, prevHookItem)
	}
	var targetedYieldSourceRule []interface{}
	for _, targetedYieldSourceItem := range targetedYieldSource {
		targetedYieldSourceRule = append(targetedYieldSourceRule, targetedYieldSourceItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "HookExecuted", hookRule, prevHookRule, targetedYieldSourceRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyHookExecuted)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "HookExecuted", log); err != nil {
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

// ParseHookExecuted is a log parse operation binding the contract event 0xedec66be61a678e975773689d9e1b08597890550d0a45c11e6e4014a7a67c713.
//
// Solidity: event HookExecuted(address indexed hook, address indexed prevHook, address indexed targetedYieldSource, bool usePrevHookAmount, bytes hookCalldata)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseHookExecuted(log types.Log) (*SuperVaultStrategyHookExecuted, error) {
	event := new(SuperVaultStrategyHookExecuted)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "HookExecuted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyHooksExecutedIterator is returned from FilterHooksExecuted and is used to iterate over the raw logs and unpacked data for HooksExecuted events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyHooksExecutedIterator struct {
	Event *SuperVaultStrategyHooksExecuted // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyHooksExecutedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyHooksExecuted)
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
		it.Event = new(SuperVaultStrategyHooksExecuted)
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
func (it *SuperVaultStrategyHooksExecutedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyHooksExecutedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyHooksExecuted represents a HooksExecuted event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyHooksExecuted struct {
	Hooks []common.Address
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterHooksExecuted is a free log retrieval operation binding the contract event 0xff9e16ffdb4688c2ca0a0c2405ef9a7237ef140b3830a164e6a28b69c9895ddc.
//
// Solidity: event HooksExecuted(address[] hooks)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterHooksExecuted(opts *bind.FilterOpts) (*SuperVaultStrategyHooksExecutedIterator, error) {

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "HooksExecuted")
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyHooksExecutedIterator{contract: _SuperVaultStrategy.contract, event: "HooksExecuted", logs: logs, sub: sub}, nil
}

// WatchHooksExecuted is a free log subscription operation binding the contract event 0xff9e16ffdb4688c2ca0a0c2405ef9a7237ef140b3830a164e6a28b69c9895ddc.
//
// Solidity: event HooksExecuted(address[] hooks)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchHooksExecuted(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyHooksExecuted) (event.Subscription, error) {

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "HooksExecuted")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyHooksExecuted)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "HooksExecuted", log); err != nil {
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

// ParseHooksExecuted is a log parse operation binding the contract event 0xff9e16ffdb4688c2ca0a0c2405ef9a7237ef140b3830a164e6a28b69c9895ddc.
//
// Solidity: event HooksExecuted(address[] hooks)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseHooksExecuted(log types.Log) (*SuperVaultStrategyHooksExecuted, error) {
	event := new(SuperVaultStrategyHooksExecuted)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "HooksExecuted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyInitializedIterator is returned from FilterInitialized and is used to iterate over the raw logs and unpacked data for Initialized events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyInitializedIterator struct {
	Event *SuperVaultStrategyInitialized // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyInitializedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyInitialized)
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
		it.Event = new(SuperVaultStrategyInitialized)
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
func (it *SuperVaultStrategyInitializedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyInitializedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyInitialized represents a Initialized event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyInitialized struct {
	Version uint64
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterInitialized is a free log retrieval operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterInitialized(opts *bind.FilterOpts) (*SuperVaultStrategyInitializedIterator, error) {

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyInitializedIterator{contract: _SuperVaultStrategy.contract, event: "Initialized", logs: logs, sub: sub}, nil
}

// WatchInitialized is a free log subscription operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchInitialized(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyInitialized) (event.Subscription, error) {

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyInitialized)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "Initialized", log); err != nil {
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

// ParseInitialized is a log parse operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseInitialized(log types.Log) (*SuperVaultStrategyInitialized, error) {
	event := new(SuperVaultStrategyInitialized)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "Initialized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyInitialized0Iterator is returned from FilterInitialized0 and is used to iterate over the raw logs and unpacked data for Initialized0 events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyInitialized0Iterator struct {
	Event *SuperVaultStrategyInitialized0 // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyInitialized0Iterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyInitialized0)
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
		it.Event = new(SuperVaultStrategyInitialized0)
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
func (it *SuperVaultStrategyInitialized0Iterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyInitialized0Iterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyInitialized0 represents a Initialized0 event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyInitialized0 struct {
	Vault common.Address
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterInitialized0 is a free log retrieval operation binding the contract event 0x908408e307fc569b417f6cbec5d5a06f44a0a505ac0479b47d421a4b2fd6a1e6.
//
// Solidity: event Initialized(address indexed vault)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterInitialized0(opts *bind.FilterOpts, vault []common.Address) (*SuperVaultStrategyInitialized0Iterator, error) {

	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "Initialized0", vaultRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyInitialized0Iterator{contract: _SuperVaultStrategy.contract, event: "Initialized0", logs: logs, sub: sub}, nil
}

// WatchInitialized0 is a free log subscription operation binding the contract event 0x908408e307fc569b417f6cbec5d5a06f44a0a505ac0479b47d421a4b2fd6a1e6.
//
// Solidity: event Initialized(address indexed vault)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchInitialized0(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyInitialized0, vault []common.Address) (event.Subscription, error) {

	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "Initialized0", vaultRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyInitialized0)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "Initialized0", log); err != nil {
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

// ParseInitialized0 is a log parse operation binding the contract event 0x908408e307fc569b417f6cbec5d5a06f44a0a505ac0479b47d421a4b2fd6a1e6.
//
// Solidity: event Initialized(address indexed vault)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseInitialized0(log types.Log) (*SuperVaultStrategyInitialized0, error) {
	event := new(SuperVaultStrategyInitialized0)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "Initialized0", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyManagementFeePaidIterator is returned from FilterManagementFeePaid and is used to iterate over the raw logs and unpacked data for ManagementFeePaid events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyManagementFeePaidIterator struct {
	Event *SuperVaultStrategyManagementFeePaid // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyManagementFeePaidIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyManagementFeePaid)
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
		it.Event = new(SuperVaultStrategyManagementFeePaid)
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
func (it *SuperVaultStrategyManagementFeePaidIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyManagementFeePaidIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyManagementFeePaid represents a ManagementFeePaid event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyManagementFeePaid struct {
	Controller common.Address
	Recipient  common.Address
	FeeAssets  *big.Int
	FeeBps     *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterManagementFeePaid is a free log retrieval operation binding the contract event 0xaa504b22cbdce5a2eefab55773a71cacbdccd9434d9650cedb1fc8f8da51380e.
//
// Solidity: event ManagementFeePaid(address indexed controller, address indexed recipient, uint256 feeAssets, uint256 feeBps)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterManagementFeePaid(opts *bind.FilterOpts, controller []common.Address, recipient []common.Address) (*SuperVaultStrategyManagementFeePaidIterator, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}
	var recipientRule []interface{}
	for _, recipientItem := range recipient {
		recipientRule = append(recipientRule, recipientItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "ManagementFeePaid", controllerRule, recipientRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyManagementFeePaidIterator{contract: _SuperVaultStrategy.contract, event: "ManagementFeePaid", logs: logs, sub: sub}, nil
}

// WatchManagementFeePaid is a free log subscription operation binding the contract event 0xaa504b22cbdce5a2eefab55773a71cacbdccd9434d9650cedb1fc8f8da51380e.
//
// Solidity: event ManagementFeePaid(address indexed controller, address indexed recipient, uint256 feeAssets, uint256 feeBps)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchManagementFeePaid(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyManagementFeePaid, controller []common.Address, recipient []common.Address) (event.Subscription, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}
	var recipientRule []interface{}
	for _, recipientItem := range recipient {
		recipientRule = append(recipientRule, recipientItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "ManagementFeePaid", controllerRule, recipientRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyManagementFeePaid)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "ManagementFeePaid", log); err != nil {
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

// ParseManagementFeePaid is a log parse operation binding the contract event 0xaa504b22cbdce5a2eefab55773a71cacbdccd9434d9650cedb1fc8f8da51380e.
//
// Solidity: event ManagementFeePaid(address indexed controller, address indexed recipient, uint256 feeAssets, uint256 feeBps)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseManagementFeePaid(log types.Log) (*SuperVaultStrategyManagementFeePaid, error) {
	event := new(SuperVaultStrategyManagementFeePaid)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "ManagementFeePaid", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyPPSExpirationProposedIterator is returned from FilterPPSExpirationProposed and is used to iterate over the raw logs and unpacked data for PPSExpirationProposed events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyPPSExpirationProposedIterator struct {
	Event *SuperVaultStrategyPPSExpirationProposed // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyPPSExpirationProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyPPSExpirationProposed)
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
		it.Event = new(SuperVaultStrategyPPSExpirationProposed)
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
func (it *SuperVaultStrategyPPSExpirationProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyPPSExpirationProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyPPSExpirationProposed represents a PPSExpirationProposed event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyPPSExpirationProposed struct {
	CurrentProposedThreshold *big.Int
	PpsExpiration            *big.Int
	EffectiveTime            *big.Int
	Raw                      types.Log // Blockchain specific contextual infos
}

// FilterPPSExpirationProposed is a free log retrieval operation binding the contract event 0x3e72cdc1d8daeaf69a057c41ccd19b6bbe966c4176c62bcbaa8eea512109e997.
//
// Solidity: event PPSExpirationProposed(uint256 currentProposedThreshold, uint256 ppsExpiration, uint256 effectiveTime)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterPPSExpirationProposed(opts *bind.FilterOpts) (*SuperVaultStrategyPPSExpirationProposedIterator, error) {

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "PPSExpirationProposed")
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyPPSExpirationProposedIterator{contract: _SuperVaultStrategy.contract, event: "PPSExpirationProposed", logs: logs, sub: sub}, nil
}

// WatchPPSExpirationProposed is a free log subscription operation binding the contract event 0x3e72cdc1d8daeaf69a057c41ccd19b6bbe966c4176c62bcbaa8eea512109e997.
//
// Solidity: event PPSExpirationProposed(uint256 currentProposedThreshold, uint256 ppsExpiration, uint256 effectiveTime)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchPPSExpirationProposed(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyPPSExpirationProposed) (event.Subscription, error) {

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "PPSExpirationProposed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyPPSExpirationProposed)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "PPSExpirationProposed", log); err != nil {
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

// ParsePPSExpirationProposed is a log parse operation binding the contract event 0x3e72cdc1d8daeaf69a057c41ccd19b6bbe966c4176c62bcbaa8eea512109e997.
//
// Solidity: event PPSExpirationProposed(uint256 currentProposedThreshold, uint256 ppsExpiration, uint256 effectiveTime)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParsePPSExpirationProposed(log types.Log) (*SuperVaultStrategyPPSExpirationProposed, error) {
	event := new(SuperVaultStrategyPPSExpirationProposed)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "PPSExpirationProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyPPSExpiryThresholdProposalCanceledIterator is returned from FilterPPSExpiryThresholdProposalCanceled and is used to iterate over the raw logs and unpacked data for PPSExpiryThresholdProposalCanceled events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyPPSExpiryThresholdProposalCanceledIterator struct {
	Event *SuperVaultStrategyPPSExpiryThresholdProposalCanceled // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyPPSExpiryThresholdProposalCanceledIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyPPSExpiryThresholdProposalCanceled)
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
		it.Event = new(SuperVaultStrategyPPSExpiryThresholdProposalCanceled)
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
func (it *SuperVaultStrategyPPSExpiryThresholdProposalCanceledIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyPPSExpiryThresholdProposalCanceledIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyPPSExpiryThresholdProposalCanceled represents a PPSExpiryThresholdProposalCanceled event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyPPSExpiryThresholdProposalCanceled struct {
	Raw types.Log // Blockchain specific contextual infos
}

// FilterPPSExpiryThresholdProposalCanceled is a free log retrieval operation binding the contract event 0x685fff2a20ca77490d01b40b7e8b21eeb93eb59b758d92bc664c081f1762c449.
//
// Solidity: event PPSExpiryThresholdProposalCanceled()
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterPPSExpiryThresholdProposalCanceled(opts *bind.FilterOpts) (*SuperVaultStrategyPPSExpiryThresholdProposalCanceledIterator, error) {

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "PPSExpiryThresholdProposalCanceled")
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyPPSExpiryThresholdProposalCanceledIterator{contract: _SuperVaultStrategy.contract, event: "PPSExpiryThresholdProposalCanceled", logs: logs, sub: sub}, nil
}

// WatchPPSExpiryThresholdProposalCanceled is a free log subscription operation binding the contract event 0x685fff2a20ca77490d01b40b7e8b21eeb93eb59b758d92bc664c081f1762c449.
//
// Solidity: event PPSExpiryThresholdProposalCanceled()
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchPPSExpiryThresholdProposalCanceled(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyPPSExpiryThresholdProposalCanceled) (event.Subscription, error) {

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "PPSExpiryThresholdProposalCanceled")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyPPSExpiryThresholdProposalCanceled)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "PPSExpiryThresholdProposalCanceled", log); err != nil {
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

// ParsePPSExpiryThresholdProposalCanceled is a log parse operation binding the contract event 0x685fff2a20ca77490d01b40b7e8b21eeb93eb59b758d92bc664c081f1762c449.
//
// Solidity: event PPSExpiryThresholdProposalCanceled()
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParsePPSExpiryThresholdProposalCanceled(log types.Log) (*SuperVaultStrategyPPSExpiryThresholdProposalCanceled, error) {
	event := new(SuperVaultStrategyPPSExpiryThresholdProposalCanceled)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "PPSExpiryThresholdProposalCanceled", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyPPSExpiryThresholdUpdatedIterator is returned from FilterPPSExpiryThresholdUpdated and is used to iterate over the raw logs and unpacked data for PPSExpiryThresholdUpdated events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyPPSExpiryThresholdUpdatedIterator struct {
	Event *SuperVaultStrategyPPSExpiryThresholdUpdated // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyPPSExpiryThresholdUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyPPSExpiryThresholdUpdated)
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
		it.Event = new(SuperVaultStrategyPPSExpiryThresholdUpdated)
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
func (it *SuperVaultStrategyPPSExpiryThresholdUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyPPSExpiryThresholdUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyPPSExpiryThresholdUpdated represents a PPSExpiryThresholdUpdated event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyPPSExpiryThresholdUpdated struct {
	PpsExpiration *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterPPSExpiryThresholdUpdated is a free log retrieval operation binding the contract event 0x0be4516136fc02c5d8d064aada0e66b756dd68b26fbd5fb074835752f346ca84.
//
// Solidity: event PPSExpiryThresholdUpdated(uint256 ppsExpiration)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterPPSExpiryThresholdUpdated(opts *bind.FilterOpts) (*SuperVaultStrategyPPSExpiryThresholdUpdatedIterator, error) {

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "PPSExpiryThresholdUpdated")
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyPPSExpiryThresholdUpdatedIterator{contract: _SuperVaultStrategy.contract, event: "PPSExpiryThresholdUpdated", logs: logs, sub: sub}, nil
}

// WatchPPSExpiryThresholdUpdated is a free log subscription operation binding the contract event 0x0be4516136fc02c5d8d064aada0e66b756dd68b26fbd5fb074835752f346ca84.
//
// Solidity: event PPSExpiryThresholdUpdated(uint256 ppsExpiration)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchPPSExpiryThresholdUpdated(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyPPSExpiryThresholdUpdated) (event.Subscription, error) {

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "PPSExpiryThresholdUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyPPSExpiryThresholdUpdated)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "PPSExpiryThresholdUpdated", log); err != nil {
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

// ParsePPSExpiryThresholdUpdated is a log parse operation binding the contract event 0x0be4516136fc02c5d8d064aada0e66b756dd68b26fbd5fb074835752f346ca84.
//
// Solidity: event PPSExpiryThresholdUpdated(uint256 ppsExpiration)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParsePPSExpiryThresholdUpdated(log types.Log) (*SuperVaultStrategyPPSExpiryThresholdUpdated, error) {
	event := new(SuperVaultStrategyPPSExpiryThresholdUpdated)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "PPSExpiryThresholdUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyPPSUpdatedIterator is returned from FilterPPSUpdated and is used to iterate over the raw logs and unpacked data for PPSUpdated events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyPPSUpdatedIterator struct {
	Event *SuperVaultStrategyPPSUpdated // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyPPSUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyPPSUpdated)
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
		it.Event = new(SuperVaultStrategyPPSUpdated)
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
func (it *SuperVaultStrategyPPSUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyPPSUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyPPSUpdated represents a PPSUpdated event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyPPSUpdated struct {
	NewPPS           *big.Int
	CalculationBlock *big.Int
	Raw              types.Log // Blockchain specific contextual infos
}

// FilterPPSUpdated is a free log retrieval operation binding the contract event 0xb6cc0c2ff0c9234f0af39df37dc4a66ff11533ec5936b359e86bb1f63a5f9b0e.
//
// Solidity: event PPSUpdated(uint256 newPPS, uint256 calculationBlock)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterPPSUpdated(opts *bind.FilterOpts) (*SuperVaultStrategyPPSUpdatedIterator, error) {

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "PPSUpdated")
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyPPSUpdatedIterator{contract: _SuperVaultStrategy.contract, event: "PPSUpdated", logs: logs, sub: sub}, nil
}

// WatchPPSUpdated is a free log subscription operation binding the contract event 0xb6cc0c2ff0c9234f0af39df37dc4a66ff11533ec5936b359e86bb1f63a5f9b0e.
//
// Solidity: event PPSUpdated(uint256 newPPS, uint256 calculationBlock)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchPPSUpdated(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyPPSUpdated) (event.Subscription, error) {

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "PPSUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyPPSUpdated)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "PPSUpdated", log); err != nil {
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

// ParsePPSUpdated is a log parse operation binding the contract event 0xb6cc0c2ff0c9234f0af39df37dc4a66ff11533ec5936b359e86bb1f63a5f9b0e.
//
// Solidity: event PPSUpdated(uint256 newPPS, uint256 calculationBlock)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParsePPSUpdated(log types.Log) (*SuperVaultStrategyPPSUpdated, error) {
	event := new(SuperVaultStrategyPPSUpdated)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "PPSUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyPerformanceFeeSkimmedIterator is returned from FilterPerformanceFeeSkimmed and is used to iterate over the raw logs and unpacked data for PerformanceFeeSkimmed events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyPerformanceFeeSkimmedIterator struct {
	Event *SuperVaultStrategyPerformanceFeeSkimmed // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyPerformanceFeeSkimmedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyPerformanceFeeSkimmed)
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
		it.Event = new(SuperVaultStrategyPerformanceFeeSkimmed)
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
func (it *SuperVaultStrategyPerformanceFeeSkimmedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyPerformanceFeeSkimmedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyPerformanceFeeSkimmed represents a PerformanceFeeSkimmed event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyPerformanceFeeSkimmed struct {
	TotalFee     *big.Int
	SuperformFee *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterPerformanceFeeSkimmed is a free log retrieval operation binding the contract event 0xe99c9610207391351c94b1119215d644cb958ddad6ff314c19c425ee979f883c.
//
// Solidity: event PerformanceFeeSkimmed(uint256 totalFee, uint256 superformFee)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterPerformanceFeeSkimmed(opts *bind.FilterOpts) (*SuperVaultStrategyPerformanceFeeSkimmedIterator, error) {

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "PerformanceFeeSkimmed")
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyPerformanceFeeSkimmedIterator{contract: _SuperVaultStrategy.contract, event: "PerformanceFeeSkimmed", logs: logs, sub: sub}, nil
}

// WatchPerformanceFeeSkimmed is a free log subscription operation binding the contract event 0xe99c9610207391351c94b1119215d644cb958ddad6ff314c19c425ee979f883c.
//
// Solidity: event PerformanceFeeSkimmed(uint256 totalFee, uint256 superformFee)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchPerformanceFeeSkimmed(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyPerformanceFeeSkimmed) (event.Subscription, error) {

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "PerformanceFeeSkimmed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyPerformanceFeeSkimmed)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "PerformanceFeeSkimmed", log); err != nil {
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

// ParsePerformanceFeeSkimmed is a log parse operation binding the contract event 0xe99c9610207391351c94b1119215d644cb958ddad6ff314c19c425ee979f883c.
//
// Solidity: event PerformanceFeeSkimmed(uint256 totalFee, uint256 superformFee)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParsePerformanceFeeSkimmed(log types.Log) (*SuperVaultStrategyPerformanceFeeSkimmed, error) {
	event := new(SuperVaultStrategyPerformanceFeeSkimmed)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "PerformanceFeeSkimmed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyRedeemCancelRequestFulfilledIterator is returned from FilterRedeemCancelRequestFulfilled and is used to iterate over the raw logs and unpacked data for RedeemCancelRequestFulfilled events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyRedeemCancelRequestFulfilledIterator struct {
	Event *SuperVaultStrategyRedeemCancelRequestFulfilled // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyRedeemCancelRequestFulfilledIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyRedeemCancelRequestFulfilled)
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
		it.Event = new(SuperVaultStrategyRedeemCancelRequestFulfilled)
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
func (it *SuperVaultStrategyRedeemCancelRequestFulfilledIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyRedeemCancelRequestFulfilledIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyRedeemCancelRequestFulfilled represents a RedeemCancelRequestFulfilled event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyRedeemCancelRequestFulfilled struct {
	Controller common.Address
	Shares     *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterRedeemCancelRequestFulfilled is a free log retrieval operation binding the contract event 0xc3f738f21dd3a6bb2f509483fd1fb51f53309a75a8e01041ef38b5a56d07f313.
//
// Solidity: event RedeemCancelRequestFulfilled(address indexed controller, uint256 shares)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterRedeemCancelRequestFulfilled(opts *bind.FilterOpts, controller []common.Address) (*SuperVaultStrategyRedeemCancelRequestFulfilledIterator, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "RedeemCancelRequestFulfilled", controllerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyRedeemCancelRequestFulfilledIterator{contract: _SuperVaultStrategy.contract, event: "RedeemCancelRequestFulfilled", logs: logs, sub: sub}, nil
}

// WatchRedeemCancelRequestFulfilled is a free log subscription operation binding the contract event 0xc3f738f21dd3a6bb2f509483fd1fb51f53309a75a8e01041ef38b5a56d07f313.
//
// Solidity: event RedeemCancelRequestFulfilled(address indexed controller, uint256 shares)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchRedeemCancelRequestFulfilled(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyRedeemCancelRequestFulfilled, controller []common.Address) (event.Subscription, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "RedeemCancelRequestFulfilled", controllerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyRedeemCancelRequestFulfilled)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "RedeemCancelRequestFulfilled", log); err != nil {
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

// ParseRedeemCancelRequestFulfilled is a log parse operation binding the contract event 0xc3f738f21dd3a6bb2f509483fd1fb51f53309a75a8e01041ef38b5a56d07f313.
//
// Solidity: event RedeemCancelRequestFulfilled(address indexed controller, uint256 shares)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseRedeemCancelRequestFulfilled(log types.Log) (*SuperVaultStrategyRedeemCancelRequestFulfilled, error) {
	event := new(SuperVaultStrategyRedeemCancelRequestFulfilled)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "RedeemCancelRequestFulfilled", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyRedeemCancelRequestPlacedIterator is returned from FilterRedeemCancelRequestPlaced and is used to iterate over the raw logs and unpacked data for RedeemCancelRequestPlaced events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyRedeemCancelRequestPlacedIterator struct {
	Event *SuperVaultStrategyRedeemCancelRequestPlaced // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyRedeemCancelRequestPlacedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyRedeemCancelRequestPlaced)
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
		it.Event = new(SuperVaultStrategyRedeemCancelRequestPlaced)
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
func (it *SuperVaultStrategyRedeemCancelRequestPlacedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyRedeemCancelRequestPlacedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyRedeemCancelRequestPlaced represents a RedeemCancelRequestPlaced event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyRedeemCancelRequestPlaced struct {
	Controller common.Address
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterRedeemCancelRequestPlaced is a free log retrieval operation binding the contract event 0x161932217e95d8056f1c36f72905eb1116eedce891d4507f0d8a58ad72b094a8.
//
// Solidity: event RedeemCancelRequestPlaced(address indexed controller)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterRedeemCancelRequestPlaced(opts *bind.FilterOpts, controller []common.Address) (*SuperVaultStrategyRedeemCancelRequestPlacedIterator, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "RedeemCancelRequestPlaced", controllerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyRedeemCancelRequestPlacedIterator{contract: _SuperVaultStrategy.contract, event: "RedeemCancelRequestPlaced", logs: logs, sub: sub}, nil
}

// WatchRedeemCancelRequestPlaced is a free log subscription operation binding the contract event 0x161932217e95d8056f1c36f72905eb1116eedce891d4507f0d8a58ad72b094a8.
//
// Solidity: event RedeemCancelRequestPlaced(address indexed controller)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchRedeemCancelRequestPlaced(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyRedeemCancelRequestPlaced, controller []common.Address) (event.Subscription, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "RedeemCancelRequestPlaced", controllerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyRedeemCancelRequestPlaced)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "RedeemCancelRequestPlaced", log); err != nil {
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

// ParseRedeemCancelRequestPlaced is a log parse operation binding the contract event 0x161932217e95d8056f1c36f72905eb1116eedce891d4507f0d8a58ad72b094a8.
//
// Solidity: event RedeemCancelRequestPlaced(address indexed controller)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseRedeemCancelRequestPlaced(log types.Log) (*SuperVaultStrategyRedeemCancelRequestPlaced, error) {
	event := new(SuperVaultStrategyRedeemCancelRequestPlaced)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "RedeemCancelRequestPlaced", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyRedeemClaimableIterator is returned from FilterRedeemClaimable and is used to iterate over the raw logs and unpacked data for RedeemClaimable events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyRedeemClaimableIterator struct {
	Event *SuperVaultStrategyRedeemClaimable // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyRedeemClaimableIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyRedeemClaimable)
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
		it.Event = new(SuperVaultStrategyRedeemClaimable)
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
func (it *SuperVaultStrategyRedeemClaimableIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyRedeemClaimableIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyRedeemClaimable represents a RedeemClaimable event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyRedeemClaimable struct {
	Controller           common.Address
	AssetsFulfilled      *big.Int
	SharesFulfilled      *big.Int
	AverageWithdrawPrice *big.Int
	Raw                  types.Log // Blockchain specific contextual infos
}

// FilterRedeemClaimable is a free log retrieval operation binding the contract event 0x4dd5187225a2ae5f5ea35ca7b1732180f848cc4b6f7dce34b4c5e9f384d77dec.
//
// Solidity: event RedeemClaimable(address indexed controller, uint256 assetsFulfilled, uint256 sharesFulfilled, uint256 averageWithdrawPrice)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterRedeemClaimable(opts *bind.FilterOpts, controller []common.Address) (*SuperVaultStrategyRedeemClaimableIterator, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "RedeemClaimable", controllerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyRedeemClaimableIterator{contract: _SuperVaultStrategy.contract, event: "RedeemClaimable", logs: logs, sub: sub}, nil
}

// WatchRedeemClaimable is a free log subscription operation binding the contract event 0x4dd5187225a2ae5f5ea35ca7b1732180f848cc4b6f7dce34b4c5e9f384d77dec.
//
// Solidity: event RedeemClaimable(address indexed controller, uint256 assetsFulfilled, uint256 sharesFulfilled, uint256 averageWithdrawPrice)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchRedeemClaimable(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyRedeemClaimable, controller []common.Address) (event.Subscription, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "RedeemClaimable", controllerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyRedeemClaimable)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "RedeemClaimable", log); err != nil {
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

// ParseRedeemClaimable is a log parse operation binding the contract event 0x4dd5187225a2ae5f5ea35ca7b1732180f848cc4b6f7dce34b4c5e9f384d77dec.
//
// Solidity: event RedeemClaimable(address indexed controller, uint256 assetsFulfilled, uint256 sharesFulfilled, uint256 averageWithdrawPrice)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseRedeemClaimable(log types.Log) (*SuperVaultStrategyRedeemClaimable, error) {
	event := new(SuperVaultStrategyRedeemClaimable)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "RedeemClaimable", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyRedeemRequestCanceledIterator is returned from FilterRedeemRequestCanceled and is used to iterate over the raw logs and unpacked data for RedeemRequestCanceled events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyRedeemRequestCanceledIterator struct {
	Event *SuperVaultStrategyRedeemRequestCanceled // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyRedeemRequestCanceledIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyRedeemRequestCanceled)
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
		it.Event = new(SuperVaultStrategyRedeemRequestCanceled)
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
func (it *SuperVaultStrategyRedeemRequestCanceledIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyRedeemRequestCanceledIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyRedeemRequestCanceled represents a RedeemRequestCanceled event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyRedeemRequestCanceled struct {
	Controller common.Address
	Shares     *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterRedeemRequestCanceled is a free log retrieval operation binding the contract event 0x95c79fa73e29b5366d4d76636d7cee6df5062a878e67ddfaa9685f3a4b0ccc93.
//
// Solidity: event RedeemRequestCanceled(address indexed controller, uint256 shares)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterRedeemRequestCanceled(opts *bind.FilterOpts, controller []common.Address) (*SuperVaultStrategyRedeemRequestCanceledIterator, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "RedeemRequestCanceled", controllerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyRedeemRequestCanceledIterator{contract: _SuperVaultStrategy.contract, event: "RedeemRequestCanceled", logs: logs, sub: sub}, nil
}

// WatchRedeemRequestCanceled is a free log subscription operation binding the contract event 0x95c79fa73e29b5366d4d76636d7cee6df5062a878e67ddfaa9685f3a4b0ccc93.
//
// Solidity: event RedeemRequestCanceled(address indexed controller, uint256 shares)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchRedeemRequestCanceled(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyRedeemRequestCanceled, controller []common.Address) (event.Subscription, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "RedeemRequestCanceled", controllerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyRedeemRequestCanceled)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "RedeemRequestCanceled", log); err != nil {
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

// ParseRedeemRequestCanceled is a log parse operation binding the contract event 0x95c79fa73e29b5366d4d76636d7cee6df5062a878e67ddfaa9685f3a4b0ccc93.
//
// Solidity: event RedeemRequestCanceled(address indexed controller, uint256 shares)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseRedeemRequestCanceled(log types.Log) (*SuperVaultStrategyRedeemRequestCanceled, error) {
	event := new(SuperVaultStrategyRedeemRequestCanceled)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "RedeemRequestCanceled", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyRedeemRequestClaimedIterator is returned from FilterRedeemRequestClaimed and is used to iterate over the raw logs and unpacked data for RedeemRequestClaimed events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyRedeemRequestClaimedIterator struct {
	Event *SuperVaultStrategyRedeemRequestClaimed // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyRedeemRequestClaimedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyRedeemRequestClaimed)
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
		it.Event = new(SuperVaultStrategyRedeemRequestClaimed)
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
func (it *SuperVaultStrategyRedeemRequestClaimedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyRedeemRequestClaimedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyRedeemRequestClaimed represents a RedeemRequestClaimed event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyRedeemRequestClaimed struct {
	Controller common.Address
	Receiver   common.Address
	Assets     *big.Int
	Shares     *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterRedeemRequestClaimed is a free log retrieval operation binding the contract event 0xd42ea6b2881f3aa6277b6ed5f40216c4966f35cd87f3f72dc3b986f878a62c92.
//
// Solidity: event RedeemRequestClaimed(address indexed controller, address indexed receiver, uint256 assets, uint256 shares)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterRedeemRequestClaimed(opts *bind.FilterOpts, controller []common.Address, receiver []common.Address) (*SuperVaultStrategyRedeemRequestClaimedIterator, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}
	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "RedeemRequestClaimed", controllerRule, receiverRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyRedeemRequestClaimedIterator{contract: _SuperVaultStrategy.contract, event: "RedeemRequestClaimed", logs: logs, sub: sub}, nil
}

// WatchRedeemRequestClaimed is a free log subscription operation binding the contract event 0xd42ea6b2881f3aa6277b6ed5f40216c4966f35cd87f3f72dc3b986f878a62c92.
//
// Solidity: event RedeemRequestClaimed(address indexed controller, address indexed receiver, uint256 assets, uint256 shares)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchRedeemRequestClaimed(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyRedeemRequestClaimed, controller []common.Address, receiver []common.Address) (event.Subscription, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}
	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "RedeemRequestClaimed", controllerRule, receiverRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyRedeemRequestClaimed)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "RedeemRequestClaimed", log); err != nil {
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

// ParseRedeemRequestClaimed is a log parse operation binding the contract event 0xd42ea6b2881f3aa6277b6ed5f40216c4966f35cd87f3f72dc3b986f878a62c92.
//
// Solidity: event RedeemRequestClaimed(address indexed controller, address indexed receiver, uint256 assets, uint256 shares)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseRedeemRequestClaimed(log types.Log) (*SuperVaultStrategyRedeemRequestClaimed, error) {
	event := new(SuperVaultStrategyRedeemRequestClaimed)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "RedeemRequestClaimed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyRedeemRequestPlacedIterator is returned from FilterRedeemRequestPlaced and is used to iterate over the raw logs and unpacked data for RedeemRequestPlaced events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyRedeemRequestPlacedIterator struct {
	Event *SuperVaultStrategyRedeemRequestPlaced // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyRedeemRequestPlacedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyRedeemRequestPlaced)
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
		it.Event = new(SuperVaultStrategyRedeemRequestPlaced)
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
func (it *SuperVaultStrategyRedeemRequestPlacedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyRedeemRequestPlacedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyRedeemRequestPlaced represents a RedeemRequestPlaced event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyRedeemRequestPlaced struct {
	Controller common.Address
	Owner      common.Address
	Shares     *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterRedeemRequestPlaced is a free log retrieval operation binding the contract event 0xbeb06d4f35e676c2ef7181fbfd7bf2499fe739db0a96517ae96c40ebaf2f5c6b.
//
// Solidity: event RedeemRequestPlaced(address indexed controller, address indexed owner, uint256 shares)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterRedeemRequestPlaced(opts *bind.FilterOpts, controller []common.Address, owner []common.Address) (*SuperVaultStrategyRedeemRequestPlacedIterator, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}
	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "RedeemRequestPlaced", controllerRule, ownerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyRedeemRequestPlacedIterator{contract: _SuperVaultStrategy.contract, event: "RedeemRequestPlaced", logs: logs, sub: sub}, nil
}

// WatchRedeemRequestPlaced is a free log subscription operation binding the contract event 0xbeb06d4f35e676c2ef7181fbfd7bf2499fe739db0a96517ae96c40ebaf2f5c6b.
//
// Solidity: event RedeemRequestPlaced(address indexed controller, address indexed owner, uint256 shares)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchRedeemRequestPlaced(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyRedeemRequestPlaced, controller []common.Address, owner []common.Address) (event.Subscription, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}
	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "RedeemRequestPlaced", controllerRule, ownerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyRedeemRequestPlaced)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "RedeemRequestPlaced", log); err != nil {
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

// ParseRedeemRequestPlaced is a log parse operation binding the contract event 0xbeb06d4f35e676c2ef7181fbfd7bf2499fe739db0a96517ae96c40ebaf2f5c6b.
//
// Solidity: event RedeemRequestPlaced(address indexed controller, address indexed owner, uint256 shares)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseRedeemRequestPlaced(log types.Log) (*SuperVaultStrategyRedeemRequestPlaced, error) {
	event := new(SuperVaultStrategyRedeemRequestPlaced)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "RedeemRequestPlaced", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyRedeemRequestsFulfilledIterator is returned from FilterRedeemRequestsFulfilled and is used to iterate over the raw logs and unpacked data for RedeemRequestsFulfilled events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyRedeemRequestsFulfilledIterator struct {
	Event *SuperVaultStrategyRedeemRequestsFulfilled // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyRedeemRequestsFulfilledIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyRedeemRequestsFulfilled)
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
		it.Event = new(SuperVaultStrategyRedeemRequestsFulfilled)
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
func (it *SuperVaultStrategyRedeemRequestsFulfilledIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyRedeemRequestsFulfilledIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyRedeemRequestsFulfilled represents a RedeemRequestsFulfilled event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyRedeemRequestsFulfilled struct {
	Controllers     []common.Address
	ProcessedShares *big.Int
	CurrentPPS      *big.Int
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterRedeemRequestsFulfilled is a free log retrieval operation binding the contract event 0x3515c94d213c3f562af06a775e0430aca224da3485274652d61a6dcbf2434cc0.
//
// Solidity: event RedeemRequestsFulfilled(address[] controllers, uint256 processedShares, uint256 currentPPS)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterRedeemRequestsFulfilled(opts *bind.FilterOpts) (*SuperVaultStrategyRedeemRequestsFulfilledIterator, error) {

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "RedeemRequestsFulfilled")
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyRedeemRequestsFulfilledIterator{contract: _SuperVaultStrategy.contract, event: "RedeemRequestsFulfilled", logs: logs, sub: sub}, nil
}

// WatchRedeemRequestsFulfilled is a free log subscription operation binding the contract event 0x3515c94d213c3f562af06a775e0430aca224da3485274652d61a6dcbf2434cc0.
//
// Solidity: event RedeemRequestsFulfilled(address[] controllers, uint256 processedShares, uint256 currentPPS)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchRedeemRequestsFulfilled(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyRedeemRequestsFulfilled) (event.Subscription, error) {

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "RedeemRequestsFulfilled")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyRedeemRequestsFulfilled)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "RedeemRequestsFulfilled", log); err != nil {
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

// ParseRedeemRequestsFulfilled is a log parse operation binding the contract event 0x3515c94d213c3f562af06a775e0430aca224da3485274652d61a6dcbf2434cc0.
//
// Solidity: event RedeemRequestsFulfilled(address[] controllers, uint256 processedShares, uint256 currentPPS)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseRedeemRequestsFulfilled(log types.Log) (*SuperVaultStrategyRedeemRequestsFulfilled, error) {
	event := new(SuperVaultStrategyRedeemRequestsFulfilled)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "RedeemRequestsFulfilled", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyRedeemSlippageSetIterator is returned from FilterRedeemSlippageSet and is used to iterate over the raw logs and unpacked data for RedeemSlippageSet events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyRedeemSlippageSetIterator struct {
	Event *SuperVaultStrategyRedeemSlippageSet // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyRedeemSlippageSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyRedeemSlippageSet)
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
		it.Event = new(SuperVaultStrategyRedeemSlippageSet)
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
func (it *SuperVaultStrategyRedeemSlippageSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyRedeemSlippageSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyRedeemSlippageSet represents a RedeemSlippageSet event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyRedeemSlippageSet struct {
	Controller  common.Address
	SlippageBps uint16
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterRedeemSlippageSet is a free log retrieval operation binding the contract event 0x88cb456056df13ba1bdb43569879a3a6e5e6dae148f4c012c8453b8749076314.
//
// Solidity: event RedeemSlippageSet(address indexed controller, uint16 slippageBps)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterRedeemSlippageSet(opts *bind.FilterOpts, controller []common.Address) (*SuperVaultStrategyRedeemSlippageSetIterator, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "RedeemSlippageSet", controllerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyRedeemSlippageSetIterator{contract: _SuperVaultStrategy.contract, event: "RedeemSlippageSet", logs: logs, sub: sub}, nil
}

// WatchRedeemSlippageSet is a free log subscription operation binding the contract event 0x88cb456056df13ba1bdb43569879a3a6e5e6dae148f4c012c8453b8749076314.
//
// Solidity: event RedeemSlippageSet(address indexed controller, uint16 slippageBps)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchRedeemSlippageSet(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyRedeemSlippageSet, controller []common.Address) (event.Subscription, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "RedeemSlippageSet", controllerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyRedeemSlippageSet)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "RedeemSlippageSet", log); err != nil {
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

// ParseRedeemSlippageSet is a log parse operation binding the contract event 0x88cb456056df13ba1bdb43569879a3a6e5e6dae148f4c012c8453b8749076314.
//
// Solidity: event RedeemSlippageSet(address indexed controller, uint16 slippageBps)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseRedeemSlippageSet(log types.Log) (*SuperVaultStrategyRedeemSlippageSet, error) {
	event := new(SuperVaultStrategyRedeemSlippageSet)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "RedeemSlippageSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategySuperGovernorSetIterator is returned from FilterSuperGovernorSet and is used to iterate over the raw logs and unpacked data for SuperGovernorSet events raised by the SuperVaultStrategy contract.
type SuperVaultStrategySuperGovernorSetIterator struct {
	Event *SuperVaultStrategySuperGovernorSet // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategySuperGovernorSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategySuperGovernorSet)
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
		it.Event = new(SuperVaultStrategySuperGovernorSet)
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
func (it *SuperVaultStrategySuperGovernorSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategySuperGovernorSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategySuperGovernorSet represents a SuperGovernorSet event raised by the SuperVaultStrategy contract.
type SuperVaultStrategySuperGovernorSet struct {
	SuperGovernor common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterSuperGovernorSet is a free log retrieval operation binding the contract event 0x0da0926ffeff398fc5913fba71778c90421d4af535e207f385a39e335cbfa692.
//
// Solidity: event SuperGovernorSet(address indexed superGovernor)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterSuperGovernorSet(opts *bind.FilterOpts, superGovernor []common.Address) (*SuperVaultStrategySuperGovernorSetIterator, error) {

	var superGovernorRule []interface{}
	for _, superGovernorItem := range superGovernor {
		superGovernorRule = append(superGovernorRule, superGovernorItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "SuperGovernorSet", superGovernorRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategySuperGovernorSetIterator{contract: _SuperVaultStrategy.contract, event: "SuperGovernorSet", logs: logs, sub: sub}, nil
}

// WatchSuperGovernorSet is a free log subscription operation binding the contract event 0x0da0926ffeff398fc5913fba71778c90421d4af535e207f385a39e335cbfa692.
//
// Solidity: event SuperGovernorSet(address indexed superGovernor)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchSuperGovernorSet(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategySuperGovernorSet, superGovernor []common.Address) (event.Subscription, error) {

	var superGovernorRule []interface{}
	for _, superGovernorItem := range superGovernor {
		superGovernorRule = append(superGovernorRule, superGovernorItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "SuperGovernorSet", superGovernorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategySuperGovernorSet)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "SuperGovernorSet", log); err != nil {
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

// ParseSuperGovernorSet is a log parse operation binding the contract event 0x0da0926ffeff398fc5913fba71778c90421d4af535e207f385a39e335cbfa692.
//
// Solidity: event SuperGovernorSet(address indexed superGovernor)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseSuperGovernorSet(log types.Log) (*SuperVaultStrategySuperGovernorSet, error) {
	event := new(SuperVaultStrategySuperGovernorSet)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "SuperGovernorSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyVaultFeeConfigProposedIterator is returned from FilterVaultFeeConfigProposed and is used to iterate over the raw logs and unpacked data for VaultFeeConfigProposed events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyVaultFeeConfigProposedIterator struct {
	Event *SuperVaultStrategyVaultFeeConfigProposed // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyVaultFeeConfigProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyVaultFeeConfigProposed)
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
		it.Event = new(SuperVaultStrategyVaultFeeConfigProposed)
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
func (it *SuperVaultStrategyVaultFeeConfigProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyVaultFeeConfigProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyVaultFeeConfigProposed represents a VaultFeeConfigProposed event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyVaultFeeConfigProposed struct {
	PerformanceFeeBps *big.Int
	ManagementFeeBps  *big.Int
	Recipient         common.Address
	EffectiveTime     *big.Int
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterVaultFeeConfigProposed is a free log retrieval operation binding the contract event 0xd3ae821e4db28b4e45d34b6440a80d782a5d6c82690bf26c7e8afde075ae9de2.
//
// Solidity: event VaultFeeConfigProposed(uint256 performanceFeeBps, uint256 managementFeeBps, address indexed recipient, uint256 effectiveTime)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterVaultFeeConfigProposed(opts *bind.FilterOpts, recipient []common.Address) (*SuperVaultStrategyVaultFeeConfigProposedIterator, error) {

	var recipientRule []interface{}
	for _, recipientItem := range recipient {
		recipientRule = append(recipientRule, recipientItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "VaultFeeConfigProposed", recipientRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyVaultFeeConfigProposedIterator{contract: _SuperVaultStrategy.contract, event: "VaultFeeConfigProposed", logs: logs, sub: sub}, nil
}

// WatchVaultFeeConfigProposed is a free log subscription operation binding the contract event 0xd3ae821e4db28b4e45d34b6440a80d782a5d6c82690bf26c7e8afde075ae9de2.
//
// Solidity: event VaultFeeConfigProposed(uint256 performanceFeeBps, uint256 managementFeeBps, address indexed recipient, uint256 effectiveTime)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchVaultFeeConfigProposed(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyVaultFeeConfigProposed, recipient []common.Address) (event.Subscription, error) {

	var recipientRule []interface{}
	for _, recipientItem := range recipient {
		recipientRule = append(recipientRule, recipientItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "VaultFeeConfigProposed", recipientRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyVaultFeeConfigProposed)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "VaultFeeConfigProposed", log); err != nil {
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

// ParseVaultFeeConfigProposed is a log parse operation binding the contract event 0xd3ae821e4db28b4e45d34b6440a80d782a5d6c82690bf26c7e8afde075ae9de2.
//
// Solidity: event VaultFeeConfigProposed(uint256 performanceFeeBps, uint256 managementFeeBps, address indexed recipient, uint256 effectiveTime)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseVaultFeeConfigProposed(log types.Log) (*SuperVaultStrategyVaultFeeConfigProposed, error) {
	event := new(SuperVaultStrategyVaultFeeConfigProposed)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "VaultFeeConfigProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyVaultFeeConfigUpdatedIterator is returned from FilterVaultFeeConfigUpdated and is used to iterate over the raw logs and unpacked data for VaultFeeConfigUpdated events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyVaultFeeConfigUpdatedIterator struct {
	Event *SuperVaultStrategyVaultFeeConfigUpdated // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyVaultFeeConfigUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyVaultFeeConfigUpdated)
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
		it.Event = new(SuperVaultStrategyVaultFeeConfigUpdated)
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
func (it *SuperVaultStrategyVaultFeeConfigUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyVaultFeeConfigUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyVaultFeeConfigUpdated represents a VaultFeeConfigUpdated event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyVaultFeeConfigUpdated struct {
	PerformanceFeeBps *big.Int
	ManagementFeeBps  *big.Int
	Recipient         common.Address
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterVaultFeeConfigUpdated is a free log retrieval operation binding the contract event 0x041b1399f977ad0e4a4999c4e9e555b429504d348297068ae6e554c11a84d06d.
//
// Solidity: event VaultFeeConfigUpdated(uint256 performanceFeeBps, uint256 managementFeeBps, address indexed recipient)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterVaultFeeConfigUpdated(opts *bind.FilterOpts, recipient []common.Address) (*SuperVaultStrategyVaultFeeConfigUpdatedIterator, error) {

	var recipientRule []interface{}
	for _, recipientItem := range recipient {
		recipientRule = append(recipientRule, recipientItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "VaultFeeConfigUpdated", recipientRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyVaultFeeConfigUpdatedIterator{contract: _SuperVaultStrategy.contract, event: "VaultFeeConfigUpdated", logs: logs, sub: sub}, nil
}

// WatchVaultFeeConfigUpdated is a free log subscription operation binding the contract event 0x041b1399f977ad0e4a4999c4e9e555b429504d348297068ae6e554c11a84d06d.
//
// Solidity: event VaultFeeConfigUpdated(uint256 performanceFeeBps, uint256 managementFeeBps, address indexed recipient)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchVaultFeeConfigUpdated(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyVaultFeeConfigUpdated, recipient []common.Address) (event.Subscription, error) {

	var recipientRule []interface{}
	for _, recipientItem := range recipient {
		recipientRule = append(recipientRule, recipientItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "VaultFeeConfigUpdated", recipientRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyVaultFeeConfigUpdated)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "VaultFeeConfigUpdated", log); err != nil {
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

// ParseVaultFeeConfigUpdated is a log parse operation binding the contract event 0x041b1399f977ad0e4a4999c4e9e555b429504d348297068ae6e554c11a84d06d.
//
// Solidity: event VaultFeeConfigUpdated(uint256 performanceFeeBps, uint256 managementFeeBps, address indexed recipient)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseVaultFeeConfigUpdated(log types.Log) (*SuperVaultStrategyVaultFeeConfigUpdated, error) {
	event := new(SuperVaultStrategyVaultFeeConfigUpdated)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "VaultFeeConfigUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyYieldSourceAddedIterator is returned from FilterYieldSourceAdded and is used to iterate over the raw logs and unpacked data for YieldSourceAdded events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyYieldSourceAddedIterator struct {
	Event *SuperVaultStrategyYieldSourceAdded // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyYieldSourceAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyYieldSourceAdded)
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
		it.Event = new(SuperVaultStrategyYieldSourceAdded)
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
func (it *SuperVaultStrategyYieldSourceAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyYieldSourceAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyYieldSourceAdded represents a YieldSourceAdded event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyYieldSourceAdded struct {
	Source common.Address
	Oracle common.Address
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterYieldSourceAdded is a free log retrieval operation binding the contract event 0xe707395e33aba2b86eeb8427d34294bf318cfbc202805d3452f1f9a753bb77bc.
//
// Solidity: event YieldSourceAdded(address indexed source, address indexed oracle)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterYieldSourceAdded(opts *bind.FilterOpts, source []common.Address, oracle []common.Address) (*SuperVaultStrategyYieldSourceAddedIterator, error) {

	var sourceRule []interface{}
	for _, sourceItem := range source {
		sourceRule = append(sourceRule, sourceItem)
	}
	var oracleRule []interface{}
	for _, oracleItem := range oracle {
		oracleRule = append(oracleRule, oracleItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "YieldSourceAdded", sourceRule, oracleRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyYieldSourceAddedIterator{contract: _SuperVaultStrategy.contract, event: "YieldSourceAdded", logs: logs, sub: sub}, nil
}

// WatchYieldSourceAdded is a free log subscription operation binding the contract event 0xe707395e33aba2b86eeb8427d34294bf318cfbc202805d3452f1f9a753bb77bc.
//
// Solidity: event YieldSourceAdded(address indexed source, address indexed oracle)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchYieldSourceAdded(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyYieldSourceAdded, source []common.Address, oracle []common.Address) (event.Subscription, error) {

	var sourceRule []interface{}
	for _, sourceItem := range source {
		sourceRule = append(sourceRule, sourceItem)
	}
	var oracleRule []interface{}
	for _, oracleItem := range oracle {
		oracleRule = append(oracleRule, oracleItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "YieldSourceAdded", sourceRule, oracleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyYieldSourceAdded)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "YieldSourceAdded", log); err != nil {
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

// ParseYieldSourceAdded is a log parse operation binding the contract event 0xe707395e33aba2b86eeb8427d34294bf318cfbc202805d3452f1f9a753bb77bc.
//
// Solidity: event YieldSourceAdded(address indexed source, address indexed oracle)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseYieldSourceAdded(log types.Log) (*SuperVaultStrategyYieldSourceAdded, error) {
	event := new(SuperVaultStrategyYieldSourceAdded)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "YieldSourceAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyYieldSourceOracleUpdatedIterator is returned from FilterYieldSourceOracleUpdated and is used to iterate over the raw logs and unpacked data for YieldSourceOracleUpdated events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyYieldSourceOracleUpdatedIterator struct {
	Event *SuperVaultStrategyYieldSourceOracleUpdated // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyYieldSourceOracleUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyYieldSourceOracleUpdated)
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
		it.Event = new(SuperVaultStrategyYieldSourceOracleUpdated)
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
func (it *SuperVaultStrategyYieldSourceOracleUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyYieldSourceOracleUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyYieldSourceOracleUpdated represents a YieldSourceOracleUpdated event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyYieldSourceOracleUpdated struct {
	Source    common.Address
	OldOracle common.Address
	NewOracle common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterYieldSourceOracleUpdated is a free log retrieval operation binding the contract event 0x850afc8bf4c49f8b6f53abfe029a2997d0a83103e3ad01b1e95e7ffb6470be6d.
//
// Solidity: event YieldSourceOracleUpdated(address indexed source, address indexed oldOracle, address indexed newOracle)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterYieldSourceOracleUpdated(opts *bind.FilterOpts, source []common.Address, oldOracle []common.Address, newOracle []common.Address) (*SuperVaultStrategyYieldSourceOracleUpdatedIterator, error) {

	var sourceRule []interface{}
	for _, sourceItem := range source {
		sourceRule = append(sourceRule, sourceItem)
	}
	var oldOracleRule []interface{}
	for _, oldOracleItem := range oldOracle {
		oldOracleRule = append(oldOracleRule, oldOracleItem)
	}
	var newOracleRule []interface{}
	for _, newOracleItem := range newOracle {
		newOracleRule = append(newOracleRule, newOracleItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "YieldSourceOracleUpdated", sourceRule, oldOracleRule, newOracleRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyYieldSourceOracleUpdatedIterator{contract: _SuperVaultStrategy.contract, event: "YieldSourceOracleUpdated", logs: logs, sub: sub}, nil
}

// WatchYieldSourceOracleUpdated is a free log subscription operation binding the contract event 0x850afc8bf4c49f8b6f53abfe029a2997d0a83103e3ad01b1e95e7ffb6470be6d.
//
// Solidity: event YieldSourceOracleUpdated(address indexed source, address indexed oldOracle, address indexed newOracle)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchYieldSourceOracleUpdated(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyYieldSourceOracleUpdated, source []common.Address, oldOracle []common.Address, newOracle []common.Address) (event.Subscription, error) {

	var sourceRule []interface{}
	for _, sourceItem := range source {
		sourceRule = append(sourceRule, sourceItem)
	}
	var oldOracleRule []interface{}
	for _, oldOracleItem := range oldOracle {
		oldOracleRule = append(oldOracleRule, oldOracleItem)
	}
	var newOracleRule []interface{}
	for _, newOracleItem := range newOracle {
		newOracleRule = append(newOracleRule, newOracleItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "YieldSourceOracleUpdated", sourceRule, oldOracleRule, newOracleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyYieldSourceOracleUpdated)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "YieldSourceOracleUpdated", log); err != nil {
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

// ParseYieldSourceOracleUpdated is a log parse operation binding the contract event 0x850afc8bf4c49f8b6f53abfe029a2997d0a83103e3ad01b1e95e7ffb6470be6d.
//
// Solidity: event YieldSourceOracleUpdated(address indexed source, address indexed oldOracle, address indexed newOracle)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseYieldSourceOracleUpdated(log types.Log) (*SuperVaultStrategyYieldSourceOracleUpdated, error) {
	event := new(SuperVaultStrategyYieldSourceOracleUpdated)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "YieldSourceOracleUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultStrategyYieldSourceRemovedIterator is returned from FilterYieldSourceRemoved and is used to iterate over the raw logs and unpacked data for YieldSourceRemoved events raised by the SuperVaultStrategy contract.
type SuperVaultStrategyYieldSourceRemovedIterator struct {
	Event *SuperVaultStrategyYieldSourceRemoved // Event containing the contract specifics and raw log

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
func (it *SuperVaultStrategyYieldSourceRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultStrategyYieldSourceRemoved)
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
		it.Event = new(SuperVaultStrategyYieldSourceRemoved)
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
func (it *SuperVaultStrategyYieldSourceRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultStrategyYieldSourceRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultStrategyYieldSourceRemoved represents a YieldSourceRemoved event raised by the SuperVaultStrategy contract.
type SuperVaultStrategyYieldSourceRemoved struct {
	Source common.Address
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterYieldSourceRemoved is a free log retrieval operation binding the contract event 0xe7816966a8707500235695bccaf160aa49f5d2cb6356db2408ded57832c8b916.
//
// Solidity: event YieldSourceRemoved(address indexed source)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) FilterYieldSourceRemoved(opts *bind.FilterOpts, source []common.Address) (*SuperVaultStrategyYieldSourceRemovedIterator, error) {

	var sourceRule []interface{}
	for _, sourceItem := range source {
		sourceRule = append(sourceRule, sourceItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.FilterLogs(opts, "YieldSourceRemoved", sourceRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultStrategyYieldSourceRemovedIterator{contract: _SuperVaultStrategy.contract, event: "YieldSourceRemoved", logs: logs, sub: sub}, nil
}

// WatchYieldSourceRemoved is a free log subscription operation binding the contract event 0xe7816966a8707500235695bccaf160aa49f5d2cb6356db2408ded57832c8b916.
//
// Solidity: event YieldSourceRemoved(address indexed source)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) WatchYieldSourceRemoved(opts *bind.WatchOpts, sink chan<- *SuperVaultStrategyYieldSourceRemoved, source []common.Address) (event.Subscription, error) {

	var sourceRule []interface{}
	for _, sourceItem := range source {
		sourceRule = append(sourceRule, sourceItem)
	}

	logs, sub, err := _SuperVaultStrategy.contract.WatchLogs(opts, "YieldSourceRemoved", sourceRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultStrategyYieldSourceRemoved)
				if err := _SuperVaultStrategy.contract.UnpackLog(event, "YieldSourceRemoved", log); err != nil {
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

// ParseYieldSourceRemoved is a log parse operation binding the contract event 0xe7816966a8707500235695bccaf160aa49f5d2cb6356db2408ded57832c8b916.
//
// Solidity: event YieldSourceRemoved(address indexed source)
func (_SuperVaultStrategy *SuperVaultStrategyFilterer) ParseYieldSourceRemoved(log types.Log) (*SuperVaultStrategyYieldSourceRemoved, error) {
	event := new(SuperVaultStrategyYieldSourceRemoved)
	if err := _SuperVaultStrategy.contract.UnpackLog(event, "YieldSourceRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
