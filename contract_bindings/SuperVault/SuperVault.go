// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package SuperVault

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

// SuperVaultMetaData contains all meta data concerning the SuperVault contract.
var SuperVaultMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"superGovernor_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"AUTHORIZE_OPERATOR_TYPEHASH\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"DOMAIN_SEPARATOR\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"PRECISION\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_GOVERNOR\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISuperGovernor\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"allowance\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"spender\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"approve\",\"inputs\":[{\"name\":\"spender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"asset\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"authorizations\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"nonce\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"used\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"authorizeOperator\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"nonce\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"deadline\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"signature\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"balanceOf\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"burnShares\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"cancelRedeemRequest\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"claimCancelRedeemRequest\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"claimableCancelRedeemRequest\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"claimableShares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"claimableRedeemRequest\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"claimableShares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"convertToAssets\",\"inputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"convertToShares\",\"inputs\":[{\"name\":\"assets\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"decimals\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"deposit\",\"inputs\":[{\"name\":\"assets\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"eip712Domain\",\"inputs\":[],\"outputs\":[{\"name\":\"fields\",\"type\":\"bytes1\",\"internalType\":\"bytes1\"},{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"version\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"chainId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"verifyingContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"salt\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"extensions\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"escrow\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getEscrowedAssets\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"initialize\",\"inputs\":[{\"name\":\"asset_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"name_\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"symbol_\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"strategy_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"escrow_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"invalidateNonce\",\"inputs\":[{\"name\":\"nonce\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"isOperator\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"maxDeposit\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"maxMint\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"maxRedeem\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"maxWithdraw\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"mint\",\"inputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"assets\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"name\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pendingCancelRedeemRequest\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"isPending\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pendingRedeemRequest\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"pendingShares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"previewDeposit\",\"inputs\":[{\"name\":\"assets\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"previewMint\",\"inputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"previewRedeem\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"previewWithdraw\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"redeem\",\"inputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"assets\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"requestRedeem\",\"inputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setOperator\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[{\"name\":\"success\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"share\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"strategy\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISuperVaultStrategy\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"symbol\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalAssets\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalSupply\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transfer\",\"inputs\":[{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"withdraw\",\"inputs\":[{\"name\":\"assets\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"Approval\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"spender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CancelRedeemClaim\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"controller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"requestId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CancelRedeemRequest\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"requestId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Deposit\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"assets\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EIP712DomainChanged\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Initialized\",\"inputs\":[{\"name\":\"version\",\"type\":\"uint64\",\"indexed\":false,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Initialized\",\"inputs\":[{\"name\":\"asset\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"escrow\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"NonceInvalidated\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"nonce\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OperatorSet\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RedeemRequest\",\"inputs\":[{\"name\":\"controller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"requestId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"assets\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SuperGovernorSet\",\"inputs\":[{\"name\":\"superGovernor\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Transfer\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Withdraw\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"receiver\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"assets\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"CANCELLATION_REDEEM_REQUEST_PENDING\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CONTROLLER_MUST_EQUAL_OWNER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"DEADLINE_PASSED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ECDSAInvalidSignature\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ECDSAInvalidSignatureLength\",\"inputs\":[{\"name\":\"length\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ECDSAInvalidSignatureS\",\"inputs\":[{\"name\":\"s\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"ERC20InsufficientAllowance\",\"inputs\":[{\"name\":\"spender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"allowance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"needed\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC20InsufficientBalance\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"needed\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC20InvalidApprover\",\"inputs\":[{\"name\":\"approver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC20InvalidReceiver\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC20InvalidSender\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC20InvalidSpender\",\"inputs\":[{\"name\":\"spender\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"INVALID_AMOUNT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_ASSET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_ASSET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_CONTROLLER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_NONCE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_SIGNATURE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_WITHDRAW_PRICE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidInitialization\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_ENOUGH_ASSETS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_IMPLEMENTED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NotInitializing\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"RECEIVER_MUST_EQUAL_CONTROLLER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ReentrancyGuardReentrantCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"UNAUTHORIZED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_AMOUNT\",\"inputs\":[]}]",
}

// SuperVaultABI is the input ABI used to generate the binding from.
// Deprecated: Use SuperVaultMetaData.ABI instead.
var SuperVaultABI = SuperVaultMetaData.ABI

// SuperVault is an auto generated Go binding around an Ethereum contract.
type SuperVault struct {
	SuperVaultCaller     // Read-only binding to the contract
	SuperVaultTransactor // Write-only binding to the contract
	SuperVaultFilterer   // Log filterer for contract events
}

// SuperVaultCaller is an auto generated read-only Go binding around an Ethereum contract.
type SuperVaultCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultTransactor is an auto generated write-only Go binding around an Ethereum contract.
type SuperVaultTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type SuperVaultFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type SuperVaultSession struct {
	Contract     *SuperVault       // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// SuperVaultCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type SuperVaultCallerSession struct {
	Contract *SuperVaultCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts     // Call options to use throughout this session
}

// SuperVaultTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type SuperVaultTransactorSession struct {
	Contract     *SuperVaultTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts     // Transaction auth options to use throughout this session
}

// SuperVaultRaw is an auto generated low-level Go binding around an Ethereum contract.
type SuperVaultRaw struct {
	Contract *SuperVault // Generic contract binding to access the raw methods on
}

// SuperVaultCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type SuperVaultCallerRaw struct {
	Contract *SuperVaultCaller // Generic read-only contract binding to access the raw methods on
}

// SuperVaultTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type SuperVaultTransactorRaw struct {
	Contract *SuperVaultTransactor // Generic write-only contract binding to access the raw methods on
}

// NewSuperVault creates a new instance of SuperVault, bound to a specific deployed contract.
func NewSuperVault(address common.Address, backend bind.ContractBackend) (*SuperVault, error) {
	contract, err := bindSuperVault(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &SuperVault{SuperVaultCaller: SuperVaultCaller{contract: contract}, SuperVaultTransactor: SuperVaultTransactor{contract: contract}, SuperVaultFilterer: SuperVaultFilterer{contract: contract}}, nil
}

// NewSuperVaultCaller creates a new read-only instance of SuperVault, bound to a specific deployed contract.
func NewSuperVaultCaller(address common.Address, caller bind.ContractCaller) (*SuperVaultCaller, error) {
	contract, err := bindSuperVault(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &SuperVaultCaller{contract: contract}, nil
}

// NewSuperVaultTransactor creates a new write-only instance of SuperVault, bound to a specific deployed contract.
func NewSuperVaultTransactor(address common.Address, transactor bind.ContractTransactor) (*SuperVaultTransactor, error) {
	contract, err := bindSuperVault(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &SuperVaultTransactor{contract: contract}, nil
}

// NewSuperVaultFilterer creates a new log filterer instance of SuperVault, bound to a specific deployed contract.
func NewSuperVaultFilterer(address common.Address, filterer bind.ContractFilterer) (*SuperVaultFilterer, error) {
	contract, err := bindSuperVault(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &SuperVaultFilterer{contract: contract}, nil
}

// bindSuperVault binds a generic wrapper to an already deployed contract.
func bindSuperVault(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := SuperVaultMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperVault *SuperVaultRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperVault.Contract.SuperVaultCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperVault *SuperVaultRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVault.Contract.SuperVaultTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperVault *SuperVaultRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperVault.Contract.SuperVaultTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperVault *SuperVaultCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperVault.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperVault *SuperVaultTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVault.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperVault *SuperVaultTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperVault.Contract.contract.Transact(opts, method, params...)
}

// AUTHORIZEOPERATORTYPEHASH is a free data retrieval call binding the contract method 0x0d62c332.
//
// Solidity: function AUTHORIZE_OPERATOR_TYPEHASH() view returns(bytes32)
func (_SuperVault *SuperVaultCaller) AUTHORIZEOPERATORTYPEHASH(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "AUTHORIZE_OPERATOR_TYPEHASH")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// AUTHORIZEOPERATORTYPEHASH is a free data retrieval call binding the contract method 0x0d62c332.
//
// Solidity: function AUTHORIZE_OPERATOR_TYPEHASH() view returns(bytes32)
func (_SuperVault *SuperVaultSession) AUTHORIZEOPERATORTYPEHASH() ([32]byte, error) {
	return _SuperVault.Contract.AUTHORIZEOPERATORTYPEHASH(&_SuperVault.CallOpts)
}

// AUTHORIZEOPERATORTYPEHASH is a free data retrieval call binding the contract method 0x0d62c332.
//
// Solidity: function AUTHORIZE_OPERATOR_TYPEHASH() view returns(bytes32)
func (_SuperVault *SuperVaultCallerSession) AUTHORIZEOPERATORTYPEHASH() ([32]byte, error) {
	return _SuperVault.Contract.AUTHORIZEOPERATORTYPEHASH(&_SuperVault.CallOpts)
}

// DOMAINSEPARATOR is a free data retrieval call binding the contract method 0x3644e515.
//
// Solidity: function DOMAIN_SEPARATOR() view returns(bytes32)
func (_SuperVault *SuperVaultCaller) DOMAINSEPARATOR(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "DOMAIN_SEPARATOR")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DOMAINSEPARATOR is a free data retrieval call binding the contract method 0x3644e515.
//
// Solidity: function DOMAIN_SEPARATOR() view returns(bytes32)
func (_SuperVault *SuperVaultSession) DOMAINSEPARATOR() ([32]byte, error) {
	return _SuperVault.Contract.DOMAINSEPARATOR(&_SuperVault.CallOpts)
}

// DOMAINSEPARATOR is a free data retrieval call binding the contract method 0x3644e515.
//
// Solidity: function DOMAIN_SEPARATOR() view returns(bytes32)
func (_SuperVault *SuperVaultCallerSession) DOMAINSEPARATOR() ([32]byte, error) {
	return _SuperVault.Contract.DOMAINSEPARATOR(&_SuperVault.CallOpts)
}

// PRECISION is a free data retrieval call binding the contract method 0xaaf5eb68.
//
// Solidity: function PRECISION() view returns(uint256)
func (_SuperVault *SuperVaultCaller) PRECISION(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "PRECISION")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PRECISION is a free data retrieval call binding the contract method 0xaaf5eb68.
//
// Solidity: function PRECISION() view returns(uint256)
func (_SuperVault *SuperVaultSession) PRECISION() (*big.Int, error) {
	return _SuperVault.Contract.PRECISION(&_SuperVault.CallOpts)
}

// PRECISION is a free data retrieval call binding the contract method 0xaaf5eb68.
//
// Solidity: function PRECISION() view returns(uint256)
func (_SuperVault *SuperVaultCallerSession) PRECISION() (*big.Int, error) {
	return _SuperVault.Contract.PRECISION(&_SuperVault.CallOpts)
}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_SuperVault *SuperVaultCaller) SUPERGOVERNOR(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "SUPER_GOVERNOR")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_SuperVault *SuperVaultSession) SUPERGOVERNOR() (common.Address, error) {
	return _SuperVault.Contract.SUPERGOVERNOR(&_SuperVault.CallOpts)
}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_SuperVault *SuperVaultCallerSession) SUPERGOVERNOR() (common.Address, error) {
	return _SuperVault.Contract.SUPERGOVERNOR(&_SuperVault.CallOpts)
}

// Allowance is a free data retrieval call binding the contract method 0xdd62ed3e.
//
// Solidity: function allowance(address owner, address spender) view returns(uint256)
func (_SuperVault *SuperVaultCaller) Allowance(opts *bind.CallOpts, owner common.Address, spender common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "allowance", owner, spender)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Allowance is a free data retrieval call binding the contract method 0xdd62ed3e.
//
// Solidity: function allowance(address owner, address spender) view returns(uint256)
func (_SuperVault *SuperVaultSession) Allowance(owner common.Address, spender common.Address) (*big.Int, error) {
	return _SuperVault.Contract.Allowance(&_SuperVault.CallOpts, owner, spender)
}

// Allowance is a free data retrieval call binding the contract method 0xdd62ed3e.
//
// Solidity: function allowance(address owner, address spender) view returns(uint256)
func (_SuperVault *SuperVaultCallerSession) Allowance(owner common.Address, spender common.Address) (*big.Int, error) {
	return _SuperVault.Contract.Allowance(&_SuperVault.CallOpts, owner, spender)
}

// Asset is a free data retrieval call binding the contract method 0x38d52e0f.
//
// Solidity: function asset() view returns(address)
func (_SuperVault *SuperVaultCaller) Asset(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "asset")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Asset is a free data retrieval call binding the contract method 0x38d52e0f.
//
// Solidity: function asset() view returns(address)
func (_SuperVault *SuperVaultSession) Asset() (common.Address, error) {
	return _SuperVault.Contract.Asset(&_SuperVault.CallOpts)
}

// Asset is a free data retrieval call binding the contract method 0x38d52e0f.
//
// Solidity: function asset() view returns(address)
func (_SuperVault *SuperVaultCallerSession) Asset() (common.Address, error) {
	return _SuperVault.Contract.Asset(&_SuperVault.CallOpts)
}

// Authorizations is a free data retrieval call binding the contract method 0xcdf5bba3.
//
// Solidity: function authorizations(address controller, bytes32 nonce) view returns(bool used)
func (_SuperVault *SuperVaultCaller) Authorizations(opts *bind.CallOpts, controller common.Address, nonce [32]byte) (bool, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "authorizations", controller, nonce)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Authorizations is a free data retrieval call binding the contract method 0xcdf5bba3.
//
// Solidity: function authorizations(address controller, bytes32 nonce) view returns(bool used)
func (_SuperVault *SuperVaultSession) Authorizations(controller common.Address, nonce [32]byte) (bool, error) {
	return _SuperVault.Contract.Authorizations(&_SuperVault.CallOpts, controller, nonce)
}

// Authorizations is a free data retrieval call binding the contract method 0xcdf5bba3.
//
// Solidity: function authorizations(address controller, bytes32 nonce) view returns(bool used)
func (_SuperVault *SuperVaultCallerSession) Authorizations(controller common.Address, nonce [32]byte) (bool, error) {
	return _SuperVault.Contract.Authorizations(&_SuperVault.CallOpts, controller, nonce)
}

// BalanceOf is a free data retrieval call binding the contract method 0x70a08231.
//
// Solidity: function balanceOf(address account) view returns(uint256)
func (_SuperVault *SuperVaultCaller) BalanceOf(opts *bind.CallOpts, account common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "balanceOf", account)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BalanceOf is a free data retrieval call binding the contract method 0x70a08231.
//
// Solidity: function balanceOf(address account) view returns(uint256)
func (_SuperVault *SuperVaultSession) BalanceOf(account common.Address) (*big.Int, error) {
	return _SuperVault.Contract.BalanceOf(&_SuperVault.CallOpts, account)
}

// BalanceOf is a free data retrieval call binding the contract method 0x70a08231.
//
// Solidity: function balanceOf(address account) view returns(uint256)
func (_SuperVault *SuperVaultCallerSession) BalanceOf(account common.Address) (*big.Int, error) {
	return _SuperVault.Contract.BalanceOf(&_SuperVault.CallOpts, account)
}

// ClaimableCancelRedeemRequest is a free data retrieval call binding the contract method 0xb04a5e05.
//
// Solidity: function claimableCancelRedeemRequest(uint256 , address controller) view returns(uint256 claimableShares)
func (_SuperVault *SuperVaultCaller) ClaimableCancelRedeemRequest(opts *bind.CallOpts, arg0 *big.Int, controller common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "claimableCancelRedeemRequest", arg0, controller)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ClaimableCancelRedeemRequest is a free data retrieval call binding the contract method 0xb04a5e05.
//
// Solidity: function claimableCancelRedeemRequest(uint256 , address controller) view returns(uint256 claimableShares)
func (_SuperVault *SuperVaultSession) ClaimableCancelRedeemRequest(arg0 *big.Int, controller common.Address) (*big.Int, error) {
	return _SuperVault.Contract.ClaimableCancelRedeemRequest(&_SuperVault.CallOpts, arg0, controller)
}

// ClaimableCancelRedeemRequest is a free data retrieval call binding the contract method 0xb04a5e05.
//
// Solidity: function claimableCancelRedeemRequest(uint256 , address controller) view returns(uint256 claimableShares)
func (_SuperVault *SuperVaultCallerSession) ClaimableCancelRedeemRequest(arg0 *big.Int, controller common.Address) (*big.Int, error) {
	return _SuperVault.Contract.ClaimableCancelRedeemRequest(&_SuperVault.CallOpts, arg0, controller)
}

// ClaimableRedeemRequest is a free data retrieval call binding the contract method 0xeaed1d07.
//
// Solidity: function claimableRedeemRequest(uint256 , address controller) view returns(uint256 claimableShares)
func (_SuperVault *SuperVaultCaller) ClaimableRedeemRequest(opts *bind.CallOpts, arg0 *big.Int, controller common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "claimableRedeemRequest", arg0, controller)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ClaimableRedeemRequest is a free data retrieval call binding the contract method 0xeaed1d07.
//
// Solidity: function claimableRedeemRequest(uint256 , address controller) view returns(uint256 claimableShares)
func (_SuperVault *SuperVaultSession) ClaimableRedeemRequest(arg0 *big.Int, controller common.Address) (*big.Int, error) {
	return _SuperVault.Contract.ClaimableRedeemRequest(&_SuperVault.CallOpts, arg0, controller)
}

// ClaimableRedeemRequest is a free data retrieval call binding the contract method 0xeaed1d07.
//
// Solidity: function claimableRedeemRequest(uint256 , address controller) view returns(uint256 claimableShares)
func (_SuperVault *SuperVaultCallerSession) ClaimableRedeemRequest(arg0 *big.Int, controller common.Address) (*big.Int, error) {
	return _SuperVault.Contract.ClaimableRedeemRequest(&_SuperVault.CallOpts, arg0, controller)
}

// ConvertToAssets is a free data retrieval call binding the contract method 0x07a2d13a.
//
// Solidity: function convertToAssets(uint256 shares) view returns(uint256)
func (_SuperVault *SuperVaultCaller) ConvertToAssets(opts *bind.CallOpts, shares *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "convertToAssets", shares)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ConvertToAssets is a free data retrieval call binding the contract method 0x07a2d13a.
//
// Solidity: function convertToAssets(uint256 shares) view returns(uint256)
func (_SuperVault *SuperVaultSession) ConvertToAssets(shares *big.Int) (*big.Int, error) {
	return _SuperVault.Contract.ConvertToAssets(&_SuperVault.CallOpts, shares)
}

// ConvertToAssets is a free data retrieval call binding the contract method 0x07a2d13a.
//
// Solidity: function convertToAssets(uint256 shares) view returns(uint256)
func (_SuperVault *SuperVaultCallerSession) ConvertToAssets(shares *big.Int) (*big.Int, error) {
	return _SuperVault.Contract.ConvertToAssets(&_SuperVault.CallOpts, shares)
}

// ConvertToShares is a free data retrieval call binding the contract method 0xc6e6f592.
//
// Solidity: function convertToShares(uint256 assets) view returns(uint256)
func (_SuperVault *SuperVaultCaller) ConvertToShares(opts *bind.CallOpts, assets *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "convertToShares", assets)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ConvertToShares is a free data retrieval call binding the contract method 0xc6e6f592.
//
// Solidity: function convertToShares(uint256 assets) view returns(uint256)
func (_SuperVault *SuperVaultSession) ConvertToShares(assets *big.Int) (*big.Int, error) {
	return _SuperVault.Contract.ConvertToShares(&_SuperVault.CallOpts, assets)
}

// ConvertToShares is a free data retrieval call binding the contract method 0xc6e6f592.
//
// Solidity: function convertToShares(uint256 assets) view returns(uint256)
func (_SuperVault *SuperVaultCallerSession) ConvertToShares(assets *big.Int) (*big.Int, error) {
	return _SuperVault.Contract.ConvertToShares(&_SuperVault.CallOpts, assets)
}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint8)
func (_SuperVault *SuperVaultCaller) Decimals(opts *bind.CallOpts) (uint8, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "decimals")

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint8)
func (_SuperVault *SuperVaultSession) Decimals() (uint8, error) {
	return _SuperVault.Contract.Decimals(&_SuperVault.CallOpts)
}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint8)
func (_SuperVault *SuperVaultCallerSession) Decimals() (uint8, error) {
	return _SuperVault.Contract.Decimals(&_SuperVault.CallOpts)
}

// Eip712Domain is a free data retrieval call binding the contract method 0x84b0196e.
//
// Solidity: function eip712Domain() view returns(bytes1 fields, string name, string version, uint256 chainId, address verifyingContract, bytes32 salt, uint256[] extensions)
func (_SuperVault *SuperVaultCaller) Eip712Domain(opts *bind.CallOpts) (struct {
	Fields            [1]byte
	Name              string
	Version           string
	ChainId           *big.Int
	VerifyingContract common.Address
	Salt              [32]byte
	Extensions        []*big.Int
}, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "eip712Domain")

	outstruct := new(struct {
		Fields            [1]byte
		Name              string
		Version           string
		ChainId           *big.Int
		VerifyingContract common.Address
		Salt              [32]byte
		Extensions        []*big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Fields = *abi.ConvertType(out[0], new([1]byte)).(*[1]byte)
	outstruct.Name = *abi.ConvertType(out[1], new(string)).(*string)
	outstruct.Version = *abi.ConvertType(out[2], new(string)).(*string)
	outstruct.ChainId = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)
	outstruct.VerifyingContract = *abi.ConvertType(out[4], new(common.Address)).(*common.Address)
	outstruct.Salt = *abi.ConvertType(out[5], new([32]byte)).(*[32]byte)
	outstruct.Extensions = *abi.ConvertType(out[6], new([]*big.Int)).(*[]*big.Int)

	return *outstruct, err

}

// Eip712Domain is a free data retrieval call binding the contract method 0x84b0196e.
//
// Solidity: function eip712Domain() view returns(bytes1 fields, string name, string version, uint256 chainId, address verifyingContract, bytes32 salt, uint256[] extensions)
func (_SuperVault *SuperVaultSession) Eip712Domain() (struct {
	Fields            [1]byte
	Name              string
	Version           string
	ChainId           *big.Int
	VerifyingContract common.Address
	Salt              [32]byte
	Extensions        []*big.Int
}, error) {
	return _SuperVault.Contract.Eip712Domain(&_SuperVault.CallOpts)
}

// Eip712Domain is a free data retrieval call binding the contract method 0x84b0196e.
//
// Solidity: function eip712Domain() view returns(bytes1 fields, string name, string version, uint256 chainId, address verifyingContract, bytes32 salt, uint256[] extensions)
func (_SuperVault *SuperVaultCallerSession) Eip712Domain() (struct {
	Fields            [1]byte
	Name              string
	Version           string
	ChainId           *big.Int
	VerifyingContract common.Address
	Salt              [32]byte
	Extensions        []*big.Int
}, error) {
	return _SuperVault.Contract.Eip712Domain(&_SuperVault.CallOpts)
}

// Escrow is a free data retrieval call binding the contract method 0xe2fdcc17.
//
// Solidity: function escrow() view returns(address)
func (_SuperVault *SuperVaultCaller) Escrow(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "escrow")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Escrow is a free data retrieval call binding the contract method 0xe2fdcc17.
//
// Solidity: function escrow() view returns(address)
func (_SuperVault *SuperVaultSession) Escrow() (common.Address, error) {
	return _SuperVault.Contract.Escrow(&_SuperVault.CallOpts)
}

// Escrow is a free data retrieval call binding the contract method 0xe2fdcc17.
//
// Solidity: function escrow() view returns(address)
func (_SuperVault *SuperVaultCallerSession) Escrow() (common.Address, error) {
	return _SuperVault.Contract.Escrow(&_SuperVault.CallOpts)
}

// GetEscrowedAssets is a free data retrieval call binding the contract method 0x4cd667d2.
//
// Solidity: function getEscrowedAssets() view returns(uint256)
func (_SuperVault *SuperVaultCaller) GetEscrowedAssets(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "getEscrowedAssets")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetEscrowedAssets is a free data retrieval call binding the contract method 0x4cd667d2.
//
// Solidity: function getEscrowedAssets() view returns(uint256)
func (_SuperVault *SuperVaultSession) GetEscrowedAssets() (*big.Int, error) {
	return _SuperVault.Contract.GetEscrowedAssets(&_SuperVault.CallOpts)
}

// GetEscrowedAssets is a free data retrieval call binding the contract method 0x4cd667d2.
//
// Solidity: function getEscrowedAssets() view returns(uint256)
func (_SuperVault *SuperVaultCallerSession) GetEscrowedAssets() (*big.Int, error) {
	return _SuperVault.Contract.GetEscrowedAssets(&_SuperVault.CallOpts)
}

// IsOperator is a free data retrieval call binding the contract method 0xb6363cf2.
//
// Solidity: function isOperator(address owner, address operator) view returns(bool)
func (_SuperVault *SuperVaultCaller) IsOperator(opts *bind.CallOpts, owner common.Address, operator common.Address) (bool, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "isOperator", owner, operator)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsOperator is a free data retrieval call binding the contract method 0xb6363cf2.
//
// Solidity: function isOperator(address owner, address operator) view returns(bool)
func (_SuperVault *SuperVaultSession) IsOperator(owner common.Address, operator common.Address) (bool, error) {
	return _SuperVault.Contract.IsOperator(&_SuperVault.CallOpts, owner, operator)
}

// IsOperator is a free data retrieval call binding the contract method 0xb6363cf2.
//
// Solidity: function isOperator(address owner, address operator) view returns(bool)
func (_SuperVault *SuperVaultCallerSession) IsOperator(owner common.Address, operator common.Address) (bool, error) {
	return _SuperVault.Contract.IsOperator(&_SuperVault.CallOpts, owner, operator)
}

// MaxDeposit is a free data retrieval call binding the contract method 0x402d267d.
//
// Solidity: function maxDeposit(address ) view returns(uint256)
func (_SuperVault *SuperVaultCaller) MaxDeposit(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "maxDeposit", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MaxDeposit is a free data retrieval call binding the contract method 0x402d267d.
//
// Solidity: function maxDeposit(address ) view returns(uint256)
func (_SuperVault *SuperVaultSession) MaxDeposit(arg0 common.Address) (*big.Int, error) {
	return _SuperVault.Contract.MaxDeposit(&_SuperVault.CallOpts, arg0)
}

// MaxDeposit is a free data retrieval call binding the contract method 0x402d267d.
//
// Solidity: function maxDeposit(address ) view returns(uint256)
func (_SuperVault *SuperVaultCallerSession) MaxDeposit(arg0 common.Address) (*big.Int, error) {
	return _SuperVault.Contract.MaxDeposit(&_SuperVault.CallOpts, arg0)
}

// MaxMint is a free data retrieval call binding the contract method 0xc63d75b6.
//
// Solidity: function maxMint(address ) view returns(uint256)
func (_SuperVault *SuperVaultCaller) MaxMint(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "maxMint", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MaxMint is a free data retrieval call binding the contract method 0xc63d75b6.
//
// Solidity: function maxMint(address ) view returns(uint256)
func (_SuperVault *SuperVaultSession) MaxMint(arg0 common.Address) (*big.Int, error) {
	return _SuperVault.Contract.MaxMint(&_SuperVault.CallOpts, arg0)
}

// MaxMint is a free data retrieval call binding the contract method 0xc63d75b6.
//
// Solidity: function maxMint(address ) view returns(uint256)
func (_SuperVault *SuperVaultCallerSession) MaxMint(arg0 common.Address) (*big.Int, error) {
	return _SuperVault.Contract.MaxMint(&_SuperVault.CallOpts, arg0)
}

// MaxRedeem is a free data retrieval call binding the contract method 0xd905777e.
//
// Solidity: function maxRedeem(address owner) view returns(uint256)
func (_SuperVault *SuperVaultCaller) MaxRedeem(opts *bind.CallOpts, owner common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "maxRedeem", owner)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MaxRedeem is a free data retrieval call binding the contract method 0xd905777e.
//
// Solidity: function maxRedeem(address owner) view returns(uint256)
func (_SuperVault *SuperVaultSession) MaxRedeem(owner common.Address) (*big.Int, error) {
	return _SuperVault.Contract.MaxRedeem(&_SuperVault.CallOpts, owner)
}

// MaxRedeem is a free data retrieval call binding the contract method 0xd905777e.
//
// Solidity: function maxRedeem(address owner) view returns(uint256)
func (_SuperVault *SuperVaultCallerSession) MaxRedeem(owner common.Address) (*big.Int, error) {
	return _SuperVault.Contract.MaxRedeem(&_SuperVault.CallOpts, owner)
}

// MaxWithdraw is a free data retrieval call binding the contract method 0xce96cb77.
//
// Solidity: function maxWithdraw(address owner) view returns(uint256)
func (_SuperVault *SuperVaultCaller) MaxWithdraw(opts *bind.CallOpts, owner common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "maxWithdraw", owner)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MaxWithdraw is a free data retrieval call binding the contract method 0xce96cb77.
//
// Solidity: function maxWithdraw(address owner) view returns(uint256)
func (_SuperVault *SuperVaultSession) MaxWithdraw(owner common.Address) (*big.Int, error) {
	return _SuperVault.Contract.MaxWithdraw(&_SuperVault.CallOpts, owner)
}

// MaxWithdraw is a free data retrieval call binding the contract method 0xce96cb77.
//
// Solidity: function maxWithdraw(address owner) view returns(uint256)
func (_SuperVault *SuperVaultCallerSession) MaxWithdraw(owner common.Address) (*big.Int, error) {
	return _SuperVault.Contract.MaxWithdraw(&_SuperVault.CallOpts, owner)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_SuperVault *SuperVaultCaller) Name(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "name")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_SuperVault *SuperVaultSession) Name() (string, error) {
	return _SuperVault.Contract.Name(&_SuperVault.CallOpts)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_SuperVault *SuperVaultCallerSession) Name() (string, error) {
	return _SuperVault.Contract.Name(&_SuperVault.CallOpts)
}

// PendingCancelRedeemRequest is a free data retrieval call binding the contract method 0x7c1b50c4.
//
// Solidity: function pendingCancelRedeemRequest(uint256 , address controller) view returns(bool isPending)
func (_SuperVault *SuperVaultCaller) PendingCancelRedeemRequest(opts *bind.CallOpts, arg0 *big.Int, controller common.Address) (bool, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "pendingCancelRedeemRequest", arg0, controller)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// PendingCancelRedeemRequest is a free data retrieval call binding the contract method 0x7c1b50c4.
//
// Solidity: function pendingCancelRedeemRequest(uint256 , address controller) view returns(bool isPending)
func (_SuperVault *SuperVaultSession) PendingCancelRedeemRequest(arg0 *big.Int, controller common.Address) (bool, error) {
	return _SuperVault.Contract.PendingCancelRedeemRequest(&_SuperVault.CallOpts, arg0, controller)
}

// PendingCancelRedeemRequest is a free data retrieval call binding the contract method 0x7c1b50c4.
//
// Solidity: function pendingCancelRedeemRequest(uint256 , address controller) view returns(bool isPending)
func (_SuperVault *SuperVaultCallerSession) PendingCancelRedeemRequest(arg0 *big.Int, controller common.Address) (bool, error) {
	return _SuperVault.Contract.PendingCancelRedeemRequest(&_SuperVault.CallOpts, arg0, controller)
}

// PendingRedeemRequest is a free data retrieval call binding the contract method 0xf5a23d8d.
//
// Solidity: function pendingRedeemRequest(uint256 , address controller) view returns(uint256 pendingShares)
func (_SuperVault *SuperVaultCaller) PendingRedeemRequest(opts *bind.CallOpts, arg0 *big.Int, controller common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "pendingRedeemRequest", arg0, controller)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PendingRedeemRequest is a free data retrieval call binding the contract method 0xf5a23d8d.
//
// Solidity: function pendingRedeemRequest(uint256 , address controller) view returns(uint256 pendingShares)
func (_SuperVault *SuperVaultSession) PendingRedeemRequest(arg0 *big.Int, controller common.Address) (*big.Int, error) {
	return _SuperVault.Contract.PendingRedeemRequest(&_SuperVault.CallOpts, arg0, controller)
}

// PendingRedeemRequest is a free data retrieval call binding the contract method 0xf5a23d8d.
//
// Solidity: function pendingRedeemRequest(uint256 , address controller) view returns(uint256 pendingShares)
func (_SuperVault *SuperVaultCallerSession) PendingRedeemRequest(arg0 *big.Int, controller common.Address) (*big.Int, error) {
	return _SuperVault.Contract.PendingRedeemRequest(&_SuperVault.CallOpts, arg0, controller)
}

// PreviewDeposit is a free data retrieval call binding the contract method 0xef8b30f7.
//
// Solidity: function previewDeposit(uint256 assets) view returns(uint256)
func (_SuperVault *SuperVaultCaller) PreviewDeposit(opts *bind.CallOpts, assets *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "previewDeposit", assets)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PreviewDeposit is a free data retrieval call binding the contract method 0xef8b30f7.
//
// Solidity: function previewDeposit(uint256 assets) view returns(uint256)
func (_SuperVault *SuperVaultSession) PreviewDeposit(assets *big.Int) (*big.Int, error) {
	return _SuperVault.Contract.PreviewDeposit(&_SuperVault.CallOpts, assets)
}

// PreviewDeposit is a free data retrieval call binding the contract method 0xef8b30f7.
//
// Solidity: function previewDeposit(uint256 assets) view returns(uint256)
func (_SuperVault *SuperVaultCallerSession) PreviewDeposit(assets *big.Int) (*big.Int, error) {
	return _SuperVault.Contract.PreviewDeposit(&_SuperVault.CallOpts, assets)
}

// PreviewMint is a free data retrieval call binding the contract method 0xb3d7f6b9.
//
// Solidity: function previewMint(uint256 shares) view returns(uint256)
func (_SuperVault *SuperVaultCaller) PreviewMint(opts *bind.CallOpts, shares *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "previewMint", shares)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PreviewMint is a free data retrieval call binding the contract method 0xb3d7f6b9.
//
// Solidity: function previewMint(uint256 shares) view returns(uint256)
func (_SuperVault *SuperVaultSession) PreviewMint(shares *big.Int) (*big.Int, error) {
	return _SuperVault.Contract.PreviewMint(&_SuperVault.CallOpts, shares)
}

// PreviewMint is a free data retrieval call binding the contract method 0xb3d7f6b9.
//
// Solidity: function previewMint(uint256 shares) view returns(uint256)
func (_SuperVault *SuperVaultCallerSession) PreviewMint(shares *big.Int) (*big.Int, error) {
	return _SuperVault.Contract.PreviewMint(&_SuperVault.CallOpts, shares)
}

// PreviewRedeem is a free data retrieval call binding the contract method 0x4cdad506.
//
// Solidity: function previewRedeem(uint256 ) pure returns(uint256)
func (_SuperVault *SuperVaultCaller) PreviewRedeem(opts *bind.CallOpts, arg0 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "previewRedeem", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PreviewRedeem is a free data retrieval call binding the contract method 0x4cdad506.
//
// Solidity: function previewRedeem(uint256 ) pure returns(uint256)
func (_SuperVault *SuperVaultSession) PreviewRedeem(arg0 *big.Int) (*big.Int, error) {
	return _SuperVault.Contract.PreviewRedeem(&_SuperVault.CallOpts, arg0)
}

// PreviewRedeem is a free data retrieval call binding the contract method 0x4cdad506.
//
// Solidity: function previewRedeem(uint256 ) pure returns(uint256)
func (_SuperVault *SuperVaultCallerSession) PreviewRedeem(arg0 *big.Int) (*big.Int, error) {
	return _SuperVault.Contract.PreviewRedeem(&_SuperVault.CallOpts, arg0)
}

// PreviewWithdraw is a free data retrieval call binding the contract method 0x0a28a477.
//
// Solidity: function previewWithdraw(uint256 ) pure returns(uint256)
func (_SuperVault *SuperVaultCaller) PreviewWithdraw(opts *bind.CallOpts, arg0 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "previewWithdraw", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PreviewWithdraw is a free data retrieval call binding the contract method 0x0a28a477.
//
// Solidity: function previewWithdraw(uint256 ) pure returns(uint256)
func (_SuperVault *SuperVaultSession) PreviewWithdraw(arg0 *big.Int) (*big.Int, error) {
	return _SuperVault.Contract.PreviewWithdraw(&_SuperVault.CallOpts, arg0)
}

// PreviewWithdraw is a free data retrieval call binding the contract method 0x0a28a477.
//
// Solidity: function previewWithdraw(uint256 ) pure returns(uint256)
func (_SuperVault *SuperVaultCallerSession) PreviewWithdraw(arg0 *big.Int) (*big.Int, error) {
	return _SuperVault.Contract.PreviewWithdraw(&_SuperVault.CallOpts, arg0)
}

// Share is a free data retrieval call binding the contract method 0xa8d5fd65.
//
// Solidity: function share() view returns(address)
func (_SuperVault *SuperVaultCaller) Share(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "share")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Share is a free data retrieval call binding the contract method 0xa8d5fd65.
//
// Solidity: function share() view returns(address)
func (_SuperVault *SuperVaultSession) Share() (common.Address, error) {
	return _SuperVault.Contract.Share(&_SuperVault.CallOpts)
}

// Share is a free data retrieval call binding the contract method 0xa8d5fd65.
//
// Solidity: function share() view returns(address)
func (_SuperVault *SuperVaultCallerSession) Share() (common.Address, error) {
	return _SuperVault.Contract.Share(&_SuperVault.CallOpts)
}

// Strategy is a free data retrieval call binding the contract method 0xa8c62e76.
//
// Solidity: function strategy() view returns(address)
func (_SuperVault *SuperVaultCaller) Strategy(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "strategy")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Strategy is a free data retrieval call binding the contract method 0xa8c62e76.
//
// Solidity: function strategy() view returns(address)
func (_SuperVault *SuperVaultSession) Strategy() (common.Address, error) {
	return _SuperVault.Contract.Strategy(&_SuperVault.CallOpts)
}

// Strategy is a free data retrieval call binding the contract method 0xa8c62e76.
//
// Solidity: function strategy() view returns(address)
func (_SuperVault *SuperVaultCallerSession) Strategy() (common.Address, error) {
	return _SuperVault.Contract.Strategy(&_SuperVault.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) pure returns(bool)
func (_SuperVault *SuperVaultCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) pure returns(bool)
func (_SuperVault *SuperVaultSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _SuperVault.Contract.SupportsInterface(&_SuperVault.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) pure returns(bool)
func (_SuperVault *SuperVaultCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _SuperVault.Contract.SupportsInterface(&_SuperVault.CallOpts, interfaceId)
}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_SuperVault *SuperVaultCaller) Symbol(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "symbol")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_SuperVault *SuperVaultSession) Symbol() (string, error) {
	return _SuperVault.Contract.Symbol(&_SuperVault.CallOpts)
}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_SuperVault *SuperVaultCallerSession) Symbol() (string, error) {
	return _SuperVault.Contract.Symbol(&_SuperVault.CallOpts)
}

// TotalAssets is a free data retrieval call binding the contract method 0x01e1d114.
//
// Solidity: function totalAssets() view returns(uint256)
func (_SuperVault *SuperVaultCaller) TotalAssets(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "totalAssets")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalAssets is a free data retrieval call binding the contract method 0x01e1d114.
//
// Solidity: function totalAssets() view returns(uint256)
func (_SuperVault *SuperVaultSession) TotalAssets() (*big.Int, error) {
	return _SuperVault.Contract.TotalAssets(&_SuperVault.CallOpts)
}

// TotalAssets is a free data retrieval call binding the contract method 0x01e1d114.
//
// Solidity: function totalAssets() view returns(uint256)
func (_SuperVault *SuperVaultCallerSession) TotalAssets() (*big.Int, error) {
	return _SuperVault.Contract.TotalAssets(&_SuperVault.CallOpts)
}

// TotalSupply is a free data retrieval call binding the contract method 0x18160ddd.
//
// Solidity: function totalSupply() view returns(uint256)
func (_SuperVault *SuperVaultCaller) TotalSupply(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVault.contract.Call(opts, &out, "totalSupply")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalSupply is a free data retrieval call binding the contract method 0x18160ddd.
//
// Solidity: function totalSupply() view returns(uint256)
func (_SuperVault *SuperVaultSession) TotalSupply() (*big.Int, error) {
	return _SuperVault.Contract.TotalSupply(&_SuperVault.CallOpts)
}

// TotalSupply is a free data retrieval call binding the contract method 0x18160ddd.
//
// Solidity: function totalSupply() view returns(uint256)
func (_SuperVault *SuperVaultCallerSession) TotalSupply() (*big.Int, error) {
	return _SuperVault.Contract.TotalSupply(&_SuperVault.CallOpts)
}

// Approve is a paid mutator transaction binding the contract method 0x095ea7b3.
//
// Solidity: function approve(address spender, uint256 value) returns(bool)
func (_SuperVault *SuperVaultTransactor) Approve(opts *bind.TransactOpts, spender common.Address, value *big.Int) (*types.Transaction, error) {
	return _SuperVault.contract.Transact(opts, "approve", spender, value)
}

// Approve is a paid mutator transaction binding the contract method 0x095ea7b3.
//
// Solidity: function approve(address spender, uint256 value) returns(bool)
func (_SuperVault *SuperVaultSession) Approve(spender common.Address, value *big.Int) (*types.Transaction, error) {
	return _SuperVault.Contract.Approve(&_SuperVault.TransactOpts, spender, value)
}

// Approve is a paid mutator transaction binding the contract method 0x095ea7b3.
//
// Solidity: function approve(address spender, uint256 value) returns(bool)
func (_SuperVault *SuperVaultTransactorSession) Approve(spender common.Address, value *big.Int) (*types.Transaction, error) {
	return _SuperVault.Contract.Approve(&_SuperVault.TransactOpts, spender, value)
}

// AuthorizeOperator is a paid mutator transaction binding the contract method 0x711b58ff.
//
// Solidity: function authorizeOperator(address controller, address operator, bool approved, bytes32 nonce, uint256 deadline, bytes signature) returns(bool)
func (_SuperVault *SuperVaultTransactor) AuthorizeOperator(opts *bind.TransactOpts, controller common.Address, operator common.Address, approved bool, nonce [32]byte, deadline *big.Int, signature []byte) (*types.Transaction, error) {
	return _SuperVault.contract.Transact(opts, "authorizeOperator", controller, operator, approved, nonce, deadline, signature)
}

// AuthorizeOperator is a paid mutator transaction binding the contract method 0x711b58ff.
//
// Solidity: function authorizeOperator(address controller, address operator, bool approved, bytes32 nonce, uint256 deadline, bytes signature) returns(bool)
func (_SuperVault *SuperVaultSession) AuthorizeOperator(controller common.Address, operator common.Address, approved bool, nonce [32]byte, deadline *big.Int, signature []byte) (*types.Transaction, error) {
	return _SuperVault.Contract.AuthorizeOperator(&_SuperVault.TransactOpts, controller, operator, approved, nonce, deadline, signature)
}

// AuthorizeOperator is a paid mutator transaction binding the contract method 0x711b58ff.
//
// Solidity: function authorizeOperator(address controller, address operator, bool approved, bytes32 nonce, uint256 deadline, bytes signature) returns(bool)
func (_SuperVault *SuperVaultTransactorSession) AuthorizeOperator(controller common.Address, operator common.Address, approved bool, nonce [32]byte, deadline *big.Int, signature []byte) (*types.Transaction, error) {
	return _SuperVault.Contract.AuthorizeOperator(&_SuperVault.TransactOpts, controller, operator, approved, nonce, deadline, signature)
}

// BurnShares is a paid mutator transaction binding the contract method 0x853c637d.
//
// Solidity: function burnShares(uint256 amount) returns()
func (_SuperVault *SuperVaultTransactor) BurnShares(opts *bind.TransactOpts, amount *big.Int) (*types.Transaction, error) {
	return _SuperVault.contract.Transact(opts, "burnShares", amount)
}

// BurnShares is a paid mutator transaction binding the contract method 0x853c637d.
//
// Solidity: function burnShares(uint256 amount) returns()
func (_SuperVault *SuperVaultSession) BurnShares(amount *big.Int) (*types.Transaction, error) {
	return _SuperVault.Contract.BurnShares(&_SuperVault.TransactOpts, amount)
}

// BurnShares is a paid mutator transaction binding the contract method 0x853c637d.
//
// Solidity: function burnShares(uint256 amount) returns()
func (_SuperVault *SuperVaultTransactorSession) BurnShares(amount *big.Int) (*types.Transaction, error) {
	return _SuperVault.Contract.BurnShares(&_SuperVault.TransactOpts, amount)
}

// CancelRedeemRequest is a paid mutator transaction binding the contract method 0x2b9d9c1f.
//
// Solidity: function cancelRedeemRequest(uint256 , address controller) returns()
func (_SuperVault *SuperVaultTransactor) CancelRedeemRequest(opts *bind.TransactOpts, arg0 *big.Int, controller common.Address) (*types.Transaction, error) {
	return _SuperVault.contract.Transact(opts, "cancelRedeemRequest", arg0, controller)
}

// CancelRedeemRequest is a paid mutator transaction binding the contract method 0x2b9d9c1f.
//
// Solidity: function cancelRedeemRequest(uint256 , address controller) returns()
func (_SuperVault *SuperVaultSession) CancelRedeemRequest(arg0 *big.Int, controller common.Address) (*types.Transaction, error) {
	return _SuperVault.Contract.CancelRedeemRequest(&_SuperVault.TransactOpts, arg0, controller)
}

// CancelRedeemRequest is a paid mutator transaction binding the contract method 0x2b9d9c1f.
//
// Solidity: function cancelRedeemRequest(uint256 , address controller) returns()
func (_SuperVault *SuperVaultTransactorSession) CancelRedeemRequest(arg0 *big.Int, controller common.Address) (*types.Transaction, error) {
	return _SuperVault.Contract.CancelRedeemRequest(&_SuperVault.TransactOpts, arg0, controller)
}

// ClaimCancelRedeemRequest is a paid mutator transaction binding the contract method 0x00a06d19.
//
// Solidity: function claimCancelRedeemRequest(uint256 , address receiver, address controller) returns(uint256 shares)
func (_SuperVault *SuperVaultTransactor) ClaimCancelRedeemRequest(opts *bind.TransactOpts, arg0 *big.Int, receiver common.Address, controller common.Address) (*types.Transaction, error) {
	return _SuperVault.contract.Transact(opts, "claimCancelRedeemRequest", arg0, receiver, controller)
}

// ClaimCancelRedeemRequest is a paid mutator transaction binding the contract method 0x00a06d19.
//
// Solidity: function claimCancelRedeemRequest(uint256 , address receiver, address controller) returns(uint256 shares)
func (_SuperVault *SuperVaultSession) ClaimCancelRedeemRequest(arg0 *big.Int, receiver common.Address, controller common.Address) (*types.Transaction, error) {
	return _SuperVault.Contract.ClaimCancelRedeemRequest(&_SuperVault.TransactOpts, arg0, receiver, controller)
}

// ClaimCancelRedeemRequest is a paid mutator transaction binding the contract method 0x00a06d19.
//
// Solidity: function claimCancelRedeemRequest(uint256 , address receiver, address controller) returns(uint256 shares)
func (_SuperVault *SuperVaultTransactorSession) ClaimCancelRedeemRequest(arg0 *big.Int, receiver common.Address, controller common.Address) (*types.Transaction, error) {
	return _SuperVault.Contract.ClaimCancelRedeemRequest(&_SuperVault.TransactOpts, arg0, receiver, controller)
}

// Deposit is a paid mutator transaction binding the contract method 0x6e553f65.
//
// Solidity: function deposit(uint256 assets, address receiver) returns(uint256 shares)
func (_SuperVault *SuperVaultTransactor) Deposit(opts *bind.TransactOpts, assets *big.Int, receiver common.Address) (*types.Transaction, error) {
	return _SuperVault.contract.Transact(opts, "deposit", assets, receiver)
}

// Deposit is a paid mutator transaction binding the contract method 0x6e553f65.
//
// Solidity: function deposit(uint256 assets, address receiver) returns(uint256 shares)
func (_SuperVault *SuperVaultSession) Deposit(assets *big.Int, receiver common.Address) (*types.Transaction, error) {
	return _SuperVault.Contract.Deposit(&_SuperVault.TransactOpts, assets, receiver)
}

// Deposit is a paid mutator transaction binding the contract method 0x6e553f65.
//
// Solidity: function deposit(uint256 assets, address receiver) returns(uint256 shares)
func (_SuperVault *SuperVaultTransactorSession) Deposit(assets *big.Int, receiver common.Address) (*types.Transaction, error) {
	return _SuperVault.Contract.Deposit(&_SuperVault.TransactOpts, assets, receiver)
}

// Initialize is a paid mutator transaction binding the contract method 0x6cf1dbed.
//
// Solidity: function initialize(address asset_, string name_, string symbol_, address strategy_, address escrow_) returns()
func (_SuperVault *SuperVaultTransactor) Initialize(opts *bind.TransactOpts, asset_ common.Address, name_ string, symbol_ string, strategy_ common.Address, escrow_ common.Address) (*types.Transaction, error) {
	return _SuperVault.contract.Transact(opts, "initialize", asset_, name_, symbol_, strategy_, escrow_)
}

// Initialize is a paid mutator transaction binding the contract method 0x6cf1dbed.
//
// Solidity: function initialize(address asset_, string name_, string symbol_, address strategy_, address escrow_) returns()
func (_SuperVault *SuperVaultSession) Initialize(asset_ common.Address, name_ string, symbol_ string, strategy_ common.Address, escrow_ common.Address) (*types.Transaction, error) {
	return _SuperVault.Contract.Initialize(&_SuperVault.TransactOpts, asset_, name_, symbol_, strategy_, escrow_)
}

// Initialize is a paid mutator transaction binding the contract method 0x6cf1dbed.
//
// Solidity: function initialize(address asset_, string name_, string symbol_, address strategy_, address escrow_) returns()
func (_SuperVault *SuperVaultTransactorSession) Initialize(asset_ common.Address, name_ string, symbol_ string, strategy_ common.Address, escrow_ common.Address) (*types.Transaction, error) {
	return _SuperVault.Contract.Initialize(&_SuperVault.TransactOpts, asset_, name_, symbol_, strategy_, escrow_)
}

// InvalidateNonce is a paid mutator transaction binding the contract method 0x234f0e3b.
//
// Solidity: function invalidateNonce(bytes32 nonce) returns()
func (_SuperVault *SuperVaultTransactor) InvalidateNonce(opts *bind.TransactOpts, nonce [32]byte) (*types.Transaction, error) {
	return _SuperVault.contract.Transact(opts, "invalidateNonce", nonce)
}

// InvalidateNonce is a paid mutator transaction binding the contract method 0x234f0e3b.
//
// Solidity: function invalidateNonce(bytes32 nonce) returns()
func (_SuperVault *SuperVaultSession) InvalidateNonce(nonce [32]byte) (*types.Transaction, error) {
	return _SuperVault.Contract.InvalidateNonce(&_SuperVault.TransactOpts, nonce)
}

// InvalidateNonce is a paid mutator transaction binding the contract method 0x234f0e3b.
//
// Solidity: function invalidateNonce(bytes32 nonce) returns()
func (_SuperVault *SuperVaultTransactorSession) InvalidateNonce(nonce [32]byte) (*types.Transaction, error) {
	return _SuperVault.Contract.InvalidateNonce(&_SuperVault.TransactOpts, nonce)
}

// Mint is a paid mutator transaction binding the contract method 0x94bf804d.
//
// Solidity: function mint(uint256 shares, address receiver) returns(uint256 assets)
func (_SuperVault *SuperVaultTransactor) Mint(opts *bind.TransactOpts, shares *big.Int, receiver common.Address) (*types.Transaction, error) {
	return _SuperVault.contract.Transact(opts, "mint", shares, receiver)
}

// Mint is a paid mutator transaction binding the contract method 0x94bf804d.
//
// Solidity: function mint(uint256 shares, address receiver) returns(uint256 assets)
func (_SuperVault *SuperVaultSession) Mint(shares *big.Int, receiver common.Address) (*types.Transaction, error) {
	return _SuperVault.Contract.Mint(&_SuperVault.TransactOpts, shares, receiver)
}

// Mint is a paid mutator transaction binding the contract method 0x94bf804d.
//
// Solidity: function mint(uint256 shares, address receiver) returns(uint256 assets)
func (_SuperVault *SuperVaultTransactorSession) Mint(shares *big.Int, receiver common.Address) (*types.Transaction, error) {
	return _SuperVault.Contract.Mint(&_SuperVault.TransactOpts, shares, receiver)
}

// Redeem is a paid mutator transaction binding the contract method 0xba087652.
//
// Solidity: function redeem(uint256 shares, address receiver, address controller) returns(uint256 assets)
func (_SuperVault *SuperVaultTransactor) Redeem(opts *bind.TransactOpts, shares *big.Int, receiver common.Address, controller common.Address) (*types.Transaction, error) {
	return _SuperVault.contract.Transact(opts, "redeem", shares, receiver, controller)
}

// Redeem is a paid mutator transaction binding the contract method 0xba087652.
//
// Solidity: function redeem(uint256 shares, address receiver, address controller) returns(uint256 assets)
func (_SuperVault *SuperVaultSession) Redeem(shares *big.Int, receiver common.Address, controller common.Address) (*types.Transaction, error) {
	return _SuperVault.Contract.Redeem(&_SuperVault.TransactOpts, shares, receiver, controller)
}

// Redeem is a paid mutator transaction binding the contract method 0xba087652.
//
// Solidity: function redeem(uint256 shares, address receiver, address controller) returns(uint256 assets)
func (_SuperVault *SuperVaultTransactorSession) Redeem(shares *big.Int, receiver common.Address, controller common.Address) (*types.Transaction, error) {
	return _SuperVault.Contract.Redeem(&_SuperVault.TransactOpts, shares, receiver, controller)
}

// RequestRedeem is a paid mutator transaction binding the contract method 0x7d41c86e.
//
// Solidity: function requestRedeem(uint256 shares, address controller, address owner) returns(uint256)
func (_SuperVault *SuperVaultTransactor) RequestRedeem(opts *bind.TransactOpts, shares *big.Int, controller common.Address, owner common.Address) (*types.Transaction, error) {
	return _SuperVault.contract.Transact(opts, "requestRedeem", shares, controller, owner)
}

// RequestRedeem is a paid mutator transaction binding the contract method 0x7d41c86e.
//
// Solidity: function requestRedeem(uint256 shares, address controller, address owner) returns(uint256)
func (_SuperVault *SuperVaultSession) RequestRedeem(shares *big.Int, controller common.Address, owner common.Address) (*types.Transaction, error) {
	return _SuperVault.Contract.RequestRedeem(&_SuperVault.TransactOpts, shares, controller, owner)
}

// RequestRedeem is a paid mutator transaction binding the contract method 0x7d41c86e.
//
// Solidity: function requestRedeem(uint256 shares, address controller, address owner) returns(uint256)
func (_SuperVault *SuperVaultTransactorSession) RequestRedeem(shares *big.Int, controller common.Address, owner common.Address) (*types.Transaction, error) {
	return _SuperVault.Contract.RequestRedeem(&_SuperVault.TransactOpts, shares, controller, owner)
}

// SetOperator is a paid mutator transaction binding the contract method 0x558a7297.
//
// Solidity: function setOperator(address operator, bool approved) returns(bool success)
func (_SuperVault *SuperVaultTransactor) SetOperator(opts *bind.TransactOpts, operator common.Address, approved bool) (*types.Transaction, error) {
	return _SuperVault.contract.Transact(opts, "setOperator", operator, approved)
}

// SetOperator is a paid mutator transaction binding the contract method 0x558a7297.
//
// Solidity: function setOperator(address operator, bool approved) returns(bool success)
func (_SuperVault *SuperVaultSession) SetOperator(operator common.Address, approved bool) (*types.Transaction, error) {
	return _SuperVault.Contract.SetOperator(&_SuperVault.TransactOpts, operator, approved)
}

// SetOperator is a paid mutator transaction binding the contract method 0x558a7297.
//
// Solidity: function setOperator(address operator, bool approved) returns(bool success)
func (_SuperVault *SuperVaultTransactorSession) SetOperator(operator common.Address, approved bool) (*types.Transaction, error) {
	return _SuperVault.Contract.SetOperator(&_SuperVault.TransactOpts, operator, approved)
}

// Transfer is a paid mutator transaction binding the contract method 0xa9059cbb.
//
// Solidity: function transfer(address to, uint256 value) returns(bool)
func (_SuperVault *SuperVaultTransactor) Transfer(opts *bind.TransactOpts, to common.Address, value *big.Int) (*types.Transaction, error) {
	return _SuperVault.contract.Transact(opts, "transfer", to, value)
}

// Transfer is a paid mutator transaction binding the contract method 0xa9059cbb.
//
// Solidity: function transfer(address to, uint256 value) returns(bool)
func (_SuperVault *SuperVaultSession) Transfer(to common.Address, value *big.Int) (*types.Transaction, error) {
	return _SuperVault.Contract.Transfer(&_SuperVault.TransactOpts, to, value)
}

// Transfer is a paid mutator transaction binding the contract method 0xa9059cbb.
//
// Solidity: function transfer(address to, uint256 value) returns(bool)
func (_SuperVault *SuperVaultTransactorSession) Transfer(to common.Address, value *big.Int) (*types.Transaction, error) {
	return _SuperVault.Contract.Transfer(&_SuperVault.TransactOpts, to, value)
}

// TransferFrom is a paid mutator transaction binding the contract method 0x23b872dd.
//
// Solidity: function transferFrom(address from, address to, uint256 value) returns(bool)
func (_SuperVault *SuperVaultTransactor) TransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, value *big.Int) (*types.Transaction, error) {
	return _SuperVault.contract.Transact(opts, "transferFrom", from, to, value)
}

// TransferFrom is a paid mutator transaction binding the contract method 0x23b872dd.
//
// Solidity: function transferFrom(address from, address to, uint256 value) returns(bool)
func (_SuperVault *SuperVaultSession) TransferFrom(from common.Address, to common.Address, value *big.Int) (*types.Transaction, error) {
	return _SuperVault.Contract.TransferFrom(&_SuperVault.TransactOpts, from, to, value)
}

// TransferFrom is a paid mutator transaction binding the contract method 0x23b872dd.
//
// Solidity: function transferFrom(address from, address to, uint256 value) returns(bool)
func (_SuperVault *SuperVaultTransactorSession) TransferFrom(from common.Address, to common.Address, value *big.Int) (*types.Transaction, error) {
	return _SuperVault.Contract.TransferFrom(&_SuperVault.TransactOpts, from, to, value)
}

// Withdraw is a paid mutator transaction binding the contract method 0xb460af94.
//
// Solidity: function withdraw(uint256 assets, address receiver, address controller) returns(uint256 shares)
func (_SuperVault *SuperVaultTransactor) Withdraw(opts *bind.TransactOpts, assets *big.Int, receiver common.Address, controller common.Address) (*types.Transaction, error) {
	return _SuperVault.contract.Transact(opts, "withdraw", assets, receiver, controller)
}

// Withdraw is a paid mutator transaction binding the contract method 0xb460af94.
//
// Solidity: function withdraw(uint256 assets, address receiver, address controller) returns(uint256 shares)
func (_SuperVault *SuperVaultSession) Withdraw(assets *big.Int, receiver common.Address, controller common.Address) (*types.Transaction, error) {
	return _SuperVault.Contract.Withdraw(&_SuperVault.TransactOpts, assets, receiver, controller)
}

// Withdraw is a paid mutator transaction binding the contract method 0xb460af94.
//
// Solidity: function withdraw(uint256 assets, address receiver, address controller) returns(uint256 shares)
func (_SuperVault *SuperVaultTransactorSession) Withdraw(assets *big.Int, receiver common.Address, controller common.Address) (*types.Transaction, error) {
	return _SuperVault.Contract.Withdraw(&_SuperVault.TransactOpts, assets, receiver, controller)
}

// SuperVaultApprovalIterator is returned from FilterApproval and is used to iterate over the raw logs and unpacked data for Approval events raised by the SuperVault contract.
type SuperVaultApprovalIterator struct {
	Event *SuperVaultApproval // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultApprovalIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultApproval)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultApproval)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultApprovalIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultApprovalIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultApproval represents a Approval event raised by the SuperVault contract.
type SuperVaultApproval struct {
	Owner   common.Address
	Spender common.Address
	Value   *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterApproval is a free log retrieval operation binding the contract event 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925.
//
// Solidity: event Approval(address indexed owner, address indexed spender, uint256 value)
func (_SuperVault *SuperVaultFilterer) FilterApproval(opts *bind.FilterOpts, owner []common.Address, spender []common.Address) (*SuperVaultApprovalIterator, error) {

	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}
	var spenderRule []interface{}
	for _, spenderItem := range spender {
		spenderRule = append(spenderRule, spenderItem)
	}

	logs, sub, err := _SuperVault.contract.FilterLogs(opts, "Approval", ownerRule, spenderRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultApprovalIterator{contract: _SuperVault.contract, event: "Approval", logs: logs, sub: sub}, nil
}

// WatchApproval is a free log subscription operation binding the contract event 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925.
//
// Solidity: event Approval(address indexed owner, address indexed spender, uint256 value)
func (_SuperVault *SuperVaultFilterer) WatchApproval(opts *bind.WatchOpts, sink chan<- *SuperVaultApproval, owner []common.Address, spender []common.Address) (event.Subscription, error) {

	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}
	var spenderRule []interface{}
	for _, spenderItem := range spender {
		spenderRule = append(spenderRule, spenderItem)
	}

	logs, sub, err := _SuperVault.contract.WatchLogs(opts, "Approval", ownerRule, spenderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultApproval)
				if err := _SuperVault.contract.UnpackLog(event, "Approval", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseApproval is a log parse operation binding the contract event 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925.
//
// Solidity: event Approval(address indexed owner, address indexed spender, uint256 value)
func (_SuperVault *SuperVaultFilterer) ParseApproval(log types.Log) (*SuperVaultApproval, error) {
	event := new(SuperVaultApproval)
	if err := _SuperVault.contract.UnpackLog(event, "Approval", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultCancelRedeemClaimIterator is returned from FilterCancelRedeemClaim and is used to iterate over the raw logs and unpacked data for CancelRedeemClaim events raised by the SuperVault contract.
type SuperVaultCancelRedeemClaimIterator struct {
	Event *SuperVaultCancelRedeemClaim // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultCancelRedeemClaimIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultCancelRedeemClaim)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultCancelRedeemClaim)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultCancelRedeemClaimIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultCancelRedeemClaimIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultCancelRedeemClaim represents a CancelRedeemClaim event raised by the SuperVault contract.
type SuperVaultCancelRedeemClaim struct {
	Receiver   common.Address
	Controller common.Address
	RequestId  *big.Int
	Sender     common.Address
	Shares     *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterCancelRedeemClaim is a free log retrieval operation binding the contract event 0x9c133d4657dc9cd12f4c08cef86ef778dbbe03f3ad3b661ff14d36bc3febb1fb.
//
// Solidity: event CancelRedeemClaim(address indexed receiver, address indexed controller, uint256 indexed requestId, address sender, uint256 shares)
func (_SuperVault *SuperVaultFilterer) FilterCancelRedeemClaim(opts *bind.FilterOpts, receiver []common.Address, controller []common.Address, requestId []*big.Int) (*SuperVaultCancelRedeemClaimIterator, error) {

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}
	var requestIdRule []interface{}
	for _, requestIdItem := range requestId {
		requestIdRule = append(requestIdRule, requestIdItem)
	}

	logs, sub, err := _SuperVault.contract.FilterLogs(opts, "CancelRedeemClaim", receiverRule, controllerRule, requestIdRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultCancelRedeemClaimIterator{contract: _SuperVault.contract, event: "CancelRedeemClaim", logs: logs, sub: sub}, nil
}

// WatchCancelRedeemClaim is a free log subscription operation binding the contract event 0x9c133d4657dc9cd12f4c08cef86ef778dbbe03f3ad3b661ff14d36bc3febb1fb.
//
// Solidity: event CancelRedeemClaim(address indexed receiver, address indexed controller, uint256 indexed requestId, address sender, uint256 shares)
func (_SuperVault *SuperVaultFilterer) WatchCancelRedeemClaim(opts *bind.WatchOpts, sink chan<- *SuperVaultCancelRedeemClaim, receiver []common.Address, controller []common.Address, requestId []*big.Int) (event.Subscription, error) {

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}
	var requestIdRule []interface{}
	for _, requestIdItem := range requestId {
		requestIdRule = append(requestIdRule, requestIdItem)
	}

	logs, sub, err := _SuperVault.contract.WatchLogs(opts, "CancelRedeemClaim", receiverRule, controllerRule, requestIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultCancelRedeemClaim)
				if err := _SuperVault.contract.UnpackLog(event, "CancelRedeemClaim", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseCancelRedeemClaim is a log parse operation binding the contract event 0x9c133d4657dc9cd12f4c08cef86ef778dbbe03f3ad3b661ff14d36bc3febb1fb.
//
// Solidity: event CancelRedeemClaim(address indexed receiver, address indexed controller, uint256 indexed requestId, address sender, uint256 shares)
func (_SuperVault *SuperVaultFilterer) ParseCancelRedeemClaim(log types.Log) (*SuperVaultCancelRedeemClaim, error) {
	event := new(SuperVaultCancelRedeemClaim)
	if err := _SuperVault.contract.UnpackLog(event, "CancelRedeemClaim", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultCancelRedeemRequestIterator is returned from FilterCancelRedeemRequest and is used to iterate over the raw logs and unpacked data for CancelRedeemRequest events raised by the SuperVault contract.
type SuperVaultCancelRedeemRequestIterator struct {
	Event *SuperVaultCancelRedeemRequest // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultCancelRedeemRequestIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultCancelRedeemRequest)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultCancelRedeemRequest)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultCancelRedeemRequestIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultCancelRedeemRequestIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultCancelRedeemRequest represents a CancelRedeemRequest event raised by the SuperVault contract.
type SuperVaultCancelRedeemRequest struct {
	Controller common.Address
	RequestId  *big.Int
	Sender     common.Address
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterCancelRedeemRequest is a free log retrieval operation binding the contract event 0xa16c0f2cab616ed5d17cd544655b00d7062a1df7c457960cc8b9bf60770f9236.
//
// Solidity: event CancelRedeemRequest(address indexed controller, uint256 indexed requestId, address sender)
func (_SuperVault *SuperVaultFilterer) FilterCancelRedeemRequest(opts *bind.FilterOpts, controller []common.Address, requestId []*big.Int) (*SuperVaultCancelRedeemRequestIterator, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}
	var requestIdRule []interface{}
	for _, requestIdItem := range requestId {
		requestIdRule = append(requestIdRule, requestIdItem)
	}

	logs, sub, err := _SuperVault.contract.FilterLogs(opts, "CancelRedeemRequest", controllerRule, requestIdRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultCancelRedeemRequestIterator{contract: _SuperVault.contract, event: "CancelRedeemRequest", logs: logs, sub: sub}, nil
}

// WatchCancelRedeemRequest is a free log subscription operation binding the contract event 0xa16c0f2cab616ed5d17cd544655b00d7062a1df7c457960cc8b9bf60770f9236.
//
// Solidity: event CancelRedeemRequest(address indexed controller, uint256 indexed requestId, address sender)
func (_SuperVault *SuperVaultFilterer) WatchCancelRedeemRequest(opts *bind.WatchOpts, sink chan<- *SuperVaultCancelRedeemRequest, controller []common.Address, requestId []*big.Int) (event.Subscription, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}
	var requestIdRule []interface{}
	for _, requestIdItem := range requestId {
		requestIdRule = append(requestIdRule, requestIdItem)
	}

	logs, sub, err := _SuperVault.contract.WatchLogs(opts, "CancelRedeemRequest", controllerRule, requestIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultCancelRedeemRequest)
				if err := _SuperVault.contract.UnpackLog(event, "CancelRedeemRequest", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseCancelRedeemRequest is a log parse operation binding the contract event 0xa16c0f2cab616ed5d17cd544655b00d7062a1df7c457960cc8b9bf60770f9236.
//
// Solidity: event CancelRedeemRequest(address indexed controller, uint256 indexed requestId, address sender)
func (_SuperVault *SuperVaultFilterer) ParseCancelRedeemRequest(log types.Log) (*SuperVaultCancelRedeemRequest, error) {
	event := new(SuperVaultCancelRedeemRequest)
	if err := _SuperVault.contract.UnpackLog(event, "CancelRedeemRequest", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultDepositIterator is returned from FilterDeposit and is used to iterate over the raw logs and unpacked data for Deposit events raised by the SuperVault contract.
type SuperVaultDepositIterator struct {
	Event *SuperVaultDeposit // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultDepositIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultDeposit)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultDeposit)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultDepositIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultDepositIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultDeposit represents a Deposit event raised by the SuperVault contract.
type SuperVaultDeposit struct {
	Sender common.Address
	Owner  common.Address
	Assets *big.Int
	Shares *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterDeposit is a free log retrieval operation binding the contract event 0xdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d7.
//
// Solidity: event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares)
func (_SuperVault *SuperVaultFilterer) FilterDeposit(opts *bind.FilterOpts, sender []common.Address, owner []common.Address) (*SuperVaultDepositIterator, error) {

	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}
	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}

	logs, sub, err := _SuperVault.contract.FilterLogs(opts, "Deposit", senderRule, ownerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultDepositIterator{contract: _SuperVault.contract, event: "Deposit", logs: logs, sub: sub}, nil
}

// WatchDeposit is a free log subscription operation binding the contract event 0xdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d7.
//
// Solidity: event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares)
func (_SuperVault *SuperVaultFilterer) WatchDeposit(opts *bind.WatchOpts, sink chan<- *SuperVaultDeposit, sender []common.Address, owner []common.Address) (event.Subscription, error) {

	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}
	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}

	logs, sub, err := _SuperVault.contract.WatchLogs(opts, "Deposit", senderRule, ownerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultDeposit)
				if err := _SuperVault.contract.UnpackLog(event, "Deposit", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseDeposit is a log parse operation binding the contract event 0xdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d7.
//
// Solidity: event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares)
func (_SuperVault *SuperVaultFilterer) ParseDeposit(log types.Log) (*SuperVaultDeposit, error) {
	event := new(SuperVaultDeposit)
	if err := _SuperVault.contract.UnpackLog(event, "Deposit", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultEIP712DomainChangedIterator is returned from FilterEIP712DomainChanged and is used to iterate over the raw logs and unpacked data for EIP712DomainChanged events raised by the SuperVault contract.
type SuperVaultEIP712DomainChangedIterator struct {
	Event *SuperVaultEIP712DomainChanged // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultEIP712DomainChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultEIP712DomainChanged)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultEIP712DomainChanged)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultEIP712DomainChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultEIP712DomainChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultEIP712DomainChanged represents a EIP712DomainChanged event raised by the SuperVault contract.
type SuperVaultEIP712DomainChanged struct {
	Raw types.Log // Blockchain specific contextual infos
}

// FilterEIP712DomainChanged is a free log retrieval operation binding the contract event 0x0a6387c9ea3628b88a633bb4f3b151770f70085117a15f9bf3787cda53f13d31.
//
// Solidity: event EIP712DomainChanged()
func (_SuperVault *SuperVaultFilterer) FilterEIP712DomainChanged(opts *bind.FilterOpts) (*SuperVaultEIP712DomainChangedIterator, error) {

	logs, sub, err := _SuperVault.contract.FilterLogs(opts, "EIP712DomainChanged")
	if err != nil {
		return nil, err
	}
	return &SuperVaultEIP712DomainChangedIterator{contract: _SuperVault.contract, event: "EIP712DomainChanged", logs: logs, sub: sub}, nil
}

// WatchEIP712DomainChanged is a free log subscription operation binding the contract event 0x0a6387c9ea3628b88a633bb4f3b151770f70085117a15f9bf3787cda53f13d31.
//
// Solidity: event EIP712DomainChanged()
func (_SuperVault *SuperVaultFilterer) WatchEIP712DomainChanged(opts *bind.WatchOpts, sink chan<- *SuperVaultEIP712DomainChanged) (event.Subscription, error) {

	logs, sub, err := _SuperVault.contract.WatchLogs(opts, "EIP712DomainChanged")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultEIP712DomainChanged)
				if err := _SuperVault.contract.UnpackLog(event, "EIP712DomainChanged", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseEIP712DomainChanged is a log parse operation binding the contract event 0x0a6387c9ea3628b88a633bb4f3b151770f70085117a15f9bf3787cda53f13d31.
//
// Solidity: event EIP712DomainChanged()
func (_SuperVault *SuperVaultFilterer) ParseEIP712DomainChanged(log types.Log) (*SuperVaultEIP712DomainChanged, error) {
	event := new(SuperVaultEIP712DomainChanged)
	if err := _SuperVault.contract.UnpackLog(event, "EIP712DomainChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultInitializedIterator is returned from FilterInitialized and is used to iterate over the raw logs and unpacked data for Initialized events raised by the SuperVault contract.
type SuperVaultInitializedIterator struct {
	Event *SuperVaultInitialized // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultInitializedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultInitialized)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultInitialized)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultInitializedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultInitializedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultInitialized represents a Initialized event raised by the SuperVault contract.
type SuperVaultInitialized struct {
	Version uint64
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterInitialized is a free log retrieval operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_SuperVault *SuperVaultFilterer) FilterInitialized(opts *bind.FilterOpts) (*SuperVaultInitializedIterator, error) {

	logs, sub, err := _SuperVault.contract.FilterLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return &SuperVaultInitializedIterator{contract: _SuperVault.contract, event: "Initialized", logs: logs, sub: sub}, nil
}

// WatchInitialized is a free log subscription operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_SuperVault *SuperVaultFilterer) WatchInitialized(opts *bind.WatchOpts, sink chan<- *SuperVaultInitialized) (event.Subscription, error) {

	logs, sub, err := _SuperVault.contract.WatchLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultInitialized)
				if err := _SuperVault.contract.UnpackLog(event, "Initialized", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
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
func (_SuperVault *SuperVaultFilterer) ParseInitialized(log types.Log) (*SuperVaultInitialized, error) {
	event := new(SuperVaultInitialized)
	if err := _SuperVault.contract.UnpackLog(event, "Initialized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultInitialized0Iterator is returned from FilterInitialized0 and is used to iterate over the raw logs and unpacked data for Initialized0 events raised by the SuperVault contract.
type SuperVaultInitialized0Iterator struct {
	Event *SuperVaultInitialized0 // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultInitialized0Iterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultInitialized0)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultInitialized0)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultInitialized0Iterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultInitialized0Iterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultInitialized0 represents a Initialized0 event raised by the SuperVault contract.
type SuperVaultInitialized0 struct {
	Asset    common.Address
	Strategy common.Address
	Escrow   common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterInitialized0 is a free log retrieval operation binding the contract event 0xad307780531f6353137c35adc50ad58d71b76e76aa891e729387f2e720f2de20.
//
// Solidity: event Initialized(address indexed asset, address indexed strategy, address indexed escrow)
func (_SuperVault *SuperVaultFilterer) FilterInitialized0(opts *bind.FilterOpts, asset []common.Address, strategy []common.Address, escrow []common.Address) (*SuperVaultInitialized0Iterator, error) {

	var assetRule []interface{}
	for _, assetItem := range asset {
		assetRule = append(assetRule, assetItem)
	}
	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var escrowRule []interface{}
	for _, escrowItem := range escrow {
		escrowRule = append(escrowRule, escrowItem)
	}

	logs, sub, err := _SuperVault.contract.FilterLogs(opts, "Initialized0", assetRule, strategyRule, escrowRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultInitialized0Iterator{contract: _SuperVault.contract, event: "Initialized0", logs: logs, sub: sub}, nil
}

// WatchInitialized0 is a free log subscription operation binding the contract event 0xad307780531f6353137c35adc50ad58d71b76e76aa891e729387f2e720f2de20.
//
// Solidity: event Initialized(address indexed asset, address indexed strategy, address indexed escrow)
func (_SuperVault *SuperVaultFilterer) WatchInitialized0(opts *bind.WatchOpts, sink chan<- *SuperVaultInitialized0, asset []common.Address, strategy []common.Address, escrow []common.Address) (event.Subscription, error) {

	var assetRule []interface{}
	for _, assetItem := range asset {
		assetRule = append(assetRule, assetItem)
	}
	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var escrowRule []interface{}
	for _, escrowItem := range escrow {
		escrowRule = append(escrowRule, escrowItem)
	}

	logs, sub, err := _SuperVault.contract.WatchLogs(opts, "Initialized0", assetRule, strategyRule, escrowRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultInitialized0)
				if err := _SuperVault.contract.UnpackLog(event, "Initialized0", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseInitialized0 is a log parse operation binding the contract event 0xad307780531f6353137c35adc50ad58d71b76e76aa891e729387f2e720f2de20.
//
// Solidity: event Initialized(address indexed asset, address indexed strategy, address indexed escrow)
func (_SuperVault *SuperVaultFilterer) ParseInitialized0(log types.Log) (*SuperVaultInitialized0, error) {
	event := new(SuperVaultInitialized0)
	if err := _SuperVault.contract.UnpackLog(event, "Initialized0", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultNonceInvalidatedIterator is returned from FilterNonceInvalidated and is used to iterate over the raw logs and unpacked data for NonceInvalidated events raised by the SuperVault contract.
type SuperVaultNonceInvalidatedIterator struct {
	Event *SuperVaultNonceInvalidated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultNonceInvalidatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultNonceInvalidated)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultNonceInvalidated)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultNonceInvalidatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultNonceInvalidatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultNonceInvalidated represents a NonceInvalidated event raised by the SuperVault contract.
type SuperVaultNonceInvalidated struct {
	Sender common.Address
	Nonce  [32]byte
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterNonceInvalidated is a free log retrieval operation binding the contract event 0xe4cac50121bc4e1c58579b5c01be6a4a4ed489837c5adf24124b08bc08f2a58a.
//
// Solidity: event NonceInvalidated(address indexed sender, bytes32 indexed nonce)
func (_SuperVault *SuperVaultFilterer) FilterNonceInvalidated(opts *bind.FilterOpts, sender []common.Address, nonce [][32]byte) (*SuperVaultNonceInvalidatedIterator, error) {

	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}
	var nonceRule []interface{}
	for _, nonceItem := range nonce {
		nonceRule = append(nonceRule, nonceItem)
	}

	logs, sub, err := _SuperVault.contract.FilterLogs(opts, "NonceInvalidated", senderRule, nonceRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultNonceInvalidatedIterator{contract: _SuperVault.contract, event: "NonceInvalidated", logs: logs, sub: sub}, nil
}

// WatchNonceInvalidated is a free log subscription operation binding the contract event 0xe4cac50121bc4e1c58579b5c01be6a4a4ed489837c5adf24124b08bc08f2a58a.
//
// Solidity: event NonceInvalidated(address indexed sender, bytes32 indexed nonce)
func (_SuperVault *SuperVaultFilterer) WatchNonceInvalidated(opts *bind.WatchOpts, sink chan<- *SuperVaultNonceInvalidated, sender []common.Address, nonce [][32]byte) (event.Subscription, error) {

	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}
	var nonceRule []interface{}
	for _, nonceItem := range nonce {
		nonceRule = append(nonceRule, nonceItem)
	}

	logs, sub, err := _SuperVault.contract.WatchLogs(opts, "NonceInvalidated", senderRule, nonceRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultNonceInvalidated)
				if err := _SuperVault.contract.UnpackLog(event, "NonceInvalidated", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseNonceInvalidated is a log parse operation binding the contract event 0xe4cac50121bc4e1c58579b5c01be6a4a4ed489837c5adf24124b08bc08f2a58a.
//
// Solidity: event NonceInvalidated(address indexed sender, bytes32 indexed nonce)
func (_SuperVault *SuperVaultFilterer) ParseNonceInvalidated(log types.Log) (*SuperVaultNonceInvalidated, error) {
	event := new(SuperVaultNonceInvalidated)
	if err := _SuperVault.contract.UnpackLog(event, "NonceInvalidated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultOperatorSetIterator is returned from FilterOperatorSet and is used to iterate over the raw logs and unpacked data for OperatorSet events raised by the SuperVault contract.
type SuperVaultOperatorSetIterator struct {
	Event *SuperVaultOperatorSet // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultOperatorSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultOperatorSet)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultOperatorSet)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultOperatorSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultOperatorSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultOperatorSet represents a OperatorSet event raised by the SuperVault contract.
type SuperVaultOperatorSet struct {
	Controller common.Address
	Operator   common.Address
	Approved   bool
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterOperatorSet is a free log retrieval operation binding the contract event 0xceb576d9f15e4e200fdb5096d64d5dfd667e16def20c1eefd14256d8e3faa267.
//
// Solidity: event OperatorSet(address indexed controller, address indexed operator, bool approved)
func (_SuperVault *SuperVaultFilterer) FilterOperatorSet(opts *bind.FilterOpts, controller []common.Address, operator []common.Address) (*SuperVaultOperatorSetIterator, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _SuperVault.contract.FilterLogs(opts, "OperatorSet", controllerRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultOperatorSetIterator{contract: _SuperVault.contract, event: "OperatorSet", logs: logs, sub: sub}, nil
}

// WatchOperatorSet is a free log subscription operation binding the contract event 0xceb576d9f15e4e200fdb5096d64d5dfd667e16def20c1eefd14256d8e3faa267.
//
// Solidity: event OperatorSet(address indexed controller, address indexed operator, bool approved)
func (_SuperVault *SuperVaultFilterer) WatchOperatorSet(opts *bind.WatchOpts, sink chan<- *SuperVaultOperatorSet, controller []common.Address, operator []common.Address) (event.Subscription, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _SuperVault.contract.WatchLogs(opts, "OperatorSet", controllerRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultOperatorSet)
				if err := _SuperVault.contract.UnpackLog(event, "OperatorSet", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseOperatorSet is a log parse operation binding the contract event 0xceb576d9f15e4e200fdb5096d64d5dfd667e16def20c1eefd14256d8e3faa267.
//
// Solidity: event OperatorSet(address indexed controller, address indexed operator, bool approved)
func (_SuperVault *SuperVaultFilterer) ParseOperatorSet(log types.Log) (*SuperVaultOperatorSet, error) {
	event := new(SuperVaultOperatorSet)
	if err := _SuperVault.contract.UnpackLog(event, "OperatorSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultRedeemRequestIterator is returned from FilterRedeemRequest and is used to iterate over the raw logs and unpacked data for RedeemRequest events raised by the SuperVault contract.
type SuperVaultRedeemRequestIterator struct {
	Event *SuperVaultRedeemRequest // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultRedeemRequestIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultRedeemRequest)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultRedeemRequest)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultRedeemRequestIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultRedeemRequestIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultRedeemRequest represents a RedeemRequest event raised by the SuperVault contract.
type SuperVaultRedeemRequest struct {
	Controller common.Address
	Owner      common.Address
	RequestId  *big.Int
	Sender     common.Address
	Assets     *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterRedeemRequest is a free log retrieval operation binding the contract event 0x1fdc681a13d8c5da54e301c7ce6542dcde4581e4725043fdab2db12ddc574506.
//
// Solidity: event RedeemRequest(address indexed controller, address indexed owner, uint256 indexed requestId, address sender, uint256 assets)
func (_SuperVault *SuperVaultFilterer) FilterRedeemRequest(opts *bind.FilterOpts, controller []common.Address, owner []common.Address, requestId []*big.Int) (*SuperVaultRedeemRequestIterator, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}
	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}
	var requestIdRule []interface{}
	for _, requestIdItem := range requestId {
		requestIdRule = append(requestIdRule, requestIdItem)
	}

	logs, sub, err := _SuperVault.contract.FilterLogs(opts, "RedeemRequest", controllerRule, ownerRule, requestIdRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultRedeemRequestIterator{contract: _SuperVault.contract, event: "RedeemRequest", logs: logs, sub: sub}, nil
}

// WatchRedeemRequest is a free log subscription operation binding the contract event 0x1fdc681a13d8c5da54e301c7ce6542dcde4581e4725043fdab2db12ddc574506.
//
// Solidity: event RedeemRequest(address indexed controller, address indexed owner, uint256 indexed requestId, address sender, uint256 assets)
func (_SuperVault *SuperVaultFilterer) WatchRedeemRequest(opts *bind.WatchOpts, sink chan<- *SuperVaultRedeemRequest, controller []common.Address, owner []common.Address, requestId []*big.Int) (event.Subscription, error) {

	var controllerRule []interface{}
	for _, controllerItem := range controller {
		controllerRule = append(controllerRule, controllerItem)
	}
	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}
	var requestIdRule []interface{}
	for _, requestIdItem := range requestId {
		requestIdRule = append(requestIdRule, requestIdItem)
	}

	logs, sub, err := _SuperVault.contract.WatchLogs(opts, "RedeemRequest", controllerRule, ownerRule, requestIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultRedeemRequest)
				if err := _SuperVault.contract.UnpackLog(event, "RedeemRequest", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRedeemRequest is a log parse operation binding the contract event 0x1fdc681a13d8c5da54e301c7ce6542dcde4581e4725043fdab2db12ddc574506.
//
// Solidity: event RedeemRequest(address indexed controller, address indexed owner, uint256 indexed requestId, address sender, uint256 assets)
func (_SuperVault *SuperVaultFilterer) ParseRedeemRequest(log types.Log) (*SuperVaultRedeemRequest, error) {
	event := new(SuperVaultRedeemRequest)
	if err := _SuperVault.contract.UnpackLog(event, "RedeemRequest", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultSuperGovernorSetIterator is returned from FilterSuperGovernorSet and is used to iterate over the raw logs and unpacked data for SuperGovernorSet events raised by the SuperVault contract.
type SuperVaultSuperGovernorSetIterator struct {
	Event *SuperVaultSuperGovernorSet // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultSuperGovernorSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultSuperGovernorSet)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultSuperGovernorSet)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultSuperGovernorSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultSuperGovernorSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultSuperGovernorSet represents a SuperGovernorSet event raised by the SuperVault contract.
type SuperVaultSuperGovernorSet struct {
	SuperGovernor common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterSuperGovernorSet is a free log retrieval operation binding the contract event 0x0da0926ffeff398fc5913fba71778c90421d4af535e207f385a39e335cbfa692.
//
// Solidity: event SuperGovernorSet(address indexed superGovernor)
func (_SuperVault *SuperVaultFilterer) FilterSuperGovernorSet(opts *bind.FilterOpts, superGovernor []common.Address) (*SuperVaultSuperGovernorSetIterator, error) {

	var superGovernorRule []interface{}
	for _, superGovernorItem := range superGovernor {
		superGovernorRule = append(superGovernorRule, superGovernorItem)
	}

	logs, sub, err := _SuperVault.contract.FilterLogs(opts, "SuperGovernorSet", superGovernorRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultSuperGovernorSetIterator{contract: _SuperVault.contract, event: "SuperGovernorSet", logs: logs, sub: sub}, nil
}

// WatchSuperGovernorSet is a free log subscription operation binding the contract event 0x0da0926ffeff398fc5913fba71778c90421d4af535e207f385a39e335cbfa692.
//
// Solidity: event SuperGovernorSet(address indexed superGovernor)
func (_SuperVault *SuperVaultFilterer) WatchSuperGovernorSet(opts *bind.WatchOpts, sink chan<- *SuperVaultSuperGovernorSet, superGovernor []common.Address) (event.Subscription, error) {

	var superGovernorRule []interface{}
	for _, superGovernorItem := range superGovernor {
		superGovernorRule = append(superGovernorRule, superGovernorItem)
	}

	logs, sub, err := _SuperVault.contract.WatchLogs(opts, "SuperGovernorSet", superGovernorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultSuperGovernorSet)
				if err := _SuperVault.contract.UnpackLog(event, "SuperGovernorSet", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
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
func (_SuperVault *SuperVaultFilterer) ParseSuperGovernorSet(log types.Log) (*SuperVaultSuperGovernorSet, error) {
	event := new(SuperVaultSuperGovernorSet)
	if err := _SuperVault.contract.UnpackLog(event, "SuperGovernorSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultTransferIterator is returned from FilterTransfer and is used to iterate over the raw logs and unpacked data for Transfer events raised by the SuperVault contract.
type SuperVaultTransferIterator struct {
	Event *SuperVaultTransfer // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultTransferIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultTransfer)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultTransfer)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultTransferIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultTransferIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultTransfer represents a Transfer event raised by the SuperVault contract.
type SuperVaultTransfer struct {
	From  common.Address
	To    common.Address
	Value *big.Int
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterTransfer is a free log retrieval operation binding the contract event 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef.
//
// Solidity: event Transfer(address indexed from, address indexed to, uint256 value)
func (_SuperVault *SuperVaultFilterer) FilterTransfer(opts *bind.FilterOpts, from []common.Address, to []common.Address) (*SuperVaultTransferIterator, error) {

	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _SuperVault.contract.FilterLogs(opts, "Transfer", fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultTransferIterator{contract: _SuperVault.contract, event: "Transfer", logs: logs, sub: sub}, nil
}

// WatchTransfer is a free log subscription operation binding the contract event 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef.
//
// Solidity: event Transfer(address indexed from, address indexed to, uint256 value)
func (_SuperVault *SuperVaultFilterer) WatchTransfer(opts *bind.WatchOpts, sink chan<- *SuperVaultTransfer, from []common.Address, to []common.Address) (event.Subscription, error) {

	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _SuperVault.contract.WatchLogs(opts, "Transfer", fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultTransfer)
				if err := _SuperVault.contract.UnpackLog(event, "Transfer", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseTransfer is a log parse operation binding the contract event 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef.
//
// Solidity: event Transfer(address indexed from, address indexed to, uint256 value)
func (_SuperVault *SuperVaultFilterer) ParseTransfer(log types.Log) (*SuperVaultTransfer, error) {
	event := new(SuperVaultTransfer)
	if err := _SuperVault.contract.UnpackLog(event, "Transfer", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultWithdrawIterator is returned from FilterWithdraw and is used to iterate over the raw logs and unpacked data for Withdraw events raised by the SuperVault contract.
type SuperVaultWithdrawIterator struct {
	Event *SuperVaultWithdraw // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultWithdrawIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultWithdraw)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultWithdraw)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultWithdrawIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultWithdrawIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultWithdraw represents a Withdraw event raised by the SuperVault contract.
type SuperVaultWithdraw struct {
	Sender   common.Address
	Receiver common.Address
	Owner    common.Address
	Assets   *big.Int
	Shares   *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterWithdraw is a free log retrieval operation binding the contract event 0xfbde797d201c681b91056529119e0b02407c7bb96a4a2c75c01fc9667232c8db.
//
// Solidity: event Withdraw(address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares)
func (_SuperVault *SuperVaultFilterer) FilterWithdraw(opts *bind.FilterOpts, sender []common.Address, receiver []common.Address, owner []common.Address) (*SuperVaultWithdrawIterator, error) {

	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}
	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}

	logs, sub, err := _SuperVault.contract.FilterLogs(opts, "Withdraw", senderRule, receiverRule, ownerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultWithdrawIterator{contract: _SuperVault.contract, event: "Withdraw", logs: logs, sub: sub}, nil
}

// WatchWithdraw is a free log subscription operation binding the contract event 0xfbde797d201c681b91056529119e0b02407c7bb96a4a2c75c01fc9667232c8db.
//
// Solidity: event Withdraw(address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares)
func (_SuperVault *SuperVaultFilterer) WatchWithdraw(opts *bind.WatchOpts, sink chan<- *SuperVaultWithdraw, sender []common.Address, receiver []common.Address, owner []common.Address) (event.Subscription, error) {

	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}
	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}

	logs, sub, err := _SuperVault.contract.WatchLogs(opts, "Withdraw", senderRule, receiverRule, ownerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultWithdraw)
				if err := _SuperVault.contract.UnpackLog(event, "Withdraw", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseWithdraw is a log parse operation binding the contract event 0xfbde797d201c681b91056529119e0b02407c7bb96a4a2c75c01fc9667232c8db.
//
// Solidity: event Withdraw(address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares)
func (_SuperVault *SuperVaultFilterer) ParseWithdraw(log types.Log) (*SuperVaultWithdraw, error) {
	event := new(SuperVaultWithdraw)
	if err := _SuperVault.contract.UnpackLog(event, "Withdraw", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
