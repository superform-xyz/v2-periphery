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

// ISuperVaultBatchOperatorBatchRequest is an auto generated low-level Go binding around an user-defined struct.
type ISuperVaultBatchOperatorBatchRequest struct {
	Vault      common.Address
	Controller common.Address
	Amount     *big.Int
}

// SuperVaultBatchOperatorMetaData contains all meta data concerning the SuperVaultBatchOperator contract.
var SuperVaultBatchOperatorMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"admin\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"OPERATOR_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"batchEmergencyWithdraw\",\"inputs\":[{\"name\":\"tokens\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"batchRedeem\",\"inputs\":[{\"name\":\"requests\",\"type\":\"tuple[]\",\"internalType\":\"structISuperVaultBatchOperator.BatchRequest[]\",\"components\":[{\"name\":\"vault\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"batchWithdraw\",\"inputs\":[{\"name\":\"requests\",\"type\":\"tuple[]\",\"internalType\":\"structISuperVaultBatchOperator.BatchRequest[]\",\"components\":[{\"name\":\"vault\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"controller\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"callerConfirmation\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"BatchEmergencyWithdraw\",\"inputs\":[{\"name\":\"tokens\",\"type\":\"address[]\",\"indexed\":false,\"internalType\":\"address[]\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"BatchRedeemExecuted\",\"inputs\":[{\"name\":\"caller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"requestCount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"BatchWithdrawExecuted\",\"inputs\":[{\"name\":\"caller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"requestCount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RedeemFailed\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"vault\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"controller\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RedeemRequestSkipped\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"vault\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"controller\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawFailed\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"vault\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"controller\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawRequestSkipped\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"vault\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"controller\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AccessControlBadConfirmation\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"neededRole\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"EMPTY_REQUESTS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ZERO_ADMIN_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_OPERATOR_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_TOKEN_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_TO_ADDRESS\",\"inputs\":[]}]",
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

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorCaller) DEFAULTADMINROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperVaultBatchOperator.contract.Call(opts, &out, "DEFAULT_ADMIN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _SuperVaultBatchOperator.Contract.DEFAULTADMINROLE(&_SuperVaultBatchOperator.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorCallerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _SuperVaultBatchOperator.Contract.DEFAULTADMINROLE(&_SuperVaultBatchOperator.CallOpts)
}

// OPERATORROLE is a free data retrieval call binding the contract method 0xf5b541a6.
//
// Solidity: function OPERATOR_ROLE() view returns(bytes32)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorCaller) OPERATORROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperVaultBatchOperator.contract.Call(opts, &out, "OPERATOR_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// OPERATORROLE is a free data retrieval call binding the contract method 0xf5b541a6.
//
// Solidity: function OPERATOR_ROLE() view returns(bytes32)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorSession) OPERATORROLE() ([32]byte, error) {
	return _SuperVaultBatchOperator.Contract.OPERATORROLE(&_SuperVaultBatchOperator.CallOpts)
}

// OPERATORROLE is a free data retrieval call binding the contract method 0xf5b541a6.
//
// Solidity: function OPERATOR_ROLE() view returns(bytes32)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorCallerSession) OPERATORROLE() ([32]byte, error) {
	return _SuperVaultBatchOperator.Contract.OPERATORROLE(&_SuperVaultBatchOperator.CallOpts)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorCaller) GetRoleAdmin(opts *bind.CallOpts, role [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _SuperVaultBatchOperator.contract.Call(opts, &out, "getRoleAdmin", role)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _SuperVaultBatchOperator.Contract.GetRoleAdmin(&_SuperVaultBatchOperator.CallOpts, role)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorCallerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _SuperVaultBatchOperator.Contract.GetRoleAdmin(&_SuperVaultBatchOperator.CallOpts, role)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorCaller) HasRole(opts *bind.CallOpts, role [32]byte, account common.Address) (bool, error) {
	var out []interface{}
	err := _SuperVaultBatchOperator.contract.Call(opts, &out, "hasRole", role, account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _SuperVaultBatchOperator.Contract.HasRole(&_SuperVaultBatchOperator.CallOpts, role, account)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorCallerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _SuperVaultBatchOperator.Contract.HasRole(&_SuperVaultBatchOperator.CallOpts, role, account)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _SuperVaultBatchOperator.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _SuperVaultBatchOperator.Contract.SupportsInterface(&_SuperVaultBatchOperator.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _SuperVaultBatchOperator.Contract.SupportsInterface(&_SuperVaultBatchOperator.CallOpts, interfaceId)
}

// BatchEmergencyWithdraw is a paid mutator transaction binding the contract method 0x44559b3c.
//
// Solidity: function batchEmergencyWithdraw(address[] tokens, address to) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorTransactor) BatchEmergencyWithdraw(opts *bind.TransactOpts, tokens []common.Address, to common.Address) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.contract.Transact(opts, "batchEmergencyWithdraw", tokens, to)
}

// BatchEmergencyWithdraw is a paid mutator transaction binding the contract method 0x44559b3c.
//
// Solidity: function batchEmergencyWithdraw(address[] tokens, address to) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorSession) BatchEmergencyWithdraw(tokens []common.Address, to common.Address) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.BatchEmergencyWithdraw(&_SuperVaultBatchOperator.TransactOpts, tokens, to)
}

// BatchEmergencyWithdraw is a paid mutator transaction binding the contract method 0x44559b3c.
//
// Solidity: function batchEmergencyWithdraw(address[] tokens, address to) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorTransactorSession) BatchEmergencyWithdraw(tokens []common.Address, to common.Address) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.BatchEmergencyWithdraw(&_SuperVaultBatchOperator.TransactOpts, tokens, to)
}

// BatchRedeem is a paid mutator transaction binding the contract method 0x0baf3fae.
//
// Solidity: function batchRedeem((address,address,uint256)[] requests) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorTransactor) BatchRedeem(opts *bind.TransactOpts, requests []ISuperVaultBatchOperatorBatchRequest) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.contract.Transact(opts, "batchRedeem", requests)
}

// BatchRedeem is a paid mutator transaction binding the contract method 0x0baf3fae.
//
// Solidity: function batchRedeem((address,address,uint256)[] requests) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorSession) BatchRedeem(requests []ISuperVaultBatchOperatorBatchRequest) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.BatchRedeem(&_SuperVaultBatchOperator.TransactOpts, requests)
}

// BatchRedeem is a paid mutator transaction binding the contract method 0x0baf3fae.
//
// Solidity: function batchRedeem((address,address,uint256)[] requests) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorTransactorSession) BatchRedeem(requests []ISuperVaultBatchOperatorBatchRequest) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.BatchRedeem(&_SuperVaultBatchOperator.TransactOpts, requests)
}

// BatchWithdraw is a paid mutator transaction binding the contract method 0x0513d63d.
//
// Solidity: function batchWithdraw((address,address,uint256)[] requests) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorTransactor) BatchWithdraw(opts *bind.TransactOpts, requests []ISuperVaultBatchOperatorBatchRequest) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.contract.Transact(opts, "batchWithdraw", requests)
}

// BatchWithdraw is a paid mutator transaction binding the contract method 0x0513d63d.
//
// Solidity: function batchWithdraw((address,address,uint256)[] requests) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorSession) BatchWithdraw(requests []ISuperVaultBatchOperatorBatchRequest) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.BatchWithdraw(&_SuperVaultBatchOperator.TransactOpts, requests)
}

// BatchWithdraw is a paid mutator transaction binding the contract method 0x0513d63d.
//
// Solidity: function batchWithdraw((address,address,uint256)[] requests) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorTransactorSession) BatchWithdraw(requests []ISuperVaultBatchOperatorBatchRequest) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.BatchWithdraw(&_SuperVaultBatchOperator.TransactOpts, requests)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorTransactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.GrantRole(&_SuperVaultBatchOperator.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorTransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.GrantRole(&_SuperVaultBatchOperator.TransactOpts, role, account)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorTransactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.contract.Transact(opts, "renounceRole", role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.RenounceRole(&_SuperVaultBatchOperator.TransactOpts, role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorTransactorSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.RenounceRole(&_SuperVaultBatchOperator.TransactOpts, role, callerConfirmation)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorTransactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.RevokeRole(&_SuperVaultBatchOperator.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorTransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperVaultBatchOperator.Contract.RevokeRole(&_SuperVaultBatchOperator.TransactOpts, role, account)
}

// SuperVaultBatchOperatorBatchEmergencyWithdrawIterator is returned from FilterBatchEmergencyWithdraw and is used to iterate over the raw logs and unpacked data for BatchEmergencyWithdraw events raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorBatchEmergencyWithdrawIterator struct {
	Event *SuperVaultBatchOperatorBatchEmergencyWithdraw // Event containing the contract specifics and raw log

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
func (it *SuperVaultBatchOperatorBatchEmergencyWithdrawIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultBatchOperatorBatchEmergencyWithdraw)
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
		it.Event = new(SuperVaultBatchOperatorBatchEmergencyWithdraw)
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
func (it *SuperVaultBatchOperatorBatchEmergencyWithdrawIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultBatchOperatorBatchEmergencyWithdrawIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultBatchOperatorBatchEmergencyWithdraw represents a BatchEmergencyWithdraw event raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorBatchEmergencyWithdraw struct {
	Tokens  []common.Address
	To      common.Address
	Amounts []*big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterBatchEmergencyWithdraw is a free log retrieval operation binding the contract event 0xf51aa207463e9869b2dd9463eb5be4109216115d6580f7b59991a9e3d7cc9f1f.
//
// Solidity: event BatchEmergencyWithdraw(address[] tokens, address indexed to, uint256[] amounts)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) FilterBatchEmergencyWithdraw(opts *bind.FilterOpts, to []common.Address) (*SuperVaultBatchOperatorBatchEmergencyWithdrawIterator, error) {

	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _SuperVaultBatchOperator.contract.FilterLogs(opts, "BatchEmergencyWithdraw", toRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultBatchOperatorBatchEmergencyWithdrawIterator{contract: _SuperVaultBatchOperator.contract, event: "BatchEmergencyWithdraw", logs: logs, sub: sub}, nil
}

// WatchBatchEmergencyWithdraw is a free log subscription operation binding the contract event 0xf51aa207463e9869b2dd9463eb5be4109216115d6580f7b59991a9e3d7cc9f1f.
//
// Solidity: event BatchEmergencyWithdraw(address[] tokens, address indexed to, uint256[] amounts)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) WatchBatchEmergencyWithdraw(opts *bind.WatchOpts, sink chan<- *SuperVaultBatchOperatorBatchEmergencyWithdraw, to []common.Address) (event.Subscription, error) {

	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _SuperVaultBatchOperator.contract.WatchLogs(opts, "BatchEmergencyWithdraw", toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultBatchOperatorBatchEmergencyWithdraw)
				if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "BatchEmergencyWithdraw", log); err != nil {
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

// ParseBatchEmergencyWithdraw is a log parse operation binding the contract event 0xf51aa207463e9869b2dd9463eb5be4109216115d6580f7b59991a9e3d7cc9f1f.
//
// Solidity: event BatchEmergencyWithdraw(address[] tokens, address indexed to, uint256[] amounts)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) ParseBatchEmergencyWithdraw(log types.Log) (*SuperVaultBatchOperatorBatchEmergencyWithdraw, error) {
	event := new(SuperVaultBatchOperatorBatchEmergencyWithdraw)
	if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "BatchEmergencyWithdraw", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultBatchOperatorBatchRedeemExecutedIterator is returned from FilterBatchRedeemExecuted and is used to iterate over the raw logs and unpacked data for BatchRedeemExecuted events raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorBatchRedeemExecutedIterator struct {
	Event *SuperVaultBatchOperatorBatchRedeemExecuted // Event containing the contract specifics and raw log

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
func (it *SuperVaultBatchOperatorBatchRedeemExecutedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultBatchOperatorBatchRedeemExecuted)
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
		it.Event = new(SuperVaultBatchOperatorBatchRedeemExecuted)
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
func (it *SuperVaultBatchOperatorBatchRedeemExecutedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultBatchOperatorBatchRedeemExecutedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultBatchOperatorBatchRedeemExecuted represents a BatchRedeemExecuted event raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorBatchRedeemExecuted struct {
	Caller       common.Address
	RequestCount *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterBatchRedeemExecuted is a free log retrieval operation binding the contract event 0x5ab7aa1e8bc519ae6e033dae855bc90b28f3ac4699e1ef2ab6fdee8d2a1c96cb.
//
// Solidity: event BatchRedeemExecuted(address indexed caller, uint256 requestCount)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) FilterBatchRedeemExecuted(opts *bind.FilterOpts, caller []common.Address) (*SuperVaultBatchOperatorBatchRedeemExecutedIterator, error) {

	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _SuperVaultBatchOperator.contract.FilterLogs(opts, "BatchRedeemExecuted", callerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultBatchOperatorBatchRedeemExecutedIterator{contract: _SuperVaultBatchOperator.contract, event: "BatchRedeemExecuted", logs: logs, sub: sub}, nil
}

// WatchBatchRedeemExecuted is a free log subscription operation binding the contract event 0x5ab7aa1e8bc519ae6e033dae855bc90b28f3ac4699e1ef2ab6fdee8d2a1c96cb.
//
// Solidity: event BatchRedeemExecuted(address indexed caller, uint256 requestCount)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) WatchBatchRedeemExecuted(opts *bind.WatchOpts, sink chan<- *SuperVaultBatchOperatorBatchRedeemExecuted, caller []common.Address) (event.Subscription, error) {

	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _SuperVaultBatchOperator.contract.WatchLogs(opts, "BatchRedeemExecuted", callerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultBatchOperatorBatchRedeemExecuted)
				if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "BatchRedeemExecuted", log); err != nil {
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

// ParseBatchRedeemExecuted is a log parse operation binding the contract event 0x5ab7aa1e8bc519ae6e033dae855bc90b28f3ac4699e1ef2ab6fdee8d2a1c96cb.
//
// Solidity: event BatchRedeemExecuted(address indexed caller, uint256 requestCount)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) ParseBatchRedeemExecuted(log types.Log) (*SuperVaultBatchOperatorBatchRedeemExecuted, error) {
	event := new(SuperVaultBatchOperatorBatchRedeemExecuted)
	if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "BatchRedeemExecuted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultBatchOperatorBatchWithdrawExecutedIterator is returned from FilterBatchWithdrawExecuted and is used to iterate over the raw logs and unpacked data for BatchWithdrawExecuted events raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorBatchWithdrawExecutedIterator struct {
	Event *SuperVaultBatchOperatorBatchWithdrawExecuted // Event containing the contract specifics and raw log

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
func (it *SuperVaultBatchOperatorBatchWithdrawExecutedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultBatchOperatorBatchWithdrawExecuted)
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
		it.Event = new(SuperVaultBatchOperatorBatchWithdrawExecuted)
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
func (it *SuperVaultBatchOperatorBatchWithdrawExecutedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultBatchOperatorBatchWithdrawExecutedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultBatchOperatorBatchWithdrawExecuted represents a BatchWithdrawExecuted event raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorBatchWithdrawExecuted struct {
	Caller       common.Address
	RequestCount *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterBatchWithdrawExecuted is a free log retrieval operation binding the contract event 0x52cc3cbb9ba447be2acf8c157cfb0f7b133158f4c4ad10a43f43d77c18c37168.
//
// Solidity: event BatchWithdrawExecuted(address indexed caller, uint256 requestCount)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) FilterBatchWithdrawExecuted(opts *bind.FilterOpts, caller []common.Address) (*SuperVaultBatchOperatorBatchWithdrawExecutedIterator, error) {

	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _SuperVaultBatchOperator.contract.FilterLogs(opts, "BatchWithdrawExecuted", callerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultBatchOperatorBatchWithdrawExecutedIterator{contract: _SuperVaultBatchOperator.contract, event: "BatchWithdrawExecuted", logs: logs, sub: sub}, nil
}

// WatchBatchWithdrawExecuted is a free log subscription operation binding the contract event 0x52cc3cbb9ba447be2acf8c157cfb0f7b133158f4c4ad10a43f43d77c18c37168.
//
// Solidity: event BatchWithdrawExecuted(address indexed caller, uint256 requestCount)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) WatchBatchWithdrawExecuted(opts *bind.WatchOpts, sink chan<- *SuperVaultBatchOperatorBatchWithdrawExecuted, caller []common.Address) (event.Subscription, error) {

	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _SuperVaultBatchOperator.contract.WatchLogs(opts, "BatchWithdrawExecuted", callerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultBatchOperatorBatchWithdrawExecuted)
				if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "BatchWithdrawExecuted", log); err != nil {
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

// ParseBatchWithdrawExecuted is a log parse operation binding the contract event 0x52cc3cbb9ba447be2acf8c157cfb0f7b133158f4c4ad10a43f43d77c18c37168.
//
// Solidity: event BatchWithdrawExecuted(address indexed caller, uint256 requestCount)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) ParseBatchWithdrawExecuted(log types.Log) (*SuperVaultBatchOperatorBatchWithdrawExecuted, error) {
	event := new(SuperVaultBatchOperatorBatchWithdrawExecuted)
	if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "BatchWithdrawExecuted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultBatchOperatorRedeemFailedIterator is returned from FilterRedeemFailed and is used to iterate over the raw logs and unpacked data for RedeemFailed events raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorRedeemFailedIterator struct {
	Event *SuperVaultBatchOperatorRedeemFailed // Event containing the contract specifics and raw log

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
func (it *SuperVaultBatchOperatorRedeemFailedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultBatchOperatorRedeemFailed)
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
		it.Event = new(SuperVaultBatchOperatorRedeemFailed)
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
func (it *SuperVaultBatchOperatorRedeemFailedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultBatchOperatorRedeemFailedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultBatchOperatorRedeemFailed represents a RedeemFailed event raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorRedeemFailed struct {
	Index      *big.Int
	Vault      common.Address
	Controller common.Address
	Amount     *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterRedeemFailed is a free log retrieval operation binding the contract event 0x53e10e5c1b2fec3b613c6b8c88e69cfc5672696d0092541411737693ff9e4876.
//
// Solidity: event RedeemFailed(uint256 indexed index, address indexed vault, address controller, uint256 amount)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) FilterRedeemFailed(opts *bind.FilterOpts, index []*big.Int, vault []common.Address) (*SuperVaultBatchOperatorRedeemFailedIterator, error) {

	var indexRule []interface{}
	for _, indexItem := range index {
		indexRule = append(indexRule, indexItem)
	}
	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _SuperVaultBatchOperator.contract.FilterLogs(opts, "RedeemFailed", indexRule, vaultRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultBatchOperatorRedeemFailedIterator{contract: _SuperVaultBatchOperator.contract, event: "RedeemFailed", logs: logs, sub: sub}, nil
}

// WatchRedeemFailed is a free log subscription operation binding the contract event 0x53e10e5c1b2fec3b613c6b8c88e69cfc5672696d0092541411737693ff9e4876.
//
// Solidity: event RedeemFailed(uint256 indexed index, address indexed vault, address controller, uint256 amount)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) WatchRedeemFailed(opts *bind.WatchOpts, sink chan<- *SuperVaultBatchOperatorRedeemFailed, index []*big.Int, vault []common.Address) (event.Subscription, error) {

	var indexRule []interface{}
	for _, indexItem := range index {
		indexRule = append(indexRule, indexItem)
	}
	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _SuperVaultBatchOperator.contract.WatchLogs(opts, "RedeemFailed", indexRule, vaultRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultBatchOperatorRedeemFailed)
				if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "RedeemFailed", log); err != nil {
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

// ParseRedeemFailed is a log parse operation binding the contract event 0x53e10e5c1b2fec3b613c6b8c88e69cfc5672696d0092541411737693ff9e4876.
//
// Solidity: event RedeemFailed(uint256 indexed index, address indexed vault, address controller, uint256 amount)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) ParseRedeemFailed(log types.Log) (*SuperVaultBatchOperatorRedeemFailed, error) {
	event := new(SuperVaultBatchOperatorRedeemFailed)
	if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "RedeemFailed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultBatchOperatorRedeemRequestSkippedIterator is returned from FilterRedeemRequestSkipped and is used to iterate over the raw logs and unpacked data for RedeemRequestSkipped events raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorRedeemRequestSkippedIterator struct {
	Event *SuperVaultBatchOperatorRedeemRequestSkipped // Event containing the contract specifics and raw log

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
func (it *SuperVaultBatchOperatorRedeemRequestSkippedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultBatchOperatorRedeemRequestSkipped)
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
		it.Event = new(SuperVaultBatchOperatorRedeemRequestSkipped)
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
func (it *SuperVaultBatchOperatorRedeemRequestSkippedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultBatchOperatorRedeemRequestSkippedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultBatchOperatorRedeemRequestSkipped represents a RedeemRequestSkipped event raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorRedeemRequestSkipped struct {
	Index      *big.Int
	Vault      common.Address
	Controller common.Address
	Amount     *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterRedeemRequestSkipped is a free log retrieval operation binding the contract event 0xec45852a920fb023a1d176a20ac66c4de7a9188a6acffd83ffc66368b58299b0.
//
// Solidity: event RedeemRequestSkipped(uint256 indexed index, address indexed vault, address controller, uint256 amount)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) FilterRedeemRequestSkipped(opts *bind.FilterOpts, index []*big.Int, vault []common.Address) (*SuperVaultBatchOperatorRedeemRequestSkippedIterator, error) {

	var indexRule []interface{}
	for _, indexItem := range index {
		indexRule = append(indexRule, indexItem)
	}
	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _SuperVaultBatchOperator.contract.FilterLogs(opts, "RedeemRequestSkipped", indexRule, vaultRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultBatchOperatorRedeemRequestSkippedIterator{contract: _SuperVaultBatchOperator.contract, event: "RedeemRequestSkipped", logs: logs, sub: sub}, nil
}

// WatchRedeemRequestSkipped is a free log subscription operation binding the contract event 0xec45852a920fb023a1d176a20ac66c4de7a9188a6acffd83ffc66368b58299b0.
//
// Solidity: event RedeemRequestSkipped(uint256 indexed index, address indexed vault, address controller, uint256 amount)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) WatchRedeemRequestSkipped(opts *bind.WatchOpts, sink chan<- *SuperVaultBatchOperatorRedeemRequestSkipped, index []*big.Int, vault []common.Address) (event.Subscription, error) {

	var indexRule []interface{}
	for _, indexItem := range index {
		indexRule = append(indexRule, indexItem)
	}
	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _SuperVaultBatchOperator.contract.WatchLogs(opts, "RedeemRequestSkipped", indexRule, vaultRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultBatchOperatorRedeemRequestSkipped)
				if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "RedeemRequestSkipped", log); err != nil {
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

// ParseRedeemRequestSkipped is a log parse operation binding the contract event 0xec45852a920fb023a1d176a20ac66c4de7a9188a6acffd83ffc66368b58299b0.
//
// Solidity: event RedeemRequestSkipped(uint256 indexed index, address indexed vault, address controller, uint256 amount)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) ParseRedeemRequestSkipped(log types.Log) (*SuperVaultBatchOperatorRedeemRequestSkipped, error) {
	event := new(SuperVaultBatchOperatorRedeemRequestSkipped)
	if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "RedeemRequestSkipped", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultBatchOperatorRoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorRoleAdminChangedIterator struct {
	Event *SuperVaultBatchOperatorRoleAdminChanged // Event containing the contract specifics and raw log

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
func (it *SuperVaultBatchOperatorRoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultBatchOperatorRoleAdminChanged)
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
		it.Event = new(SuperVaultBatchOperatorRoleAdminChanged)
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
func (it *SuperVaultBatchOperatorRoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultBatchOperatorRoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultBatchOperatorRoleAdminChanged represents a RoleAdminChanged event raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorRoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) FilterRoleAdminChanged(opts *bind.FilterOpts, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (*SuperVaultBatchOperatorRoleAdminChangedIterator, error) {

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

	logs, sub, err := _SuperVaultBatchOperator.contract.FilterLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultBatchOperatorRoleAdminChangedIterator{contract: _SuperVaultBatchOperator.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *SuperVaultBatchOperatorRoleAdminChanged, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (event.Subscription, error) {

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

	logs, sub, err := _SuperVaultBatchOperator.contract.WatchLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultBatchOperatorRoleAdminChanged)
				if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
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
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) ParseRoleAdminChanged(log types.Log) (*SuperVaultBatchOperatorRoleAdminChanged, error) {
	event := new(SuperVaultBatchOperatorRoleAdminChanged)
	if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultBatchOperatorRoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorRoleGrantedIterator struct {
	Event *SuperVaultBatchOperatorRoleGranted // Event containing the contract specifics and raw log

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
func (it *SuperVaultBatchOperatorRoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultBatchOperatorRoleGranted)
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
		it.Event = new(SuperVaultBatchOperatorRoleGranted)
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
func (it *SuperVaultBatchOperatorRoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultBatchOperatorRoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultBatchOperatorRoleGranted represents a RoleGranted event raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorRoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) FilterRoleGranted(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*SuperVaultBatchOperatorRoleGrantedIterator, error) {

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

	logs, sub, err := _SuperVaultBatchOperator.contract.FilterLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultBatchOperatorRoleGrantedIterator{contract: _SuperVaultBatchOperator.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *SuperVaultBatchOperatorRoleGranted, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _SuperVaultBatchOperator.contract.WatchLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultBatchOperatorRoleGranted)
				if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "RoleGranted", log); err != nil {
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
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) ParseRoleGranted(log types.Log) (*SuperVaultBatchOperatorRoleGranted, error) {
	event := new(SuperVaultBatchOperatorRoleGranted)
	if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultBatchOperatorRoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorRoleRevokedIterator struct {
	Event *SuperVaultBatchOperatorRoleRevoked // Event containing the contract specifics and raw log

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
func (it *SuperVaultBatchOperatorRoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultBatchOperatorRoleRevoked)
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
		it.Event = new(SuperVaultBatchOperatorRoleRevoked)
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
func (it *SuperVaultBatchOperatorRoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultBatchOperatorRoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultBatchOperatorRoleRevoked represents a RoleRevoked event raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorRoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) FilterRoleRevoked(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*SuperVaultBatchOperatorRoleRevokedIterator, error) {

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

	logs, sub, err := _SuperVaultBatchOperator.contract.FilterLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultBatchOperatorRoleRevokedIterator{contract: _SuperVaultBatchOperator.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *SuperVaultBatchOperatorRoleRevoked, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _SuperVaultBatchOperator.contract.WatchLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultBatchOperatorRoleRevoked)
				if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
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
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) ParseRoleRevoked(log types.Log) (*SuperVaultBatchOperatorRoleRevoked, error) {
	event := new(SuperVaultBatchOperatorRoleRevoked)
	if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultBatchOperatorWithdrawFailedIterator is returned from FilterWithdrawFailed and is used to iterate over the raw logs and unpacked data for WithdrawFailed events raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorWithdrawFailedIterator struct {
	Event *SuperVaultBatchOperatorWithdrawFailed // Event containing the contract specifics and raw log

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
func (it *SuperVaultBatchOperatorWithdrawFailedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultBatchOperatorWithdrawFailed)
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
		it.Event = new(SuperVaultBatchOperatorWithdrawFailed)
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
func (it *SuperVaultBatchOperatorWithdrawFailedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultBatchOperatorWithdrawFailedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultBatchOperatorWithdrawFailed represents a WithdrawFailed event raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorWithdrawFailed struct {
	Index      *big.Int
	Vault      common.Address
	Controller common.Address
	Amount     *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterWithdrawFailed is a free log retrieval operation binding the contract event 0x0e0e09850922e2234c4cec8b1fb49c549130f1e25c268f710d41579eb4826a70.
//
// Solidity: event WithdrawFailed(uint256 indexed index, address indexed vault, address controller, uint256 amount)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) FilterWithdrawFailed(opts *bind.FilterOpts, index []*big.Int, vault []common.Address) (*SuperVaultBatchOperatorWithdrawFailedIterator, error) {

	var indexRule []interface{}
	for _, indexItem := range index {
		indexRule = append(indexRule, indexItem)
	}
	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _SuperVaultBatchOperator.contract.FilterLogs(opts, "WithdrawFailed", indexRule, vaultRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultBatchOperatorWithdrawFailedIterator{contract: _SuperVaultBatchOperator.contract, event: "WithdrawFailed", logs: logs, sub: sub}, nil
}

// WatchWithdrawFailed is a free log subscription operation binding the contract event 0x0e0e09850922e2234c4cec8b1fb49c549130f1e25c268f710d41579eb4826a70.
//
// Solidity: event WithdrawFailed(uint256 indexed index, address indexed vault, address controller, uint256 amount)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) WatchWithdrawFailed(opts *bind.WatchOpts, sink chan<- *SuperVaultBatchOperatorWithdrawFailed, index []*big.Int, vault []common.Address) (event.Subscription, error) {

	var indexRule []interface{}
	for _, indexItem := range index {
		indexRule = append(indexRule, indexItem)
	}
	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _SuperVaultBatchOperator.contract.WatchLogs(opts, "WithdrawFailed", indexRule, vaultRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultBatchOperatorWithdrawFailed)
				if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "WithdrawFailed", log); err != nil {
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

// ParseWithdrawFailed is a log parse operation binding the contract event 0x0e0e09850922e2234c4cec8b1fb49c549130f1e25c268f710d41579eb4826a70.
//
// Solidity: event WithdrawFailed(uint256 indexed index, address indexed vault, address controller, uint256 amount)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) ParseWithdrawFailed(log types.Log) (*SuperVaultBatchOperatorWithdrawFailed, error) {
	event := new(SuperVaultBatchOperatorWithdrawFailed)
	if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "WithdrawFailed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultBatchOperatorWithdrawRequestSkippedIterator is returned from FilterWithdrawRequestSkipped and is used to iterate over the raw logs and unpacked data for WithdrawRequestSkipped events raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorWithdrawRequestSkippedIterator struct {
	Event *SuperVaultBatchOperatorWithdrawRequestSkipped // Event containing the contract specifics and raw log

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
func (it *SuperVaultBatchOperatorWithdrawRequestSkippedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultBatchOperatorWithdrawRequestSkipped)
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
		it.Event = new(SuperVaultBatchOperatorWithdrawRequestSkipped)
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
func (it *SuperVaultBatchOperatorWithdrawRequestSkippedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultBatchOperatorWithdrawRequestSkippedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultBatchOperatorWithdrawRequestSkipped represents a WithdrawRequestSkipped event raised by the SuperVaultBatchOperator contract.
type SuperVaultBatchOperatorWithdrawRequestSkipped struct {
	Index      *big.Int
	Vault      common.Address
	Controller common.Address
	Amount     *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterWithdrawRequestSkipped is a free log retrieval operation binding the contract event 0x4996fb0e0cff74859f415ac3f36fe452f5cb8d675b129e903ffa7ec96b01093a.
//
// Solidity: event WithdrawRequestSkipped(uint256 indexed index, address indexed vault, address controller, uint256 amount)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) FilterWithdrawRequestSkipped(opts *bind.FilterOpts, index []*big.Int, vault []common.Address) (*SuperVaultBatchOperatorWithdrawRequestSkippedIterator, error) {

	var indexRule []interface{}
	for _, indexItem := range index {
		indexRule = append(indexRule, indexItem)
	}
	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _SuperVaultBatchOperator.contract.FilterLogs(opts, "WithdrawRequestSkipped", indexRule, vaultRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultBatchOperatorWithdrawRequestSkippedIterator{contract: _SuperVaultBatchOperator.contract, event: "WithdrawRequestSkipped", logs: logs, sub: sub}, nil
}

// WatchWithdrawRequestSkipped is a free log subscription operation binding the contract event 0x4996fb0e0cff74859f415ac3f36fe452f5cb8d675b129e903ffa7ec96b01093a.
//
// Solidity: event WithdrawRequestSkipped(uint256 indexed index, address indexed vault, address controller, uint256 amount)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) WatchWithdrawRequestSkipped(opts *bind.WatchOpts, sink chan<- *SuperVaultBatchOperatorWithdrawRequestSkipped, index []*big.Int, vault []common.Address) (event.Subscription, error) {

	var indexRule []interface{}
	for _, indexItem := range index {
		indexRule = append(indexRule, indexItem)
	}
	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _SuperVaultBatchOperator.contract.WatchLogs(opts, "WithdrawRequestSkipped", indexRule, vaultRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultBatchOperatorWithdrawRequestSkipped)
				if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "WithdrawRequestSkipped", log); err != nil {
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

// ParseWithdrawRequestSkipped is a log parse operation binding the contract event 0x4996fb0e0cff74859f415ac3f36fe452f5cb8d675b129e903ffa7ec96b01093a.
//
// Solidity: event WithdrawRequestSkipped(uint256 indexed index, address indexed vault, address controller, uint256 amount)
func (_SuperVaultBatchOperator *SuperVaultBatchOperatorFilterer) ParseWithdrawRequestSkipped(log types.Log) (*SuperVaultBatchOperatorWithdrawRequestSkipped, error) {
	event := new(SuperVaultBatchOperatorWithdrawRequestSkipped)
	if err := _SuperVaultBatchOperator.contract.UnpackLog(event, "WithdrawRequestSkipped", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
