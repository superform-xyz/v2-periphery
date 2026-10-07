// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package SuperBuilderCodeRegistry

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

// SuperBuilderCodeRegistryMetaData contains all meta data concerning the SuperBuilderCodeRegistry contract.
var SuperBuilderCodeRegistryMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"governance\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"MAX_CODE_LENGTH\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"MAX_URI_LENGTH\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"codeURI\",\"inputs\":[{\"name\":\"code\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isRegistered\",\"inputs\":[{\"name\":\"code\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isValidCode\",\"inputs\":[{\"name\":\"code\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"partnerId\",\"inputs\":[{\"name\":\"code\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"payoutAddress\",\"inputs\":[{\"name\":\"code\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"registerCode\",\"inputs\":[{\"name\":\"code\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"partnerId_\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"payoutAddress_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"codeURI_\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"callerConfirmation\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setCodeURI\",\"inputs\":[{\"name\":\"code\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"codeURI_\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setPayoutAddress\",\"inputs\":[{\"name\":\"code\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"payoutAddress_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"CodeRegistered\",\"inputs\":[{\"name\":\"codeHash\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"partnerId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"code\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"payoutAddress\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"codeURI\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CodeURIUpdated\",\"inputs\":[{\"name\":\"codeHash\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousURI\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"newURI\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PayoutAddressUpdated\",\"inputs\":[{\"name\":\"codeHash\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousPayoutAddress\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"newPayoutAddress\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AccessControlBadConfirmation\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"neededRole\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"CODE_ALREADY_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CODE_NOT_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_CODE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_PARTNER_ID\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_CODE_OWNER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"URI_TOO_LONG\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_ADDRESS\",\"inputs\":[]}]",
}

// SuperBuilderCodeRegistryABI is the input ABI used to generate the binding from.
// Deprecated: Use SuperBuilderCodeRegistryMetaData.ABI instead.
var SuperBuilderCodeRegistryABI = SuperBuilderCodeRegistryMetaData.ABI

// SuperBuilderCodeRegistry is an auto generated Go binding around an Ethereum contract.
type SuperBuilderCodeRegistry struct {
	SuperBuilderCodeRegistryCaller     // Read-only binding to the contract
	SuperBuilderCodeRegistryTransactor // Write-only binding to the contract
	SuperBuilderCodeRegistryFilterer   // Log filterer for contract events
}

// SuperBuilderCodeRegistryCaller is an auto generated read-only Go binding around an Ethereum contract.
type SuperBuilderCodeRegistryCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperBuilderCodeRegistryTransactor is an auto generated write-only Go binding around an Ethereum contract.
type SuperBuilderCodeRegistryTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperBuilderCodeRegistryFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type SuperBuilderCodeRegistryFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperBuilderCodeRegistrySession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type SuperBuilderCodeRegistrySession struct {
	Contract     *SuperBuilderCodeRegistry // Generic contract binding to set the session for
	CallOpts     bind.CallOpts             // Call options to use throughout this session
	TransactOpts bind.TransactOpts         // Transaction auth options to use throughout this session
}

// SuperBuilderCodeRegistryCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type SuperBuilderCodeRegistryCallerSession struct {
	Contract *SuperBuilderCodeRegistryCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts                   // Call options to use throughout this session
}

// SuperBuilderCodeRegistryTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type SuperBuilderCodeRegistryTransactorSession struct {
	Contract     *SuperBuilderCodeRegistryTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts                   // Transaction auth options to use throughout this session
}

// SuperBuilderCodeRegistryRaw is an auto generated low-level Go binding around an Ethereum contract.
type SuperBuilderCodeRegistryRaw struct {
	Contract *SuperBuilderCodeRegistry // Generic contract binding to access the raw methods on
}

// SuperBuilderCodeRegistryCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type SuperBuilderCodeRegistryCallerRaw struct {
	Contract *SuperBuilderCodeRegistryCaller // Generic read-only contract binding to access the raw methods on
}

// SuperBuilderCodeRegistryTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type SuperBuilderCodeRegistryTransactorRaw struct {
	Contract *SuperBuilderCodeRegistryTransactor // Generic write-only contract binding to access the raw methods on
}

// NewSuperBuilderCodeRegistry creates a new instance of SuperBuilderCodeRegistry, bound to a specific deployed contract.
func NewSuperBuilderCodeRegistry(address common.Address, backend bind.ContractBackend) (*SuperBuilderCodeRegistry, error) {
	contract, err := bindSuperBuilderCodeRegistry(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &SuperBuilderCodeRegistry{SuperBuilderCodeRegistryCaller: SuperBuilderCodeRegistryCaller{contract: contract}, SuperBuilderCodeRegistryTransactor: SuperBuilderCodeRegistryTransactor{contract: contract}, SuperBuilderCodeRegistryFilterer: SuperBuilderCodeRegistryFilterer{contract: contract}}, nil
}

// NewSuperBuilderCodeRegistryCaller creates a new read-only instance of SuperBuilderCodeRegistry, bound to a specific deployed contract.
func NewSuperBuilderCodeRegistryCaller(address common.Address, caller bind.ContractCaller) (*SuperBuilderCodeRegistryCaller, error) {
	contract, err := bindSuperBuilderCodeRegistry(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &SuperBuilderCodeRegistryCaller{contract: contract}, nil
}

// NewSuperBuilderCodeRegistryTransactor creates a new write-only instance of SuperBuilderCodeRegistry, bound to a specific deployed contract.
func NewSuperBuilderCodeRegistryTransactor(address common.Address, transactor bind.ContractTransactor) (*SuperBuilderCodeRegistryTransactor, error) {
	contract, err := bindSuperBuilderCodeRegistry(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &SuperBuilderCodeRegistryTransactor{contract: contract}, nil
}

// NewSuperBuilderCodeRegistryFilterer creates a new log filterer instance of SuperBuilderCodeRegistry, bound to a specific deployed contract.
func NewSuperBuilderCodeRegistryFilterer(address common.Address, filterer bind.ContractFilterer) (*SuperBuilderCodeRegistryFilterer, error) {
	contract, err := bindSuperBuilderCodeRegistry(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &SuperBuilderCodeRegistryFilterer{contract: contract}, nil
}

// bindSuperBuilderCodeRegistry binds a generic wrapper to an already deployed contract.
func bindSuperBuilderCodeRegistry(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := SuperBuilderCodeRegistryMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperBuilderCodeRegistry.Contract.SuperBuilderCodeRegistryCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.Contract.SuperBuilderCodeRegistryTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.Contract.SuperBuilderCodeRegistryTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperBuilderCodeRegistry.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.Contract.contract.Transact(opts, method, params...)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCaller) DEFAULTADMINROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperBuilderCodeRegistry.contract.Call(opts, &out, "DEFAULT_ADMIN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistrySession) DEFAULTADMINROLE() ([32]byte, error) {
	return _SuperBuilderCodeRegistry.Contract.DEFAULTADMINROLE(&_SuperBuilderCodeRegistry.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCallerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _SuperBuilderCodeRegistry.Contract.DEFAULTADMINROLE(&_SuperBuilderCodeRegistry.CallOpts)
}

// MAXCODELENGTH is a free data retrieval call binding the contract method 0x0b66e167.
//
// Solidity: function MAX_CODE_LENGTH() view returns(uint256)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCaller) MAXCODELENGTH(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperBuilderCodeRegistry.contract.Call(opts, &out, "MAX_CODE_LENGTH")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MAXCODELENGTH is a free data retrieval call binding the contract method 0x0b66e167.
//
// Solidity: function MAX_CODE_LENGTH() view returns(uint256)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistrySession) MAXCODELENGTH() (*big.Int, error) {
	return _SuperBuilderCodeRegistry.Contract.MAXCODELENGTH(&_SuperBuilderCodeRegistry.CallOpts)
}

// MAXCODELENGTH is a free data retrieval call binding the contract method 0x0b66e167.
//
// Solidity: function MAX_CODE_LENGTH() view returns(uint256)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCallerSession) MAXCODELENGTH() (*big.Int, error) {
	return _SuperBuilderCodeRegistry.Contract.MAXCODELENGTH(&_SuperBuilderCodeRegistry.CallOpts)
}

// MAXURILENGTH is a free data retrieval call binding the contract method 0xaab5a877.
//
// Solidity: function MAX_URI_LENGTH() view returns(uint256)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCaller) MAXURILENGTH(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperBuilderCodeRegistry.contract.Call(opts, &out, "MAX_URI_LENGTH")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MAXURILENGTH is a free data retrieval call binding the contract method 0xaab5a877.
//
// Solidity: function MAX_URI_LENGTH() view returns(uint256)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistrySession) MAXURILENGTH() (*big.Int, error) {
	return _SuperBuilderCodeRegistry.Contract.MAXURILENGTH(&_SuperBuilderCodeRegistry.CallOpts)
}

// MAXURILENGTH is a free data retrieval call binding the contract method 0xaab5a877.
//
// Solidity: function MAX_URI_LENGTH() view returns(uint256)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCallerSession) MAXURILENGTH() (*big.Int, error) {
	return _SuperBuilderCodeRegistry.Contract.MAXURILENGTH(&_SuperBuilderCodeRegistry.CallOpts)
}

// CodeURI is a free data retrieval call binding the contract method 0xb2cbce0e.
//
// Solidity: function codeURI(string code) view returns(string)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCaller) CodeURI(opts *bind.CallOpts, code string) (string, error) {
	var out []interface{}
	err := _SuperBuilderCodeRegistry.contract.Call(opts, &out, "codeURI", code)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// CodeURI is a free data retrieval call binding the contract method 0xb2cbce0e.
//
// Solidity: function codeURI(string code) view returns(string)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistrySession) CodeURI(code string) (string, error) {
	return _SuperBuilderCodeRegistry.Contract.CodeURI(&_SuperBuilderCodeRegistry.CallOpts, code)
}

// CodeURI is a free data retrieval call binding the contract method 0xb2cbce0e.
//
// Solidity: function codeURI(string code) view returns(string)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCallerSession) CodeURI(code string) (string, error) {
	return _SuperBuilderCodeRegistry.Contract.CodeURI(&_SuperBuilderCodeRegistry.CallOpts, code)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCaller) GetRoleAdmin(opts *bind.CallOpts, role [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _SuperBuilderCodeRegistry.contract.Call(opts, &out, "getRoleAdmin", role)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistrySession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _SuperBuilderCodeRegistry.Contract.GetRoleAdmin(&_SuperBuilderCodeRegistry.CallOpts, role)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCallerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _SuperBuilderCodeRegistry.Contract.GetRoleAdmin(&_SuperBuilderCodeRegistry.CallOpts, role)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCaller) HasRole(opts *bind.CallOpts, role [32]byte, account common.Address) (bool, error) {
	var out []interface{}
	err := _SuperBuilderCodeRegistry.contract.Call(opts, &out, "hasRole", role, account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistrySession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _SuperBuilderCodeRegistry.Contract.HasRole(&_SuperBuilderCodeRegistry.CallOpts, role, account)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCallerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _SuperBuilderCodeRegistry.Contract.HasRole(&_SuperBuilderCodeRegistry.CallOpts, role, account)
}

// IsRegistered is a free data retrieval call binding the contract method 0xc822d7f0.
//
// Solidity: function isRegistered(string code) view returns(bool)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCaller) IsRegistered(opts *bind.CallOpts, code string) (bool, error) {
	var out []interface{}
	err := _SuperBuilderCodeRegistry.contract.Call(opts, &out, "isRegistered", code)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsRegistered is a free data retrieval call binding the contract method 0xc822d7f0.
//
// Solidity: function isRegistered(string code) view returns(bool)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistrySession) IsRegistered(code string) (bool, error) {
	return _SuperBuilderCodeRegistry.Contract.IsRegistered(&_SuperBuilderCodeRegistry.CallOpts, code)
}

// IsRegistered is a free data retrieval call binding the contract method 0xc822d7f0.
//
// Solidity: function isRegistered(string code) view returns(bool)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCallerSession) IsRegistered(code string) (bool, error) {
	return _SuperBuilderCodeRegistry.Contract.IsRegistered(&_SuperBuilderCodeRegistry.CallOpts, code)
}

// IsValidCode is a free data retrieval call binding the contract method 0x25ed64a0.
//
// Solidity: function isValidCode(string code) pure returns(bool)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCaller) IsValidCode(opts *bind.CallOpts, code string) (bool, error) {
	var out []interface{}
	err := _SuperBuilderCodeRegistry.contract.Call(opts, &out, "isValidCode", code)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsValidCode is a free data retrieval call binding the contract method 0x25ed64a0.
//
// Solidity: function isValidCode(string code) pure returns(bool)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistrySession) IsValidCode(code string) (bool, error) {
	return _SuperBuilderCodeRegistry.Contract.IsValidCode(&_SuperBuilderCodeRegistry.CallOpts, code)
}

// IsValidCode is a free data retrieval call binding the contract method 0x25ed64a0.
//
// Solidity: function isValidCode(string code) pure returns(bool)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCallerSession) IsValidCode(code string) (bool, error) {
	return _SuperBuilderCodeRegistry.Contract.IsValidCode(&_SuperBuilderCodeRegistry.CallOpts, code)
}

// PartnerId is a free data retrieval call binding the contract method 0xc050b5af.
//
// Solidity: function partnerId(string code) view returns(bytes32)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCaller) PartnerId(opts *bind.CallOpts, code string) ([32]byte, error) {
	var out []interface{}
	err := _SuperBuilderCodeRegistry.contract.Call(opts, &out, "partnerId", code)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// PartnerId is a free data retrieval call binding the contract method 0xc050b5af.
//
// Solidity: function partnerId(string code) view returns(bytes32)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistrySession) PartnerId(code string) ([32]byte, error) {
	return _SuperBuilderCodeRegistry.Contract.PartnerId(&_SuperBuilderCodeRegistry.CallOpts, code)
}

// PartnerId is a free data retrieval call binding the contract method 0xc050b5af.
//
// Solidity: function partnerId(string code) view returns(bytes32)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCallerSession) PartnerId(code string) ([32]byte, error) {
	return _SuperBuilderCodeRegistry.Contract.PartnerId(&_SuperBuilderCodeRegistry.CallOpts, code)
}

// PayoutAddress is a free data retrieval call binding the contract method 0xdfcde24b.
//
// Solidity: function payoutAddress(string code) view returns(address)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCaller) PayoutAddress(opts *bind.CallOpts, code string) (common.Address, error) {
	var out []interface{}
	err := _SuperBuilderCodeRegistry.contract.Call(opts, &out, "payoutAddress", code)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// PayoutAddress is a free data retrieval call binding the contract method 0xdfcde24b.
//
// Solidity: function payoutAddress(string code) view returns(address)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistrySession) PayoutAddress(code string) (common.Address, error) {
	return _SuperBuilderCodeRegistry.Contract.PayoutAddress(&_SuperBuilderCodeRegistry.CallOpts, code)
}

// PayoutAddress is a free data retrieval call binding the contract method 0xdfcde24b.
//
// Solidity: function payoutAddress(string code) view returns(address)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCallerSession) PayoutAddress(code string) (common.Address, error) {
	return _SuperBuilderCodeRegistry.Contract.PayoutAddress(&_SuperBuilderCodeRegistry.CallOpts, code)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _SuperBuilderCodeRegistry.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistrySession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _SuperBuilderCodeRegistry.Contract.SupportsInterface(&_SuperBuilderCodeRegistry.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _SuperBuilderCodeRegistry.Contract.SupportsInterface(&_SuperBuilderCodeRegistry.CallOpts, interfaceId)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryTransactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistrySession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.Contract.GrantRole(&_SuperBuilderCodeRegistry.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryTransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.Contract.GrantRole(&_SuperBuilderCodeRegistry.TransactOpts, role, account)
}

// RegisterCode is a paid mutator transaction binding the contract method 0x3d106b8f.
//
// Solidity: function registerCode(string code, bytes32 partnerId_, address payoutAddress_, string codeURI_) returns()
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryTransactor) RegisterCode(opts *bind.TransactOpts, code string, partnerId_ [32]byte, payoutAddress_ common.Address, codeURI_ string) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.contract.Transact(opts, "registerCode", code, partnerId_, payoutAddress_, codeURI_)
}

// RegisterCode is a paid mutator transaction binding the contract method 0x3d106b8f.
//
// Solidity: function registerCode(string code, bytes32 partnerId_, address payoutAddress_, string codeURI_) returns()
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistrySession) RegisterCode(code string, partnerId_ [32]byte, payoutAddress_ common.Address, codeURI_ string) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.Contract.RegisterCode(&_SuperBuilderCodeRegistry.TransactOpts, code, partnerId_, payoutAddress_, codeURI_)
}

// RegisterCode is a paid mutator transaction binding the contract method 0x3d106b8f.
//
// Solidity: function registerCode(string code, bytes32 partnerId_, address payoutAddress_, string codeURI_) returns()
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryTransactorSession) RegisterCode(code string, partnerId_ [32]byte, payoutAddress_ common.Address, codeURI_ string) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.Contract.RegisterCode(&_SuperBuilderCodeRegistry.TransactOpts, code, partnerId_, payoutAddress_, codeURI_)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryTransactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.contract.Transact(opts, "renounceRole", role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistrySession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.Contract.RenounceRole(&_SuperBuilderCodeRegistry.TransactOpts, role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryTransactorSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.Contract.RenounceRole(&_SuperBuilderCodeRegistry.TransactOpts, role, callerConfirmation)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryTransactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistrySession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.Contract.RevokeRole(&_SuperBuilderCodeRegistry.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryTransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.Contract.RevokeRole(&_SuperBuilderCodeRegistry.TransactOpts, role, account)
}

// SetCodeURI is a paid mutator transaction binding the contract method 0xb8b4d0ce.
//
// Solidity: function setCodeURI(string code, string codeURI_) returns()
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryTransactor) SetCodeURI(opts *bind.TransactOpts, code string, codeURI_ string) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.contract.Transact(opts, "setCodeURI", code, codeURI_)
}

// SetCodeURI is a paid mutator transaction binding the contract method 0xb8b4d0ce.
//
// Solidity: function setCodeURI(string code, string codeURI_) returns()
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistrySession) SetCodeURI(code string, codeURI_ string) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.Contract.SetCodeURI(&_SuperBuilderCodeRegistry.TransactOpts, code, codeURI_)
}

// SetCodeURI is a paid mutator transaction binding the contract method 0xb8b4d0ce.
//
// Solidity: function setCodeURI(string code, string codeURI_) returns()
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryTransactorSession) SetCodeURI(code string, codeURI_ string) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.Contract.SetCodeURI(&_SuperBuilderCodeRegistry.TransactOpts, code, codeURI_)
}

// SetPayoutAddress is a paid mutator transaction binding the contract method 0x32851c40.
//
// Solidity: function setPayoutAddress(string code, address payoutAddress_) returns()
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryTransactor) SetPayoutAddress(opts *bind.TransactOpts, code string, payoutAddress_ common.Address) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.contract.Transact(opts, "setPayoutAddress", code, payoutAddress_)
}

// SetPayoutAddress is a paid mutator transaction binding the contract method 0x32851c40.
//
// Solidity: function setPayoutAddress(string code, address payoutAddress_) returns()
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistrySession) SetPayoutAddress(code string, payoutAddress_ common.Address) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.Contract.SetPayoutAddress(&_SuperBuilderCodeRegistry.TransactOpts, code, payoutAddress_)
}

// SetPayoutAddress is a paid mutator transaction binding the contract method 0x32851c40.
//
// Solidity: function setPayoutAddress(string code, address payoutAddress_) returns()
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryTransactorSession) SetPayoutAddress(code string, payoutAddress_ common.Address) (*types.Transaction, error) {
	return _SuperBuilderCodeRegistry.Contract.SetPayoutAddress(&_SuperBuilderCodeRegistry.TransactOpts, code, payoutAddress_)
}

// SuperBuilderCodeRegistryCodeRegisteredIterator is returned from FilterCodeRegistered and is used to iterate over the raw logs and unpacked data for CodeRegistered events raised by the SuperBuilderCodeRegistry contract.
type SuperBuilderCodeRegistryCodeRegisteredIterator struct {
	Event *SuperBuilderCodeRegistryCodeRegistered // Event containing the contract specifics and raw log

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
func (it *SuperBuilderCodeRegistryCodeRegisteredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperBuilderCodeRegistryCodeRegistered)
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
		it.Event = new(SuperBuilderCodeRegistryCodeRegistered)
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
func (it *SuperBuilderCodeRegistryCodeRegisteredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperBuilderCodeRegistryCodeRegisteredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperBuilderCodeRegistryCodeRegistered represents a CodeRegistered event raised by the SuperBuilderCodeRegistry contract.
type SuperBuilderCodeRegistryCodeRegistered struct {
	CodeHash      [32]byte
	PartnerId     [32]byte
	Code          string
	PayoutAddress common.Address
	CodeURI       string
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterCodeRegistered is a free log retrieval operation binding the contract event 0xfc8e3ed4a09c8caa144365a59240e8de45513cda3433a695a1219c781c6af1e6.
//
// Solidity: event CodeRegistered(bytes32 indexed codeHash, bytes32 indexed partnerId, string code, address payoutAddress, string codeURI)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryFilterer) FilterCodeRegistered(opts *bind.FilterOpts, codeHash [][32]byte, partnerId [][32]byte) (*SuperBuilderCodeRegistryCodeRegisteredIterator, error) {

	var codeHashRule []interface{}
	for _, codeHashItem := range codeHash {
		codeHashRule = append(codeHashRule, codeHashItem)
	}
	var partnerIdRule []interface{}
	for _, partnerIdItem := range partnerId {
		partnerIdRule = append(partnerIdRule, partnerIdItem)
	}

	logs, sub, err := _SuperBuilderCodeRegistry.contract.FilterLogs(opts, "CodeRegistered", codeHashRule, partnerIdRule)
	if err != nil {
		return nil, err
	}
	return &SuperBuilderCodeRegistryCodeRegisteredIterator{contract: _SuperBuilderCodeRegistry.contract, event: "CodeRegistered", logs: logs, sub: sub}, nil
}

// WatchCodeRegistered is a free log subscription operation binding the contract event 0xfc8e3ed4a09c8caa144365a59240e8de45513cda3433a695a1219c781c6af1e6.
//
// Solidity: event CodeRegistered(bytes32 indexed codeHash, bytes32 indexed partnerId, string code, address payoutAddress, string codeURI)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryFilterer) WatchCodeRegistered(opts *bind.WatchOpts, sink chan<- *SuperBuilderCodeRegistryCodeRegistered, codeHash [][32]byte, partnerId [][32]byte) (event.Subscription, error) {

	var codeHashRule []interface{}
	for _, codeHashItem := range codeHash {
		codeHashRule = append(codeHashRule, codeHashItem)
	}
	var partnerIdRule []interface{}
	for _, partnerIdItem := range partnerId {
		partnerIdRule = append(partnerIdRule, partnerIdItem)
	}

	logs, sub, err := _SuperBuilderCodeRegistry.contract.WatchLogs(opts, "CodeRegistered", codeHashRule, partnerIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperBuilderCodeRegistryCodeRegistered)
				if err := _SuperBuilderCodeRegistry.contract.UnpackLog(event, "CodeRegistered", log); err != nil {
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

// ParseCodeRegistered is a log parse operation binding the contract event 0xfc8e3ed4a09c8caa144365a59240e8de45513cda3433a695a1219c781c6af1e6.
//
// Solidity: event CodeRegistered(bytes32 indexed codeHash, bytes32 indexed partnerId, string code, address payoutAddress, string codeURI)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryFilterer) ParseCodeRegistered(log types.Log) (*SuperBuilderCodeRegistryCodeRegistered, error) {
	event := new(SuperBuilderCodeRegistryCodeRegistered)
	if err := _SuperBuilderCodeRegistry.contract.UnpackLog(event, "CodeRegistered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperBuilderCodeRegistryCodeURIUpdatedIterator is returned from FilterCodeURIUpdated and is used to iterate over the raw logs and unpacked data for CodeURIUpdated events raised by the SuperBuilderCodeRegistry contract.
type SuperBuilderCodeRegistryCodeURIUpdatedIterator struct {
	Event *SuperBuilderCodeRegistryCodeURIUpdated // Event containing the contract specifics and raw log

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
func (it *SuperBuilderCodeRegistryCodeURIUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperBuilderCodeRegistryCodeURIUpdated)
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
		it.Event = new(SuperBuilderCodeRegistryCodeURIUpdated)
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
func (it *SuperBuilderCodeRegistryCodeURIUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperBuilderCodeRegistryCodeURIUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperBuilderCodeRegistryCodeURIUpdated represents a CodeURIUpdated event raised by the SuperBuilderCodeRegistry contract.
type SuperBuilderCodeRegistryCodeURIUpdated struct {
	CodeHash    [32]byte
	PreviousURI string
	NewURI      string
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterCodeURIUpdated is a free log retrieval operation binding the contract event 0x7cf71184dc113baa072f5c8175395c6ff8f22ed2c42d365ee654bd5df7f23786.
//
// Solidity: event CodeURIUpdated(bytes32 indexed codeHash, string previousURI, string newURI)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryFilterer) FilterCodeURIUpdated(opts *bind.FilterOpts, codeHash [][32]byte) (*SuperBuilderCodeRegistryCodeURIUpdatedIterator, error) {

	var codeHashRule []interface{}
	for _, codeHashItem := range codeHash {
		codeHashRule = append(codeHashRule, codeHashItem)
	}

	logs, sub, err := _SuperBuilderCodeRegistry.contract.FilterLogs(opts, "CodeURIUpdated", codeHashRule)
	if err != nil {
		return nil, err
	}
	return &SuperBuilderCodeRegistryCodeURIUpdatedIterator{contract: _SuperBuilderCodeRegistry.contract, event: "CodeURIUpdated", logs: logs, sub: sub}, nil
}

// WatchCodeURIUpdated is a free log subscription operation binding the contract event 0x7cf71184dc113baa072f5c8175395c6ff8f22ed2c42d365ee654bd5df7f23786.
//
// Solidity: event CodeURIUpdated(bytes32 indexed codeHash, string previousURI, string newURI)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryFilterer) WatchCodeURIUpdated(opts *bind.WatchOpts, sink chan<- *SuperBuilderCodeRegistryCodeURIUpdated, codeHash [][32]byte) (event.Subscription, error) {

	var codeHashRule []interface{}
	for _, codeHashItem := range codeHash {
		codeHashRule = append(codeHashRule, codeHashItem)
	}

	logs, sub, err := _SuperBuilderCodeRegistry.contract.WatchLogs(opts, "CodeURIUpdated", codeHashRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperBuilderCodeRegistryCodeURIUpdated)
				if err := _SuperBuilderCodeRegistry.contract.UnpackLog(event, "CodeURIUpdated", log); err != nil {
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

// ParseCodeURIUpdated is a log parse operation binding the contract event 0x7cf71184dc113baa072f5c8175395c6ff8f22ed2c42d365ee654bd5df7f23786.
//
// Solidity: event CodeURIUpdated(bytes32 indexed codeHash, string previousURI, string newURI)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryFilterer) ParseCodeURIUpdated(log types.Log) (*SuperBuilderCodeRegistryCodeURIUpdated, error) {
	event := new(SuperBuilderCodeRegistryCodeURIUpdated)
	if err := _SuperBuilderCodeRegistry.contract.UnpackLog(event, "CodeURIUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperBuilderCodeRegistryPayoutAddressUpdatedIterator is returned from FilterPayoutAddressUpdated and is used to iterate over the raw logs and unpacked data for PayoutAddressUpdated events raised by the SuperBuilderCodeRegistry contract.
type SuperBuilderCodeRegistryPayoutAddressUpdatedIterator struct {
	Event *SuperBuilderCodeRegistryPayoutAddressUpdated // Event containing the contract specifics and raw log

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
func (it *SuperBuilderCodeRegistryPayoutAddressUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperBuilderCodeRegistryPayoutAddressUpdated)
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
		it.Event = new(SuperBuilderCodeRegistryPayoutAddressUpdated)
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
func (it *SuperBuilderCodeRegistryPayoutAddressUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperBuilderCodeRegistryPayoutAddressUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperBuilderCodeRegistryPayoutAddressUpdated represents a PayoutAddressUpdated event raised by the SuperBuilderCodeRegistry contract.
type SuperBuilderCodeRegistryPayoutAddressUpdated struct {
	CodeHash              [32]byte
	PreviousPayoutAddress common.Address
	NewPayoutAddress      common.Address
	Raw                   types.Log // Blockchain specific contextual infos
}

// FilterPayoutAddressUpdated is a free log retrieval operation binding the contract event 0x21a84558f5dbef88534e90979cda4a1c24347d04af39d85c41d28db816fc85e3.
//
// Solidity: event PayoutAddressUpdated(bytes32 indexed codeHash, address previousPayoutAddress, address newPayoutAddress)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryFilterer) FilterPayoutAddressUpdated(opts *bind.FilterOpts, codeHash [][32]byte) (*SuperBuilderCodeRegistryPayoutAddressUpdatedIterator, error) {

	var codeHashRule []interface{}
	for _, codeHashItem := range codeHash {
		codeHashRule = append(codeHashRule, codeHashItem)
	}

	logs, sub, err := _SuperBuilderCodeRegistry.contract.FilterLogs(opts, "PayoutAddressUpdated", codeHashRule)
	if err != nil {
		return nil, err
	}
	return &SuperBuilderCodeRegistryPayoutAddressUpdatedIterator{contract: _SuperBuilderCodeRegistry.contract, event: "PayoutAddressUpdated", logs: logs, sub: sub}, nil
}

// WatchPayoutAddressUpdated is a free log subscription operation binding the contract event 0x21a84558f5dbef88534e90979cda4a1c24347d04af39d85c41d28db816fc85e3.
//
// Solidity: event PayoutAddressUpdated(bytes32 indexed codeHash, address previousPayoutAddress, address newPayoutAddress)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryFilterer) WatchPayoutAddressUpdated(opts *bind.WatchOpts, sink chan<- *SuperBuilderCodeRegistryPayoutAddressUpdated, codeHash [][32]byte) (event.Subscription, error) {

	var codeHashRule []interface{}
	for _, codeHashItem := range codeHash {
		codeHashRule = append(codeHashRule, codeHashItem)
	}

	logs, sub, err := _SuperBuilderCodeRegistry.contract.WatchLogs(opts, "PayoutAddressUpdated", codeHashRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperBuilderCodeRegistryPayoutAddressUpdated)
				if err := _SuperBuilderCodeRegistry.contract.UnpackLog(event, "PayoutAddressUpdated", log); err != nil {
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

// ParsePayoutAddressUpdated is a log parse operation binding the contract event 0x21a84558f5dbef88534e90979cda4a1c24347d04af39d85c41d28db816fc85e3.
//
// Solidity: event PayoutAddressUpdated(bytes32 indexed codeHash, address previousPayoutAddress, address newPayoutAddress)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryFilterer) ParsePayoutAddressUpdated(log types.Log) (*SuperBuilderCodeRegistryPayoutAddressUpdated, error) {
	event := new(SuperBuilderCodeRegistryPayoutAddressUpdated)
	if err := _SuperBuilderCodeRegistry.contract.UnpackLog(event, "PayoutAddressUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperBuilderCodeRegistryRoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the SuperBuilderCodeRegistry contract.
type SuperBuilderCodeRegistryRoleAdminChangedIterator struct {
	Event *SuperBuilderCodeRegistryRoleAdminChanged // Event containing the contract specifics and raw log

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
func (it *SuperBuilderCodeRegistryRoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperBuilderCodeRegistryRoleAdminChanged)
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
		it.Event = new(SuperBuilderCodeRegistryRoleAdminChanged)
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
func (it *SuperBuilderCodeRegistryRoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperBuilderCodeRegistryRoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperBuilderCodeRegistryRoleAdminChanged represents a RoleAdminChanged event raised by the SuperBuilderCodeRegistry contract.
type SuperBuilderCodeRegistryRoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryFilterer) FilterRoleAdminChanged(opts *bind.FilterOpts, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (*SuperBuilderCodeRegistryRoleAdminChangedIterator, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var previousAdminRoleRule []interface{}
	for _, previousAdminRoleItem := range previousAdminRole {
		previousAdminRoleRule = append(previousAdminRoleRule, previousAdminRoleItem)
	}
	var newAdminRoleRule []interface{}
	for _, newAdminRoleItem := range newAdminRole {
		newAdminRoleRule = append(newAdminRoleRule, newAdminRoleItem)
	}

	logs, sub, err := _SuperBuilderCodeRegistry.contract.FilterLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return &SuperBuilderCodeRegistryRoleAdminChangedIterator{contract: _SuperBuilderCodeRegistry.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryFilterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *SuperBuilderCodeRegistryRoleAdminChanged, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (event.Subscription, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var previousAdminRoleRule []interface{}
	for _, previousAdminRoleItem := range previousAdminRole {
		previousAdminRoleRule = append(previousAdminRoleRule, previousAdminRoleItem)
	}
	var newAdminRoleRule []interface{}
	for _, newAdminRoleItem := range newAdminRole {
		newAdminRoleRule = append(newAdminRoleRule, newAdminRoleItem)
	}

	logs, sub, err := _SuperBuilderCodeRegistry.contract.WatchLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperBuilderCodeRegistryRoleAdminChanged)
				if err := _SuperBuilderCodeRegistry.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
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

// ParseRoleAdminChanged is a log parse operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryFilterer) ParseRoleAdminChanged(log types.Log) (*SuperBuilderCodeRegistryRoleAdminChanged, error) {
	event := new(SuperBuilderCodeRegistryRoleAdminChanged)
	if err := _SuperBuilderCodeRegistry.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperBuilderCodeRegistryRoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the SuperBuilderCodeRegistry contract.
type SuperBuilderCodeRegistryRoleGrantedIterator struct {
	Event *SuperBuilderCodeRegistryRoleGranted // Event containing the contract specifics and raw log

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
func (it *SuperBuilderCodeRegistryRoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperBuilderCodeRegistryRoleGranted)
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
		it.Event = new(SuperBuilderCodeRegistryRoleGranted)
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
func (it *SuperBuilderCodeRegistryRoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperBuilderCodeRegistryRoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperBuilderCodeRegistryRoleGranted represents a RoleGranted event raised by the SuperBuilderCodeRegistry contract.
type SuperBuilderCodeRegistryRoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryFilterer) FilterRoleGranted(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*SuperBuilderCodeRegistryRoleGrantedIterator, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _SuperBuilderCodeRegistry.contract.FilterLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &SuperBuilderCodeRegistryRoleGrantedIterator{contract: _SuperBuilderCodeRegistry.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryFilterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *SuperBuilderCodeRegistryRoleGranted, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _SuperBuilderCodeRegistry.contract.WatchLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperBuilderCodeRegistryRoleGranted)
				if err := _SuperBuilderCodeRegistry.contract.UnpackLog(event, "RoleGranted", log); err != nil {
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

// ParseRoleGranted is a log parse operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryFilterer) ParseRoleGranted(log types.Log) (*SuperBuilderCodeRegistryRoleGranted, error) {
	event := new(SuperBuilderCodeRegistryRoleGranted)
	if err := _SuperBuilderCodeRegistry.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperBuilderCodeRegistryRoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the SuperBuilderCodeRegistry contract.
type SuperBuilderCodeRegistryRoleRevokedIterator struct {
	Event *SuperBuilderCodeRegistryRoleRevoked // Event containing the contract specifics and raw log

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
func (it *SuperBuilderCodeRegistryRoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperBuilderCodeRegistryRoleRevoked)
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
		it.Event = new(SuperBuilderCodeRegistryRoleRevoked)
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
func (it *SuperBuilderCodeRegistryRoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperBuilderCodeRegistryRoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperBuilderCodeRegistryRoleRevoked represents a RoleRevoked event raised by the SuperBuilderCodeRegistry contract.
type SuperBuilderCodeRegistryRoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryFilterer) FilterRoleRevoked(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*SuperBuilderCodeRegistryRoleRevokedIterator, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _SuperBuilderCodeRegistry.contract.FilterLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &SuperBuilderCodeRegistryRoleRevokedIterator{contract: _SuperBuilderCodeRegistry.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryFilterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *SuperBuilderCodeRegistryRoleRevoked, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _SuperBuilderCodeRegistry.contract.WatchLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperBuilderCodeRegistryRoleRevoked)
				if err := _SuperBuilderCodeRegistry.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
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

// ParseRoleRevoked is a log parse operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperBuilderCodeRegistry *SuperBuilderCodeRegistryFilterer) ParseRoleRevoked(log types.Log) (*SuperBuilderCodeRegistryRoleRevoked, error) {
	event := new(SuperBuilderCodeRegistryRoleRevoked)
	if err := _SuperBuilderCodeRegistry.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
