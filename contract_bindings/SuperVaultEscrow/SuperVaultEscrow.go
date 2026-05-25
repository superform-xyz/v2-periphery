// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package SuperVaultEscrow

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

// SuperVaultEscrowMetaData contains all meta data concerning the SuperVaultEscrow contract.
var SuperVaultEscrowMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"escrowShares\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"initialize\",\"inputs\":[{\"name\":\"vaultAddress\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"initialized\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"returnAssets\",\"inputs\":[{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"returnShares\",\"inputs\":[{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"vault\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"AssetsReturned\",\"inputs\":[{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Initialized\",\"inputs\":[{\"name\":\"vault\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SharesEscrowed\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SharesReturned\",\"inputs\":[{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ALREADY_INITIALIZED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"UNAUTHORIZED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_AMOUNT\",\"inputs\":[]}]",
}

// SuperVaultEscrowABI is the input ABI used to generate the binding from.
// Deprecated: Use SuperVaultEscrowMetaData.ABI instead.
var SuperVaultEscrowABI = SuperVaultEscrowMetaData.ABI

// SuperVaultEscrow is an auto generated Go binding around an Ethereum contract.
type SuperVaultEscrow struct {
	SuperVaultEscrowCaller     // Read-only binding to the contract
	SuperVaultEscrowTransactor // Write-only binding to the contract
	SuperVaultEscrowFilterer   // Log filterer for contract events
}

// SuperVaultEscrowCaller is an auto generated read-only Go binding around an Ethereum contract.
type SuperVaultEscrowCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultEscrowTransactor is an auto generated write-only Go binding around an Ethereum contract.
type SuperVaultEscrowTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultEscrowFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type SuperVaultEscrowFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultEscrowSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type SuperVaultEscrowSession struct {
	Contract     *SuperVaultEscrow // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// SuperVaultEscrowCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type SuperVaultEscrowCallerSession struct {
	Contract *SuperVaultEscrowCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts           // Call options to use throughout this session
}

// SuperVaultEscrowTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type SuperVaultEscrowTransactorSession struct {
	Contract     *SuperVaultEscrowTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts           // Transaction auth options to use throughout this session
}

// SuperVaultEscrowRaw is an auto generated low-level Go binding around an Ethereum contract.
type SuperVaultEscrowRaw struct {
	Contract *SuperVaultEscrow // Generic contract binding to access the raw methods on
}

// SuperVaultEscrowCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type SuperVaultEscrowCallerRaw struct {
	Contract *SuperVaultEscrowCaller // Generic read-only contract binding to access the raw methods on
}

// SuperVaultEscrowTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type SuperVaultEscrowTransactorRaw struct {
	Contract *SuperVaultEscrowTransactor // Generic write-only contract binding to access the raw methods on
}

// NewSuperVaultEscrow creates a new instance of SuperVaultEscrow, bound to a specific deployed contract.
func NewSuperVaultEscrow(address common.Address, backend bind.ContractBackend) (*SuperVaultEscrow, error) {
	contract, err := bindSuperVaultEscrow(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &SuperVaultEscrow{SuperVaultEscrowCaller: SuperVaultEscrowCaller{contract: contract}, SuperVaultEscrowTransactor: SuperVaultEscrowTransactor{contract: contract}, SuperVaultEscrowFilterer: SuperVaultEscrowFilterer{contract: contract}}, nil
}

// NewSuperVaultEscrowCaller creates a new read-only instance of SuperVaultEscrow, bound to a specific deployed contract.
func NewSuperVaultEscrowCaller(address common.Address, caller bind.ContractCaller) (*SuperVaultEscrowCaller, error) {
	contract, err := bindSuperVaultEscrow(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &SuperVaultEscrowCaller{contract: contract}, nil
}

// NewSuperVaultEscrowTransactor creates a new write-only instance of SuperVaultEscrow, bound to a specific deployed contract.
func NewSuperVaultEscrowTransactor(address common.Address, transactor bind.ContractTransactor) (*SuperVaultEscrowTransactor, error) {
	contract, err := bindSuperVaultEscrow(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &SuperVaultEscrowTransactor{contract: contract}, nil
}

// NewSuperVaultEscrowFilterer creates a new log filterer instance of SuperVaultEscrow, bound to a specific deployed contract.
func NewSuperVaultEscrowFilterer(address common.Address, filterer bind.ContractFilterer) (*SuperVaultEscrowFilterer, error) {
	contract, err := bindSuperVaultEscrow(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &SuperVaultEscrowFilterer{contract: contract}, nil
}

// bindSuperVaultEscrow binds a generic wrapper to an already deployed contract.
func bindSuperVaultEscrow(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := SuperVaultEscrowMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperVaultEscrow *SuperVaultEscrowRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperVaultEscrow.Contract.SuperVaultEscrowCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperVaultEscrow *SuperVaultEscrowRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultEscrow.Contract.SuperVaultEscrowTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperVaultEscrow *SuperVaultEscrowRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperVaultEscrow.Contract.SuperVaultEscrowTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperVaultEscrow *SuperVaultEscrowCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperVaultEscrow.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperVaultEscrow *SuperVaultEscrowTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultEscrow.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperVaultEscrow *SuperVaultEscrowTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperVaultEscrow.Contract.contract.Transact(opts, method, params...)
}

// Initialized is a free data retrieval call binding the contract method 0x158ef93e.
//
// Solidity: function initialized() view returns(bool)
func (_SuperVaultEscrow *SuperVaultEscrowCaller) Initialized(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _SuperVaultEscrow.contract.Call(opts, &out, "initialized")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Initialized is a free data retrieval call binding the contract method 0x158ef93e.
//
// Solidity: function initialized() view returns(bool)
func (_SuperVaultEscrow *SuperVaultEscrowSession) Initialized() (bool, error) {
	return _SuperVaultEscrow.Contract.Initialized(&_SuperVaultEscrow.CallOpts)
}

// Initialized is a free data retrieval call binding the contract method 0x158ef93e.
//
// Solidity: function initialized() view returns(bool)
func (_SuperVaultEscrow *SuperVaultEscrowCallerSession) Initialized() (bool, error) {
	return _SuperVaultEscrow.Contract.Initialized(&_SuperVaultEscrow.CallOpts)
}

// Vault is a free data retrieval call binding the contract method 0xfbfa77cf.
//
// Solidity: function vault() view returns(address)
func (_SuperVaultEscrow *SuperVaultEscrowCaller) Vault(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SuperVaultEscrow.contract.Call(opts, &out, "vault")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Vault is a free data retrieval call binding the contract method 0xfbfa77cf.
//
// Solidity: function vault() view returns(address)
func (_SuperVaultEscrow *SuperVaultEscrowSession) Vault() (common.Address, error) {
	return _SuperVaultEscrow.Contract.Vault(&_SuperVaultEscrow.CallOpts)
}

// Vault is a free data retrieval call binding the contract method 0xfbfa77cf.
//
// Solidity: function vault() view returns(address)
func (_SuperVaultEscrow *SuperVaultEscrowCallerSession) Vault() (common.Address, error) {
	return _SuperVaultEscrow.Contract.Vault(&_SuperVaultEscrow.CallOpts)
}

// EscrowShares is a paid mutator transaction binding the contract method 0x3aad4a4f.
//
// Solidity: function escrowShares(address from, uint256 amount) returns()
func (_SuperVaultEscrow *SuperVaultEscrowTransactor) EscrowShares(opts *bind.TransactOpts, from common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultEscrow.contract.Transact(opts, "escrowShares", from, amount)
}

// EscrowShares is a paid mutator transaction binding the contract method 0x3aad4a4f.
//
// Solidity: function escrowShares(address from, uint256 amount) returns()
func (_SuperVaultEscrow *SuperVaultEscrowSession) EscrowShares(from common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultEscrow.Contract.EscrowShares(&_SuperVaultEscrow.TransactOpts, from, amount)
}

// EscrowShares is a paid mutator transaction binding the contract method 0x3aad4a4f.
//
// Solidity: function escrowShares(address from, uint256 amount) returns()
func (_SuperVaultEscrow *SuperVaultEscrowTransactorSession) EscrowShares(from common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultEscrow.Contract.EscrowShares(&_SuperVaultEscrow.TransactOpts, from, amount)
}

// Initialize is a paid mutator transaction binding the contract method 0xc4d66de8.
//
// Solidity: function initialize(address vaultAddress) returns()
func (_SuperVaultEscrow *SuperVaultEscrowTransactor) Initialize(opts *bind.TransactOpts, vaultAddress common.Address) (*types.Transaction, error) {
	return _SuperVaultEscrow.contract.Transact(opts, "initialize", vaultAddress)
}

// Initialize is a paid mutator transaction binding the contract method 0xc4d66de8.
//
// Solidity: function initialize(address vaultAddress) returns()
func (_SuperVaultEscrow *SuperVaultEscrowSession) Initialize(vaultAddress common.Address) (*types.Transaction, error) {
	return _SuperVaultEscrow.Contract.Initialize(&_SuperVaultEscrow.TransactOpts, vaultAddress)
}

// Initialize is a paid mutator transaction binding the contract method 0xc4d66de8.
//
// Solidity: function initialize(address vaultAddress) returns()
func (_SuperVaultEscrow *SuperVaultEscrowTransactorSession) Initialize(vaultAddress common.Address) (*types.Transaction, error) {
	return _SuperVaultEscrow.Contract.Initialize(&_SuperVaultEscrow.TransactOpts, vaultAddress)
}

// ReturnAssets is a paid mutator transaction binding the contract method 0xf7b44de4.
//
// Solidity: function returnAssets(address to, uint256 amount) returns()
func (_SuperVaultEscrow *SuperVaultEscrowTransactor) ReturnAssets(opts *bind.TransactOpts, to common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultEscrow.contract.Transact(opts, "returnAssets", to, amount)
}

// ReturnAssets is a paid mutator transaction binding the contract method 0xf7b44de4.
//
// Solidity: function returnAssets(address to, uint256 amount) returns()
func (_SuperVaultEscrow *SuperVaultEscrowSession) ReturnAssets(to common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultEscrow.Contract.ReturnAssets(&_SuperVaultEscrow.TransactOpts, to, amount)
}

// ReturnAssets is a paid mutator transaction binding the contract method 0xf7b44de4.
//
// Solidity: function returnAssets(address to, uint256 amount) returns()
func (_SuperVaultEscrow *SuperVaultEscrowTransactorSession) ReturnAssets(to common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultEscrow.Contract.ReturnAssets(&_SuperVaultEscrow.TransactOpts, to, amount)
}

// ReturnShares is a paid mutator transaction binding the contract method 0x8b198025.
//
// Solidity: function returnShares(address to, uint256 amount) returns()
func (_SuperVaultEscrow *SuperVaultEscrowTransactor) ReturnShares(opts *bind.TransactOpts, to common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultEscrow.contract.Transact(opts, "returnShares", to, amount)
}

// ReturnShares is a paid mutator transaction binding the contract method 0x8b198025.
//
// Solidity: function returnShares(address to, uint256 amount) returns()
func (_SuperVaultEscrow *SuperVaultEscrowSession) ReturnShares(to common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultEscrow.Contract.ReturnShares(&_SuperVaultEscrow.TransactOpts, to, amount)
}

// ReturnShares is a paid mutator transaction binding the contract method 0x8b198025.
//
// Solidity: function returnShares(address to, uint256 amount) returns()
func (_SuperVaultEscrow *SuperVaultEscrowTransactorSession) ReturnShares(to common.Address, amount *big.Int) (*types.Transaction, error) {
	return _SuperVaultEscrow.Contract.ReturnShares(&_SuperVaultEscrow.TransactOpts, to, amount)
}

// SuperVaultEscrowAssetsReturnedIterator is returned from FilterAssetsReturned and is used to iterate over the raw logs and unpacked data for AssetsReturned events raised by the SuperVaultEscrow contract.
type SuperVaultEscrowAssetsReturnedIterator struct {
	Event *SuperVaultEscrowAssetsReturned // Event containing the contract specifics and raw log

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
func (it *SuperVaultEscrowAssetsReturnedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultEscrowAssetsReturned)
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
		it.Event = new(SuperVaultEscrowAssetsReturned)
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
func (it *SuperVaultEscrowAssetsReturnedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultEscrowAssetsReturnedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultEscrowAssetsReturned represents a AssetsReturned event raised by the SuperVaultEscrow contract.
type SuperVaultEscrowAssetsReturned struct {
	To     common.Address
	Amount *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterAssetsReturned is a free log retrieval operation binding the contract event 0xc28aafe280506b00dae26d8840c762678a635eadcb0651defdd95e67bed19fac.
//
// Solidity: event AssetsReturned(address indexed to, uint256 amount)
func (_SuperVaultEscrow *SuperVaultEscrowFilterer) FilterAssetsReturned(opts *bind.FilterOpts, to []common.Address) (*SuperVaultEscrowAssetsReturnedIterator, error) {

	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _SuperVaultEscrow.contract.FilterLogs(opts, "AssetsReturned", toRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultEscrowAssetsReturnedIterator{contract: _SuperVaultEscrow.contract, event: "AssetsReturned", logs: logs, sub: sub}, nil
}

// WatchAssetsReturned is a free log subscription operation binding the contract event 0xc28aafe280506b00dae26d8840c762678a635eadcb0651defdd95e67bed19fac.
//
// Solidity: event AssetsReturned(address indexed to, uint256 amount)
func (_SuperVaultEscrow *SuperVaultEscrowFilterer) WatchAssetsReturned(opts *bind.WatchOpts, sink chan<- *SuperVaultEscrowAssetsReturned, to []common.Address) (event.Subscription, error) {

	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _SuperVaultEscrow.contract.WatchLogs(opts, "AssetsReturned", toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultEscrowAssetsReturned)
				if err := _SuperVaultEscrow.contract.UnpackLog(event, "AssetsReturned", log); err != nil {
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

// ParseAssetsReturned is a log parse operation binding the contract event 0xc28aafe280506b00dae26d8840c762678a635eadcb0651defdd95e67bed19fac.
//
// Solidity: event AssetsReturned(address indexed to, uint256 amount)
func (_SuperVaultEscrow *SuperVaultEscrowFilterer) ParseAssetsReturned(log types.Log) (*SuperVaultEscrowAssetsReturned, error) {
	event := new(SuperVaultEscrowAssetsReturned)
	if err := _SuperVaultEscrow.contract.UnpackLog(event, "AssetsReturned", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultEscrowInitializedIterator is returned from FilterInitialized and is used to iterate over the raw logs and unpacked data for Initialized events raised by the SuperVaultEscrow contract.
type SuperVaultEscrowInitializedIterator struct {
	Event *SuperVaultEscrowInitialized // Event containing the contract specifics and raw log

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
func (it *SuperVaultEscrowInitializedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultEscrowInitialized)
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
		it.Event = new(SuperVaultEscrowInitialized)
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
func (it *SuperVaultEscrowInitializedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultEscrowInitializedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultEscrowInitialized represents a Initialized event raised by the SuperVaultEscrow contract.
type SuperVaultEscrowInitialized struct {
	Vault common.Address
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterInitialized is a free log retrieval operation binding the contract event 0x908408e307fc569b417f6cbec5d5a06f44a0a505ac0479b47d421a4b2fd6a1e6.
//
// Solidity: event Initialized(address indexed vault)
func (_SuperVaultEscrow *SuperVaultEscrowFilterer) FilterInitialized(opts *bind.FilterOpts, vault []common.Address) (*SuperVaultEscrowInitializedIterator, error) {

	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _SuperVaultEscrow.contract.FilterLogs(opts, "Initialized", vaultRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultEscrowInitializedIterator{contract: _SuperVaultEscrow.contract, event: "Initialized", logs: logs, sub: sub}, nil
}

// WatchInitialized is a free log subscription operation binding the contract event 0x908408e307fc569b417f6cbec5d5a06f44a0a505ac0479b47d421a4b2fd6a1e6.
//
// Solidity: event Initialized(address indexed vault)
func (_SuperVaultEscrow *SuperVaultEscrowFilterer) WatchInitialized(opts *bind.WatchOpts, sink chan<- *SuperVaultEscrowInitialized, vault []common.Address) (event.Subscription, error) {

	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _SuperVaultEscrow.contract.WatchLogs(opts, "Initialized", vaultRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultEscrowInitialized)
				if err := _SuperVaultEscrow.contract.UnpackLog(event, "Initialized", log); err != nil {
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

// ParseInitialized is a log parse operation binding the contract event 0x908408e307fc569b417f6cbec5d5a06f44a0a505ac0479b47d421a4b2fd6a1e6.
//
// Solidity: event Initialized(address indexed vault)
func (_SuperVaultEscrow *SuperVaultEscrowFilterer) ParseInitialized(log types.Log) (*SuperVaultEscrowInitialized, error) {
	event := new(SuperVaultEscrowInitialized)
	if err := _SuperVaultEscrow.contract.UnpackLog(event, "Initialized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultEscrowSharesEscrowedIterator is returned from FilterSharesEscrowed and is used to iterate over the raw logs and unpacked data for SharesEscrowed events raised by the SuperVaultEscrow contract.
type SuperVaultEscrowSharesEscrowedIterator struct {
	Event *SuperVaultEscrowSharesEscrowed // Event containing the contract specifics and raw log

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
func (it *SuperVaultEscrowSharesEscrowedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultEscrowSharesEscrowed)
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
		it.Event = new(SuperVaultEscrowSharesEscrowed)
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
func (it *SuperVaultEscrowSharesEscrowedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultEscrowSharesEscrowedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultEscrowSharesEscrowed represents a SharesEscrowed event raised by the SuperVaultEscrow contract.
type SuperVaultEscrowSharesEscrowed struct {
	From   common.Address
	Amount *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterSharesEscrowed is a free log retrieval operation binding the contract event 0x6470eb179b0f48659283b06594b0498aac8a92fe020214d9478fdcd1d0bc98b9.
//
// Solidity: event SharesEscrowed(address indexed from, uint256 amount)
func (_SuperVaultEscrow *SuperVaultEscrowFilterer) FilterSharesEscrowed(opts *bind.FilterOpts, from []common.Address) (*SuperVaultEscrowSharesEscrowedIterator, error) {

	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}

	logs, sub, err := _SuperVaultEscrow.contract.FilterLogs(opts, "SharesEscrowed", fromRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultEscrowSharesEscrowedIterator{contract: _SuperVaultEscrow.contract, event: "SharesEscrowed", logs: logs, sub: sub}, nil
}

// WatchSharesEscrowed is a free log subscription operation binding the contract event 0x6470eb179b0f48659283b06594b0498aac8a92fe020214d9478fdcd1d0bc98b9.
//
// Solidity: event SharesEscrowed(address indexed from, uint256 amount)
func (_SuperVaultEscrow *SuperVaultEscrowFilterer) WatchSharesEscrowed(opts *bind.WatchOpts, sink chan<- *SuperVaultEscrowSharesEscrowed, from []common.Address) (event.Subscription, error) {

	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}

	logs, sub, err := _SuperVaultEscrow.contract.WatchLogs(opts, "SharesEscrowed", fromRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultEscrowSharesEscrowed)
				if err := _SuperVaultEscrow.contract.UnpackLog(event, "SharesEscrowed", log); err != nil {
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

// ParseSharesEscrowed is a log parse operation binding the contract event 0x6470eb179b0f48659283b06594b0498aac8a92fe020214d9478fdcd1d0bc98b9.
//
// Solidity: event SharesEscrowed(address indexed from, uint256 amount)
func (_SuperVaultEscrow *SuperVaultEscrowFilterer) ParseSharesEscrowed(log types.Log) (*SuperVaultEscrowSharesEscrowed, error) {
	event := new(SuperVaultEscrowSharesEscrowed)
	if err := _SuperVaultEscrow.contract.UnpackLog(event, "SharesEscrowed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultEscrowSharesReturnedIterator is returned from FilterSharesReturned and is used to iterate over the raw logs and unpacked data for SharesReturned events raised by the SuperVaultEscrow contract.
type SuperVaultEscrowSharesReturnedIterator struct {
	Event *SuperVaultEscrowSharesReturned // Event containing the contract specifics and raw log

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
func (it *SuperVaultEscrowSharesReturnedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultEscrowSharesReturned)
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
		it.Event = new(SuperVaultEscrowSharesReturned)
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
func (it *SuperVaultEscrowSharesReturnedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultEscrowSharesReturnedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultEscrowSharesReturned represents a SharesReturned event raised by the SuperVaultEscrow contract.
type SuperVaultEscrowSharesReturned struct {
	To     common.Address
	Amount *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterSharesReturned is a free log retrieval operation binding the contract event 0xc6d0e356b4f415399e0045d173d5d8cb2cc6d88b2dba3e348e80a68c1952c450.
//
// Solidity: event SharesReturned(address indexed to, uint256 amount)
func (_SuperVaultEscrow *SuperVaultEscrowFilterer) FilterSharesReturned(opts *bind.FilterOpts, to []common.Address) (*SuperVaultEscrowSharesReturnedIterator, error) {

	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _SuperVaultEscrow.contract.FilterLogs(opts, "SharesReturned", toRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultEscrowSharesReturnedIterator{contract: _SuperVaultEscrow.contract, event: "SharesReturned", logs: logs, sub: sub}, nil
}

// WatchSharesReturned is a free log subscription operation binding the contract event 0xc6d0e356b4f415399e0045d173d5d8cb2cc6d88b2dba3e348e80a68c1952c450.
//
// Solidity: event SharesReturned(address indexed to, uint256 amount)
func (_SuperVaultEscrow *SuperVaultEscrowFilterer) WatchSharesReturned(opts *bind.WatchOpts, sink chan<- *SuperVaultEscrowSharesReturned, to []common.Address) (event.Subscription, error) {

	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _SuperVaultEscrow.contract.WatchLogs(opts, "SharesReturned", toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultEscrowSharesReturned)
				if err := _SuperVaultEscrow.contract.UnpackLog(event, "SharesReturned", log); err != nil {
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

// ParseSharesReturned is a log parse operation binding the contract event 0xc6d0e356b4f415399e0045d173d5d8cb2cc6d88b2dba3e348e80a68c1952c450.
//
// Solidity: event SharesReturned(address indexed to, uint256 amount)
func (_SuperVaultEscrow *SuperVaultEscrowFilterer) ParseSharesReturned(log types.Log) (*SuperVaultEscrowSharesReturned, error) {
	event := new(SuperVaultEscrowSharesReturned)
	if err := _SuperVaultEscrow.contract.UnpackLog(event, "SharesReturned", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
