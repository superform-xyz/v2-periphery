// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package SuperVaultExecutor

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

// ISuperVaultStrategyExecuteArgs is an auto generated low-level Go binding around an user-defined struct.
type ISuperVaultStrategyExecuteArgs struct {
	Hooks                     []common.Address
	HookCalldata              [][]byte
	ExpectedAssetsOrSharesOut []*big.Int
	GlobalProofs              [][][32]byte
	StrategyProofs            [][][32]byte
}

// SuperVaultExecutorMetaData contains all meta data concerning the SuperVaultExecutor contract.
var SuperVaultExecutorMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"superGovernor_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"admin_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"receive\",\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"MAX_BATCH_SIZE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_GOVERNOR\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISuperGovernor\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_VAULT_AGGREGATOR_KEY\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"executeHooks\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"args\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultStrategy.ExecuteArgs\",\"components\":[{\"name\":\"hooks\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"hookCalldata\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"},{\"name\":\"expectedAssetsOrSharesOut\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"globalProofs\",\"type\":\"bytes32[][]\",\"internalType\":\"bytes32[][]\"},{\"name\":\"strategyProofs\",\"type\":\"bytes32[][]\",\"internalType\":\"bytes32[][]\"}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"fulfillCancelRedeemRequests\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"controllers\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"fulfillRedeemRequests\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"controllers\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"totalAssetsOut\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSessionKeyData\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"sessionKey\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"expiry\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"grantedByManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"generation\",\"type\":\"uint88\",\"internalType\":\"uint88\"},{\"name\":\"permissions\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSessionKeyPermissions\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"sessionKey\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getStrategyGeneration\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint88\",\"internalType\":\"uint88\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"grantSessionKey\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"sessionKey\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"expiry\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"permissions\",\"type\":\"uint8[]\",\"internalType\":\"enumISuperVaultExecutor.Permission[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"grantSessionKeysBatch\",\"inputs\":[{\"name\":\"strategies\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"sessionKeys\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"expiries\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"permissions\",\"type\":\"uint8[][]\",\"internalType\":\"enumISuperVaultExecutor.Permission[][]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"invalidateAllSessionKeys\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"isSessionKeyValid\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"sessionKey\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isSessionKeyValidForPermission\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"sessionKey\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"permission\",\"type\":\"uint8\",\"internalType\":\"enumISuperVaultExecutor.Permission\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pauseStrategy\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"callerConfirmation\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeSessionKey\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"sessionKey\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeSessionKeysBatch\",\"inputs\":[{\"name\":\"strategies\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"sessionKeys\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"skimPerformanceFee\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"sweepETH\",\"inputs\":[{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"unpauseStrategy\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"AllSessionKeysInvalidated\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newGeneration\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ETHRefunded\",\"inputs\":[{\"name\":\"recipient\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ETHSwept\",\"inputs\":[{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SessionKeyGranted\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sessionKey\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"expiry\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"grantedByManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"generation\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"permissions\",\"type\":\"uint8\",\"indexed\":false,\"internalType\":\"uint8\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SessionKeyRevoked\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sessionKey\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ARRAY_LENGTH_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlBadConfirmation\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"neededRole\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"BATCH_SIZE_EXCEEDED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CALLER_NOT_PRIMARY_MANAGER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"EMPTY_ARRAY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ETH_TRANSFER_FAILED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"EXPIRY_IN_PAST\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PRIMARY_MANAGER_CHANGED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ReentrancyGuardReentrantCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SESSION_KEY_EXPIRED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SESSION_KEY_GENERATION_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SESSION_KEY_NOT_AUTHORIZED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SESSION_KEY_PERMISSION_DENIED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_EXPIRY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_PERMISSIONS\",\"inputs\":[]}]",
}

// SuperVaultExecutorABI is the input ABI used to generate the binding from.
// Deprecated: Use SuperVaultExecutorMetaData.ABI instead.
var SuperVaultExecutorABI = SuperVaultExecutorMetaData.ABI

// SuperVaultExecutor is an auto generated Go binding around an Ethereum contract.
type SuperVaultExecutor struct {
	SuperVaultExecutorCaller     // Read-only binding to the contract
	SuperVaultExecutorTransactor // Write-only binding to the contract
	SuperVaultExecutorFilterer   // Log filterer for contract events
}

// SuperVaultExecutorCaller is an auto generated read-only Go binding around an Ethereum contract.
type SuperVaultExecutorCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultExecutorTransactor is an auto generated write-only Go binding around an Ethereum contract.
type SuperVaultExecutorTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultExecutorFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type SuperVaultExecutorFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultExecutorSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type SuperVaultExecutorSession struct {
	Contract     *SuperVaultExecutor // Generic contract binding to set the session for
	CallOpts     bind.CallOpts       // Call options to use throughout this session
	TransactOpts bind.TransactOpts   // Transaction auth options to use throughout this session
}

// SuperVaultExecutorCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type SuperVaultExecutorCallerSession struct {
	Contract *SuperVaultExecutorCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts             // Call options to use throughout this session
}

// SuperVaultExecutorTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type SuperVaultExecutorTransactorSession struct {
	Contract     *SuperVaultExecutorTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts             // Transaction auth options to use throughout this session
}

// SuperVaultExecutorRaw is an auto generated low-level Go binding around an Ethereum contract.
type SuperVaultExecutorRaw struct {
	Contract *SuperVaultExecutor // Generic contract binding to access the raw methods on
}

// SuperVaultExecutorCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type SuperVaultExecutorCallerRaw struct {
	Contract *SuperVaultExecutorCaller // Generic read-only contract binding to access the raw methods on
}

// SuperVaultExecutorTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type SuperVaultExecutorTransactorRaw struct {
	Contract *SuperVaultExecutorTransactor // Generic write-only contract binding to access the raw methods on
}

// NewSuperVaultExecutor creates a new instance of SuperVaultExecutor, bound to a specific deployed contract.
func NewSuperVaultExecutor(address common.Address, backend bind.ContractBackend) (*SuperVaultExecutor, error) {
	contract, err := bindSuperVaultExecutor(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutor{SuperVaultExecutorCaller: SuperVaultExecutorCaller{contract: contract}, SuperVaultExecutorTransactor: SuperVaultExecutorTransactor{contract: contract}, SuperVaultExecutorFilterer: SuperVaultExecutorFilterer{contract: contract}}, nil
}

// NewSuperVaultExecutorCaller creates a new read-only instance of SuperVaultExecutor, bound to a specific deployed contract.
func NewSuperVaultExecutorCaller(address common.Address, caller bind.ContractCaller) (*SuperVaultExecutorCaller, error) {
	contract, err := bindSuperVaultExecutor(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorCaller{contract: contract}, nil
}

// NewSuperVaultExecutorTransactor creates a new write-only instance of SuperVaultExecutor, bound to a specific deployed contract.
func NewSuperVaultExecutorTransactor(address common.Address, transactor bind.ContractTransactor) (*SuperVaultExecutorTransactor, error) {
	contract, err := bindSuperVaultExecutor(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorTransactor{contract: contract}, nil
}

// NewSuperVaultExecutorFilterer creates a new log filterer instance of SuperVaultExecutor, bound to a specific deployed contract.
func NewSuperVaultExecutorFilterer(address common.Address, filterer bind.ContractFilterer) (*SuperVaultExecutorFilterer, error) {
	contract, err := bindSuperVaultExecutor(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorFilterer{contract: contract}, nil
}

// bindSuperVaultExecutor binds a generic wrapper to an already deployed contract.
func bindSuperVaultExecutor(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := SuperVaultExecutorMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperVaultExecutor *SuperVaultExecutorRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperVaultExecutor.Contract.SuperVaultExecutorCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperVaultExecutor *SuperVaultExecutorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.SuperVaultExecutorTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperVaultExecutor *SuperVaultExecutorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.SuperVaultExecutorTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperVaultExecutor *SuperVaultExecutorCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperVaultExecutor.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperVaultExecutor *SuperVaultExecutorTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperVaultExecutor *SuperVaultExecutorTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.contract.Transact(opts, method, params...)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) DEFAULTADMINROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "DEFAULT_ADMIN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_SuperVaultExecutor *SuperVaultExecutorSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _SuperVaultExecutor.Contract.DEFAULTADMINROLE(&_SuperVaultExecutor.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _SuperVaultExecutor.Contract.DEFAULTADMINROLE(&_SuperVaultExecutor.CallOpts)
}

// MAXBATCHSIZE is a free data retrieval call binding the contract method 0xcfdbf254.
//
// Solidity: function MAX_BATCH_SIZE() view returns(uint256)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) MAXBATCHSIZE(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "MAX_BATCH_SIZE")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MAXBATCHSIZE is a free data retrieval call binding the contract method 0xcfdbf254.
//
// Solidity: function MAX_BATCH_SIZE() view returns(uint256)
func (_SuperVaultExecutor *SuperVaultExecutorSession) MAXBATCHSIZE() (*big.Int, error) {
	return _SuperVaultExecutor.Contract.MAXBATCHSIZE(&_SuperVaultExecutor.CallOpts)
}

// MAXBATCHSIZE is a free data retrieval call binding the contract method 0xcfdbf254.
//
// Solidity: function MAX_BATCH_SIZE() view returns(uint256)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) MAXBATCHSIZE() (*big.Int, error) {
	return _SuperVaultExecutor.Contract.MAXBATCHSIZE(&_SuperVaultExecutor.CallOpts)
}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) SUPERGOVERNOR(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "SUPER_GOVERNOR")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_SuperVaultExecutor *SuperVaultExecutorSession) SUPERGOVERNOR() (common.Address, error) {
	return _SuperVaultExecutor.Contract.SUPERGOVERNOR(&_SuperVaultExecutor.CallOpts)
}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) SUPERGOVERNOR() (common.Address, error) {
	return _SuperVaultExecutor.Contract.SUPERGOVERNOR(&_SuperVaultExecutor.CallOpts)
}

// SUPERVAULTAGGREGATORKEY is a free data retrieval call binding the contract method 0xbca0cc2d.
//
// Solidity: function SUPER_VAULT_AGGREGATOR_KEY() view returns(bytes32)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) SUPERVAULTAGGREGATORKEY(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "SUPER_VAULT_AGGREGATOR_KEY")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SUPERVAULTAGGREGATORKEY is a free data retrieval call binding the contract method 0xbca0cc2d.
//
// Solidity: function SUPER_VAULT_AGGREGATOR_KEY() view returns(bytes32)
func (_SuperVaultExecutor *SuperVaultExecutorSession) SUPERVAULTAGGREGATORKEY() ([32]byte, error) {
	return _SuperVaultExecutor.Contract.SUPERVAULTAGGREGATORKEY(&_SuperVaultExecutor.CallOpts)
}

// SUPERVAULTAGGREGATORKEY is a free data retrieval call binding the contract method 0xbca0cc2d.
//
// Solidity: function SUPER_VAULT_AGGREGATOR_KEY() view returns(bytes32)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) SUPERVAULTAGGREGATORKEY() ([32]byte, error) {
	return _SuperVaultExecutor.Contract.SUPERVAULTAGGREGATORKEY(&_SuperVaultExecutor.CallOpts)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) GetRoleAdmin(opts *bind.CallOpts, role [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "getRoleAdmin", role)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_SuperVaultExecutor *SuperVaultExecutorSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _SuperVaultExecutor.Contract.GetRoleAdmin(&_SuperVaultExecutor.CallOpts, role)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _SuperVaultExecutor.Contract.GetRoleAdmin(&_SuperVaultExecutor.CallOpts, role)
}

// GetSessionKeyData is a free data retrieval call binding the contract method 0x4802254e.
//
// Solidity: function getSessionKeyData(address strategy, address sessionKey) view returns(uint256 expiry, address grantedByManager, uint88 generation, uint8 permissions)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) GetSessionKeyData(opts *bind.CallOpts, strategy common.Address, sessionKey common.Address) (struct {
	Expiry           *big.Int
	GrantedByManager common.Address
	Generation       *big.Int
	Permissions      uint8
}, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "getSessionKeyData", strategy, sessionKey)

	outstruct := new(struct {
		Expiry           *big.Int
		GrantedByManager common.Address
		Generation       *big.Int
		Permissions      uint8
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Expiry = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.GrantedByManager = *abi.ConvertType(out[1], new(common.Address)).(*common.Address)
	outstruct.Generation = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.Permissions = *abi.ConvertType(out[3], new(uint8)).(*uint8)

	return *outstruct, err

}

// GetSessionKeyData is a free data retrieval call binding the contract method 0x4802254e.
//
// Solidity: function getSessionKeyData(address strategy, address sessionKey) view returns(uint256 expiry, address grantedByManager, uint88 generation, uint8 permissions)
func (_SuperVaultExecutor *SuperVaultExecutorSession) GetSessionKeyData(strategy common.Address, sessionKey common.Address) (struct {
	Expiry           *big.Int
	GrantedByManager common.Address
	Generation       *big.Int
	Permissions      uint8
}, error) {
	return _SuperVaultExecutor.Contract.GetSessionKeyData(&_SuperVaultExecutor.CallOpts, strategy, sessionKey)
}

// GetSessionKeyData is a free data retrieval call binding the contract method 0x4802254e.
//
// Solidity: function getSessionKeyData(address strategy, address sessionKey) view returns(uint256 expiry, address grantedByManager, uint88 generation, uint8 permissions)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) GetSessionKeyData(strategy common.Address, sessionKey common.Address) (struct {
	Expiry           *big.Int
	GrantedByManager common.Address
	Generation       *big.Int
	Permissions      uint8
}, error) {
	return _SuperVaultExecutor.Contract.GetSessionKeyData(&_SuperVaultExecutor.CallOpts, strategy, sessionKey)
}

// GetSessionKeyPermissions is a free data retrieval call binding the contract method 0x97b7f20a.
//
// Solidity: function getSessionKeyPermissions(address strategy, address sessionKey) view returns(uint8)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) GetSessionKeyPermissions(opts *bind.CallOpts, strategy common.Address, sessionKey common.Address) (uint8, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "getSessionKeyPermissions", strategy, sessionKey)

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// GetSessionKeyPermissions is a free data retrieval call binding the contract method 0x97b7f20a.
//
// Solidity: function getSessionKeyPermissions(address strategy, address sessionKey) view returns(uint8)
func (_SuperVaultExecutor *SuperVaultExecutorSession) GetSessionKeyPermissions(strategy common.Address, sessionKey common.Address) (uint8, error) {
	return _SuperVaultExecutor.Contract.GetSessionKeyPermissions(&_SuperVaultExecutor.CallOpts, strategy, sessionKey)
}

// GetSessionKeyPermissions is a free data retrieval call binding the contract method 0x97b7f20a.
//
// Solidity: function getSessionKeyPermissions(address strategy, address sessionKey) view returns(uint8)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) GetSessionKeyPermissions(strategy common.Address, sessionKey common.Address) (uint8, error) {
	return _SuperVaultExecutor.Contract.GetSessionKeyPermissions(&_SuperVaultExecutor.CallOpts, strategy, sessionKey)
}

// GetStrategyGeneration is a free data retrieval call binding the contract method 0xabbf7209.
//
// Solidity: function getStrategyGeneration(address strategy) view returns(uint88)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) GetStrategyGeneration(opts *bind.CallOpts, strategy common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "getStrategyGeneration", strategy)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetStrategyGeneration is a free data retrieval call binding the contract method 0xabbf7209.
//
// Solidity: function getStrategyGeneration(address strategy) view returns(uint88)
func (_SuperVaultExecutor *SuperVaultExecutorSession) GetStrategyGeneration(strategy common.Address) (*big.Int, error) {
	return _SuperVaultExecutor.Contract.GetStrategyGeneration(&_SuperVaultExecutor.CallOpts, strategy)
}

// GetStrategyGeneration is a free data retrieval call binding the contract method 0xabbf7209.
//
// Solidity: function getStrategyGeneration(address strategy) view returns(uint88)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) GetStrategyGeneration(strategy common.Address) (*big.Int, error) {
	return _SuperVaultExecutor.Contract.GetStrategyGeneration(&_SuperVaultExecutor.CallOpts, strategy)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) HasRole(opts *bind.CallOpts, role [32]byte, account common.Address) (bool, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "hasRole", role, account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _SuperVaultExecutor.Contract.HasRole(&_SuperVaultExecutor.CallOpts, role, account)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _SuperVaultExecutor.Contract.HasRole(&_SuperVaultExecutor.CallOpts, role, account)
}

// IsSessionKeyValid is a free data retrieval call binding the contract method 0x81e9c8d1.
//
// Solidity: function isSessionKeyValid(address strategy, address sessionKey) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) IsSessionKeyValid(opts *bind.CallOpts, strategy common.Address, sessionKey common.Address) (bool, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "isSessionKeyValid", strategy, sessionKey)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsSessionKeyValid is a free data retrieval call binding the contract method 0x81e9c8d1.
//
// Solidity: function isSessionKeyValid(address strategy, address sessionKey) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorSession) IsSessionKeyValid(strategy common.Address, sessionKey common.Address) (bool, error) {
	return _SuperVaultExecutor.Contract.IsSessionKeyValid(&_SuperVaultExecutor.CallOpts, strategy, sessionKey)
}

// IsSessionKeyValid is a free data retrieval call binding the contract method 0x81e9c8d1.
//
// Solidity: function isSessionKeyValid(address strategy, address sessionKey) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) IsSessionKeyValid(strategy common.Address, sessionKey common.Address) (bool, error) {
	return _SuperVaultExecutor.Contract.IsSessionKeyValid(&_SuperVaultExecutor.CallOpts, strategy, sessionKey)
}

// IsSessionKeyValidForPermission is a free data retrieval call binding the contract method 0xf6e9e60e.
//
// Solidity: function isSessionKeyValidForPermission(address strategy, address sessionKey, uint8 permission) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) IsSessionKeyValidForPermission(opts *bind.CallOpts, strategy common.Address, sessionKey common.Address, permission uint8) (bool, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "isSessionKeyValidForPermission", strategy, sessionKey, permission)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsSessionKeyValidForPermission is a free data retrieval call binding the contract method 0xf6e9e60e.
//
// Solidity: function isSessionKeyValidForPermission(address strategy, address sessionKey, uint8 permission) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorSession) IsSessionKeyValidForPermission(strategy common.Address, sessionKey common.Address, permission uint8) (bool, error) {
	return _SuperVaultExecutor.Contract.IsSessionKeyValidForPermission(&_SuperVaultExecutor.CallOpts, strategy, sessionKey, permission)
}

// IsSessionKeyValidForPermission is a free data retrieval call binding the contract method 0xf6e9e60e.
//
// Solidity: function isSessionKeyValidForPermission(address strategy, address sessionKey, uint8 permission) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) IsSessionKeyValidForPermission(strategy common.Address, sessionKey common.Address, permission uint8) (bool, error) {
	return _SuperVaultExecutor.Contract.IsSessionKeyValidForPermission(&_SuperVaultExecutor.CallOpts, strategy, sessionKey, permission)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _SuperVaultExecutor.Contract.SupportsInterface(&_SuperVaultExecutor.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _SuperVaultExecutor.Contract.SupportsInterface(&_SuperVaultExecutor.CallOpts, interfaceId)
}

// ExecuteHooks is a paid mutator transaction binding the contract method 0x2638a293.
//
// Solidity: function executeHooks(address strategy, (address[],bytes[],uint256[],bytes32[][],bytes32[][]) args) payable returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) ExecuteHooks(opts *bind.TransactOpts, strategy common.Address, args ISuperVaultStrategyExecuteArgs) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "executeHooks", strategy, args)
}

// ExecuteHooks is a paid mutator transaction binding the contract method 0x2638a293.
//
// Solidity: function executeHooks(address strategy, (address[],bytes[],uint256[],bytes32[][],bytes32[][]) args) payable returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) ExecuteHooks(strategy common.Address, args ISuperVaultStrategyExecuteArgs) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.ExecuteHooks(&_SuperVaultExecutor.TransactOpts, strategy, args)
}

// ExecuteHooks is a paid mutator transaction binding the contract method 0x2638a293.
//
// Solidity: function executeHooks(address strategy, (address[],bytes[],uint256[],bytes32[][],bytes32[][]) args) payable returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) ExecuteHooks(strategy common.Address, args ISuperVaultStrategyExecuteArgs) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.ExecuteHooks(&_SuperVaultExecutor.TransactOpts, strategy, args)
}

// FulfillCancelRedeemRequests is a paid mutator transaction binding the contract method 0x4bdc6ebd.
//
// Solidity: function fulfillCancelRedeemRequests(address strategy, address[] controllers) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) FulfillCancelRedeemRequests(opts *bind.TransactOpts, strategy common.Address, controllers []common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "fulfillCancelRedeemRequests", strategy, controllers)
}

// FulfillCancelRedeemRequests is a paid mutator transaction binding the contract method 0x4bdc6ebd.
//
// Solidity: function fulfillCancelRedeemRequests(address strategy, address[] controllers) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) FulfillCancelRedeemRequests(strategy common.Address, controllers []common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.FulfillCancelRedeemRequests(&_SuperVaultExecutor.TransactOpts, strategy, controllers)
}

// FulfillCancelRedeemRequests is a paid mutator transaction binding the contract method 0x4bdc6ebd.
//
// Solidity: function fulfillCancelRedeemRequests(address strategy, address[] controllers) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) FulfillCancelRedeemRequests(strategy common.Address, controllers []common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.FulfillCancelRedeemRequests(&_SuperVaultExecutor.TransactOpts, strategy, controllers)
}

// FulfillRedeemRequests is a paid mutator transaction binding the contract method 0x5d9f8be7.
//
// Solidity: function fulfillRedeemRequests(address strategy, address[] controllers, uint256[] totalAssetsOut) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) FulfillRedeemRequests(opts *bind.TransactOpts, strategy common.Address, controllers []common.Address, totalAssetsOut []*big.Int) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "fulfillRedeemRequests", strategy, controllers, totalAssetsOut)
}

// FulfillRedeemRequests is a paid mutator transaction binding the contract method 0x5d9f8be7.
//
// Solidity: function fulfillRedeemRequests(address strategy, address[] controllers, uint256[] totalAssetsOut) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) FulfillRedeemRequests(strategy common.Address, controllers []common.Address, totalAssetsOut []*big.Int) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.FulfillRedeemRequests(&_SuperVaultExecutor.TransactOpts, strategy, controllers, totalAssetsOut)
}

// FulfillRedeemRequests is a paid mutator transaction binding the contract method 0x5d9f8be7.
//
// Solidity: function fulfillRedeemRequests(address strategy, address[] controllers, uint256[] totalAssetsOut) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) FulfillRedeemRequests(strategy common.Address, controllers []common.Address, totalAssetsOut []*big.Int) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.FulfillRedeemRequests(&_SuperVaultExecutor.TransactOpts, strategy, controllers, totalAssetsOut)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.GrantRole(&_SuperVaultExecutor.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.GrantRole(&_SuperVaultExecutor.TransactOpts, role, account)
}

// GrantSessionKey is a paid mutator transaction binding the contract method 0x9d16135a.
//
// Solidity: function grantSessionKey(address strategy, address sessionKey, uint256 expiry, uint8[] permissions) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) GrantSessionKey(opts *bind.TransactOpts, strategy common.Address, sessionKey common.Address, expiry *big.Int, permissions []uint8) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "grantSessionKey", strategy, sessionKey, expiry, permissions)
}

// GrantSessionKey is a paid mutator transaction binding the contract method 0x9d16135a.
//
// Solidity: function grantSessionKey(address strategy, address sessionKey, uint256 expiry, uint8[] permissions) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) GrantSessionKey(strategy common.Address, sessionKey common.Address, expiry *big.Int, permissions []uint8) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.GrantSessionKey(&_SuperVaultExecutor.TransactOpts, strategy, sessionKey, expiry, permissions)
}

// GrantSessionKey is a paid mutator transaction binding the contract method 0x9d16135a.
//
// Solidity: function grantSessionKey(address strategy, address sessionKey, uint256 expiry, uint8[] permissions) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) GrantSessionKey(strategy common.Address, sessionKey common.Address, expiry *big.Int, permissions []uint8) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.GrantSessionKey(&_SuperVaultExecutor.TransactOpts, strategy, sessionKey, expiry, permissions)
}

// GrantSessionKeysBatch is a paid mutator transaction binding the contract method 0x9a7965d0.
//
// Solidity: function grantSessionKeysBatch(address[] strategies, address[] sessionKeys, uint256[] expiries, uint8[][] permissions) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) GrantSessionKeysBatch(opts *bind.TransactOpts, strategies []common.Address, sessionKeys []common.Address, expiries []*big.Int, permissions [][]uint8) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "grantSessionKeysBatch", strategies, sessionKeys, expiries, permissions)
}

// GrantSessionKeysBatch is a paid mutator transaction binding the contract method 0x9a7965d0.
//
// Solidity: function grantSessionKeysBatch(address[] strategies, address[] sessionKeys, uint256[] expiries, uint8[][] permissions) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) GrantSessionKeysBatch(strategies []common.Address, sessionKeys []common.Address, expiries []*big.Int, permissions [][]uint8) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.GrantSessionKeysBatch(&_SuperVaultExecutor.TransactOpts, strategies, sessionKeys, expiries, permissions)
}

// GrantSessionKeysBatch is a paid mutator transaction binding the contract method 0x9a7965d0.
//
// Solidity: function grantSessionKeysBatch(address[] strategies, address[] sessionKeys, uint256[] expiries, uint8[][] permissions) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) GrantSessionKeysBatch(strategies []common.Address, sessionKeys []common.Address, expiries []*big.Int, permissions [][]uint8) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.GrantSessionKeysBatch(&_SuperVaultExecutor.TransactOpts, strategies, sessionKeys, expiries, permissions)
}

// InvalidateAllSessionKeys is a paid mutator transaction binding the contract method 0xfcea4297.
//
// Solidity: function invalidateAllSessionKeys(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) InvalidateAllSessionKeys(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "invalidateAllSessionKeys", strategy)
}

// InvalidateAllSessionKeys is a paid mutator transaction binding the contract method 0xfcea4297.
//
// Solidity: function invalidateAllSessionKeys(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) InvalidateAllSessionKeys(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.InvalidateAllSessionKeys(&_SuperVaultExecutor.TransactOpts, strategy)
}

// InvalidateAllSessionKeys is a paid mutator transaction binding the contract method 0xfcea4297.
//
// Solidity: function invalidateAllSessionKeys(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) InvalidateAllSessionKeys(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.InvalidateAllSessionKeys(&_SuperVaultExecutor.TransactOpts, strategy)
}

// PauseStrategy is a paid mutator transaction binding the contract method 0xd3f6b598.
//
// Solidity: function pauseStrategy(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) PauseStrategy(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "pauseStrategy", strategy)
}

// PauseStrategy is a paid mutator transaction binding the contract method 0xd3f6b598.
//
// Solidity: function pauseStrategy(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) PauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.PauseStrategy(&_SuperVaultExecutor.TransactOpts, strategy)
}

// PauseStrategy is a paid mutator transaction binding the contract method 0xd3f6b598.
//
// Solidity: function pauseStrategy(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) PauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.PauseStrategy(&_SuperVaultExecutor.TransactOpts, strategy)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "renounceRole", role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.RenounceRole(&_SuperVaultExecutor.TransactOpts, role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.RenounceRole(&_SuperVaultExecutor.TransactOpts, role, callerConfirmation)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.RevokeRole(&_SuperVaultExecutor.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.RevokeRole(&_SuperVaultExecutor.TransactOpts, role, account)
}

// RevokeSessionKey is a paid mutator transaction binding the contract method 0x1f091782.
//
// Solidity: function revokeSessionKey(address strategy, address sessionKey) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) RevokeSessionKey(opts *bind.TransactOpts, strategy common.Address, sessionKey common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "revokeSessionKey", strategy, sessionKey)
}

// RevokeSessionKey is a paid mutator transaction binding the contract method 0x1f091782.
//
// Solidity: function revokeSessionKey(address strategy, address sessionKey) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) RevokeSessionKey(strategy common.Address, sessionKey common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.RevokeSessionKey(&_SuperVaultExecutor.TransactOpts, strategy, sessionKey)
}

// RevokeSessionKey is a paid mutator transaction binding the contract method 0x1f091782.
//
// Solidity: function revokeSessionKey(address strategy, address sessionKey) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) RevokeSessionKey(strategy common.Address, sessionKey common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.RevokeSessionKey(&_SuperVaultExecutor.TransactOpts, strategy, sessionKey)
}

// RevokeSessionKeysBatch is a paid mutator transaction binding the contract method 0x14ea652d.
//
// Solidity: function revokeSessionKeysBatch(address[] strategies, address[] sessionKeys) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) RevokeSessionKeysBatch(opts *bind.TransactOpts, strategies []common.Address, sessionKeys []common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "revokeSessionKeysBatch", strategies, sessionKeys)
}

// RevokeSessionKeysBatch is a paid mutator transaction binding the contract method 0x14ea652d.
//
// Solidity: function revokeSessionKeysBatch(address[] strategies, address[] sessionKeys) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) RevokeSessionKeysBatch(strategies []common.Address, sessionKeys []common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.RevokeSessionKeysBatch(&_SuperVaultExecutor.TransactOpts, strategies, sessionKeys)
}

// RevokeSessionKeysBatch is a paid mutator transaction binding the contract method 0x14ea652d.
//
// Solidity: function revokeSessionKeysBatch(address[] strategies, address[] sessionKeys) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) RevokeSessionKeysBatch(strategies []common.Address, sessionKeys []common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.RevokeSessionKeysBatch(&_SuperVaultExecutor.TransactOpts, strategies, sessionKeys)
}

// SkimPerformanceFee is a paid mutator transaction binding the contract method 0xe2aab9f0.
//
// Solidity: function skimPerformanceFee(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) SkimPerformanceFee(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "skimPerformanceFee", strategy)
}

// SkimPerformanceFee is a paid mutator transaction binding the contract method 0xe2aab9f0.
//
// Solidity: function skimPerformanceFee(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) SkimPerformanceFee(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.SkimPerformanceFee(&_SuperVaultExecutor.TransactOpts, strategy)
}

// SkimPerformanceFee is a paid mutator transaction binding the contract method 0xe2aab9f0.
//
// Solidity: function skimPerformanceFee(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) SkimPerformanceFee(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.SkimPerformanceFee(&_SuperVaultExecutor.TransactOpts, strategy)
}

// SweepETH is a paid mutator transaction binding the contract method 0x1163b2b0.
//
// Solidity: function sweepETH(address to) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) SweepETH(opts *bind.TransactOpts, to common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "sweepETH", to)
}

// SweepETH is a paid mutator transaction binding the contract method 0x1163b2b0.
//
// Solidity: function sweepETH(address to) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) SweepETH(to common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.SweepETH(&_SuperVaultExecutor.TransactOpts, to)
}

// SweepETH is a paid mutator transaction binding the contract method 0x1163b2b0.
//
// Solidity: function sweepETH(address to) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) SweepETH(to common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.SweepETH(&_SuperVaultExecutor.TransactOpts, to)
}

// UnpauseStrategy is a paid mutator transaction binding the contract method 0x0ff323a3.
//
// Solidity: function unpauseStrategy(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) UnpauseStrategy(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "unpauseStrategy", strategy)
}

// UnpauseStrategy is a paid mutator transaction binding the contract method 0x0ff323a3.
//
// Solidity: function unpauseStrategy(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) UnpauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.UnpauseStrategy(&_SuperVaultExecutor.TransactOpts, strategy)
}

// UnpauseStrategy is a paid mutator transaction binding the contract method 0x0ff323a3.
//
// Solidity: function unpauseStrategy(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) UnpauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.UnpauseStrategy(&_SuperVaultExecutor.TransactOpts, strategy)
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) Receive(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.RawTransact(opts, nil) // calldata is disallowed for receive function
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) Receive() (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.Receive(&_SuperVaultExecutor.TransactOpts)
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) Receive() (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.Receive(&_SuperVaultExecutor.TransactOpts)
}

// SuperVaultExecutorAllSessionKeysInvalidatedIterator is returned from FilterAllSessionKeysInvalidated and is used to iterate over the raw logs and unpacked data for AllSessionKeysInvalidated events raised by the SuperVaultExecutor contract.
type SuperVaultExecutorAllSessionKeysInvalidatedIterator struct {
	Event *SuperVaultExecutorAllSessionKeysInvalidated // Event containing the contract specifics and raw log

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
func (it *SuperVaultExecutorAllSessionKeysInvalidatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultExecutorAllSessionKeysInvalidated)
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
		it.Event = new(SuperVaultExecutorAllSessionKeysInvalidated)
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
func (it *SuperVaultExecutorAllSessionKeysInvalidatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultExecutorAllSessionKeysInvalidatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultExecutorAllSessionKeysInvalidated represents a AllSessionKeysInvalidated event raised by the SuperVaultExecutor contract.
type SuperVaultExecutorAllSessionKeysInvalidated struct {
	Strategy      common.Address
	NewGeneration *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterAllSessionKeysInvalidated is a free log retrieval operation binding the contract event 0xe5eeca603c4108df725bc074154afd8c6100bb89d579de2af5b1c825dd7ea43f.
//
// Solidity: event AllSessionKeysInvalidated(address indexed strategy, uint256 newGeneration)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) FilterAllSessionKeysInvalidated(opts *bind.FilterOpts, strategy []common.Address) (*SuperVaultExecutorAllSessionKeysInvalidatedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.FilterLogs(opts, "AllSessionKeysInvalidated", strategyRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorAllSessionKeysInvalidatedIterator{contract: _SuperVaultExecutor.contract, event: "AllSessionKeysInvalidated", logs: logs, sub: sub}, nil
}

// WatchAllSessionKeysInvalidated is a free log subscription operation binding the contract event 0xe5eeca603c4108df725bc074154afd8c6100bb89d579de2af5b1c825dd7ea43f.
//
// Solidity: event AllSessionKeysInvalidated(address indexed strategy, uint256 newGeneration)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) WatchAllSessionKeysInvalidated(opts *bind.WatchOpts, sink chan<- *SuperVaultExecutorAllSessionKeysInvalidated, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.WatchLogs(opts, "AllSessionKeysInvalidated", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultExecutorAllSessionKeysInvalidated)
				if err := _SuperVaultExecutor.contract.UnpackLog(event, "AllSessionKeysInvalidated", log); err != nil {
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

// ParseAllSessionKeysInvalidated is a log parse operation binding the contract event 0xe5eeca603c4108df725bc074154afd8c6100bb89d579de2af5b1c825dd7ea43f.
//
// Solidity: event AllSessionKeysInvalidated(address indexed strategy, uint256 newGeneration)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) ParseAllSessionKeysInvalidated(log types.Log) (*SuperVaultExecutorAllSessionKeysInvalidated, error) {
	event := new(SuperVaultExecutorAllSessionKeysInvalidated)
	if err := _SuperVaultExecutor.contract.UnpackLog(event, "AllSessionKeysInvalidated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultExecutorETHRefundedIterator is returned from FilterETHRefunded and is used to iterate over the raw logs and unpacked data for ETHRefunded events raised by the SuperVaultExecutor contract.
type SuperVaultExecutorETHRefundedIterator struct {
	Event *SuperVaultExecutorETHRefunded // Event containing the contract specifics and raw log

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
func (it *SuperVaultExecutorETHRefundedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultExecutorETHRefunded)
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
		it.Event = new(SuperVaultExecutorETHRefunded)
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
func (it *SuperVaultExecutorETHRefundedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultExecutorETHRefundedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultExecutorETHRefunded represents a ETHRefunded event raised by the SuperVaultExecutor contract.
type SuperVaultExecutorETHRefunded struct {
	Recipient common.Address
	Amount    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterETHRefunded is a free log retrieval operation binding the contract event 0xb593fb7f0ed454d644104a0e41134bbe1f73b78eb6c1c6dc7f82a46ef25ea785.
//
// Solidity: event ETHRefunded(address indexed recipient, uint256 amount)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) FilterETHRefunded(opts *bind.FilterOpts, recipient []common.Address) (*SuperVaultExecutorETHRefundedIterator, error) {

	var recipientRule []interface{}
	for _, recipientItem := range recipient {
		recipientRule = append(recipientRule, recipientItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.FilterLogs(opts, "ETHRefunded", recipientRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorETHRefundedIterator{contract: _SuperVaultExecutor.contract, event: "ETHRefunded", logs: logs, sub: sub}, nil
}

// WatchETHRefunded is a free log subscription operation binding the contract event 0xb593fb7f0ed454d644104a0e41134bbe1f73b78eb6c1c6dc7f82a46ef25ea785.
//
// Solidity: event ETHRefunded(address indexed recipient, uint256 amount)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) WatchETHRefunded(opts *bind.WatchOpts, sink chan<- *SuperVaultExecutorETHRefunded, recipient []common.Address) (event.Subscription, error) {

	var recipientRule []interface{}
	for _, recipientItem := range recipient {
		recipientRule = append(recipientRule, recipientItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.WatchLogs(opts, "ETHRefunded", recipientRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultExecutorETHRefunded)
				if err := _SuperVaultExecutor.contract.UnpackLog(event, "ETHRefunded", log); err != nil {
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

// ParseETHRefunded is a log parse operation binding the contract event 0xb593fb7f0ed454d644104a0e41134bbe1f73b78eb6c1c6dc7f82a46ef25ea785.
//
// Solidity: event ETHRefunded(address indexed recipient, uint256 amount)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) ParseETHRefunded(log types.Log) (*SuperVaultExecutorETHRefunded, error) {
	event := new(SuperVaultExecutorETHRefunded)
	if err := _SuperVaultExecutor.contract.UnpackLog(event, "ETHRefunded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultExecutorETHSweptIterator is returned from FilterETHSwept and is used to iterate over the raw logs and unpacked data for ETHSwept events raised by the SuperVaultExecutor contract.
type SuperVaultExecutorETHSweptIterator struct {
	Event *SuperVaultExecutorETHSwept // Event containing the contract specifics and raw log

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
func (it *SuperVaultExecutorETHSweptIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultExecutorETHSwept)
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
		it.Event = new(SuperVaultExecutorETHSwept)
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
func (it *SuperVaultExecutorETHSweptIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultExecutorETHSweptIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultExecutorETHSwept represents a ETHSwept event raised by the SuperVaultExecutor contract.
type SuperVaultExecutorETHSwept struct {
	To     common.Address
	Amount *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterETHSwept is a free log retrieval operation binding the contract event 0xab31ddb82a9ca2de51c9befe9da7c6e815e12eac49ae58b8d9cb6b7a181cbc71.
//
// Solidity: event ETHSwept(address indexed to, uint256 amount)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) FilterETHSwept(opts *bind.FilterOpts, to []common.Address) (*SuperVaultExecutorETHSweptIterator, error) {

	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.FilterLogs(opts, "ETHSwept", toRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorETHSweptIterator{contract: _SuperVaultExecutor.contract, event: "ETHSwept", logs: logs, sub: sub}, nil
}

// WatchETHSwept is a free log subscription operation binding the contract event 0xab31ddb82a9ca2de51c9befe9da7c6e815e12eac49ae58b8d9cb6b7a181cbc71.
//
// Solidity: event ETHSwept(address indexed to, uint256 amount)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) WatchETHSwept(opts *bind.WatchOpts, sink chan<- *SuperVaultExecutorETHSwept, to []common.Address) (event.Subscription, error) {

	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.WatchLogs(opts, "ETHSwept", toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultExecutorETHSwept)
				if err := _SuperVaultExecutor.contract.UnpackLog(event, "ETHSwept", log); err != nil {
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

// ParseETHSwept is a log parse operation binding the contract event 0xab31ddb82a9ca2de51c9befe9da7c6e815e12eac49ae58b8d9cb6b7a181cbc71.
//
// Solidity: event ETHSwept(address indexed to, uint256 amount)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) ParseETHSwept(log types.Log) (*SuperVaultExecutorETHSwept, error) {
	event := new(SuperVaultExecutorETHSwept)
	if err := _SuperVaultExecutor.contract.UnpackLog(event, "ETHSwept", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultExecutorRoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the SuperVaultExecutor contract.
type SuperVaultExecutorRoleAdminChangedIterator struct {
	Event *SuperVaultExecutorRoleAdminChanged // Event containing the contract specifics and raw log

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
func (it *SuperVaultExecutorRoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultExecutorRoleAdminChanged)
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
		it.Event = new(SuperVaultExecutorRoleAdminChanged)
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
func (it *SuperVaultExecutorRoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultExecutorRoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultExecutorRoleAdminChanged represents a RoleAdminChanged event raised by the SuperVaultExecutor contract.
type SuperVaultExecutorRoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) FilterRoleAdminChanged(opts *bind.FilterOpts, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (*SuperVaultExecutorRoleAdminChangedIterator, error) {

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

	logs, sub, err := _SuperVaultExecutor.contract.FilterLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorRoleAdminChangedIterator{contract: _SuperVaultExecutor.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *SuperVaultExecutorRoleAdminChanged, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (event.Subscription, error) {

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

	logs, sub, err := _SuperVaultExecutor.contract.WatchLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultExecutorRoleAdminChanged)
				if err := _SuperVaultExecutor.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
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
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) ParseRoleAdminChanged(log types.Log) (*SuperVaultExecutorRoleAdminChanged, error) {
	event := new(SuperVaultExecutorRoleAdminChanged)
	if err := _SuperVaultExecutor.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultExecutorRoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the SuperVaultExecutor contract.
type SuperVaultExecutorRoleGrantedIterator struct {
	Event *SuperVaultExecutorRoleGranted // Event containing the contract specifics and raw log

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
func (it *SuperVaultExecutorRoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultExecutorRoleGranted)
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
		it.Event = new(SuperVaultExecutorRoleGranted)
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
func (it *SuperVaultExecutorRoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultExecutorRoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultExecutorRoleGranted represents a RoleGranted event raised by the SuperVaultExecutor contract.
type SuperVaultExecutorRoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) FilterRoleGranted(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*SuperVaultExecutorRoleGrantedIterator, error) {

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

	logs, sub, err := _SuperVaultExecutor.contract.FilterLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorRoleGrantedIterator{contract: _SuperVaultExecutor.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *SuperVaultExecutorRoleGranted, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _SuperVaultExecutor.contract.WatchLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultExecutorRoleGranted)
				if err := _SuperVaultExecutor.contract.UnpackLog(event, "RoleGranted", log); err != nil {
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
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) ParseRoleGranted(log types.Log) (*SuperVaultExecutorRoleGranted, error) {
	event := new(SuperVaultExecutorRoleGranted)
	if err := _SuperVaultExecutor.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultExecutorRoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the SuperVaultExecutor contract.
type SuperVaultExecutorRoleRevokedIterator struct {
	Event *SuperVaultExecutorRoleRevoked // Event containing the contract specifics and raw log

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
func (it *SuperVaultExecutorRoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultExecutorRoleRevoked)
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
		it.Event = new(SuperVaultExecutorRoleRevoked)
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
func (it *SuperVaultExecutorRoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultExecutorRoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultExecutorRoleRevoked represents a RoleRevoked event raised by the SuperVaultExecutor contract.
type SuperVaultExecutorRoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) FilterRoleRevoked(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*SuperVaultExecutorRoleRevokedIterator, error) {

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

	logs, sub, err := _SuperVaultExecutor.contract.FilterLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorRoleRevokedIterator{contract: _SuperVaultExecutor.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *SuperVaultExecutorRoleRevoked, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _SuperVaultExecutor.contract.WatchLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultExecutorRoleRevoked)
				if err := _SuperVaultExecutor.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
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
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) ParseRoleRevoked(log types.Log) (*SuperVaultExecutorRoleRevoked, error) {
	event := new(SuperVaultExecutorRoleRevoked)
	if err := _SuperVaultExecutor.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultExecutorSessionKeyGrantedIterator is returned from FilterSessionKeyGranted and is used to iterate over the raw logs and unpacked data for SessionKeyGranted events raised by the SuperVaultExecutor contract.
type SuperVaultExecutorSessionKeyGrantedIterator struct {
	Event *SuperVaultExecutorSessionKeyGranted // Event containing the contract specifics and raw log

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
func (it *SuperVaultExecutorSessionKeyGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultExecutorSessionKeyGranted)
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
		it.Event = new(SuperVaultExecutorSessionKeyGranted)
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
func (it *SuperVaultExecutorSessionKeyGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultExecutorSessionKeyGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultExecutorSessionKeyGranted represents a SessionKeyGranted event raised by the SuperVaultExecutor contract.
type SuperVaultExecutorSessionKeyGranted struct {
	Strategy         common.Address
	SessionKey       common.Address
	Expiry           *big.Int
	GrantedByManager common.Address
	Generation       *big.Int
	Permissions      uint8
	Raw              types.Log // Blockchain specific contextual infos
}

// FilterSessionKeyGranted is a free log retrieval operation binding the contract event 0x950e902eb725e5fda180e86bd6700328081ae909659737b6f8e024992afbf74b.
//
// Solidity: event SessionKeyGranted(address indexed strategy, address indexed sessionKey, uint256 expiry, address indexed grantedByManager, uint256 generation, uint8 permissions)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) FilterSessionKeyGranted(opts *bind.FilterOpts, strategy []common.Address, sessionKey []common.Address, grantedByManager []common.Address) (*SuperVaultExecutorSessionKeyGrantedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var sessionKeyRule []interface{}
	for _, sessionKeyItem := range sessionKey {
		sessionKeyRule = append(sessionKeyRule, sessionKeyItem)
	}

	var grantedByManagerRule []interface{}
	for _, grantedByManagerItem := range grantedByManager {
		grantedByManagerRule = append(grantedByManagerRule, grantedByManagerItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.FilterLogs(opts, "SessionKeyGranted", strategyRule, sessionKeyRule, grantedByManagerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorSessionKeyGrantedIterator{contract: _SuperVaultExecutor.contract, event: "SessionKeyGranted", logs: logs, sub: sub}, nil
}

// WatchSessionKeyGranted is a free log subscription operation binding the contract event 0x950e902eb725e5fda180e86bd6700328081ae909659737b6f8e024992afbf74b.
//
// Solidity: event SessionKeyGranted(address indexed strategy, address indexed sessionKey, uint256 expiry, address indexed grantedByManager, uint256 generation, uint8 permissions)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) WatchSessionKeyGranted(opts *bind.WatchOpts, sink chan<- *SuperVaultExecutorSessionKeyGranted, strategy []common.Address, sessionKey []common.Address, grantedByManager []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var sessionKeyRule []interface{}
	for _, sessionKeyItem := range sessionKey {
		sessionKeyRule = append(sessionKeyRule, sessionKeyItem)
	}

	var grantedByManagerRule []interface{}
	for _, grantedByManagerItem := range grantedByManager {
		grantedByManagerRule = append(grantedByManagerRule, grantedByManagerItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.WatchLogs(opts, "SessionKeyGranted", strategyRule, sessionKeyRule, grantedByManagerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultExecutorSessionKeyGranted)
				if err := _SuperVaultExecutor.contract.UnpackLog(event, "SessionKeyGranted", log); err != nil {
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

// ParseSessionKeyGranted is a log parse operation binding the contract event 0x950e902eb725e5fda180e86bd6700328081ae909659737b6f8e024992afbf74b.
//
// Solidity: event SessionKeyGranted(address indexed strategy, address indexed sessionKey, uint256 expiry, address indexed grantedByManager, uint256 generation, uint8 permissions)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) ParseSessionKeyGranted(log types.Log) (*SuperVaultExecutorSessionKeyGranted, error) {
	event := new(SuperVaultExecutorSessionKeyGranted)
	if err := _SuperVaultExecutor.contract.UnpackLog(event, "SessionKeyGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultExecutorSessionKeyRevokedIterator is returned from FilterSessionKeyRevoked and is used to iterate over the raw logs and unpacked data for SessionKeyRevoked events raised by the SuperVaultExecutor contract.
type SuperVaultExecutorSessionKeyRevokedIterator struct {
	Event *SuperVaultExecutorSessionKeyRevoked // Event containing the contract specifics and raw log

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
func (it *SuperVaultExecutorSessionKeyRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultExecutorSessionKeyRevoked)
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
		it.Event = new(SuperVaultExecutorSessionKeyRevoked)
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
func (it *SuperVaultExecutorSessionKeyRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultExecutorSessionKeyRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultExecutorSessionKeyRevoked represents a SessionKeyRevoked event raised by the SuperVaultExecutor contract.
type SuperVaultExecutorSessionKeyRevoked struct {
	Strategy   common.Address
	SessionKey common.Address
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterSessionKeyRevoked is a free log retrieval operation binding the contract event 0x744157ccffbd293a2e8644928cd7d23d650f869b88f72d7bfea8041b76ca6bec.
//
// Solidity: event SessionKeyRevoked(address indexed strategy, address indexed sessionKey)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) FilterSessionKeyRevoked(opts *bind.FilterOpts, strategy []common.Address, sessionKey []common.Address) (*SuperVaultExecutorSessionKeyRevokedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var sessionKeyRule []interface{}
	for _, sessionKeyItem := range sessionKey {
		sessionKeyRule = append(sessionKeyRule, sessionKeyItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.FilterLogs(opts, "SessionKeyRevoked", strategyRule, sessionKeyRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorSessionKeyRevokedIterator{contract: _SuperVaultExecutor.contract, event: "SessionKeyRevoked", logs: logs, sub: sub}, nil
}

// WatchSessionKeyRevoked is a free log subscription operation binding the contract event 0x744157ccffbd293a2e8644928cd7d23d650f869b88f72d7bfea8041b76ca6bec.
//
// Solidity: event SessionKeyRevoked(address indexed strategy, address indexed sessionKey)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) WatchSessionKeyRevoked(opts *bind.WatchOpts, sink chan<- *SuperVaultExecutorSessionKeyRevoked, strategy []common.Address, sessionKey []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var sessionKeyRule []interface{}
	for _, sessionKeyItem := range sessionKey {
		sessionKeyRule = append(sessionKeyRule, sessionKeyItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.WatchLogs(opts, "SessionKeyRevoked", strategyRule, sessionKeyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultExecutorSessionKeyRevoked)
				if err := _SuperVaultExecutor.contract.UnpackLog(event, "SessionKeyRevoked", log); err != nil {
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

// ParseSessionKeyRevoked is a log parse operation binding the contract event 0x744157ccffbd293a2e8644928cd7d23d650f869b88f72d7bfea8041b76ca6bec.
//
// Solidity: event SessionKeyRevoked(address indexed strategy, address indexed sessionKey)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) ParseSessionKeyRevoked(log types.Log) (*SuperVaultExecutorSessionKeyRevoked, error) {
	event := new(SuperVaultExecutorSessionKeyRevoked)
	if err := _SuperVaultExecutor.contract.UnpackLog(event, "SessionKeyRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
