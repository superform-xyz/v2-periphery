// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package IECDSAPPSOracle

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

// IECDSAPPSOracleUpdatePPSArgs is an auto generated low-level Go binding around an user-defined struct.
type IECDSAPPSOracleUpdatePPSArgs struct {
	Strategies      []common.Address
	ProofsArray     [][][]byte
	Ppss            []*big.Int
	PpsStdevs       []*big.Int
	ValidatorSets   []*big.Int
	TotalValidators []*big.Int
	Timestamps      []*big.Int
}

// IECDSAPPSOracleValidationParams is an auto generated low-level Go binding around an user-defined struct.
type IECDSAPPSOracleValidationParams struct {
	Strategy        common.Address
	Proofs          [][]byte
	Pps             *big.Int
	PpsStdev        *big.Int
	ValidatorSet    *big.Int
	TotalValidators *big.Int
	Timestamp       *big.Int
}

// IECDSAPPSOracleMetaData contains all meta data concerning the IECDSAPPSOracle contract.
var IECDSAPPSOracleMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"UPDATE_PPS_TYPEHASH\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"domainSeparator\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"noncePerStrategy\",\"inputs\":[{\"name\":\"strategy_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"updatePPS\",\"inputs\":[{\"name\":\"args\",\"type\":\"tuple\",\"internalType\":\"structIECDSAPPSOracle.UpdatePPSArgs\",\"components\":[{\"name\":\"strategies\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"proofsArray\",\"type\":\"bytes[][]\",\"internalType\":\"bytes[][]\"},{\"name\":\"ppss\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"ppsStdevs\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"validatorSets\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"totalValidators\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"timestamps\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"validateProofs\",\"inputs\":[{\"name\":\"params\",\"type\":\"tuple\",\"internalType\":\"structIECDSAPPSOracle.ValidationParams\",\"components\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"proofs\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"},{\"name\":\"pps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"ppsStdev\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"validatorSet\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalValidators\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"outputs\":[],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validateProofs\",\"inputs\":[{\"name\":\"params\",\"type\":\"tuple\",\"internalType\":\"structIECDSAPPSOracle.ValidationParams\",\"components\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"proofs\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"},{\"name\":\"pps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"ppsStdev\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"validatorSet\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalValidators\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"cachedTotalValidators\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"requiredQuorum\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"BatchForwardPPSFailed\",\"inputs\":[{\"name\":\"reason\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"BatchForwardPPSFailedLowLevel\",\"inputs\":[{\"name\":\"lowLevelData\",\"type\":\"bytes\",\"indexed\":false,\"internalType\":\"bytes\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"InsufficientGasForForward\",\"inputs\":[{\"name\":\"gasLeft\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"requiredGas\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSValidated\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"pps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"ppsStdev\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"validatorSet\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"totalValidators\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ProofValidationFailed\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"reason\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ProofValidationFailedLowLevel\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"data\",\"type\":\"bytes\",\"indexed\":false,\"internalType\":\"bytes\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ARRAY_LENGTH_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"HIGH_PPS_DEVIATION\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"HIGH_PPS_DISPERSION\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_GAS_FOR_EXTERNAL_CALL\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_VALIDATOR_PARTICIPATION\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_PROOF\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_TIMESTAMP\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_TOTAL_VALIDATORS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_VALIDATOR\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_VALIDATOR_SET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PPS_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"QUORUM_NOT_MET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"STRATEGY_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"VALIDATOR_COUNT_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_LENGTH_ARRAY\",\"inputs\":[]}]",
}

// IECDSAPPSOracleABI is the input ABI used to generate the binding from.
// Deprecated: Use IECDSAPPSOracleMetaData.ABI instead.
var IECDSAPPSOracleABI = IECDSAPPSOracleMetaData.ABI

// IECDSAPPSOracle is an auto generated Go binding around an Ethereum contract.
type IECDSAPPSOracle struct {
	IECDSAPPSOracleCaller     // Read-only binding to the contract
	IECDSAPPSOracleTransactor // Write-only binding to the contract
	IECDSAPPSOracleFilterer   // Log filterer for contract events
}

// IECDSAPPSOracleCaller is an auto generated read-only Go binding around an Ethereum contract.
type IECDSAPPSOracleCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// IECDSAPPSOracleTransactor is an auto generated write-only Go binding around an Ethereum contract.
type IECDSAPPSOracleTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// IECDSAPPSOracleFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type IECDSAPPSOracleFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// IECDSAPPSOracleSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type IECDSAPPSOracleSession struct {
	Contract     *IECDSAPPSOracle  // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// IECDSAPPSOracleCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type IECDSAPPSOracleCallerSession struct {
	Contract *IECDSAPPSOracleCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts          // Call options to use throughout this session
}

// IECDSAPPSOracleTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type IECDSAPPSOracleTransactorSession struct {
	Contract     *IECDSAPPSOracleTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts          // Transaction auth options to use throughout this session
}

// IECDSAPPSOracleRaw is an auto generated low-level Go binding around an Ethereum contract.
type IECDSAPPSOracleRaw struct {
	Contract *IECDSAPPSOracle // Generic contract binding to access the raw methods on
}

// IECDSAPPSOracleCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type IECDSAPPSOracleCallerRaw struct {
	Contract *IECDSAPPSOracleCaller // Generic read-only contract binding to access the raw methods on
}

// IECDSAPPSOracleTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type IECDSAPPSOracleTransactorRaw struct {
	Contract *IECDSAPPSOracleTransactor // Generic write-only contract binding to access the raw methods on
}

// NewIECDSAPPSOracle creates a new instance of IECDSAPPSOracle, bound to a specific deployed contract.
func NewIECDSAPPSOracle(address common.Address, backend bind.ContractBackend) (*IECDSAPPSOracle, error) {
	contract, err := bindIECDSAPPSOracle(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &IECDSAPPSOracle{IECDSAPPSOracleCaller: IECDSAPPSOracleCaller{contract: contract}, IECDSAPPSOracleTransactor: IECDSAPPSOracleTransactor{contract: contract}, IECDSAPPSOracleFilterer: IECDSAPPSOracleFilterer{contract: contract}}, nil
}

// NewIECDSAPPSOracleCaller creates a new read-only instance of IECDSAPPSOracle, bound to a specific deployed contract.
func NewIECDSAPPSOracleCaller(address common.Address, caller bind.ContractCaller) (*IECDSAPPSOracleCaller, error) {
	contract, err := bindIECDSAPPSOracle(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &IECDSAPPSOracleCaller{contract: contract}, nil
}

// NewIECDSAPPSOracleTransactor creates a new write-only instance of IECDSAPPSOracle, bound to a specific deployed contract.
func NewIECDSAPPSOracleTransactor(address common.Address, transactor bind.ContractTransactor) (*IECDSAPPSOracleTransactor, error) {
	contract, err := bindIECDSAPPSOracle(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &IECDSAPPSOracleTransactor{contract: contract}, nil
}

// NewIECDSAPPSOracleFilterer creates a new log filterer instance of IECDSAPPSOracle, bound to a specific deployed contract.
func NewIECDSAPPSOracleFilterer(address common.Address, filterer bind.ContractFilterer) (*IECDSAPPSOracleFilterer, error) {
	contract, err := bindIECDSAPPSOracle(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &IECDSAPPSOracleFilterer{contract: contract}, nil
}

// bindIECDSAPPSOracle binds a generic wrapper to an already deployed contract.
func bindIECDSAPPSOracle(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := IECDSAPPSOracleMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_IECDSAPPSOracle *IECDSAPPSOracleRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _IECDSAPPSOracle.Contract.IECDSAPPSOracleCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_IECDSAPPSOracle *IECDSAPPSOracleRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _IECDSAPPSOracle.Contract.IECDSAPPSOracleTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_IECDSAPPSOracle *IECDSAPPSOracleRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _IECDSAPPSOracle.Contract.IECDSAPPSOracleTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_IECDSAPPSOracle *IECDSAPPSOracleCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _IECDSAPPSOracle.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_IECDSAPPSOracle *IECDSAPPSOracleTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _IECDSAPPSOracle.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_IECDSAPPSOracle *IECDSAPPSOracleTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _IECDSAPPSOracle.Contract.contract.Transact(opts, method, params...)
}

// UPDATEPPSTYPEHASH is a free data retrieval call binding the contract method 0xe2c42656.
//
// Solidity: function UPDATE_PPS_TYPEHASH() view returns(bytes32)
func (_IECDSAPPSOracle *IECDSAPPSOracleCaller) UPDATEPPSTYPEHASH(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _IECDSAPPSOracle.contract.Call(opts, &out, "UPDATE_PPS_TYPEHASH")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// UPDATEPPSTYPEHASH is a free data retrieval call binding the contract method 0xe2c42656.
//
// Solidity: function UPDATE_PPS_TYPEHASH() view returns(bytes32)
func (_IECDSAPPSOracle *IECDSAPPSOracleSession) UPDATEPPSTYPEHASH() ([32]byte, error) {
	return _IECDSAPPSOracle.Contract.UPDATEPPSTYPEHASH(&_IECDSAPPSOracle.CallOpts)
}

// UPDATEPPSTYPEHASH is a free data retrieval call binding the contract method 0xe2c42656.
//
// Solidity: function UPDATE_PPS_TYPEHASH() view returns(bytes32)
func (_IECDSAPPSOracle *IECDSAPPSOracleCallerSession) UPDATEPPSTYPEHASH() ([32]byte, error) {
	return _IECDSAPPSOracle.Contract.UPDATEPPSTYPEHASH(&_IECDSAPPSOracle.CallOpts)
}

// DomainSeparator is a free data retrieval call binding the contract method 0xf698da25.
//
// Solidity: function domainSeparator() view returns(bytes32)
func (_IECDSAPPSOracle *IECDSAPPSOracleCaller) DomainSeparator(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _IECDSAPPSOracle.contract.Call(opts, &out, "domainSeparator")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DomainSeparator is a free data retrieval call binding the contract method 0xf698da25.
//
// Solidity: function domainSeparator() view returns(bytes32)
func (_IECDSAPPSOracle *IECDSAPPSOracleSession) DomainSeparator() ([32]byte, error) {
	return _IECDSAPPSOracle.Contract.DomainSeparator(&_IECDSAPPSOracle.CallOpts)
}

// DomainSeparator is a free data retrieval call binding the contract method 0xf698da25.
//
// Solidity: function domainSeparator() view returns(bytes32)
func (_IECDSAPPSOracle *IECDSAPPSOracleCallerSession) DomainSeparator() ([32]byte, error) {
	return _IECDSAPPSOracle.Contract.DomainSeparator(&_IECDSAPPSOracle.CallOpts)
}

// NoncePerStrategy is a free data retrieval call binding the contract method 0xe1e86edc.
//
// Solidity: function noncePerStrategy(address strategy_) view returns(uint256)
func (_IECDSAPPSOracle *IECDSAPPSOracleCaller) NoncePerStrategy(opts *bind.CallOpts, strategy_ common.Address) (*big.Int, error) {
	var out []interface{}
	err := _IECDSAPPSOracle.contract.Call(opts, &out, "noncePerStrategy", strategy_)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// NoncePerStrategy is a free data retrieval call binding the contract method 0xe1e86edc.
//
// Solidity: function noncePerStrategy(address strategy_) view returns(uint256)
func (_IECDSAPPSOracle *IECDSAPPSOracleSession) NoncePerStrategy(strategy_ common.Address) (*big.Int, error) {
	return _IECDSAPPSOracle.Contract.NoncePerStrategy(&_IECDSAPPSOracle.CallOpts, strategy_)
}

// NoncePerStrategy is a free data retrieval call binding the contract method 0xe1e86edc.
//
// Solidity: function noncePerStrategy(address strategy_) view returns(uint256)
func (_IECDSAPPSOracle *IECDSAPPSOracleCallerSession) NoncePerStrategy(strategy_ common.Address) (*big.Int, error) {
	return _IECDSAPPSOracle.Contract.NoncePerStrategy(&_IECDSAPPSOracle.CallOpts, strategy_)
}

// ValidateProofs is a free data retrieval call binding the contract method 0x047ff5ad.
//
// Solidity: function validateProofs((address,bytes[],uint256,uint256,uint256,uint256,uint256) params) view returns()
func (_IECDSAPPSOracle *IECDSAPPSOracleCaller) ValidateProofs(opts *bind.CallOpts, params IECDSAPPSOracleValidationParams) error {
	var out []interface{}
	err := _IECDSAPPSOracle.contract.Call(opts, &out, "validateProofs", params)

	if err != nil {
		return err
	}

	return err

}

// ValidateProofs is a free data retrieval call binding the contract method 0x047ff5ad.
//
// Solidity: function validateProofs((address,bytes[],uint256,uint256,uint256,uint256,uint256) params) view returns()
func (_IECDSAPPSOracle *IECDSAPPSOracleSession) ValidateProofs(params IECDSAPPSOracleValidationParams) error {
	return _IECDSAPPSOracle.Contract.ValidateProofs(&_IECDSAPPSOracle.CallOpts, params)
}

// ValidateProofs is a free data retrieval call binding the contract method 0x047ff5ad.
//
// Solidity: function validateProofs((address,bytes[],uint256,uint256,uint256,uint256,uint256) params) view returns()
func (_IECDSAPPSOracle *IECDSAPPSOracleCallerSession) ValidateProofs(params IECDSAPPSOracleValidationParams) error {
	return _IECDSAPPSOracle.Contract.ValidateProofs(&_IECDSAPPSOracle.CallOpts, params)
}

// ValidateProofs0 is a free data retrieval call binding the contract method 0xc5bd4aab.
//
// Solidity: function validateProofs((address,bytes[],uint256,uint256,uint256,uint256,uint256) params, uint256 cachedTotalValidators, uint256 requiredQuorum) view returns()
func (_IECDSAPPSOracle *IECDSAPPSOracleCaller) ValidateProofs0(opts *bind.CallOpts, params IECDSAPPSOracleValidationParams, cachedTotalValidators *big.Int, requiredQuorum *big.Int) error {
	var out []interface{}
	err := _IECDSAPPSOracle.contract.Call(opts, &out, "validateProofs0", params, cachedTotalValidators, requiredQuorum)

	if err != nil {
		return err
	}

	return err

}

// ValidateProofs0 is a free data retrieval call binding the contract method 0xc5bd4aab.
//
// Solidity: function validateProofs((address,bytes[],uint256,uint256,uint256,uint256,uint256) params, uint256 cachedTotalValidators, uint256 requiredQuorum) view returns()
func (_IECDSAPPSOracle *IECDSAPPSOracleSession) ValidateProofs0(params IECDSAPPSOracleValidationParams, cachedTotalValidators *big.Int, requiredQuorum *big.Int) error {
	return _IECDSAPPSOracle.Contract.ValidateProofs0(&_IECDSAPPSOracle.CallOpts, params, cachedTotalValidators, requiredQuorum)
}

// ValidateProofs0 is a free data retrieval call binding the contract method 0xc5bd4aab.
//
// Solidity: function validateProofs((address,bytes[],uint256,uint256,uint256,uint256,uint256) params, uint256 cachedTotalValidators, uint256 requiredQuorum) view returns()
func (_IECDSAPPSOracle *IECDSAPPSOracleCallerSession) ValidateProofs0(params IECDSAPPSOracleValidationParams, cachedTotalValidators *big.Int, requiredQuorum *big.Int) error {
	return _IECDSAPPSOracle.Contract.ValidateProofs0(&_IECDSAPPSOracle.CallOpts, params, cachedTotalValidators, requiredQuorum)
}

// UpdatePPS is a paid mutator transaction binding the contract method 0xb2aaa967.
//
// Solidity: function updatePPS((address[],bytes[][],uint256[],uint256[],uint256[],uint256[],uint256[]) args) returns()
func (_IECDSAPPSOracle *IECDSAPPSOracleTransactor) UpdatePPS(opts *bind.TransactOpts, args IECDSAPPSOracleUpdatePPSArgs) (*types.Transaction, error) {
	return _IECDSAPPSOracle.contract.Transact(opts, "updatePPS", args)
}

// UpdatePPS is a paid mutator transaction binding the contract method 0xb2aaa967.
//
// Solidity: function updatePPS((address[],bytes[][],uint256[],uint256[],uint256[],uint256[],uint256[]) args) returns()
func (_IECDSAPPSOracle *IECDSAPPSOracleSession) UpdatePPS(args IECDSAPPSOracleUpdatePPSArgs) (*types.Transaction, error) {
	return _IECDSAPPSOracle.Contract.UpdatePPS(&_IECDSAPPSOracle.TransactOpts, args)
}

// UpdatePPS is a paid mutator transaction binding the contract method 0xb2aaa967.
//
// Solidity: function updatePPS((address[],bytes[][],uint256[],uint256[],uint256[],uint256[],uint256[]) args) returns()
func (_IECDSAPPSOracle *IECDSAPPSOracleTransactorSession) UpdatePPS(args IECDSAPPSOracleUpdatePPSArgs) (*types.Transaction, error) {
	return _IECDSAPPSOracle.Contract.UpdatePPS(&_IECDSAPPSOracle.TransactOpts, args)
}

// IECDSAPPSOracleBatchForwardPPSFailedIterator is returned from FilterBatchForwardPPSFailed and is used to iterate over the raw logs and unpacked data for BatchForwardPPSFailed events raised by the IECDSAPPSOracle contract.
type IECDSAPPSOracleBatchForwardPPSFailedIterator struct {
	Event *IECDSAPPSOracleBatchForwardPPSFailed // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *IECDSAPPSOracleBatchForwardPPSFailedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(IECDSAPPSOracleBatchForwardPPSFailed)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(IECDSAPPSOracleBatchForwardPPSFailed)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *IECDSAPPSOracleBatchForwardPPSFailedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *IECDSAPPSOracleBatchForwardPPSFailedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// IECDSAPPSOracleBatchForwardPPSFailed represents a BatchForwardPPSFailed event raised by the IECDSAPPSOracle contract.
type IECDSAPPSOracleBatchForwardPPSFailed struct {
	Reason string
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterBatchForwardPPSFailed is a free log retrieval operation binding the contract event 0x76327474cf24da9a3ca187cce345d66144c7edc1bea0b4595fb2e0a15bbf3bf9.
//
// Solidity: event BatchForwardPPSFailed(string reason)
func (_IECDSAPPSOracle *IECDSAPPSOracleFilterer) FilterBatchForwardPPSFailed(opts *bind.FilterOpts) (*IECDSAPPSOracleBatchForwardPPSFailedIterator, error) {

	logs, sub, err := _IECDSAPPSOracle.contract.FilterLogs(opts, "BatchForwardPPSFailed")
	if err != nil {
		return nil, err
	}
	return &IECDSAPPSOracleBatchForwardPPSFailedIterator{contract: _IECDSAPPSOracle.contract, event: "BatchForwardPPSFailed", logs: logs, sub: sub}, nil
}

// WatchBatchForwardPPSFailed is a free log subscription operation binding the contract event 0x76327474cf24da9a3ca187cce345d66144c7edc1bea0b4595fb2e0a15bbf3bf9.
//
// Solidity: event BatchForwardPPSFailed(string reason)
func (_IECDSAPPSOracle *IECDSAPPSOracleFilterer) WatchBatchForwardPPSFailed(opts *bind.WatchOpts, sink chan<- *IECDSAPPSOracleBatchForwardPPSFailed) (event.Subscription, error) {

	logs, sub, err := _IECDSAPPSOracle.contract.WatchLogs(opts, "BatchForwardPPSFailed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(IECDSAPPSOracleBatchForwardPPSFailed)
				if err := _IECDSAPPSOracle.contract.UnpackLog(event, "BatchForwardPPSFailed", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseBatchForwardPPSFailed is a log parse operation binding the contract event 0x76327474cf24da9a3ca187cce345d66144c7edc1bea0b4595fb2e0a15bbf3bf9.
//
// Solidity: event BatchForwardPPSFailed(string reason)
func (_IECDSAPPSOracle *IECDSAPPSOracleFilterer) ParseBatchForwardPPSFailed(log types.Log) (*IECDSAPPSOracleBatchForwardPPSFailed, error) {
	event := new(IECDSAPPSOracleBatchForwardPPSFailed)
	if err := _IECDSAPPSOracle.contract.UnpackLog(event, "BatchForwardPPSFailed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// IECDSAPPSOracleBatchForwardPPSFailedLowLevelIterator is returned from FilterBatchForwardPPSFailedLowLevel and is used to iterate over the raw logs and unpacked data for BatchForwardPPSFailedLowLevel events raised by the IECDSAPPSOracle contract.
type IECDSAPPSOracleBatchForwardPPSFailedLowLevelIterator struct {
	Event *IECDSAPPSOracleBatchForwardPPSFailedLowLevel // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *IECDSAPPSOracleBatchForwardPPSFailedLowLevelIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(IECDSAPPSOracleBatchForwardPPSFailedLowLevel)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(IECDSAPPSOracleBatchForwardPPSFailedLowLevel)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *IECDSAPPSOracleBatchForwardPPSFailedLowLevelIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *IECDSAPPSOracleBatchForwardPPSFailedLowLevelIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// IECDSAPPSOracleBatchForwardPPSFailedLowLevel represents a BatchForwardPPSFailedLowLevel event raised by the IECDSAPPSOracle contract.
type IECDSAPPSOracleBatchForwardPPSFailedLowLevel struct {
	LowLevelData []byte
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterBatchForwardPPSFailedLowLevel is a free log retrieval operation binding the contract event 0xa52bfbf922afe2d72308fa5c2c094b23921d8c0d8511e1b6f7767aa3c32255d8.
//
// Solidity: event BatchForwardPPSFailedLowLevel(bytes lowLevelData)
func (_IECDSAPPSOracle *IECDSAPPSOracleFilterer) FilterBatchForwardPPSFailedLowLevel(opts *bind.FilterOpts) (*IECDSAPPSOracleBatchForwardPPSFailedLowLevelIterator, error) {

	logs, sub, err := _IECDSAPPSOracle.contract.FilterLogs(opts, "BatchForwardPPSFailedLowLevel")
	if err != nil {
		return nil, err
	}
	return &IECDSAPPSOracleBatchForwardPPSFailedLowLevelIterator{contract: _IECDSAPPSOracle.contract, event: "BatchForwardPPSFailedLowLevel", logs: logs, sub: sub}, nil
}

// WatchBatchForwardPPSFailedLowLevel is a free log subscription operation binding the contract event 0xa52bfbf922afe2d72308fa5c2c094b23921d8c0d8511e1b6f7767aa3c32255d8.
//
// Solidity: event BatchForwardPPSFailedLowLevel(bytes lowLevelData)
func (_IECDSAPPSOracle *IECDSAPPSOracleFilterer) WatchBatchForwardPPSFailedLowLevel(opts *bind.WatchOpts, sink chan<- *IECDSAPPSOracleBatchForwardPPSFailedLowLevel) (event.Subscription, error) {

	logs, sub, err := _IECDSAPPSOracle.contract.WatchLogs(opts, "BatchForwardPPSFailedLowLevel")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(IECDSAPPSOracleBatchForwardPPSFailedLowLevel)
				if err := _IECDSAPPSOracle.contract.UnpackLog(event, "BatchForwardPPSFailedLowLevel", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseBatchForwardPPSFailedLowLevel is a log parse operation binding the contract event 0xa52bfbf922afe2d72308fa5c2c094b23921d8c0d8511e1b6f7767aa3c32255d8.
//
// Solidity: event BatchForwardPPSFailedLowLevel(bytes lowLevelData)
func (_IECDSAPPSOracle *IECDSAPPSOracleFilterer) ParseBatchForwardPPSFailedLowLevel(log types.Log) (*IECDSAPPSOracleBatchForwardPPSFailedLowLevel, error) {
	event := new(IECDSAPPSOracleBatchForwardPPSFailedLowLevel)
	if err := _IECDSAPPSOracle.contract.UnpackLog(event, "BatchForwardPPSFailedLowLevel", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// IECDSAPPSOracleInsufficientGasForForwardIterator is returned from FilterInsufficientGasForForward and is used to iterate over the raw logs and unpacked data for InsufficientGasForForward events raised by the IECDSAPPSOracle contract.
type IECDSAPPSOracleInsufficientGasForForwardIterator struct {
	Event *IECDSAPPSOracleInsufficientGasForForward // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *IECDSAPPSOracleInsufficientGasForForwardIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(IECDSAPPSOracleInsufficientGasForForward)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(IECDSAPPSOracleInsufficientGasForForward)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *IECDSAPPSOracleInsufficientGasForForwardIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *IECDSAPPSOracleInsufficientGasForForwardIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// IECDSAPPSOracleInsufficientGasForForward represents a InsufficientGasForForward event raised by the IECDSAPPSOracle contract.
type IECDSAPPSOracleInsufficientGasForForward struct {
	GasLeft     *big.Int
	RequiredGas *big.Int
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterInsufficientGasForForward is a free log retrieval operation binding the contract event 0x92a29f6ec9a5c0291fa4acf5fdccec764f8931ce4cc00a2e1fb04a1e36062a11.
//
// Solidity: event InsufficientGasForForward(uint256 gasLeft, uint256 requiredGas)
func (_IECDSAPPSOracle *IECDSAPPSOracleFilterer) FilterInsufficientGasForForward(opts *bind.FilterOpts) (*IECDSAPPSOracleInsufficientGasForForwardIterator, error) {

	logs, sub, err := _IECDSAPPSOracle.contract.FilterLogs(opts, "InsufficientGasForForward")
	if err != nil {
		return nil, err
	}
	return &IECDSAPPSOracleInsufficientGasForForwardIterator{contract: _IECDSAPPSOracle.contract, event: "InsufficientGasForForward", logs: logs, sub: sub}, nil
}

// WatchInsufficientGasForForward is a free log subscription operation binding the contract event 0x92a29f6ec9a5c0291fa4acf5fdccec764f8931ce4cc00a2e1fb04a1e36062a11.
//
// Solidity: event InsufficientGasForForward(uint256 gasLeft, uint256 requiredGas)
func (_IECDSAPPSOracle *IECDSAPPSOracleFilterer) WatchInsufficientGasForForward(opts *bind.WatchOpts, sink chan<- *IECDSAPPSOracleInsufficientGasForForward) (event.Subscription, error) {

	logs, sub, err := _IECDSAPPSOracle.contract.WatchLogs(opts, "InsufficientGasForForward")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(IECDSAPPSOracleInsufficientGasForForward)
				if err := _IECDSAPPSOracle.contract.UnpackLog(event, "InsufficientGasForForward", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseInsufficientGasForForward is a log parse operation binding the contract event 0x92a29f6ec9a5c0291fa4acf5fdccec764f8931ce4cc00a2e1fb04a1e36062a11.
//
// Solidity: event InsufficientGasForForward(uint256 gasLeft, uint256 requiredGas)
func (_IECDSAPPSOracle *IECDSAPPSOracleFilterer) ParseInsufficientGasForForward(log types.Log) (*IECDSAPPSOracleInsufficientGasForForward, error) {
	event := new(IECDSAPPSOracleInsufficientGasForForward)
	if err := _IECDSAPPSOracle.contract.UnpackLog(event, "InsufficientGasForForward", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// IECDSAPPSOraclePPSValidatedIterator is returned from FilterPPSValidated and is used to iterate over the raw logs and unpacked data for PPSValidated events raised by the IECDSAPPSOracle contract.
type IECDSAPPSOraclePPSValidatedIterator struct {
	Event *IECDSAPPSOraclePPSValidated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *IECDSAPPSOraclePPSValidatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(IECDSAPPSOraclePPSValidated)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(IECDSAPPSOraclePPSValidated)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *IECDSAPPSOraclePPSValidatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *IECDSAPPSOraclePPSValidatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// IECDSAPPSOraclePPSValidated represents a PPSValidated event raised by the IECDSAPPSOracle contract.
type IECDSAPPSOraclePPSValidated struct {
	Strategy        common.Address
	Pps             *big.Int
	PpsStdev        *big.Int
	ValidatorSet    *big.Int
	TotalValidators *big.Int
	Timestamp       *big.Int
	Sender          common.Address
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterPPSValidated is a free log retrieval operation binding the contract event 0xfbdd9422833aff4d04333f008c0d33063458b4050c51fbd4f1eeb2cea915e954.
//
// Solidity: event PPSValidated(address indexed strategy, uint256 pps, uint256 ppsStdev, uint256 validatorSet, uint256 totalValidators, uint256 timestamp, address indexed sender)
func (_IECDSAPPSOracle *IECDSAPPSOracleFilterer) FilterPPSValidated(opts *bind.FilterOpts, strategy []common.Address, sender []common.Address) (*IECDSAPPSOraclePPSValidatedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _IECDSAPPSOracle.contract.FilterLogs(opts, "PPSValidated", strategyRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &IECDSAPPSOraclePPSValidatedIterator{contract: _IECDSAPPSOracle.contract, event: "PPSValidated", logs: logs, sub: sub}, nil
}

// WatchPPSValidated is a free log subscription operation binding the contract event 0xfbdd9422833aff4d04333f008c0d33063458b4050c51fbd4f1eeb2cea915e954.
//
// Solidity: event PPSValidated(address indexed strategy, uint256 pps, uint256 ppsStdev, uint256 validatorSet, uint256 totalValidators, uint256 timestamp, address indexed sender)
func (_IECDSAPPSOracle *IECDSAPPSOracleFilterer) WatchPPSValidated(opts *bind.WatchOpts, sink chan<- *IECDSAPPSOraclePPSValidated, strategy []common.Address, sender []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _IECDSAPPSOracle.contract.WatchLogs(opts, "PPSValidated", strategyRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(IECDSAPPSOraclePPSValidated)
				if err := _IECDSAPPSOracle.contract.UnpackLog(event, "PPSValidated", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParsePPSValidated is a log parse operation binding the contract event 0xfbdd9422833aff4d04333f008c0d33063458b4050c51fbd4f1eeb2cea915e954.
//
// Solidity: event PPSValidated(address indexed strategy, uint256 pps, uint256 ppsStdev, uint256 validatorSet, uint256 totalValidators, uint256 timestamp, address indexed sender)
func (_IECDSAPPSOracle *IECDSAPPSOracleFilterer) ParsePPSValidated(log types.Log) (*IECDSAPPSOraclePPSValidated, error) {
	event := new(IECDSAPPSOraclePPSValidated)
	if err := _IECDSAPPSOracle.contract.UnpackLog(event, "PPSValidated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// IECDSAPPSOracleProofValidationFailedIterator is returned from FilterProofValidationFailed and is used to iterate over the raw logs and unpacked data for ProofValidationFailed events raised by the IECDSAPPSOracle contract.
type IECDSAPPSOracleProofValidationFailedIterator struct {
	Event *IECDSAPPSOracleProofValidationFailed // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *IECDSAPPSOracleProofValidationFailedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(IECDSAPPSOracleProofValidationFailed)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(IECDSAPPSOracleProofValidationFailed)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *IECDSAPPSOracleProofValidationFailedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *IECDSAPPSOracleProofValidationFailedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// IECDSAPPSOracleProofValidationFailed represents a ProofValidationFailed event raised by the IECDSAPPSOracle contract.
type IECDSAPPSOracleProofValidationFailed struct {
	Strategy common.Address
	Reason   string
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterProofValidationFailed is a free log retrieval operation binding the contract event 0xd515726916f48939288f55b95c9c10f4b3b63b7ed16b334257d4a1f91d67bb37.
//
// Solidity: event ProofValidationFailed(address indexed strategy, string reason)
func (_IECDSAPPSOracle *IECDSAPPSOracleFilterer) FilterProofValidationFailed(opts *bind.FilterOpts, strategy []common.Address) (*IECDSAPPSOracleProofValidationFailedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _IECDSAPPSOracle.contract.FilterLogs(opts, "ProofValidationFailed", strategyRule)
	if err != nil {
		return nil, err
	}
	return &IECDSAPPSOracleProofValidationFailedIterator{contract: _IECDSAPPSOracle.contract, event: "ProofValidationFailed", logs: logs, sub: sub}, nil
}

// WatchProofValidationFailed is a free log subscription operation binding the contract event 0xd515726916f48939288f55b95c9c10f4b3b63b7ed16b334257d4a1f91d67bb37.
//
// Solidity: event ProofValidationFailed(address indexed strategy, string reason)
func (_IECDSAPPSOracle *IECDSAPPSOracleFilterer) WatchProofValidationFailed(opts *bind.WatchOpts, sink chan<- *IECDSAPPSOracleProofValidationFailed, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _IECDSAPPSOracle.contract.WatchLogs(opts, "ProofValidationFailed", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(IECDSAPPSOracleProofValidationFailed)
				if err := _IECDSAPPSOracle.contract.UnpackLog(event, "ProofValidationFailed", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseProofValidationFailed is a log parse operation binding the contract event 0xd515726916f48939288f55b95c9c10f4b3b63b7ed16b334257d4a1f91d67bb37.
//
// Solidity: event ProofValidationFailed(address indexed strategy, string reason)
func (_IECDSAPPSOracle *IECDSAPPSOracleFilterer) ParseProofValidationFailed(log types.Log) (*IECDSAPPSOracleProofValidationFailed, error) {
	event := new(IECDSAPPSOracleProofValidationFailed)
	if err := _IECDSAPPSOracle.contract.UnpackLog(event, "ProofValidationFailed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// IECDSAPPSOracleProofValidationFailedLowLevelIterator is returned from FilterProofValidationFailedLowLevel and is used to iterate over the raw logs and unpacked data for ProofValidationFailedLowLevel events raised by the IECDSAPPSOracle contract.
type IECDSAPPSOracleProofValidationFailedLowLevelIterator struct {
	Event *IECDSAPPSOracleProofValidationFailedLowLevel // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *IECDSAPPSOracleProofValidationFailedLowLevelIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(IECDSAPPSOracleProofValidationFailedLowLevel)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(IECDSAPPSOracleProofValidationFailedLowLevel)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *IECDSAPPSOracleProofValidationFailedLowLevelIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *IECDSAPPSOracleProofValidationFailedLowLevelIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// IECDSAPPSOracleProofValidationFailedLowLevel represents a ProofValidationFailedLowLevel event raised by the IECDSAPPSOracle contract.
type IECDSAPPSOracleProofValidationFailedLowLevel struct {
	Strategy common.Address
	Data     []byte
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterProofValidationFailedLowLevel is a free log retrieval operation binding the contract event 0x0120ac3ec8e7663a13f8db6b3b68d56bc1176068ea11b71dca46ed12288bbca0.
//
// Solidity: event ProofValidationFailedLowLevel(address indexed strategy, bytes data)
func (_IECDSAPPSOracle *IECDSAPPSOracleFilterer) FilterProofValidationFailedLowLevel(opts *bind.FilterOpts, strategy []common.Address) (*IECDSAPPSOracleProofValidationFailedLowLevelIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _IECDSAPPSOracle.contract.FilterLogs(opts, "ProofValidationFailedLowLevel", strategyRule)
	if err != nil {
		return nil, err
	}
	return &IECDSAPPSOracleProofValidationFailedLowLevelIterator{contract: _IECDSAPPSOracle.contract, event: "ProofValidationFailedLowLevel", logs: logs, sub: sub}, nil
}

// WatchProofValidationFailedLowLevel is a free log subscription operation binding the contract event 0x0120ac3ec8e7663a13f8db6b3b68d56bc1176068ea11b71dca46ed12288bbca0.
//
// Solidity: event ProofValidationFailedLowLevel(address indexed strategy, bytes data)
func (_IECDSAPPSOracle *IECDSAPPSOracleFilterer) WatchProofValidationFailedLowLevel(opts *bind.WatchOpts, sink chan<- *IECDSAPPSOracleProofValidationFailedLowLevel, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _IECDSAPPSOracle.contract.WatchLogs(opts, "ProofValidationFailedLowLevel", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(IECDSAPPSOracleProofValidationFailedLowLevel)
				if err := _IECDSAPPSOracle.contract.UnpackLog(event, "ProofValidationFailedLowLevel", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseProofValidationFailedLowLevel is a log parse operation binding the contract event 0x0120ac3ec8e7663a13f8db6b3b68d56bc1176068ea11b71dca46ed12288bbca0.
//
// Solidity: event ProofValidationFailedLowLevel(address indexed strategy, bytes data)
func (_IECDSAPPSOracle *IECDSAPPSOracleFilterer) ParseProofValidationFailedLowLevel(log types.Log) (*IECDSAPPSOracleProofValidationFailedLowLevel, error) {
	event := new(IECDSAPPSOracleProofValidationFailedLowLevel)
	if err := _IECDSAPPSOracle.contract.UnpackLog(event, "ProofValidationFailedLowLevel", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
