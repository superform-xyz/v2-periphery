// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package MockAggregator

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

// MockAggregatorMetaData contains all meta data concerning the MockAggregator contract.
var MockAggregatorMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"answer_\",\"type\":\"int256\",\"internalType\":\"int256\"},{\"name\":\"decimals_\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"decimals\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"description\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"getRoundData\",\"inputs\":[{\"name\":\"\",\"type\":\"uint80\",\"internalType\":\"uint80\"}],\"outputs\":[{\"name\":\"roundId\",\"type\":\"uint80\",\"internalType\":\"uint80\"},{\"name\":\"answer\",\"type\":\"int256\",\"internalType\":\"int256\"},{\"name\":\"startedAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"updatedAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"answeredInRound\",\"type\":\"uint80\",\"internalType\":\"uint80\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"latestRoundData\",\"inputs\":[],\"outputs\":[{\"name\":\"roundId\",\"type\":\"uint80\",\"internalType\":\"uint80\"},{\"name\":\"answer\",\"type\":\"int256\",\"internalType\":\"int256\"},{\"name\":\"startedAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"updatedAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"answeredInRound\",\"type\":\"uint80\",\"internalType\":\"uint80\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"setAnswer\",\"inputs\":[{\"name\":\"answer_\",\"type\":\"int256\",\"internalType\":\"int256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setUpdatedAt\",\"inputs\":[{\"name\":\"updatedAt_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"version\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"pure\"}]",
}

// MockAggregatorABI is the input ABI used to generate the binding from.
// Deprecated: Use MockAggregatorMetaData.ABI instead.
var MockAggregatorABI = MockAggregatorMetaData.ABI

// MockAggregator is an auto generated Go binding around an Ethereum contract.
type MockAggregator struct {
	MockAggregatorCaller     // Read-only binding to the contract
	MockAggregatorTransactor // Write-only binding to the contract
	MockAggregatorFilterer   // Log filterer for contract events
}

// MockAggregatorCaller is an auto generated read-only Go binding around an Ethereum contract.
type MockAggregatorCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockAggregatorTransactor is an auto generated write-only Go binding around an Ethereum contract.
type MockAggregatorTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockAggregatorFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type MockAggregatorFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockAggregatorSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type MockAggregatorSession struct {
	Contract     *MockAggregator   // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// MockAggregatorCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type MockAggregatorCallerSession struct {
	Contract *MockAggregatorCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts         // Call options to use throughout this session
}

// MockAggregatorTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type MockAggregatorTransactorSession struct {
	Contract     *MockAggregatorTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts         // Transaction auth options to use throughout this session
}

// MockAggregatorRaw is an auto generated low-level Go binding around an Ethereum contract.
type MockAggregatorRaw struct {
	Contract *MockAggregator // Generic contract binding to access the raw methods on
}

// MockAggregatorCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type MockAggregatorCallerRaw struct {
	Contract *MockAggregatorCaller // Generic read-only contract binding to access the raw methods on
}

// MockAggregatorTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type MockAggregatorTransactorRaw struct {
	Contract *MockAggregatorTransactor // Generic write-only contract binding to access the raw methods on
}

// NewMockAggregator creates a new instance of MockAggregator, bound to a specific deployed contract.
func NewMockAggregator(address common.Address, backend bind.ContractBackend) (*MockAggregator, error) {
	contract, err := bindMockAggregator(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &MockAggregator{MockAggregatorCaller: MockAggregatorCaller{contract: contract}, MockAggregatorTransactor: MockAggregatorTransactor{contract: contract}, MockAggregatorFilterer: MockAggregatorFilterer{contract: contract}}, nil
}

// NewMockAggregatorCaller creates a new read-only instance of MockAggregator, bound to a specific deployed contract.
func NewMockAggregatorCaller(address common.Address, caller bind.ContractCaller) (*MockAggregatorCaller, error) {
	contract, err := bindMockAggregator(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &MockAggregatorCaller{contract: contract}, nil
}

// NewMockAggregatorTransactor creates a new write-only instance of MockAggregator, bound to a specific deployed contract.
func NewMockAggregatorTransactor(address common.Address, transactor bind.ContractTransactor) (*MockAggregatorTransactor, error) {
	contract, err := bindMockAggregator(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &MockAggregatorTransactor{contract: contract}, nil
}

// NewMockAggregatorFilterer creates a new log filterer instance of MockAggregator, bound to a specific deployed contract.
func NewMockAggregatorFilterer(address common.Address, filterer bind.ContractFilterer) (*MockAggregatorFilterer, error) {
	contract, err := bindMockAggregator(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &MockAggregatorFilterer{contract: contract}, nil
}

// bindMockAggregator binds a generic wrapper to an already deployed contract.
func bindMockAggregator(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := MockAggregatorMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MockAggregator *MockAggregatorRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MockAggregator.Contract.MockAggregatorCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MockAggregator *MockAggregatorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockAggregator.Contract.MockAggregatorTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MockAggregator *MockAggregatorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MockAggregator.Contract.MockAggregatorTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MockAggregator *MockAggregatorCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MockAggregator.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MockAggregator *MockAggregatorTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockAggregator.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MockAggregator *MockAggregatorTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MockAggregator.Contract.contract.Transact(opts, method, params...)
}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint8)
func (_MockAggregator *MockAggregatorCaller) Decimals(opts *bind.CallOpts) (uint8, error) {
	var out []interface{}
	err := _MockAggregator.contract.Call(opts, &out, "decimals")

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint8)
func (_MockAggregator *MockAggregatorSession) Decimals() (uint8, error) {
	return _MockAggregator.Contract.Decimals(&_MockAggregator.CallOpts)
}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint8)
func (_MockAggregator *MockAggregatorCallerSession) Decimals() (uint8, error) {
	return _MockAggregator.Contract.Decimals(&_MockAggregator.CallOpts)
}

// Description is a free data retrieval call binding the contract method 0x7284e416.
//
// Solidity: function description() pure returns(string)
func (_MockAggregator *MockAggregatorCaller) Description(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _MockAggregator.contract.Call(opts, &out, "description")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Description is a free data retrieval call binding the contract method 0x7284e416.
//
// Solidity: function description() pure returns(string)
func (_MockAggregator *MockAggregatorSession) Description() (string, error) {
	return _MockAggregator.Contract.Description(&_MockAggregator.CallOpts)
}

// Description is a free data retrieval call binding the contract method 0x7284e416.
//
// Solidity: function description() pure returns(string)
func (_MockAggregator *MockAggregatorCallerSession) Description() (string, error) {
	return _MockAggregator.Contract.Description(&_MockAggregator.CallOpts)
}

// GetRoundData is a free data retrieval call binding the contract method 0x9a6fc8f5.
//
// Solidity: function getRoundData(uint80 ) view returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
func (_MockAggregator *MockAggregatorCaller) GetRoundData(opts *bind.CallOpts, arg0 *big.Int) (struct {
	RoundId         *big.Int
	Answer          *big.Int
	StartedAt       *big.Int
	UpdatedAt       *big.Int
	AnsweredInRound *big.Int
}, error) {
	var out []interface{}
	err := _MockAggregator.contract.Call(opts, &out, "getRoundData", arg0)

	outstruct := new(struct {
		RoundId         *big.Int
		Answer          *big.Int
		StartedAt       *big.Int
		UpdatedAt       *big.Int
		AnsweredInRound *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.RoundId = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.Answer = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.StartedAt = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.UpdatedAt = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)
	outstruct.AnsweredInRound = *abi.ConvertType(out[4], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// GetRoundData is a free data retrieval call binding the contract method 0x9a6fc8f5.
//
// Solidity: function getRoundData(uint80 ) view returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
func (_MockAggregator *MockAggregatorSession) GetRoundData(arg0 *big.Int) (struct {
	RoundId         *big.Int
	Answer          *big.Int
	StartedAt       *big.Int
	UpdatedAt       *big.Int
	AnsweredInRound *big.Int
}, error) {
	return _MockAggregator.Contract.GetRoundData(&_MockAggregator.CallOpts, arg0)
}

// GetRoundData is a free data retrieval call binding the contract method 0x9a6fc8f5.
//
// Solidity: function getRoundData(uint80 ) view returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
func (_MockAggregator *MockAggregatorCallerSession) GetRoundData(arg0 *big.Int) (struct {
	RoundId         *big.Int
	Answer          *big.Int
	StartedAt       *big.Int
	UpdatedAt       *big.Int
	AnsweredInRound *big.Int
}, error) {
	return _MockAggregator.Contract.GetRoundData(&_MockAggregator.CallOpts, arg0)
}

// LatestRoundData is a free data retrieval call binding the contract method 0xfeaf968c.
//
// Solidity: function latestRoundData() view returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
func (_MockAggregator *MockAggregatorCaller) LatestRoundData(opts *bind.CallOpts) (struct {
	RoundId         *big.Int
	Answer          *big.Int
	StartedAt       *big.Int
	UpdatedAt       *big.Int
	AnsweredInRound *big.Int
}, error) {
	var out []interface{}
	err := _MockAggregator.contract.Call(opts, &out, "latestRoundData")

	outstruct := new(struct {
		RoundId         *big.Int
		Answer          *big.Int
		StartedAt       *big.Int
		UpdatedAt       *big.Int
		AnsweredInRound *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.RoundId = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.Answer = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.StartedAt = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.UpdatedAt = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)
	outstruct.AnsweredInRound = *abi.ConvertType(out[4], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// LatestRoundData is a free data retrieval call binding the contract method 0xfeaf968c.
//
// Solidity: function latestRoundData() view returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
func (_MockAggregator *MockAggregatorSession) LatestRoundData() (struct {
	RoundId         *big.Int
	Answer          *big.Int
	StartedAt       *big.Int
	UpdatedAt       *big.Int
	AnsweredInRound *big.Int
}, error) {
	return _MockAggregator.Contract.LatestRoundData(&_MockAggregator.CallOpts)
}

// LatestRoundData is a free data retrieval call binding the contract method 0xfeaf968c.
//
// Solidity: function latestRoundData() view returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
func (_MockAggregator *MockAggregatorCallerSession) LatestRoundData() (struct {
	RoundId         *big.Int
	Answer          *big.Int
	StartedAt       *big.Int
	UpdatedAt       *big.Int
	AnsweredInRound *big.Int
}, error) {
	return _MockAggregator.Contract.LatestRoundData(&_MockAggregator.CallOpts)
}

// Version is a free data retrieval call binding the contract method 0x54fd4d50.
//
// Solidity: function version() pure returns(uint256)
func (_MockAggregator *MockAggregatorCaller) Version(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MockAggregator.contract.Call(opts, &out, "version")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Version is a free data retrieval call binding the contract method 0x54fd4d50.
//
// Solidity: function version() pure returns(uint256)
func (_MockAggregator *MockAggregatorSession) Version() (*big.Int, error) {
	return _MockAggregator.Contract.Version(&_MockAggregator.CallOpts)
}

// Version is a free data retrieval call binding the contract method 0x54fd4d50.
//
// Solidity: function version() pure returns(uint256)
func (_MockAggregator *MockAggregatorCallerSession) Version() (*big.Int, error) {
	return _MockAggregator.Contract.Version(&_MockAggregator.CallOpts)
}

// SetAnswer is a paid mutator transaction binding the contract method 0x99213cd8.
//
// Solidity: function setAnswer(int256 answer_) returns()
func (_MockAggregator *MockAggregatorTransactor) SetAnswer(opts *bind.TransactOpts, answer_ *big.Int) (*types.Transaction, error) {
	return _MockAggregator.contract.Transact(opts, "setAnswer", answer_)
}

// SetAnswer is a paid mutator transaction binding the contract method 0x99213cd8.
//
// Solidity: function setAnswer(int256 answer_) returns()
func (_MockAggregator *MockAggregatorSession) SetAnswer(answer_ *big.Int) (*types.Transaction, error) {
	return _MockAggregator.Contract.SetAnswer(&_MockAggregator.TransactOpts, answer_)
}

// SetAnswer is a paid mutator transaction binding the contract method 0x99213cd8.
//
// Solidity: function setAnswer(int256 answer_) returns()
func (_MockAggregator *MockAggregatorTransactorSession) SetAnswer(answer_ *big.Int) (*types.Transaction, error) {
	return _MockAggregator.Contract.SetAnswer(&_MockAggregator.TransactOpts, answer_)
}

// SetUpdatedAt is a paid mutator transaction binding the contract method 0x1ecc7d88.
//
// Solidity: function setUpdatedAt(uint256 updatedAt_) returns()
func (_MockAggregator *MockAggregatorTransactor) SetUpdatedAt(opts *bind.TransactOpts, updatedAt_ *big.Int) (*types.Transaction, error) {
	return _MockAggregator.contract.Transact(opts, "setUpdatedAt", updatedAt_)
}

// SetUpdatedAt is a paid mutator transaction binding the contract method 0x1ecc7d88.
//
// Solidity: function setUpdatedAt(uint256 updatedAt_) returns()
func (_MockAggregator *MockAggregatorSession) SetUpdatedAt(updatedAt_ *big.Int) (*types.Transaction, error) {
	return _MockAggregator.Contract.SetUpdatedAt(&_MockAggregator.TransactOpts, updatedAt_)
}

// SetUpdatedAt is a paid mutator transaction binding the contract method 0x1ecc7d88.
//
// Solidity: function setUpdatedAt(uint256 updatedAt_) returns()
func (_MockAggregator *MockAggregatorTransactorSession) SetUpdatedAt(updatedAt_ *big.Int) (*types.Transaction, error) {
	return _MockAggregator.Contract.SetUpdatedAt(&_MockAggregator.TransactOpts, updatedAt_)
}
