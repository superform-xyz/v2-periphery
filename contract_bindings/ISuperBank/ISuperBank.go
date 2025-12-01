// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package ISuperBank

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

// IHookExecutionDataHookExecutionData is an auto generated low-level Go binding around an user-defined struct.
type IHookExecutionDataHookExecutionData struct {
	Hooks                     []common.Address
	Data                      [][]byte
	MerkleProofs              [][][32]byte
	ExpectedAssetsOrSharesOut []*big.Int
}

// ISuperBankMetaData contains all meta data concerning the ISuperBank contract.
var ISuperBankMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"distribute\",\"inputs\":[{\"name\":\"upAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeHooks\",\"inputs\":[{\"name\":\"executionData\",\"type\":\"tuple\",\"internalType\":\"structIHookExecutionData.HookExecutionData\",\"components\":[{\"name\":\"hooks\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"data\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"},{\"name\":\"merkleProofs\",\"type\":\"bytes32[][]\",\"internalType\":\"bytes32[][]\"},{\"name\":\"expectedAssetsOrSharesOut\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"event\",\"name\":\"RevenueDistributed\",\"inputs\":[{\"name\":\"upToken\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"supStrategyVault\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"treasury\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"supAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"treasuryAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"INVALID_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_BANK_MANAGER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_REVENUE_SHARE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_UP_AMOUNT_TO_DISTRIBUTE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"TRANSFER_FAILED\",\"inputs\":[]}]",
}

// ISuperBankABI is the input ABI used to generate the binding from.
// Deprecated: Use ISuperBankMetaData.ABI instead.
var ISuperBankABI = ISuperBankMetaData.ABI

// ISuperBank is an auto generated Go binding around an Ethereum contract.
type ISuperBank struct {
	ISuperBankCaller     // Read-only binding to the contract
	ISuperBankTransactor // Write-only binding to the contract
	ISuperBankFilterer   // Log filterer for contract events
}

// ISuperBankCaller is an auto generated read-only Go binding around an Ethereum contract.
type ISuperBankCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ISuperBankTransactor is an auto generated write-only Go binding around an Ethereum contract.
type ISuperBankTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ISuperBankFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type ISuperBankFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ISuperBankSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type ISuperBankSession struct {
	Contract     *ISuperBank       // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// ISuperBankCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type ISuperBankCallerSession struct {
	Contract *ISuperBankCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts     // Call options to use throughout this session
}

// ISuperBankTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type ISuperBankTransactorSession struct {
	Contract     *ISuperBankTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts     // Transaction auth options to use throughout this session
}

// ISuperBankRaw is an auto generated low-level Go binding around an Ethereum contract.
type ISuperBankRaw struct {
	Contract *ISuperBank // Generic contract binding to access the raw methods on
}

// ISuperBankCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type ISuperBankCallerRaw struct {
	Contract *ISuperBankCaller // Generic read-only contract binding to access the raw methods on
}

// ISuperBankTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type ISuperBankTransactorRaw struct {
	Contract *ISuperBankTransactor // Generic write-only contract binding to access the raw methods on
}

// NewISuperBank creates a new instance of ISuperBank, bound to a specific deployed contract.
func NewISuperBank(address common.Address, backend bind.ContractBackend) (*ISuperBank, error) {
	contract, err := bindISuperBank(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &ISuperBank{ISuperBankCaller: ISuperBankCaller{contract: contract}, ISuperBankTransactor: ISuperBankTransactor{contract: contract}, ISuperBankFilterer: ISuperBankFilterer{contract: contract}}, nil
}

// NewISuperBankCaller creates a new read-only instance of ISuperBank, bound to a specific deployed contract.
func NewISuperBankCaller(address common.Address, caller bind.ContractCaller) (*ISuperBankCaller, error) {
	contract, err := bindISuperBank(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &ISuperBankCaller{contract: contract}, nil
}

// NewISuperBankTransactor creates a new write-only instance of ISuperBank, bound to a specific deployed contract.
func NewISuperBankTransactor(address common.Address, transactor bind.ContractTransactor) (*ISuperBankTransactor, error) {
	contract, err := bindISuperBank(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &ISuperBankTransactor{contract: contract}, nil
}

// NewISuperBankFilterer creates a new log filterer instance of ISuperBank, bound to a specific deployed contract.
func NewISuperBankFilterer(address common.Address, filterer bind.ContractFilterer) (*ISuperBankFilterer, error) {
	contract, err := bindISuperBank(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &ISuperBankFilterer{contract: contract}, nil
}

// bindISuperBank binds a generic wrapper to an already deployed contract.
func bindISuperBank(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := ISuperBankMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_ISuperBank *ISuperBankRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _ISuperBank.Contract.ISuperBankCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_ISuperBank *ISuperBankRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ISuperBank.Contract.ISuperBankTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_ISuperBank *ISuperBankRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _ISuperBank.Contract.ISuperBankTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_ISuperBank *ISuperBankCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _ISuperBank.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_ISuperBank *ISuperBankTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ISuperBank.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_ISuperBank *ISuperBankTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _ISuperBank.Contract.contract.Transact(opts, method, params...)
}

// Distribute is a paid mutator transaction binding the contract method 0x91c05b0b.
//
// Solidity: function distribute(uint256 upAmount) returns()
func (_ISuperBank *ISuperBankTransactor) Distribute(opts *bind.TransactOpts, upAmount *big.Int) (*types.Transaction, error) {
	return _ISuperBank.contract.Transact(opts, "distribute", upAmount)
}

// Distribute is a paid mutator transaction binding the contract method 0x91c05b0b.
//
// Solidity: function distribute(uint256 upAmount) returns()
func (_ISuperBank *ISuperBankSession) Distribute(upAmount *big.Int) (*types.Transaction, error) {
	return _ISuperBank.Contract.Distribute(&_ISuperBank.TransactOpts, upAmount)
}

// Distribute is a paid mutator transaction binding the contract method 0x91c05b0b.
//
// Solidity: function distribute(uint256 upAmount) returns()
func (_ISuperBank *ISuperBankTransactorSession) Distribute(upAmount *big.Int) (*types.Transaction, error) {
	return _ISuperBank.Contract.Distribute(&_ISuperBank.TransactOpts, upAmount)
}

// ExecuteHooks is a paid mutator transaction binding the contract method 0xfa5d53fc.
//
// Solidity: function executeHooks((address[],bytes[],bytes32[][],uint256[]) executionData) payable returns()
func (_ISuperBank *ISuperBankTransactor) ExecuteHooks(opts *bind.TransactOpts, executionData IHookExecutionDataHookExecutionData) (*types.Transaction, error) {
	return _ISuperBank.contract.Transact(opts, "executeHooks", executionData)
}

// ExecuteHooks is a paid mutator transaction binding the contract method 0xfa5d53fc.
//
// Solidity: function executeHooks((address[],bytes[],bytes32[][],uint256[]) executionData) payable returns()
func (_ISuperBank *ISuperBankSession) ExecuteHooks(executionData IHookExecutionDataHookExecutionData) (*types.Transaction, error) {
	return _ISuperBank.Contract.ExecuteHooks(&_ISuperBank.TransactOpts, executionData)
}

// ExecuteHooks is a paid mutator transaction binding the contract method 0xfa5d53fc.
//
// Solidity: function executeHooks((address[],bytes[],bytes32[][],uint256[]) executionData) payable returns()
func (_ISuperBank *ISuperBankTransactorSession) ExecuteHooks(executionData IHookExecutionDataHookExecutionData) (*types.Transaction, error) {
	return _ISuperBank.Contract.ExecuteHooks(&_ISuperBank.TransactOpts, executionData)
}

// ISuperBankRevenueDistributedIterator is returned from FilterRevenueDistributed and is used to iterate over the raw logs and unpacked data for RevenueDistributed events raised by the ISuperBank contract.
type ISuperBankRevenueDistributedIterator struct {
	Event *ISuperBankRevenueDistributed // Event containing the contract specifics and raw log

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
func (it *ISuperBankRevenueDistributedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperBankRevenueDistributed)
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
		it.Event = new(ISuperBankRevenueDistributed)
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
func (it *ISuperBankRevenueDistributedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperBankRevenueDistributedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperBankRevenueDistributed represents a RevenueDistributed event raised by the ISuperBank contract.
type ISuperBankRevenueDistributed struct {
	UpToken          common.Address
	SupStrategyVault common.Address
	Treasury         common.Address
	SupAmount        *big.Int
	TreasuryAmount   *big.Int
	Raw              types.Log // Blockchain specific contextual infos
}

// FilterRevenueDistributed is a free log retrieval operation binding the contract event 0xee5bc9a05820722887a4100a84ffe71dcbee663d7ac3328b7462b575d43763d7.
//
// Solidity: event RevenueDistributed(address indexed upToken, address indexed supStrategyVault, address indexed treasury, uint256 supAmount, uint256 treasuryAmount)
func (_ISuperBank *ISuperBankFilterer) FilterRevenueDistributed(opts *bind.FilterOpts, upToken []common.Address, supStrategyVault []common.Address, treasury []common.Address) (*ISuperBankRevenueDistributedIterator, error) {

	var upTokenRule []interface{}
	for _, upTokenItem := range upToken {
		upTokenRule = append(upTokenRule, upTokenItem)
	}
	var supStrategyVaultRule []interface{}
	for _, supStrategyVaultItem := range supStrategyVault {
		supStrategyVaultRule = append(supStrategyVaultRule, supStrategyVaultItem)
	}
	var treasuryRule []interface{}
	for _, treasuryItem := range treasury {
		treasuryRule = append(treasuryRule, treasuryItem)
	}

	logs, sub, err := _ISuperBank.contract.FilterLogs(opts, "RevenueDistributed", upTokenRule, supStrategyVaultRule, treasuryRule)
	if err != nil {
		return nil, err
	}
	return &ISuperBankRevenueDistributedIterator{contract: _ISuperBank.contract, event: "RevenueDistributed", logs: logs, sub: sub}, nil
}

// WatchRevenueDistributed is a free log subscription operation binding the contract event 0xee5bc9a05820722887a4100a84ffe71dcbee663d7ac3328b7462b575d43763d7.
//
// Solidity: event RevenueDistributed(address indexed upToken, address indexed supStrategyVault, address indexed treasury, uint256 supAmount, uint256 treasuryAmount)
func (_ISuperBank *ISuperBankFilterer) WatchRevenueDistributed(opts *bind.WatchOpts, sink chan<- *ISuperBankRevenueDistributed, upToken []common.Address, supStrategyVault []common.Address, treasury []common.Address) (event.Subscription, error) {

	var upTokenRule []interface{}
	for _, upTokenItem := range upToken {
		upTokenRule = append(upTokenRule, upTokenItem)
	}
	var supStrategyVaultRule []interface{}
	for _, supStrategyVaultItem := range supStrategyVault {
		supStrategyVaultRule = append(supStrategyVaultRule, supStrategyVaultItem)
	}
	var treasuryRule []interface{}
	for _, treasuryItem := range treasury {
		treasuryRule = append(treasuryRule, treasuryItem)
	}

	logs, sub, err := _ISuperBank.contract.WatchLogs(opts, "RevenueDistributed", upTokenRule, supStrategyVaultRule, treasuryRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperBankRevenueDistributed)
				if err := _ISuperBank.contract.UnpackLog(event, "RevenueDistributed", log); err != nil {
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

// ParseRevenueDistributed is a log parse operation binding the contract event 0xee5bc9a05820722887a4100a84ffe71dcbee663d7ac3328b7462b575d43763d7.
//
// Solidity: event RevenueDistributed(address indexed upToken, address indexed supStrategyVault, address indexed treasury, uint256 supAmount, uint256 treasuryAmount)
func (_ISuperBank *ISuperBankFilterer) ParseRevenueDistributed(log types.Log) (*ISuperBankRevenueDistributed, error) {
	event := new(ISuperBankRevenueDistributed)
	if err := _ISuperBank.contract.UnpackLog(event, "RevenueDistributed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
