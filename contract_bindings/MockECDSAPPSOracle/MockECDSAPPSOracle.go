// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package MockECDSAPPSOracle

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
	Strategies  []common.Address
	ProofsArray [][][]byte
	Ppss        []*big.Int
	Timestamps  []*big.Int
}

// MockECDSAPPSOracleMetaData contains all meta data concerning the MockECDSAPPSOracle contract.
var MockECDSAPPSOracleMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"SUPER_GOVERNOR\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"UPDATE_PPS_TYPEHASH\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"domainSeparator\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"eip712Domain\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes1\",\"internalType\":\"bytes1\"},{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"nonce\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"setDomainSeparatorReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSUPER_GOVERNORReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setUPDATE_PPS_TYPEHASHReturn\",\"inputs\":[{\"name\":\"_value0\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"updatePPS\",\"inputs\":[{\"name\":\"args\",\"type\":\"tuple\",\"internalType\":\"structIECDSAPPSOracle.UpdatePPSArgs\",\"components\":[{\"name\":\"strategies\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"proofsArray\",\"type\":\"bytes[][]\",\"internalType\":\"bytes[][]\"},{\"name\":\"ppss\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"timestamps\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"EIP712DomainChanged\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSValidated\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"pps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"ppsStdev\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"validatorSet\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"totalValidators\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false}]",
}

// MockECDSAPPSOracleABI is the input ABI used to generate the binding from.
// Deprecated: Use MockECDSAPPSOracleMetaData.ABI instead.
var MockECDSAPPSOracleABI = MockECDSAPPSOracleMetaData.ABI

// MockECDSAPPSOracle is an auto generated Go binding around an Ethereum contract.
type MockECDSAPPSOracle struct {
	MockECDSAPPSOracleCaller     // Read-only binding to the contract
	MockECDSAPPSOracleTransactor // Write-only binding to the contract
	MockECDSAPPSOracleFilterer   // Log filterer for contract events
}

// MockECDSAPPSOracleCaller is an auto generated read-only Go binding around an Ethereum contract.
type MockECDSAPPSOracleCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockECDSAPPSOracleTransactor is an auto generated write-only Go binding around an Ethereum contract.
type MockECDSAPPSOracleTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockECDSAPPSOracleFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type MockECDSAPPSOracleFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockECDSAPPSOracleSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type MockECDSAPPSOracleSession struct {
	Contract     *MockECDSAPPSOracle // Generic contract binding to set the session for
	CallOpts     bind.CallOpts       // Call options to use throughout this session
	TransactOpts bind.TransactOpts   // Transaction auth options to use throughout this session
}

// MockECDSAPPSOracleCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type MockECDSAPPSOracleCallerSession struct {
	Contract *MockECDSAPPSOracleCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts             // Call options to use throughout this session
}

// MockECDSAPPSOracleTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type MockECDSAPPSOracleTransactorSession struct {
	Contract     *MockECDSAPPSOracleTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts             // Transaction auth options to use throughout this session
}

// MockECDSAPPSOracleRaw is an auto generated low-level Go binding around an Ethereum contract.
type MockECDSAPPSOracleRaw struct {
	Contract *MockECDSAPPSOracle // Generic contract binding to access the raw methods on
}

// MockECDSAPPSOracleCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type MockECDSAPPSOracleCallerRaw struct {
	Contract *MockECDSAPPSOracleCaller // Generic read-only contract binding to access the raw methods on
}

// MockECDSAPPSOracleTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type MockECDSAPPSOracleTransactorRaw struct {
	Contract *MockECDSAPPSOracleTransactor // Generic write-only contract binding to access the raw methods on
}

// NewMockECDSAPPSOracle creates a new instance of MockECDSAPPSOracle, bound to a specific deployed contract.
func NewMockECDSAPPSOracle(address common.Address, backend bind.ContractBackend) (*MockECDSAPPSOracle, error) {
	contract, err := bindMockECDSAPPSOracle(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &MockECDSAPPSOracle{MockECDSAPPSOracleCaller: MockECDSAPPSOracleCaller{contract: contract}, MockECDSAPPSOracleTransactor: MockECDSAPPSOracleTransactor{contract: contract}, MockECDSAPPSOracleFilterer: MockECDSAPPSOracleFilterer{contract: contract}}, nil
}

// NewMockECDSAPPSOracleCaller creates a new read-only instance of MockECDSAPPSOracle, bound to a specific deployed contract.
func NewMockECDSAPPSOracleCaller(address common.Address, caller bind.ContractCaller) (*MockECDSAPPSOracleCaller, error) {
	contract, err := bindMockECDSAPPSOracle(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &MockECDSAPPSOracleCaller{contract: contract}, nil
}

// NewMockECDSAPPSOracleTransactor creates a new write-only instance of MockECDSAPPSOracle, bound to a specific deployed contract.
func NewMockECDSAPPSOracleTransactor(address common.Address, transactor bind.ContractTransactor) (*MockECDSAPPSOracleTransactor, error) {
	contract, err := bindMockECDSAPPSOracle(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &MockECDSAPPSOracleTransactor{contract: contract}, nil
}

// NewMockECDSAPPSOracleFilterer creates a new log filterer instance of MockECDSAPPSOracle, bound to a specific deployed contract.
func NewMockECDSAPPSOracleFilterer(address common.Address, filterer bind.ContractFilterer) (*MockECDSAPPSOracleFilterer, error) {
	contract, err := bindMockECDSAPPSOracle(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &MockECDSAPPSOracleFilterer{contract: contract}, nil
}

// bindMockECDSAPPSOracle binds a generic wrapper to an already deployed contract.
func bindMockECDSAPPSOracle(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := MockECDSAPPSOracleMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MockECDSAPPSOracle *MockECDSAPPSOracleRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MockECDSAPPSOracle.Contract.MockECDSAPPSOracleCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MockECDSAPPSOracle *MockECDSAPPSOracleRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockECDSAPPSOracle.Contract.MockECDSAPPSOracleTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MockECDSAPPSOracle *MockECDSAPPSOracleRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MockECDSAPPSOracle.Contract.MockECDSAPPSOracleTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MockECDSAPPSOracle *MockECDSAPPSOracleCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MockECDSAPPSOracle.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MockECDSAPPSOracle *MockECDSAPPSOracleTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockECDSAPPSOracle.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MockECDSAPPSOracle *MockECDSAPPSOracleTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MockECDSAPPSOracle.Contract.contract.Transact(opts, method, params...)
}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_MockECDSAPPSOracle *MockECDSAPPSOracleCaller) SUPERGOVERNOR(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MockECDSAPPSOracle.contract.Call(opts, &out, "SUPER_GOVERNOR")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_MockECDSAPPSOracle *MockECDSAPPSOracleSession) SUPERGOVERNOR() (common.Address, error) {
	return _MockECDSAPPSOracle.Contract.SUPERGOVERNOR(&_MockECDSAPPSOracle.CallOpts)
}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_MockECDSAPPSOracle *MockECDSAPPSOracleCallerSession) SUPERGOVERNOR() (common.Address, error) {
	return _MockECDSAPPSOracle.Contract.SUPERGOVERNOR(&_MockECDSAPPSOracle.CallOpts)
}

// UPDATEPPSTYPEHASH is a free data retrieval call binding the contract method 0xe2c42656.
//
// Solidity: function UPDATE_PPS_TYPEHASH() view returns(bytes32)
func (_MockECDSAPPSOracle *MockECDSAPPSOracleCaller) UPDATEPPSTYPEHASH(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockECDSAPPSOracle.contract.Call(opts, &out, "UPDATE_PPS_TYPEHASH")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// UPDATEPPSTYPEHASH is a free data retrieval call binding the contract method 0xe2c42656.
//
// Solidity: function UPDATE_PPS_TYPEHASH() view returns(bytes32)
func (_MockECDSAPPSOracle *MockECDSAPPSOracleSession) UPDATEPPSTYPEHASH() ([32]byte, error) {
	return _MockECDSAPPSOracle.Contract.UPDATEPPSTYPEHASH(&_MockECDSAPPSOracle.CallOpts)
}

// UPDATEPPSTYPEHASH is a free data retrieval call binding the contract method 0xe2c42656.
//
// Solidity: function UPDATE_PPS_TYPEHASH() view returns(bytes32)
func (_MockECDSAPPSOracle *MockECDSAPPSOracleCallerSession) UPDATEPPSTYPEHASH() ([32]byte, error) {
	return _MockECDSAPPSOracle.Contract.UPDATEPPSTYPEHASH(&_MockECDSAPPSOracle.CallOpts)
}

// DomainSeparator is a free data retrieval call binding the contract method 0xf698da25.
//
// Solidity: function domainSeparator() view returns(bytes32)
func (_MockECDSAPPSOracle *MockECDSAPPSOracleCaller) DomainSeparator(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MockECDSAPPSOracle.contract.Call(opts, &out, "domainSeparator")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DomainSeparator is a free data retrieval call binding the contract method 0xf698da25.
//
// Solidity: function domainSeparator() view returns(bytes32)
func (_MockECDSAPPSOracle *MockECDSAPPSOracleSession) DomainSeparator() ([32]byte, error) {
	return _MockECDSAPPSOracle.Contract.DomainSeparator(&_MockECDSAPPSOracle.CallOpts)
}

// DomainSeparator is a free data retrieval call binding the contract method 0xf698da25.
//
// Solidity: function domainSeparator() view returns(bytes32)
func (_MockECDSAPPSOracle *MockECDSAPPSOracleCallerSession) DomainSeparator() ([32]byte, error) {
	return _MockECDSAPPSOracle.Contract.DomainSeparator(&_MockECDSAPPSOracle.CallOpts)
}

// Eip712Domain is a free data retrieval call binding the contract method 0x84b0196e.
//
// Solidity: function eip712Domain() view returns(bytes1, string, string, uint256, address, bytes32, uint256[])
func (_MockECDSAPPSOracle *MockECDSAPPSOracleCaller) Eip712Domain(opts *bind.CallOpts) ([1]byte, string, string, *big.Int, common.Address, [32]byte, []*big.Int, error) {
	var out []interface{}
	err := _MockECDSAPPSOracle.contract.Call(opts, &out, "eip712Domain")

	if err != nil {
		return *new([1]byte), *new(string), *new(string), *new(*big.Int), *new(common.Address), *new([32]byte), *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([1]byte)).(*[1]byte)
	out1 := *abi.ConvertType(out[1], new(string)).(*string)
	out2 := *abi.ConvertType(out[2], new(string)).(*string)
	out3 := *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)
	out4 := *abi.ConvertType(out[4], new(common.Address)).(*common.Address)
	out5 := *abi.ConvertType(out[5], new([32]byte)).(*[32]byte)
	out6 := *abi.ConvertType(out[6], new([]*big.Int)).(*[]*big.Int)

	return out0, out1, out2, out3, out4, out5, out6, err

}

// Eip712Domain is a free data retrieval call binding the contract method 0x84b0196e.
//
// Solidity: function eip712Domain() view returns(bytes1, string, string, uint256, address, bytes32, uint256[])
func (_MockECDSAPPSOracle *MockECDSAPPSOracleSession) Eip712Domain() ([1]byte, string, string, *big.Int, common.Address, [32]byte, []*big.Int, error) {
	return _MockECDSAPPSOracle.Contract.Eip712Domain(&_MockECDSAPPSOracle.CallOpts)
}

// Eip712Domain is a free data retrieval call binding the contract method 0x84b0196e.
//
// Solidity: function eip712Domain() view returns(bytes1, string, string, uint256, address, bytes32, uint256[])
func (_MockECDSAPPSOracle *MockECDSAPPSOracleCallerSession) Eip712Domain() ([1]byte, string, string, *big.Int, common.Address, [32]byte, []*big.Int, error) {
	return _MockECDSAPPSOracle.Contract.Eip712Domain(&_MockECDSAPPSOracle.CallOpts)
}

// Nonce is a free data retrieval call binding the contract method 0xaffed0e0.
//
// Solidity: function nonce() view returns(uint256)
func (_MockECDSAPPSOracle *MockECDSAPPSOracleCaller) Nonce(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MockECDSAPPSOracle.contract.Call(opts, &out, "nonce")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Nonce is a free data retrieval call binding the contract method 0xaffed0e0.
//
// Solidity: function nonce() view returns(uint256)
func (_MockECDSAPPSOracle *MockECDSAPPSOracleSession) Nonce() (*big.Int, error) {
	return _MockECDSAPPSOracle.Contract.Nonce(&_MockECDSAPPSOracle.CallOpts)
}

// Nonce is a free data retrieval call binding the contract method 0xaffed0e0.
//
// Solidity: function nonce() view returns(uint256)
func (_MockECDSAPPSOracle *MockECDSAPPSOracleCallerSession) Nonce() (*big.Int, error) {
	return _MockECDSAPPSOracle.Contract.Nonce(&_MockECDSAPPSOracle.CallOpts)
}

// SetDomainSeparatorReturn is a paid mutator transaction binding the contract method 0x26b3da6b.
//
// Solidity: function setDomainSeparatorReturn(bytes32 _value0) returns()
func (_MockECDSAPPSOracle *MockECDSAPPSOracleTransactor) SetDomainSeparatorReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockECDSAPPSOracle.contract.Transact(opts, "setDomainSeparatorReturn", _value0)
}

// SetDomainSeparatorReturn is a paid mutator transaction binding the contract method 0x26b3da6b.
//
// Solidity: function setDomainSeparatorReturn(bytes32 _value0) returns()
func (_MockECDSAPPSOracle *MockECDSAPPSOracleSession) SetDomainSeparatorReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockECDSAPPSOracle.Contract.SetDomainSeparatorReturn(&_MockECDSAPPSOracle.TransactOpts, _value0)
}

// SetDomainSeparatorReturn is a paid mutator transaction binding the contract method 0x26b3da6b.
//
// Solidity: function setDomainSeparatorReturn(bytes32 _value0) returns()
func (_MockECDSAPPSOracle *MockECDSAPPSOracleTransactorSession) SetDomainSeparatorReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockECDSAPPSOracle.Contract.SetDomainSeparatorReturn(&_MockECDSAPPSOracle.TransactOpts, _value0)
}

// SetSUPERGOVERNORReturn is a paid mutator transaction binding the contract method 0xd5f56bb5.
//
// Solidity: function setSUPER_GOVERNORReturn(address _value0) returns()
func (_MockECDSAPPSOracle *MockECDSAPPSOracleTransactor) SetSUPERGOVERNORReturn(opts *bind.TransactOpts, _value0 common.Address) (*types.Transaction, error) {
	return _MockECDSAPPSOracle.contract.Transact(opts, "setSUPER_GOVERNORReturn", _value0)
}

// SetSUPERGOVERNORReturn is a paid mutator transaction binding the contract method 0xd5f56bb5.
//
// Solidity: function setSUPER_GOVERNORReturn(address _value0) returns()
func (_MockECDSAPPSOracle *MockECDSAPPSOracleSession) SetSUPERGOVERNORReturn(_value0 common.Address) (*types.Transaction, error) {
	return _MockECDSAPPSOracle.Contract.SetSUPERGOVERNORReturn(&_MockECDSAPPSOracle.TransactOpts, _value0)
}

// SetSUPERGOVERNORReturn is a paid mutator transaction binding the contract method 0xd5f56bb5.
//
// Solidity: function setSUPER_GOVERNORReturn(address _value0) returns()
func (_MockECDSAPPSOracle *MockECDSAPPSOracleTransactorSession) SetSUPERGOVERNORReturn(_value0 common.Address) (*types.Transaction, error) {
	return _MockECDSAPPSOracle.Contract.SetSUPERGOVERNORReturn(&_MockECDSAPPSOracle.TransactOpts, _value0)
}

// SetUPDATEPPSTYPEHASHReturn is a paid mutator transaction binding the contract method 0x41789c3a.
//
// Solidity: function setUPDATE_PPS_TYPEHASHReturn(bytes32 _value0) returns()
func (_MockECDSAPPSOracle *MockECDSAPPSOracleTransactor) SetUPDATEPPSTYPEHASHReturn(opts *bind.TransactOpts, _value0 [32]byte) (*types.Transaction, error) {
	return _MockECDSAPPSOracle.contract.Transact(opts, "setUPDATE_PPS_TYPEHASHReturn", _value0)
}

// SetUPDATEPPSTYPEHASHReturn is a paid mutator transaction binding the contract method 0x41789c3a.
//
// Solidity: function setUPDATE_PPS_TYPEHASHReturn(bytes32 _value0) returns()
func (_MockECDSAPPSOracle *MockECDSAPPSOracleSession) SetUPDATEPPSTYPEHASHReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockECDSAPPSOracle.Contract.SetUPDATEPPSTYPEHASHReturn(&_MockECDSAPPSOracle.TransactOpts, _value0)
}

// SetUPDATEPPSTYPEHASHReturn is a paid mutator transaction binding the contract method 0x41789c3a.
//
// Solidity: function setUPDATE_PPS_TYPEHASHReturn(bytes32 _value0) returns()
func (_MockECDSAPPSOracle *MockECDSAPPSOracleTransactorSession) SetUPDATEPPSTYPEHASHReturn(_value0 [32]byte) (*types.Transaction, error) {
	return _MockECDSAPPSOracle.Contract.SetUPDATEPPSTYPEHASHReturn(&_MockECDSAPPSOracle.TransactOpts, _value0)
}

// UpdatePPS is a paid mutator transaction binding the contract method 0x029365f8.
//
// Solidity: function updatePPS((address[],bytes[][],uint256[],uint256[]) args) returns()
func (_MockECDSAPPSOracle *MockECDSAPPSOracleTransactor) UpdatePPS(opts *bind.TransactOpts, args IECDSAPPSOracleUpdatePPSArgs) (*types.Transaction, error) {
	return _MockECDSAPPSOracle.contract.Transact(opts, "updatePPS", args)
}

// UpdatePPS is a paid mutator transaction binding the contract method 0x029365f8.
//
// Solidity: function updatePPS((address[],bytes[][],uint256[],uint256[]) args) returns()
func (_MockECDSAPPSOracle *MockECDSAPPSOracleSession) UpdatePPS(args IECDSAPPSOracleUpdatePPSArgs) (*types.Transaction, error) {
	return _MockECDSAPPSOracle.Contract.UpdatePPS(&_MockECDSAPPSOracle.TransactOpts, args)
}

// UpdatePPS is a paid mutator transaction binding the contract method 0x029365f8.
//
// Solidity: function updatePPS((address[],bytes[][],uint256[],uint256[]) args) returns()
func (_MockECDSAPPSOracle *MockECDSAPPSOracleTransactorSession) UpdatePPS(args IECDSAPPSOracleUpdatePPSArgs) (*types.Transaction, error) {
	return _MockECDSAPPSOracle.Contract.UpdatePPS(&_MockECDSAPPSOracle.TransactOpts, args)
}

// MockECDSAPPSOracleEIP712DomainChangedIterator is returned from FilterEIP712DomainChanged and is used to iterate over the raw logs and unpacked data for EIP712DomainChanged events raised by the MockECDSAPPSOracle contract.
type MockECDSAPPSOracleEIP712DomainChangedIterator struct {
	Event *MockECDSAPPSOracleEIP712DomainChanged // Event containing the contract specifics and raw log

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
func (it *MockECDSAPPSOracleEIP712DomainChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockECDSAPPSOracleEIP712DomainChanged)
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
		it.Event = new(MockECDSAPPSOracleEIP712DomainChanged)
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
func (it *MockECDSAPPSOracleEIP712DomainChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockECDSAPPSOracleEIP712DomainChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockECDSAPPSOracleEIP712DomainChanged represents a EIP712DomainChanged event raised by the MockECDSAPPSOracle contract.
type MockECDSAPPSOracleEIP712DomainChanged struct {
	Raw types.Log // Blockchain specific contextual infos
}

// FilterEIP712DomainChanged is a free log retrieval operation binding the contract event 0x0a6387c9ea3628b88a633bb4f3b151770f70085117a15f9bf3787cda53f13d31.
//
// Solidity: event EIP712DomainChanged()
func (_MockECDSAPPSOracle *MockECDSAPPSOracleFilterer) FilterEIP712DomainChanged(opts *bind.FilterOpts) (*MockECDSAPPSOracleEIP712DomainChangedIterator, error) {

	logs, sub, err := _MockECDSAPPSOracle.contract.FilterLogs(opts, "EIP712DomainChanged")
	if err != nil {
		return nil, err
	}
	return &MockECDSAPPSOracleEIP712DomainChangedIterator{contract: _MockECDSAPPSOracle.contract, event: "EIP712DomainChanged", logs: logs, sub: sub}, nil
}

// WatchEIP712DomainChanged is a free log subscription operation binding the contract event 0x0a6387c9ea3628b88a633bb4f3b151770f70085117a15f9bf3787cda53f13d31.
//
// Solidity: event EIP712DomainChanged()
func (_MockECDSAPPSOracle *MockECDSAPPSOracleFilterer) WatchEIP712DomainChanged(opts *bind.WatchOpts, sink chan<- *MockECDSAPPSOracleEIP712DomainChanged) (event.Subscription, error) {

	logs, sub, err := _MockECDSAPPSOracle.contract.WatchLogs(opts, "EIP712DomainChanged")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockECDSAPPSOracleEIP712DomainChanged)
				if err := _MockECDSAPPSOracle.contract.UnpackLog(event, "EIP712DomainChanged", log); err != nil {
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
func (_MockECDSAPPSOracle *MockECDSAPPSOracleFilterer) ParseEIP712DomainChanged(log types.Log) (*MockECDSAPPSOracleEIP712DomainChanged, error) {
	event := new(MockECDSAPPSOracleEIP712DomainChanged)
	if err := _MockECDSAPPSOracle.contract.UnpackLog(event, "EIP712DomainChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockECDSAPPSOraclePPSValidatedIterator is returned from FilterPPSValidated and is used to iterate over the raw logs and unpacked data for PPSValidated events raised by the MockECDSAPPSOracle contract.
type MockECDSAPPSOraclePPSValidatedIterator struct {
	Event *MockECDSAPPSOraclePPSValidated // Event containing the contract specifics and raw log

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
func (it *MockECDSAPPSOraclePPSValidatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockECDSAPPSOraclePPSValidated)
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
		it.Event = new(MockECDSAPPSOraclePPSValidated)
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
func (it *MockECDSAPPSOraclePPSValidatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockECDSAPPSOraclePPSValidatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockECDSAPPSOraclePPSValidated represents a PPSValidated event raised by the MockECDSAPPSOracle contract.
type MockECDSAPPSOraclePPSValidated struct {
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
// Solidity: event PPSValidated(address strategy, uint256 pps, uint256 ppsStdev, uint256 validatorSet, uint256 totalValidators, uint256 timestamp, address sender)
func (_MockECDSAPPSOracle *MockECDSAPPSOracleFilterer) FilterPPSValidated(opts *bind.FilterOpts) (*MockECDSAPPSOraclePPSValidatedIterator, error) {

	logs, sub, err := _MockECDSAPPSOracle.contract.FilterLogs(opts, "PPSValidated")
	if err != nil {
		return nil, err
	}
	return &MockECDSAPPSOraclePPSValidatedIterator{contract: _MockECDSAPPSOracle.contract, event: "PPSValidated", logs: logs, sub: sub}, nil
}

// WatchPPSValidated is a free log subscription operation binding the contract event 0xfbdd9422833aff4d04333f008c0d33063458b4050c51fbd4f1eeb2cea915e954.
//
// Solidity: event PPSValidated(address strategy, uint256 pps, uint256 ppsStdev, uint256 validatorSet, uint256 totalValidators, uint256 timestamp, address sender)
func (_MockECDSAPPSOracle *MockECDSAPPSOracleFilterer) WatchPPSValidated(opts *bind.WatchOpts, sink chan<- *MockECDSAPPSOraclePPSValidated) (event.Subscription, error) {

	logs, sub, err := _MockECDSAPPSOracle.contract.WatchLogs(opts, "PPSValidated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockECDSAPPSOraclePPSValidated)
				if err := _MockECDSAPPSOracle.contract.UnpackLog(event, "PPSValidated", log); err != nil {
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
// Solidity: event PPSValidated(address strategy, uint256 pps, uint256 ppsStdev, uint256 validatorSet, uint256 totalValidators, uint256 timestamp, address sender)
func (_MockECDSAPPSOracle *MockECDSAPPSOracleFilterer) ParsePPSValidated(log types.Log) (*MockECDSAPPSOraclePPSValidated, error) {
	event := new(MockECDSAPPSOraclePPSValidated)
	if err := _MockECDSAPPSOracle.contract.UnpackLog(event, "PPSValidated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
