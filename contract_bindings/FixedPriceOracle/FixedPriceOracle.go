// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package FixedPriceOracle

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

// FixedPriceOracleMetaData contains all meta data concerning the FixedPriceOracle contract.
var FixedPriceOracleMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"initialPrice\",\"type\":\"int256\",\"internalType\":\"int256\"},{\"name\":\"decimals_\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"owner_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"decimals\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"description\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"getRoundData\",\"inputs\":[{\"name\":\"_roundId\",\"type\":\"uint80\",\"internalType\":\"uint80\"}],\"outputs\":[{\"name\":\"roundId\",\"type\":\"uint80\",\"internalType\":\"uint80\"},{\"name\":\"answer\",\"type\":\"int256\",\"internalType\":\"int256\"},{\"name\":\"startedAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"updatedAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"answeredInRound\",\"type\":\"uint80\",\"internalType\":\"uint80\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getTimestamp\",\"inputs\":[{\"name\":\"_roundId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"latestAnswer\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"latestRoundData\",\"inputs\":[],\"outputs\":[{\"name\":\"roundId\",\"type\":\"uint80\",\"internalType\":\"uint80\"},{\"name\":\"answer\",\"type\":\"int256\",\"internalType\":\"int256\"},{\"name\":\"startedAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"updatedAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"answeredInRound\",\"type\":\"uint80\",\"internalType\":\"uint80\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"phaseAggregators\",\"inputs\":[{\"name\":\"_phaseId\",\"type\":\"uint16\",\"internalType\":\"uint16\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"phaseId\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint16\",\"internalType\":\"uint16\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setDecimals\",\"inputs\":[{\"name\":\"newDecimals\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setPrice\",\"inputs\":[{\"name\":\"newPrice\",\"type\":\"int256\",\"internalType\":\"int256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"version\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"pure\"},{\"type\":\"event\",\"name\":\"DecimalsUpdated\",\"inputs\":[{\"name\":\"oldDecimals\",\"type\":\"uint8\",\"indexed\":false,\"internalType\":\"uint8\"},{\"name\":\"newDecimals\",\"type\":\"uint8\",\"indexed\":false,\"internalType\":\"uint8\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PriceUpdated\",\"inputs\":[{\"name\":\"oldPrice\",\"type\":\"int256\",\"indexed\":false,\"internalType\":\"int256\"},{\"name\":\"newPrice\",\"type\":\"int256\",\"indexed\":false,\"internalType\":\"int256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"INVALID_PRICE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"OwnableInvalidOwner\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]}]",
}

// FixedPriceOracleABI is the input ABI used to generate the binding from.
// Deprecated: Use FixedPriceOracleMetaData.ABI instead.
var FixedPriceOracleABI = FixedPriceOracleMetaData.ABI

// FixedPriceOracle is an auto generated Go binding around an Ethereum contract.
type FixedPriceOracle struct {
	FixedPriceOracleCaller     // Read-only binding to the contract
	FixedPriceOracleTransactor // Write-only binding to the contract
	FixedPriceOracleFilterer   // Log filterer for contract events
}

// FixedPriceOracleCaller is an auto generated read-only Go binding around an Ethereum contract.
type FixedPriceOracleCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// FixedPriceOracleTransactor is an auto generated write-only Go binding around an Ethereum contract.
type FixedPriceOracleTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// FixedPriceOracleFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type FixedPriceOracleFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// FixedPriceOracleSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type FixedPriceOracleSession struct {
	Contract     *FixedPriceOracle // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// FixedPriceOracleCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type FixedPriceOracleCallerSession struct {
	Contract *FixedPriceOracleCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts           // Call options to use throughout this session
}

// FixedPriceOracleTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type FixedPriceOracleTransactorSession struct {
	Contract     *FixedPriceOracleTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts           // Transaction auth options to use throughout this session
}

// FixedPriceOracleRaw is an auto generated low-level Go binding around an Ethereum contract.
type FixedPriceOracleRaw struct {
	Contract *FixedPriceOracle // Generic contract binding to access the raw methods on
}

// FixedPriceOracleCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type FixedPriceOracleCallerRaw struct {
	Contract *FixedPriceOracleCaller // Generic read-only contract binding to access the raw methods on
}

// FixedPriceOracleTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type FixedPriceOracleTransactorRaw struct {
	Contract *FixedPriceOracleTransactor // Generic write-only contract binding to access the raw methods on
}

// NewFixedPriceOracle creates a new instance of FixedPriceOracle, bound to a specific deployed contract.
func NewFixedPriceOracle(address common.Address, backend bind.ContractBackend) (*FixedPriceOracle, error) {
	contract, err := bindFixedPriceOracle(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &FixedPriceOracle{FixedPriceOracleCaller: FixedPriceOracleCaller{contract: contract}, FixedPriceOracleTransactor: FixedPriceOracleTransactor{contract: contract}, FixedPriceOracleFilterer: FixedPriceOracleFilterer{contract: contract}}, nil
}

// NewFixedPriceOracleCaller creates a new read-only instance of FixedPriceOracle, bound to a specific deployed contract.
func NewFixedPriceOracleCaller(address common.Address, caller bind.ContractCaller) (*FixedPriceOracleCaller, error) {
	contract, err := bindFixedPriceOracle(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &FixedPriceOracleCaller{contract: contract}, nil
}

// NewFixedPriceOracleTransactor creates a new write-only instance of FixedPriceOracle, bound to a specific deployed contract.
func NewFixedPriceOracleTransactor(address common.Address, transactor bind.ContractTransactor) (*FixedPriceOracleTransactor, error) {
	contract, err := bindFixedPriceOracle(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &FixedPriceOracleTransactor{contract: contract}, nil
}

// NewFixedPriceOracleFilterer creates a new log filterer instance of FixedPriceOracle, bound to a specific deployed contract.
func NewFixedPriceOracleFilterer(address common.Address, filterer bind.ContractFilterer) (*FixedPriceOracleFilterer, error) {
	contract, err := bindFixedPriceOracle(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &FixedPriceOracleFilterer{contract: contract}, nil
}

// bindFixedPriceOracle binds a generic wrapper to an already deployed contract.
func bindFixedPriceOracle(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := FixedPriceOracleMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_FixedPriceOracle *FixedPriceOracleRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _FixedPriceOracle.Contract.FixedPriceOracleCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_FixedPriceOracle *FixedPriceOracleRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _FixedPriceOracle.Contract.FixedPriceOracleTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_FixedPriceOracle *FixedPriceOracleRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _FixedPriceOracle.Contract.FixedPriceOracleTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_FixedPriceOracle *FixedPriceOracleCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _FixedPriceOracle.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_FixedPriceOracle *FixedPriceOracleTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _FixedPriceOracle.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_FixedPriceOracle *FixedPriceOracleTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _FixedPriceOracle.Contract.contract.Transact(opts, method, params...)
}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint8)
func (_FixedPriceOracle *FixedPriceOracleCaller) Decimals(opts *bind.CallOpts) (uint8, error) {
	var out []interface{}
	err := _FixedPriceOracle.contract.Call(opts, &out, "decimals")

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint8)
func (_FixedPriceOracle *FixedPriceOracleSession) Decimals() (uint8, error) {
	return _FixedPriceOracle.Contract.Decimals(&_FixedPriceOracle.CallOpts)
}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint8)
func (_FixedPriceOracle *FixedPriceOracleCallerSession) Decimals() (uint8, error) {
	return _FixedPriceOracle.Contract.Decimals(&_FixedPriceOracle.CallOpts)
}

// Description is a free data retrieval call binding the contract method 0x7284e416.
//
// Solidity: function description() pure returns(string)
func (_FixedPriceOracle *FixedPriceOracleCaller) Description(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _FixedPriceOracle.contract.Call(opts, &out, "description")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Description is a free data retrieval call binding the contract method 0x7284e416.
//
// Solidity: function description() pure returns(string)
func (_FixedPriceOracle *FixedPriceOracleSession) Description() (string, error) {
	return _FixedPriceOracle.Contract.Description(&_FixedPriceOracle.CallOpts)
}

// Description is a free data retrieval call binding the contract method 0x7284e416.
//
// Solidity: function description() pure returns(string)
func (_FixedPriceOracle *FixedPriceOracleCallerSession) Description() (string, error) {
	return _FixedPriceOracle.Contract.Description(&_FixedPriceOracle.CallOpts)
}

// GetRoundData is a free data retrieval call binding the contract method 0x9a6fc8f5.
//
// Solidity: function getRoundData(uint80 _roundId) view returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
func (_FixedPriceOracle *FixedPriceOracleCaller) GetRoundData(opts *bind.CallOpts, _roundId *big.Int) (struct {
	RoundId         *big.Int
	Answer          *big.Int
	StartedAt       *big.Int
	UpdatedAt       *big.Int
	AnsweredInRound *big.Int
}, error) {
	var out []interface{}
	err := _FixedPriceOracle.contract.Call(opts, &out, "getRoundData", _roundId)

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
// Solidity: function getRoundData(uint80 _roundId) view returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
func (_FixedPriceOracle *FixedPriceOracleSession) GetRoundData(_roundId *big.Int) (struct {
	RoundId         *big.Int
	Answer          *big.Int
	StartedAt       *big.Int
	UpdatedAt       *big.Int
	AnsweredInRound *big.Int
}, error) {
	return _FixedPriceOracle.Contract.GetRoundData(&_FixedPriceOracle.CallOpts, _roundId)
}

// GetRoundData is a free data retrieval call binding the contract method 0x9a6fc8f5.
//
// Solidity: function getRoundData(uint80 _roundId) view returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
func (_FixedPriceOracle *FixedPriceOracleCallerSession) GetRoundData(_roundId *big.Int) (struct {
	RoundId         *big.Int
	Answer          *big.Int
	StartedAt       *big.Int
	UpdatedAt       *big.Int
	AnsweredInRound *big.Int
}, error) {
	return _FixedPriceOracle.Contract.GetRoundData(&_FixedPriceOracle.CallOpts, _roundId)
}

// GetTimestamp is a free data retrieval call binding the contract method 0xb633620c.
//
// Solidity: function getTimestamp(uint256 _roundId) view returns(uint256)
func (_FixedPriceOracle *FixedPriceOracleCaller) GetTimestamp(opts *bind.CallOpts, _roundId *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _FixedPriceOracle.contract.Call(opts, &out, "getTimestamp", _roundId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetTimestamp is a free data retrieval call binding the contract method 0xb633620c.
//
// Solidity: function getTimestamp(uint256 _roundId) view returns(uint256)
func (_FixedPriceOracle *FixedPriceOracleSession) GetTimestamp(_roundId *big.Int) (*big.Int, error) {
	return _FixedPriceOracle.Contract.GetTimestamp(&_FixedPriceOracle.CallOpts, _roundId)
}

// GetTimestamp is a free data retrieval call binding the contract method 0xb633620c.
//
// Solidity: function getTimestamp(uint256 _roundId) view returns(uint256)
func (_FixedPriceOracle *FixedPriceOracleCallerSession) GetTimestamp(_roundId *big.Int) (*big.Int, error) {
	return _FixedPriceOracle.Contract.GetTimestamp(&_FixedPriceOracle.CallOpts, _roundId)
}

// LatestAnswer is a free data retrieval call binding the contract method 0x50d25bcd.
//
// Solidity: function latestAnswer() view returns(uint256)
func (_FixedPriceOracle *FixedPriceOracleCaller) LatestAnswer(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _FixedPriceOracle.contract.Call(opts, &out, "latestAnswer")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// LatestAnswer is a free data retrieval call binding the contract method 0x50d25bcd.
//
// Solidity: function latestAnswer() view returns(uint256)
func (_FixedPriceOracle *FixedPriceOracleSession) LatestAnswer() (*big.Int, error) {
	return _FixedPriceOracle.Contract.LatestAnswer(&_FixedPriceOracle.CallOpts)
}

// LatestAnswer is a free data retrieval call binding the contract method 0x50d25bcd.
//
// Solidity: function latestAnswer() view returns(uint256)
func (_FixedPriceOracle *FixedPriceOracleCallerSession) LatestAnswer() (*big.Int, error) {
	return _FixedPriceOracle.Contract.LatestAnswer(&_FixedPriceOracle.CallOpts)
}

// LatestRoundData is a free data retrieval call binding the contract method 0xfeaf968c.
//
// Solidity: function latestRoundData() view returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
func (_FixedPriceOracle *FixedPriceOracleCaller) LatestRoundData(opts *bind.CallOpts) (struct {
	RoundId         *big.Int
	Answer          *big.Int
	StartedAt       *big.Int
	UpdatedAt       *big.Int
	AnsweredInRound *big.Int
}, error) {
	var out []interface{}
	err := _FixedPriceOracle.contract.Call(opts, &out, "latestRoundData")

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
func (_FixedPriceOracle *FixedPriceOracleSession) LatestRoundData() (struct {
	RoundId         *big.Int
	Answer          *big.Int
	StartedAt       *big.Int
	UpdatedAt       *big.Int
	AnsweredInRound *big.Int
}, error) {
	return _FixedPriceOracle.Contract.LatestRoundData(&_FixedPriceOracle.CallOpts)
}

// LatestRoundData is a free data retrieval call binding the contract method 0xfeaf968c.
//
// Solidity: function latestRoundData() view returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
func (_FixedPriceOracle *FixedPriceOracleCallerSession) LatestRoundData() (struct {
	RoundId         *big.Int
	Answer          *big.Int
	StartedAt       *big.Int
	UpdatedAt       *big.Int
	AnsweredInRound *big.Int
}, error) {
	return _FixedPriceOracle.Contract.LatestRoundData(&_FixedPriceOracle.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_FixedPriceOracle *FixedPriceOracleCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _FixedPriceOracle.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_FixedPriceOracle *FixedPriceOracleSession) Owner() (common.Address, error) {
	return _FixedPriceOracle.Contract.Owner(&_FixedPriceOracle.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_FixedPriceOracle *FixedPriceOracleCallerSession) Owner() (common.Address, error) {
	return _FixedPriceOracle.Contract.Owner(&_FixedPriceOracle.CallOpts)
}

// PhaseAggregators is a free data retrieval call binding the contract method 0xc1597304.
//
// Solidity: function phaseAggregators(uint16 _phaseId) view returns(address)
func (_FixedPriceOracle *FixedPriceOracleCaller) PhaseAggregators(opts *bind.CallOpts, _phaseId uint16) (common.Address, error) {
	var out []interface{}
	err := _FixedPriceOracle.contract.Call(opts, &out, "phaseAggregators", _phaseId)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// PhaseAggregators is a free data retrieval call binding the contract method 0xc1597304.
//
// Solidity: function phaseAggregators(uint16 _phaseId) view returns(address)
func (_FixedPriceOracle *FixedPriceOracleSession) PhaseAggregators(_phaseId uint16) (common.Address, error) {
	return _FixedPriceOracle.Contract.PhaseAggregators(&_FixedPriceOracle.CallOpts, _phaseId)
}

// PhaseAggregators is a free data retrieval call binding the contract method 0xc1597304.
//
// Solidity: function phaseAggregators(uint16 _phaseId) view returns(address)
func (_FixedPriceOracle *FixedPriceOracleCallerSession) PhaseAggregators(_phaseId uint16) (common.Address, error) {
	return _FixedPriceOracle.Contract.PhaseAggregators(&_FixedPriceOracle.CallOpts, _phaseId)
}

// PhaseId is a free data retrieval call binding the contract method 0x58303b10.
//
// Solidity: function phaseId() pure returns(uint16)
func (_FixedPriceOracle *FixedPriceOracleCaller) PhaseId(opts *bind.CallOpts) (uint16, error) {
	var out []interface{}
	err := _FixedPriceOracle.contract.Call(opts, &out, "phaseId")

	if err != nil {
		return *new(uint16), err
	}

	out0 := *abi.ConvertType(out[0], new(uint16)).(*uint16)

	return out0, err

}

// PhaseId is a free data retrieval call binding the contract method 0x58303b10.
//
// Solidity: function phaseId() pure returns(uint16)
func (_FixedPriceOracle *FixedPriceOracleSession) PhaseId() (uint16, error) {
	return _FixedPriceOracle.Contract.PhaseId(&_FixedPriceOracle.CallOpts)
}

// PhaseId is a free data retrieval call binding the contract method 0x58303b10.
//
// Solidity: function phaseId() pure returns(uint16)
func (_FixedPriceOracle *FixedPriceOracleCallerSession) PhaseId() (uint16, error) {
	return _FixedPriceOracle.Contract.PhaseId(&_FixedPriceOracle.CallOpts)
}

// Version is a free data retrieval call binding the contract method 0x54fd4d50.
//
// Solidity: function version() pure returns(uint256)
func (_FixedPriceOracle *FixedPriceOracleCaller) Version(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _FixedPriceOracle.contract.Call(opts, &out, "version")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Version is a free data retrieval call binding the contract method 0x54fd4d50.
//
// Solidity: function version() pure returns(uint256)
func (_FixedPriceOracle *FixedPriceOracleSession) Version() (*big.Int, error) {
	return _FixedPriceOracle.Contract.Version(&_FixedPriceOracle.CallOpts)
}

// Version is a free data retrieval call binding the contract method 0x54fd4d50.
//
// Solidity: function version() pure returns(uint256)
func (_FixedPriceOracle *FixedPriceOracleCallerSession) Version() (*big.Int, error) {
	return _FixedPriceOracle.Contract.Version(&_FixedPriceOracle.CallOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_FixedPriceOracle *FixedPriceOracleTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _FixedPriceOracle.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_FixedPriceOracle *FixedPriceOracleSession) RenounceOwnership() (*types.Transaction, error) {
	return _FixedPriceOracle.Contract.RenounceOwnership(&_FixedPriceOracle.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_FixedPriceOracle *FixedPriceOracleTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _FixedPriceOracle.Contract.RenounceOwnership(&_FixedPriceOracle.TransactOpts)
}

// SetDecimals is a paid mutator transaction binding the contract method 0x7a1395aa.
//
// Solidity: function setDecimals(uint8 newDecimals) returns()
func (_FixedPriceOracle *FixedPriceOracleTransactor) SetDecimals(opts *bind.TransactOpts, newDecimals uint8) (*types.Transaction, error) {
	return _FixedPriceOracle.contract.Transact(opts, "setDecimals", newDecimals)
}

// SetDecimals is a paid mutator transaction binding the contract method 0x7a1395aa.
//
// Solidity: function setDecimals(uint8 newDecimals) returns()
func (_FixedPriceOracle *FixedPriceOracleSession) SetDecimals(newDecimals uint8) (*types.Transaction, error) {
	return _FixedPriceOracle.Contract.SetDecimals(&_FixedPriceOracle.TransactOpts, newDecimals)
}

// SetDecimals is a paid mutator transaction binding the contract method 0x7a1395aa.
//
// Solidity: function setDecimals(uint8 newDecimals) returns()
func (_FixedPriceOracle *FixedPriceOracleTransactorSession) SetDecimals(newDecimals uint8) (*types.Transaction, error) {
	return _FixedPriceOracle.Contract.SetDecimals(&_FixedPriceOracle.TransactOpts, newDecimals)
}

// SetPrice is a paid mutator transaction binding the contract method 0xf7a30806.
//
// Solidity: function setPrice(int256 newPrice) returns()
func (_FixedPriceOracle *FixedPriceOracleTransactor) SetPrice(opts *bind.TransactOpts, newPrice *big.Int) (*types.Transaction, error) {
	return _FixedPriceOracle.contract.Transact(opts, "setPrice", newPrice)
}

// SetPrice is a paid mutator transaction binding the contract method 0xf7a30806.
//
// Solidity: function setPrice(int256 newPrice) returns()
func (_FixedPriceOracle *FixedPriceOracleSession) SetPrice(newPrice *big.Int) (*types.Transaction, error) {
	return _FixedPriceOracle.Contract.SetPrice(&_FixedPriceOracle.TransactOpts, newPrice)
}

// SetPrice is a paid mutator transaction binding the contract method 0xf7a30806.
//
// Solidity: function setPrice(int256 newPrice) returns()
func (_FixedPriceOracle *FixedPriceOracleTransactorSession) SetPrice(newPrice *big.Int) (*types.Transaction, error) {
	return _FixedPriceOracle.Contract.SetPrice(&_FixedPriceOracle.TransactOpts, newPrice)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_FixedPriceOracle *FixedPriceOracleTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _FixedPriceOracle.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_FixedPriceOracle *FixedPriceOracleSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _FixedPriceOracle.Contract.TransferOwnership(&_FixedPriceOracle.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_FixedPriceOracle *FixedPriceOracleTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _FixedPriceOracle.Contract.TransferOwnership(&_FixedPriceOracle.TransactOpts, newOwner)
}

// FixedPriceOracleDecimalsUpdatedIterator is returned from FilterDecimalsUpdated and is used to iterate over the raw logs and unpacked data for DecimalsUpdated events raised by the FixedPriceOracle contract.
type FixedPriceOracleDecimalsUpdatedIterator struct {
	Event *FixedPriceOracleDecimalsUpdated // Event containing the contract specifics and raw log

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
func (it *FixedPriceOracleDecimalsUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(FixedPriceOracleDecimalsUpdated)
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
		it.Event = new(FixedPriceOracleDecimalsUpdated)
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
func (it *FixedPriceOracleDecimalsUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *FixedPriceOracleDecimalsUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// FixedPriceOracleDecimalsUpdated represents a DecimalsUpdated event raised by the FixedPriceOracle contract.
type FixedPriceOracleDecimalsUpdated struct {
	OldDecimals uint8
	NewDecimals uint8
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterDecimalsUpdated is a free log retrieval operation binding the contract event 0xbb300b99407e7132db221db848f03bdc0743c8712b9c492868b94f4fb579d761.
//
// Solidity: event DecimalsUpdated(uint8 oldDecimals, uint8 newDecimals)
func (_FixedPriceOracle *FixedPriceOracleFilterer) FilterDecimalsUpdated(opts *bind.FilterOpts) (*FixedPriceOracleDecimalsUpdatedIterator, error) {

	logs, sub, err := _FixedPriceOracle.contract.FilterLogs(opts, "DecimalsUpdated")
	if err != nil {
		return nil, err
	}
	return &FixedPriceOracleDecimalsUpdatedIterator{contract: _FixedPriceOracle.contract, event: "DecimalsUpdated", logs: logs, sub: sub}, nil
}

// WatchDecimalsUpdated is a free log subscription operation binding the contract event 0xbb300b99407e7132db221db848f03bdc0743c8712b9c492868b94f4fb579d761.
//
// Solidity: event DecimalsUpdated(uint8 oldDecimals, uint8 newDecimals)
func (_FixedPriceOracle *FixedPriceOracleFilterer) WatchDecimalsUpdated(opts *bind.WatchOpts, sink chan<- *FixedPriceOracleDecimalsUpdated) (event.Subscription, error) {

	logs, sub, err := _FixedPriceOracle.contract.WatchLogs(opts, "DecimalsUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(FixedPriceOracleDecimalsUpdated)
				if err := _FixedPriceOracle.contract.UnpackLog(event, "DecimalsUpdated", log); err != nil {
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

// ParseDecimalsUpdated is a log parse operation binding the contract event 0xbb300b99407e7132db221db848f03bdc0743c8712b9c492868b94f4fb579d761.
//
// Solidity: event DecimalsUpdated(uint8 oldDecimals, uint8 newDecimals)
func (_FixedPriceOracle *FixedPriceOracleFilterer) ParseDecimalsUpdated(log types.Log) (*FixedPriceOracleDecimalsUpdated, error) {
	event := new(FixedPriceOracleDecimalsUpdated)
	if err := _FixedPriceOracle.contract.UnpackLog(event, "DecimalsUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// FixedPriceOracleOwnershipTransferredIterator is returned from FilterOwnershipTransferred and is used to iterate over the raw logs and unpacked data for OwnershipTransferred events raised by the FixedPriceOracle contract.
type FixedPriceOracleOwnershipTransferredIterator struct {
	Event *FixedPriceOracleOwnershipTransferred // Event containing the contract specifics and raw log

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
func (it *FixedPriceOracleOwnershipTransferredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(FixedPriceOracleOwnershipTransferred)
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
		it.Event = new(FixedPriceOracleOwnershipTransferred)
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
func (it *FixedPriceOracleOwnershipTransferredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *FixedPriceOracleOwnershipTransferredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// FixedPriceOracleOwnershipTransferred represents a OwnershipTransferred event raised by the FixedPriceOracle contract.
type FixedPriceOracleOwnershipTransferred struct {
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterOwnershipTransferred is a free log retrieval operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_FixedPriceOracle *FixedPriceOracleFilterer) FilterOwnershipTransferred(opts *bind.FilterOpts, previousOwner []common.Address, newOwner []common.Address) (*FixedPriceOracleOwnershipTransferredIterator, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _FixedPriceOracle.contract.FilterLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return &FixedPriceOracleOwnershipTransferredIterator{contract: _FixedPriceOracle.contract, event: "OwnershipTransferred", logs: logs, sub: sub}, nil
}

// WatchOwnershipTransferred is a free log subscription operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_FixedPriceOracle *FixedPriceOracleFilterer) WatchOwnershipTransferred(opts *bind.WatchOpts, sink chan<- *FixedPriceOracleOwnershipTransferred, previousOwner []common.Address, newOwner []common.Address) (event.Subscription, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _FixedPriceOracle.contract.WatchLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(FixedPriceOracleOwnershipTransferred)
				if err := _FixedPriceOracle.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
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

// ParseOwnershipTransferred is a log parse operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_FixedPriceOracle *FixedPriceOracleFilterer) ParseOwnershipTransferred(log types.Log) (*FixedPriceOracleOwnershipTransferred, error) {
	event := new(FixedPriceOracleOwnershipTransferred)
	if err := _FixedPriceOracle.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// FixedPriceOraclePriceUpdatedIterator is returned from FilterPriceUpdated and is used to iterate over the raw logs and unpacked data for PriceUpdated events raised by the FixedPriceOracle contract.
type FixedPriceOraclePriceUpdatedIterator struct {
	Event *FixedPriceOraclePriceUpdated // Event containing the contract specifics and raw log

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
func (it *FixedPriceOraclePriceUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(FixedPriceOraclePriceUpdated)
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
		it.Event = new(FixedPriceOraclePriceUpdated)
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
func (it *FixedPriceOraclePriceUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *FixedPriceOraclePriceUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// FixedPriceOraclePriceUpdated represents a PriceUpdated event raised by the FixedPriceOracle contract.
type FixedPriceOraclePriceUpdated struct {
	OldPrice *big.Int
	NewPrice *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterPriceUpdated is a free log retrieval operation binding the contract event 0x92ddd77a3b8d4ec2f8d939408c461519c5ddea9083fd78b1ab24a449fe3427b9.
//
// Solidity: event PriceUpdated(int256 oldPrice, int256 newPrice)
func (_FixedPriceOracle *FixedPriceOracleFilterer) FilterPriceUpdated(opts *bind.FilterOpts) (*FixedPriceOraclePriceUpdatedIterator, error) {

	logs, sub, err := _FixedPriceOracle.contract.FilterLogs(opts, "PriceUpdated")
	if err != nil {
		return nil, err
	}
	return &FixedPriceOraclePriceUpdatedIterator{contract: _FixedPriceOracle.contract, event: "PriceUpdated", logs: logs, sub: sub}, nil
}

// WatchPriceUpdated is a free log subscription operation binding the contract event 0x92ddd77a3b8d4ec2f8d939408c461519c5ddea9083fd78b1ab24a449fe3427b9.
//
// Solidity: event PriceUpdated(int256 oldPrice, int256 newPrice)
func (_FixedPriceOracle *FixedPriceOracleFilterer) WatchPriceUpdated(opts *bind.WatchOpts, sink chan<- *FixedPriceOraclePriceUpdated) (event.Subscription, error) {

	logs, sub, err := _FixedPriceOracle.contract.WatchLogs(opts, "PriceUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(FixedPriceOraclePriceUpdated)
				if err := _FixedPriceOracle.contract.UnpackLog(event, "PriceUpdated", log); err != nil {
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

// ParsePriceUpdated is a log parse operation binding the contract event 0x92ddd77a3b8d4ec2f8d939408c461519c5ddea9083fd78b1ab24a449fe3427b9.
//
// Solidity: event PriceUpdated(int256 oldPrice, int256 newPrice)
func (_FixedPriceOracle *FixedPriceOracleFilterer) ParsePriceUpdated(log types.Log) (*FixedPriceOraclePriceUpdated, error) {
	event := new(FixedPriceOraclePriceUpdated)
	if err := _FixedPriceOracle.contract.UnpackLog(event, "PriceUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
