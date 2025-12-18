// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package SuperVaultBatchOperator

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

// SuperVaultBatchOperatorBatchRequest is an auto generated low-level Go binding around an user-defined struct.
type SuperVaultBatchOperatorBatchRequest struct {
	Vault  common.Address
	Owner  common.Address
	Assets *big.Int
}

// SuperVaultBatchOperatorMetaData contains all meta data concerning the SuperVaultBatchOperator contract.
var SuperVaultBatchOperatorMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"batchRedeem\",\"inputs\":[{\"name\":\"vaultRequests\",\"type\":\"tuple[]\",\"internalType\":\"structSuperVaultBatchOperator.BatchRequest[]\",\"components\":[{\"name\":\"vault\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"assets\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"batchWithdraw\",\"inputs\":[{\"name\":\"vaultRequests\",\"type\":\"tuple[]\",\"internalType\":\"structSuperVaultBatchOperator.BatchRequest[]\",\"components\":[{\"name\":\"vault\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"assets\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"}]",
}

// SuperVaultBatchOperatorABI is the input ABI used to generate the binding from.
// Deprecated: Use SuperVaultBatchOperatorMetaData.ABI instead.
var SuperVaultBatchOperatorABI = SuperVaultBatchOperatorMetaData.ABI

// SuperVaultBatchOperator is an auto generated Go binding around an Ethereum contract.
type SuperVaultBatchOperator struct {
	SuperVaultBatchOperatorCaller     // Read-only binding to the contract
	SuperVaultBatchOperatorTransactor // Write-only binding to the contract
	SuperVaultBatchOperatorFilterer   // Log filterer for contract events
}

// SuperVaultBatchOperatorCaller is an auto generated read-only Go binding around an Ethereum contract.
type SuperVaultBatchOperatorCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultBatchOperatorTransactor is an auto generated write-only Go binding around an Ethereum contract.
type SuperVaultBatchOperatorTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultBatchOperatorFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type SuperVaultBatchOperatorFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultBatchOperatorSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type SuperVaultBatchOperatorSession struct {
	Contract     *SuperVaultBatchOperator // Generic contract binding to set the session for
	CallOpts     bind.CallOpts            // Call options to use throughout this session
	TransactOpts bind.TransactOpts        // Transaction auth options to use throughout this session
}

// SuperVaultBatchOperatorCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type SuperVaultBatchOperatorCallerSession struct {
	Contract *SuperVaultBatchOperatorCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts                  // Call options to use throughout this session
}

// SuperVaultBatchOperatorTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type SuperVaultBatchOperatorTransactorSession struct {
	Contract     *SuperVaultBatchOperatorTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts                  // Transaction auth options to use throughout this session
}

// SuperVaultBatchOperatorRaw is an auto generated low-level Go binding around an Ethereum contract.
type SuperVaultBatchOperatorRaw struct {
	Contract *SuperVaultBatchOperator // Generic contract binding to access the raw methods on
}

// SuperVaultBatchOperatorCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type SuperVaultBatchOperatorCallerRaw struct {
	Contract *SuperVaultBatchOperatorCaller // Generic read-only contract binding to access the raw methods on
}

// SuperVaultBatchOperatorTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type SuperVaultBatchOperatorTransactorRaw struct {
	Contract *SuperVaultBatchOperatorTransactor // Generic write-only contract binding to access the raw methods on
}

// NewSuperVaultBatchOperator creates a new instance of SuperVaultBatchOperator, bound to a specific deployed contract.
func NewSuperVaultBatchOperator(address common.Address, backend bind.ContractBackend) (*SuperVaultBatchOperator, error) {
	contract, err := bindSuperVaultBatchOperator(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &SuperVaultBatchOperator{SuperVaultBatchOperatorCaller: SuperVaultBatchOperatorCaller{contract: contract}, SuperVaultBatchOperatorTransactor: SuperVaultBatchOperatorTransactor{contract: contract}, SuperVaultBatchOperatorFilterer: SuperVaultBatchOperatorFilterer{contract: contract}}, nil
}

// NewSuperVaultBatchOperatorCaller creates a new read-only instance of SuperVaultBatchOperator, bound to a specific deployed contract.
func NewSuperVaultBatchOperatorCaller(address common.Address, caller bind.ContractCaller) (*SuperVaultBatchOperatorCaller, error) {
	contract, err := bindSuperVaultBatchOperator(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &SuperVaultBatchOperatorCaller{contract: contract}, nil
}

// NewSuperVaultBatchOperatorTransactor creates a new write-only instance of SuperVaultBatchOperator, bound to a specific deployed contract.
func NewSuperVaultBatchOperatorTransactor(address common.Address, transactor bind.ContractTransactor) (*SuperVaultBatchOperatorTransactor, error) {
	contract, err := bindSuperVaultBatchOperator(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &SuperVaultBatchOperatorTransactor{contract: contract}, nil
}

// NewSuperVaultBatchOperatorFilterer creates a new log filterer instance of SuperVaultBatchOperator, bound to a specific deployed contract.
func NewSuperVaultBatchOperatorFilterer(address common.Address, filterer bind.ContractFilterer) (*SuperVaultBatchOperatorFilterer, error) {
	contract, err := bindSuperVaultBatchOperator(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &SuperVaultBatchOperatorFilterer{contract: contract}, nil
}

// bindSuperVaultBatchOperator binds a generic wrapper to an already deployed contract.
func bindSuperVaultBatchOperator(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := SuperVaultBatchOperatorMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperVaultBatchOperator.Contract.SuperVaultBatchOperatorCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.SuperVaultBatchOperatorTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.SuperVaultBatchOperatorTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperVaultBatchOperator.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.contract.Transact(opts, method, params...)
}

// BatchRedeem is a paid mutator transaction binding the contract method 0x0baf3fae.
//
// Solidity: function batchRedeem((address,address,uint256)[] vaultRequests) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorTransactor) BatchRedeem(opts *bind.TransactOpts, vaultRequests []SuperVaultBatchOperatorBatchRequest) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.contract.Transact(opts, "batchRedeem", vaultRequests)
}

// BatchRedeem is a paid mutator transaction binding the contract method 0x0baf3fae.
//
// Solidity: function batchRedeem((address,address,uint256)[] vaultRequests) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorSession) BatchRedeem(vaultRequests []SuperVaultBatchOperatorBatchRequest) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.BatchRedeem(&_SuperVaultBatchOperator.TransactOpts, vaultRequests)
}

// BatchRedeem is a paid mutator transaction binding the contract method 0x0baf3fae.
//
// Solidity: function batchRedeem((address,address,uint256)[] vaultRequests) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorTransactorSession) BatchRedeem(vaultRequests []SuperVaultBatchOperatorBatchRequest) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.BatchRedeem(&_SuperVaultBatchOperator.TransactOpts, vaultRequests)
}

// BatchWithdraw is a paid mutator transaction binding the contract method 0x0513d63d.
//
// Solidity: function batchWithdraw((address,address,uint256)[] vaultRequests) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorTransactor) BatchWithdraw(opts *bind.TransactOpts, vaultRequests []SuperVaultBatchOperatorBatchRequest) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.contract.Transact(opts, "batchWithdraw", vaultRequests)
}

// BatchWithdraw is a paid mutator transaction binding the contract method 0x0513d63d.
//
// Solidity: function batchWithdraw((address,address,uint256)[] vaultRequests) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorSession) BatchWithdraw(vaultRequests []SuperVaultBatchOperatorBatchRequest) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.BatchWithdraw(&_SuperVaultBatchOperator.TransactOpts, vaultRequests)
}

// BatchWithdraw is a paid mutator transaction binding the contract method 0x0513d63d.
//
// Solidity: function batchWithdraw((address,address,uint256)[] vaultRequests) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorTransactorSession) BatchWithdraw(vaultRequests []SuperVaultBatchOperatorBatchRequest) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.BatchWithdraw(&_SuperVaultBatchOperator.TransactOpts, vaultRequests)
}
