// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package MockSuperOracle

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

// MockSuperOracleMetaData contains all meta data concerning the MockSuperOracle contract.
var MockSuperOracleMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"_quoteAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"decimals\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"executeProviderRemoval\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getQuote\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getQuoteFromProvider\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"providerRemoved\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"queueProviderRemoval\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"quoteAmount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"setQuoteAmount\",\"inputs\":[{\"name\":\"_quoteAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"error\",\"name\":\"OracleUnsupportedPair\",\"inputs\":[{\"name\":\"base\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"quote\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OracleUntrustedData\",\"inputs\":[{\"name\":\"base\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"quote\",\"type\":\"address\",\"internalType\":\"address\"}]}]",
}

// MockSuperOracleABI is the input ABI used to generate the binding from.
// Deprecated: Use MockSuperOracleMetaData.ABI instead.
var MockSuperOracleABI = MockSuperOracleMetaData.ABI

// MockSuperOracle is an auto generated Go binding around an Ethereum contract.
type MockSuperOracle struct {
	MockSuperOracleCaller     // Read-only binding to the contract
	MockSuperOracleTransactor // Write-only binding to the contract
	MockSuperOracleFilterer   // Log filterer for contract events
}

// MockSuperOracleCaller is an auto generated read-only Go binding around an Ethereum contract.
type MockSuperOracleCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockSuperOracleTransactor is an auto generated write-only Go binding around an Ethereum contract.
type MockSuperOracleTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockSuperOracleFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type MockSuperOracleFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockSuperOracleSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type MockSuperOracleSession struct {
	Contract     *MockSuperOracle  // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// MockSuperOracleCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type MockSuperOracleCallerSession struct {
	Contract *MockSuperOracleCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts          // Call options to use throughout this session
}

// MockSuperOracleTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type MockSuperOracleTransactorSession struct {
	Contract     *MockSuperOracleTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts          // Transaction auth options to use throughout this session
}

// MockSuperOracleRaw is an auto generated low-level Go binding around an Ethereum contract.
type MockSuperOracleRaw struct {
	Contract *MockSuperOracle // Generic contract binding to access the raw methods on
}

// MockSuperOracleCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type MockSuperOracleCallerRaw struct {
	Contract *MockSuperOracleCaller // Generic read-only contract binding to access the raw methods on
}

// MockSuperOracleTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type MockSuperOracleTransactorRaw struct {
	Contract *MockSuperOracleTransactor // Generic write-only contract binding to access the raw methods on
}

// NewMockSuperOracle creates a new instance of MockSuperOracle, bound to a specific deployed contract.
func NewMockSuperOracle(address common.Address, backend bind.ContractBackend) (*MockSuperOracle, error) {
	contract, err := bindMockSuperOracle(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &MockSuperOracle{MockSuperOracleCaller: MockSuperOracleCaller{contract: contract}, MockSuperOracleTransactor: MockSuperOracleTransactor{contract: contract}, MockSuperOracleFilterer: MockSuperOracleFilterer{contract: contract}}, nil
}

// NewMockSuperOracleCaller creates a new read-only instance of MockSuperOracle, bound to a specific deployed contract.
func NewMockSuperOracleCaller(address common.Address, caller bind.ContractCaller) (*MockSuperOracleCaller, error) {
	contract, err := bindMockSuperOracle(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &MockSuperOracleCaller{contract: contract}, nil
}

// NewMockSuperOracleTransactor creates a new write-only instance of MockSuperOracle, bound to a specific deployed contract.
func NewMockSuperOracleTransactor(address common.Address, transactor bind.ContractTransactor) (*MockSuperOracleTransactor, error) {
	contract, err := bindMockSuperOracle(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &MockSuperOracleTransactor{contract: contract}, nil
}

// NewMockSuperOracleFilterer creates a new log filterer instance of MockSuperOracle, bound to a specific deployed contract.
func NewMockSuperOracleFilterer(address common.Address, filterer bind.ContractFilterer) (*MockSuperOracleFilterer, error) {
	contract, err := bindMockSuperOracle(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &MockSuperOracleFilterer{contract: contract}, nil
}

// bindMockSuperOracle binds a generic wrapper to an already deployed contract.
func bindMockSuperOracle(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := MockSuperOracleMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MockSuperOracle *MockSuperOracleRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MockSuperOracle.Contract.MockSuperOracleCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MockSuperOracle *MockSuperOracleRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockSuperOracle.Contract.MockSuperOracleTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MockSuperOracle *MockSuperOracleRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MockSuperOracle.Contract.MockSuperOracleTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MockSuperOracle *MockSuperOracleCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MockSuperOracle.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MockSuperOracle *MockSuperOracleTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockSuperOracle.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MockSuperOracle *MockSuperOracleTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MockSuperOracle.Contract.contract.Transact(opts, method, params...)
}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() pure returns(uint8)
func (_MockSuperOracle *MockSuperOracleCaller) Decimals(opts *bind.CallOpts) (uint8, error) {
	var out []interface{}
	err := _MockSuperOracle.contract.Call(opts, &out, "decimals")

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() pure returns(uint8)
func (_MockSuperOracle *MockSuperOracleSession) Decimals() (uint8, error) {
	return _MockSuperOracle.Contract.Decimals(&_MockSuperOracle.CallOpts)
}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() pure returns(uint8)
func (_MockSuperOracle *MockSuperOracleCallerSession) Decimals() (uint8, error) {
	return _MockSuperOracle.Contract.Decimals(&_MockSuperOracle.CallOpts)
}

// GetQuote is a free data retrieval call binding the contract method 0xae68676c.
//
// Solidity: function getQuote(uint256 , address , address ) view returns(uint256)
func (_MockSuperOracle *MockSuperOracleCaller) GetQuote(opts *bind.CallOpts, arg0 *big.Int, arg1 common.Address, arg2 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _MockSuperOracle.contract.Call(opts, &out, "getQuote", arg0, arg1, arg2)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetQuote is a free data retrieval call binding the contract method 0xae68676c.
//
// Solidity: function getQuote(uint256 , address , address ) view returns(uint256)
func (_MockSuperOracle *MockSuperOracleSession) GetQuote(arg0 *big.Int, arg1 common.Address, arg2 common.Address) (*big.Int, error) {
	return _MockSuperOracle.Contract.GetQuote(&_MockSuperOracle.CallOpts, arg0, arg1, arg2)
}

// GetQuote is a free data retrieval call binding the contract method 0xae68676c.
//
// Solidity: function getQuote(uint256 , address , address ) view returns(uint256)
func (_MockSuperOracle *MockSuperOracleCallerSession) GetQuote(arg0 *big.Int, arg1 common.Address, arg2 common.Address) (*big.Int, error) {
	return _MockSuperOracle.Contract.GetQuote(&_MockSuperOracle.CallOpts, arg0, arg1, arg2)
}

// GetQuoteFromProvider is a free data retrieval call binding the contract method 0xeacc8037.
//
// Solidity: function getQuoteFromProvider(uint256 , address , address , bytes32 ) view returns(uint256, uint256, uint256, uint256)
func (_MockSuperOracle *MockSuperOracleCaller) GetQuoteFromProvider(opts *bind.CallOpts, arg0 *big.Int, arg1 common.Address, arg2 common.Address, arg3 [32]byte) (*big.Int, *big.Int, *big.Int, *big.Int, error) {
	var out []interface{}
	err := _MockSuperOracle.contract.Call(opts, &out, "getQuoteFromProvider", arg0, arg1, arg2, arg3)

	if err != nil {
		return *new(*big.Int), *new(*big.Int), *new(*big.Int), *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	out1 := *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	out2 := *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	out3 := *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)

	return out0, out1, out2, out3, err

}

// GetQuoteFromProvider is a free data retrieval call binding the contract method 0xeacc8037.
//
// Solidity: function getQuoteFromProvider(uint256 , address , address , bytes32 ) view returns(uint256, uint256, uint256, uint256)
func (_MockSuperOracle *MockSuperOracleSession) GetQuoteFromProvider(arg0 *big.Int, arg1 common.Address, arg2 common.Address, arg3 [32]byte) (*big.Int, *big.Int, *big.Int, *big.Int, error) {
	return _MockSuperOracle.Contract.GetQuoteFromProvider(&_MockSuperOracle.CallOpts, arg0, arg1, arg2, arg3)
}

// GetQuoteFromProvider is a free data retrieval call binding the contract method 0xeacc8037.
//
// Solidity: function getQuoteFromProvider(uint256 , address , address , bytes32 ) view returns(uint256, uint256, uint256, uint256)
func (_MockSuperOracle *MockSuperOracleCallerSession) GetQuoteFromProvider(arg0 *big.Int, arg1 common.Address, arg2 common.Address, arg3 [32]byte) (*big.Int, *big.Int, *big.Int, *big.Int, error) {
	return _MockSuperOracle.Contract.GetQuoteFromProvider(&_MockSuperOracle.CallOpts, arg0, arg1, arg2, arg3)
}

// ProviderRemoved is a free data retrieval call binding the contract method 0xf5e27c77.
//
// Solidity: function providerRemoved() view returns(bool)
func (_MockSuperOracle *MockSuperOracleCaller) ProviderRemoved(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _MockSuperOracle.contract.Call(opts, &out, "providerRemoved")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// ProviderRemoved is a free data retrieval call binding the contract method 0xf5e27c77.
//
// Solidity: function providerRemoved() view returns(bool)
func (_MockSuperOracle *MockSuperOracleSession) ProviderRemoved() (bool, error) {
	return _MockSuperOracle.Contract.ProviderRemoved(&_MockSuperOracle.CallOpts)
}

// ProviderRemoved is a free data retrieval call binding the contract method 0xf5e27c77.
//
// Solidity: function providerRemoved() view returns(bool)
func (_MockSuperOracle *MockSuperOracleCallerSession) ProviderRemoved() (bool, error) {
	return _MockSuperOracle.Contract.ProviderRemoved(&_MockSuperOracle.CallOpts)
}

// QuoteAmount is a free data retrieval call binding the contract method 0x0d40886d.
//
// Solidity: function quoteAmount() view returns(uint256)
func (_MockSuperOracle *MockSuperOracleCaller) QuoteAmount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MockSuperOracle.contract.Call(opts, &out, "quoteAmount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// QuoteAmount is a free data retrieval call binding the contract method 0x0d40886d.
//
// Solidity: function quoteAmount() view returns(uint256)
func (_MockSuperOracle *MockSuperOracleSession) QuoteAmount() (*big.Int, error) {
	return _MockSuperOracle.Contract.QuoteAmount(&_MockSuperOracle.CallOpts)
}

// QuoteAmount is a free data retrieval call binding the contract method 0x0d40886d.
//
// Solidity: function quoteAmount() view returns(uint256)
func (_MockSuperOracle *MockSuperOracleCallerSession) QuoteAmount() (*big.Int, error) {
	return _MockSuperOracle.Contract.QuoteAmount(&_MockSuperOracle.CallOpts)
}

// ExecuteProviderRemoval is a paid mutator transaction binding the contract method 0x41cad0bf.
//
// Solidity: function executeProviderRemoval() returns()
func (_MockSuperOracle *MockSuperOracleTransactor) ExecuteProviderRemoval(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockSuperOracle.contract.Transact(opts, "executeProviderRemoval")
}

// ExecuteProviderRemoval is a paid mutator transaction binding the contract method 0x41cad0bf.
//
// Solidity: function executeProviderRemoval() returns()
func (_MockSuperOracle *MockSuperOracleSession) ExecuteProviderRemoval() (*types.Transaction, error) {
	return _MockSuperOracle.Contract.ExecuteProviderRemoval(&_MockSuperOracle.TransactOpts)
}

// ExecuteProviderRemoval is a paid mutator transaction binding the contract method 0x41cad0bf.
//
// Solidity: function executeProviderRemoval() returns()
func (_MockSuperOracle *MockSuperOracleTransactorSession) ExecuteProviderRemoval() (*types.Transaction, error) {
	return _MockSuperOracle.Contract.ExecuteProviderRemoval(&_MockSuperOracle.TransactOpts)
}

// QueueProviderRemoval is a paid mutator transaction binding the contract method 0x2e8d764a.
//
// Solidity: function queueProviderRemoval(bytes32[] ) returns()
func (_MockSuperOracle *MockSuperOracleTransactor) QueueProviderRemoval(opts *bind.TransactOpts, arg0 [][32]byte) (*types.Transaction, error) {
	return _MockSuperOracle.contract.Transact(opts, "queueProviderRemoval", arg0)
}

// QueueProviderRemoval is a paid mutator transaction binding the contract method 0x2e8d764a.
//
// Solidity: function queueProviderRemoval(bytes32[] ) returns()
func (_MockSuperOracle *MockSuperOracleSession) QueueProviderRemoval(arg0 [][32]byte) (*types.Transaction, error) {
	return _MockSuperOracle.Contract.QueueProviderRemoval(&_MockSuperOracle.TransactOpts, arg0)
}

// QueueProviderRemoval is a paid mutator transaction binding the contract method 0x2e8d764a.
//
// Solidity: function queueProviderRemoval(bytes32[] ) returns()
func (_MockSuperOracle *MockSuperOracleTransactorSession) QueueProviderRemoval(arg0 [][32]byte) (*types.Transaction, error) {
	return _MockSuperOracle.Contract.QueueProviderRemoval(&_MockSuperOracle.TransactOpts, arg0)
}

// SetQuoteAmount is a paid mutator transaction binding the contract method 0x4e15d283.
//
// Solidity: function setQuoteAmount(uint256 _quoteAmount) returns()
func (_MockSuperOracle *MockSuperOracleTransactor) SetQuoteAmount(opts *bind.TransactOpts, _quoteAmount *big.Int) (*types.Transaction, error) {
	return _MockSuperOracle.contract.Transact(opts, "setQuoteAmount", _quoteAmount)
}

// SetQuoteAmount is a paid mutator transaction binding the contract method 0x4e15d283.
//
// Solidity: function setQuoteAmount(uint256 _quoteAmount) returns()
func (_MockSuperOracle *MockSuperOracleSession) SetQuoteAmount(_quoteAmount *big.Int) (*types.Transaction, error) {
	return _MockSuperOracle.Contract.SetQuoteAmount(&_MockSuperOracle.TransactOpts, _quoteAmount)
}

// SetQuoteAmount is a paid mutator transaction binding the contract method 0x4e15d283.
//
// Solidity: function setQuoteAmount(uint256 _quoteAmount) returns()
func (_MockSuperOracle *MockSuperOracleTransactorSession) SetQuoteAmount(_quoteAmount *big.Int) (*types.Transaction, error) {
	return _MockSuperOracle.Contract.SetQuoteAmount(&_MockSuperOracle.TransactOpts, _quoteAmount)
}
