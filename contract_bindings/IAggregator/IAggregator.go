// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package IAggregator

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

// PackedUserOperation is an auto generated low-level Go binding around an user-defined struct.
type PackedUserOperation struct {
	Sender             common.Address
	Nonce              *big.Int
	InitCode           []byte
	CallData           []byte
	AccountGasLimits   [32]byte
	PreVerificationGas *big.Int
	GasFees            [32]byte
	PaymasterAndData   []byte
	Signature          []byte
}

// IAggregatorMetaData contains all meta data concerning the IAggregator contract.
var IAggregatorMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"aggregateSignatures\",\"inputs\":[{\"name\":\"userOps\",\"type\":\"tuple[]\",\"internalType\":\"structPackedUserOperation[]\",\"components\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"initCode\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"callData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"accountGasLimits\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"preVerificationGas\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"gasFees\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"paymasterAndData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"signature\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}],\"outputs\":[{\"name\":\"aggregatedSignature\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validateSignatures\",\"inputs\":[{\"name\":\"userOps\",\"type\":\"tuple[]\",\"internalType\":\"structPackedUserOperation[]\",\"components\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"initCode\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"callData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"accountGasLimits\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"preVerificationGas\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"gasFees\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"paymasterAndData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"signature\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]},{\"name\":\"signature\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validateUserOpSignature\",\"inputs\":[{\"name\":\"userOp\",\"type\":\"tuple\",\"internalType\":\"structPackedUserOperation\",\"components\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"initCode\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"callData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"accountGasLimits\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"preVerificationGas\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"gasFees\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"paymasterAndData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"signature\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}],\"outputs\":[{\"name\":\"sigForUserOp\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"stateMutability\":\"view\"}]",
}

// IAggregatorABI is the input ABI used to generate the binding from.
// Deprecated: Use IAggregatorMetaData.ABI instead.
var IAggregatorABI = IAggregatorMetaData.ABI

// IAggregator is an auto generated Go binding around an Ethereum contract.
type IAggregator struct {
	IAggregatorCaller     // Read-only binding to the contract
	IAggregatorTransactor // Write-only binding to the contract
	IAggregatorFilterer   // Log filterer for contract events
}

// IAggregatorCaller is an auto generated read-only Go binding around an Ethereum contract.
type IAggregatorCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// IAggregatorTransactor is an auto generated write-only Go binding around an Ethereum contract.
type IAggregatorTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// IAggregatorFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type IAggregatorFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// IAggregatorSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type IAggregatorSession struct {
	Contract     *IAggregator      // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// IAggregatorCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type IAggregatorCallerSession struct {
	Contract *IAggregatorCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts      // Call options to use throughout this session
}

// IAggregatorTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type IAggregatorTransactorSession struct {
	Contract     *IAggregatorTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts      // Transaction auth options to use throughout this session
}

// IAggregatorRaw is an auto generated low-level Go binding around an Ethereum contract.
type IAggregatorRaw struct {
	Contract *IAggregator // Generic contract binding to access the raw methods on
}

// IAggregatorCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type IAggregatorCallerRaw struct {
	Contract *IAggregatorCaller // Generic read-only contract binding to access the raw methods on
}

// IAggregatorTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type IAggregatorTransactorRaw struct {
	Contract *IAggregatorTransactor // Generic write-only contract binding to access the raw methods on
}

// NewIAggregator creates a new instance of IAggregator, bound to a specific deployed contract.
func NewIAggregator(address common.Address, backend bind.ContractBackend) (*IAggregator, error) {
	contract, err := bindIAggregator(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &IAggregator{IAggregatorCaller: IAggregatorCaller{contract: contract}, IAggregatorTransactor: IAggregatorTransactor{contract: contract}, IAggregatorFilterer: IAggregatorFilterer{contract: contract}}, nil
}

// NewIAggregatorCaller creates a new read-only instance of IAggregator, bound to a specific deployed contract.
func NewIAggregatorCaller(address common.Address, caller bind.ContractCaller) (*IAggregatorCaller, error) {
	contract, err := bindIAggregator(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &IAggregatorCaller{contract: contract}, nil
}

// NewIAggregatorTransactor creates a new write-only instance of IAggregator, bound to a specific deployed contract.
func NewIAggregatorTransactor(address common.Address, transactor bind.ContractTransactor) (*IAggregatorTransactor, error) {
	contract, err := bindIAggregator(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &IAggregatorTransactor{contract: contract}, nil
}

// NewIAggregatorFilterer creates a new log filterer instance of IAggregator, bound to a specific deployed contract.
func NewIAggregatorFilterer(address common.Address, filterer bind.ContractFilterer) (*IAggregatorFilterer, error) {
	contract, err := bindIAggregator(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &IAggregatorFilterer{contract: contract}, nil
}

// bindIAggregator binds a generic wrapper to an already deployed contract.
func bindIAggregator(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := IAggregatorMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_IAggregator *IAggregatorRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _IAggregator.Contract.IAggregatorCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_IAggregator *IAggregatorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _IAggregator.Contract.IAggregatorTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_IAggregator *IAggregatorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _IAggregator.Contract.IAggregatorTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_IAggregator *IAggregatorCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _IAggregator.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_IAggregator *IAggregatorTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _IAggregator.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_IAggregator *IAggregatorTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _IAggregator.Contract.contract.Transact(opts, method, params...)
}

// AggregateSignatures is a free data retrieval call binding the contract method 0xae574a43.
//
// Solidity: function aggregateSignatures((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes)[] userOps) view returns(bytes aggregatedSignature)
func (_IAggregator *IAggregatorCaller) AggregateSignatures(opts *bind.CallOpts, userOps []PackedUserOperation) ([]byte, error) {
	var out []interface{}
	err := _IAggregator.contract.Call(opts, &out, "aggregateSignatures", userOps)

	if err != nil {
		return *new([]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([]byte)).(*[]byte)

	return out0, err

}

// AggregateSignatures is a free data retrieval call binding the contract method 0xae574a43.
//
// Solidity: function aggregateSignatures((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes)[] userOps) view returns(bytes aggregatedSignature)
func (_IAggregator *IAggregatorSession) AggregateSignatures(userOps []PackedUserOperation) ([]byte, error) {
	return _IAggregator.Contract.AggregateSignatures(&_IAggregator.CallOpts, userOps)
}

// AggregateSignatures is a free data retrieval call binding the contract method 0xae574a43.
//
// Solidity: function aggregateSignatures((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes)[] userOps) view returns(bytes aggregatedSignature)
func (_IAggregator *IAggregatorCallerSession) AggregateSignatures(userOps []PackedUserOperation) ([]byte, error) {
	return _IAggregator.Contract.AggregateSignatures(&_IAggregator.CallOpts, userOps)
}

// ValidateSignatures is a free data retrieval call binding the contract method 0x2dd81133.
//
// Solidity: function validateSignatures((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes)[] userOps, bytes signature) view returns()
func (_IAggregator *IAggregatorCaller) ValidateSignatures(opts *bind.CallOpts, userOps []PackedUserOperation, signature []byte) error {
	var out []interface{}
	err := _IAggregator.contract.Call(opts, &out, "validateSignatures", userOps, signature)

	if err != nil {
		return err
	}

	return err

}

// ValidateSignatures is a free data retrieval call binding the contract method 0x2dd81133.
//
// Solidity: function validateSignatures((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes)[] userOps, bytes signature) view returns()
func (_IAggregator *IAggregatorSession) ValidateSignatures(userOps []PackedUserOperation, signature []byte) error {
	return _IAggregator.Contract.ValidateSignatures(&_IAggregator.CallOpts, userOps, signature)
}

// ValidateSignatures is a free data retrieval call binding the contract method 0x2dd81133.
//
// Solidity: function validateSignatures((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes)[] userOps, bytes signature) view returns()
func (_IAggregator *IAggregatorCallerSession) ValidateSignatures(userOps []PackedUserOperation, signature []byte) error {
	return _IAggregator.Contract.ValidateSignatures(&_IAggregator.CallOpts, userOps, signature)
}

// ValidateUserOpSignature is a free data retrieval call binding the contract method 0x062a422b.
//
// Solidity: function validateUserOpSignature((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes) userOp) view returns(bytes sigForUserOp)
func (_IAggregator *IAggregatorCaller) ValidateUserOpSignature(opts *bind.CallOpts, userOp PackedUserOperation) ([]byte, error) {
	var out []interface{}
	err := _IAggregator.contract.Call(opts, &out, "validateUserOpSignature", userOp)

	if err != nil {
		return *new([]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([]byte)).(*[]byte)

	return out0, err

}

// ValidateUserOpSignature is a free data retrieval call binding the contract method 0x062a422b.
//
// Solidity: function validateUserOpSignature((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes) userOp) view returns(bytes sigForUserOp)
func (_IAggregator *IAggregatorSession) ValidateUserOpSignature(userOp PackedUserOperation) ([]byte, error) {
	return _IAggregator.Contract.ValidateUserOpSignature(&_IAggregator.CallOpts, userOp)
}

// ValidateUserOpSignature is a free data retrieval call binding the contract method 0x062a422b.
//
// Solidity: function validateUserOpSignature((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes) userOp) view returns(bytes sigForUserOp)
func (_IAggregator *IAggregatorCallerSession) ValidateUserOpSignature(userOp PackedUserOperation) ([]byte, error) {
	return _IAggregator.Contract.ValidateUserOpSignature(&_IAggregator.CallOpts, userOp)
}
