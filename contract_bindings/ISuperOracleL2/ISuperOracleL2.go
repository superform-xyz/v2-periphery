// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package ISuperOracleL2

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

// ISuperOracleL2MetaData contains all meta data concerning the ISuperOracleL2 contract.
var ISuperOracleL2MetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"batchSetUptimeFeed\",\"inputs\":[{\"name\":\"dataOracles\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"uptimeOracles\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"gracePeriods\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"GracePeriodSet\",\"inputs\":[{\"name\":\"uptimeOracle\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"gracePeriod\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UptimeFeedSet\",\"inputs\":[{\"name\":\"dataOracle\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"uptimeOracle\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"GRACE_PERIOD_NOT_OVER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"GRACE_PERIOD_TOO_LOW\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_UPTIME_FEED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SEQUENCER_DOWN\",\"inputs\":[]}]",
}

// ISuperOracleL2ABI is the input ABI used to generate the binding from.
// Deprecated: Use ISuperOracleL2MetaData.ABI instead.
var ISuperOracleL2ABI = ISuperOracleL2MetaData.ABI

// ISuperOracleL2 is an auto generated Go binding around an Ethereum contract.
type ISuperOracleL2 struct {
	ISuperOracleL2Caller     // Read-only binding to the contract
	ISuperOracleL2Transactor // Write-only binding to the contract
	ISuperOracleL2Filterer   // Log filterer for contract events
}

// ISuperOracleL2Caller is an auto generated read-only Go binding around an Ethereum contract.
type ISuperOracleL2Caller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ISuperOracleL2Transactor is an auto generated write-only Go binding around an Ethereum contract.
type ISuperOracleL2Transactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ISuperOracleL2Filterer is an auto generated log filtering Go binding around an Ethereum contract events.
type ISuperOracleL2Filterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ISuperOracleL2Session is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type ISuperOracleL2Session struct {
	Contract     *ISuperOracleL2   // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// ISuperOracleL2CallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type ISuperOracleL2CallerSession struct {
	Contract *ISuperOracleL2Caller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts         // Call options to use throughout this session
}

// ISuperOracleL2TransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type ISuperOracleL2TransactorSession struct {
	Contract     *ISuperOracleL2Transactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts         // Transaction auth options to use throughout this session
}

// ISuperOracleL2Raw is an auto generated low-level Go binding around an Ethereum contract.
type ISuperOracleL2Raw struct {
	Contract *ISuperOracleL2 // Generic contract binding to access the raw methods on
}

// ISuperOracleL2CallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type ISuperOracleL2CallerRaw struct {
	Contract *ISuperOracleL2Caller // Generic read-only contract binding to access the raw methods on
}

// ISuperOracleL2TransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type ISuperOracleL2TransactorRaw struct {
	Contract *ISuperOracleL2Transactor // Generic write-only contract binding to access the raw methods on
}

// NewISuperOracleL2 creates a new instance of ISuperOracleL2, bound to a specific deployed contract.
func NewISuperOracleL2(address common.Address, backend bind.ContractBackend) (*ISuperOracleL2, error) {
	contract, err := bindISuperOracleL2(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &ISuperOracleL2{ISuperOracleL2Caller: ISuperOracleL2Caller{contract: contract}, ISuperOracleL2Transactor: ISuperOracleL2Transactor{contract: contract}, ISuperOracleL2Filterer: ISuperOracleL2Filterer{contract: contract}}, nil
}

// NewISuperOracleL2Caller creates a new read-only instance of ISuperOracleL2, bound to a specific deployed contract.
func NewISuperOracleL2Caller(address common.Address, caller bind.ContractCaller) (*ISuperOracleL2Caller, error) {
	contract, err := bindISuperOracleL2(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &ISuperOracleL2Caller{contract: contract}, nil
}

// NewISuperOracleL2Transactor creates a new write-only instance of ISuperOracleL2, bound to a specific deployed contract.
func NewISuperOracleL2Transactor(address common.Address, transactor bind.ContractTransactor) (*ISuperOracleL2Transactor, error) {
	contract, err := bindISuperOracleL2(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &ISuperOracleL2Transactor{contract: contract}, nil
}

// NewISuperOracleL2Filterer creates a new log filterer instance of ISuperOracleL2, bound to a specific deployed contract.
func NewISuperOracleL2Filterer(address common.Address, filterer bind.ContractFilterer) (*ISuperOracleL2Filterer, error) {
	contract, err := bindISuperOracleL2(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &ISuperOracleL2Filterer{contract: contract}, nil
}

// bindISuperOracleL2 binds a generic wrapper to an already deployed contract.
func bindISuperOracleL2(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := ISuperOracleL2MetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_ISuperOracleL2 *ISuperOracleL2Raw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _ISuperOracleL2.Contract.ISuperOracleL2Caller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_ISuperOracleL2 *ISuperOracleL2Raw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ISuperOracleL2.Contract.ISuperOracleL2Transactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_ISuperOracleL2 *ISuperOracleL2Raw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _ISuperOracleL2.Contract.ISuperOracleL2Transactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_ISuperOracleL2 *ISuperOracleL2CallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _ISuperOracleL2.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_ISuperOracleL2 *ISuperOracleL2TransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ISuperOracleL2.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_ISuperOracleL2 *ISuperOracleL2TransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _ISuperOracleL2.Contract.contract.Transact(opts, method, params...)
}

// BatchSetUptimeFeed is a paid mutator transaction binding the contract method 0xae42457f.
//
// Solidity: function batchSetUptimeFeed(address[] dataOracles, address[] uptimeOracles, uint256[] gracePeriods) returns()
func (_ISuperOracleL2 *ISuperOracleL2Transactor) BatchSetUptimeFeed(opts *bind.TransactOpts, dataOracles []common.Address, uptimeOracles []common.Address, gracePeriods []*big.Int) (*types.Transaction, error) {
	return _ISuperOracleL2.contract.Transact(opts, "batchSetUptimeFeed", dataOracles, uptimeOracles, gracePeriods)
}

// BatchSetUptimeFeed is a paid mutator transaction binding the contract method 0xae42457f.
//
// Solidity: function batchSetUptimeFeed(address[] dataOracles, address[] uptimeOracles, uint256[] gracePeriods) returns()
func (_ISuperOracleL2 *ISuperOracleL2Session) BatchSetUptimeFeed(dataOracles []common.Address, uptimeOracles []common.Address, gracePeriods []*big.Int) (*types.Transaction, error) {
	return _ISuperOracleL2.Contract.BatchSetUptimeFeed(&_ISuperOracleL2.TransactOpts, dataOracles, uptimeOracles, gracePeriods)
}

// BatchSetUptimeFeed is a paid mutator transaction binding the contract method 0xae42457f.
//
// Solidity: function batchSetUptimeFeed(address[] dataOracles, address[] uptimeOracles, uint256[] gracePeriods) returns()
func (_ISuperOracleL2 *ISuperOracleL2TransactorSession) BatchSetUptimeFeed(dataOracles []common.Address, uptimeOracles []common.Address, gracePeriods []*big.Int) (*types.Transaction, error) {
	return _ISuperOracleL2.Contract.BatchSetUptimeFeed(&_ISuperOracleL2.TransactOpts, dataOracles, uptimeOracles, gracePeriods)
}

// ISuperOracleL2GracePeriodSetIterator is returned from FilterGracePeriodSet and is used to iterate over the raw logs and unpacked data for GracePeriodSet events raised by the ISuperOracleL2 contract.
type ISuperOracleL2GracePeriodSetIterator struct {
	Event *ISuperOracleL2GracePeriodSet // Event containing the contract specifics and raw log

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
func (it *ISuperOracleL2GracePeriodSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperOracleL2GracePeriodSet)
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
		it.Event = new(ISuperOracleL2GracePeriodSet)
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
func (it *ISuperOracleL2GracePeriodSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperOracleL2GracePeriodSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperOracleL2GracePeriodSet represents a GracePeriodSet event raised by the ISuperOracleL2 contract.
type ISuperOracleL2GracePeriodSet struct {
	UptimeOracle common.Address
	GracePeriod  *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterGracePeriodSet is a free log retrieval operation binding the contract event 0x5e49a0f74ce60fb80493b458c23b3d1bf1f01c47dac774d48ed470ab3a615e26.
//
// Solidity: event GracePeriodSet(address uptimeOracle, uint256 gracePeriod)
func (_ISuperOracleL2 *ISuperOracleL2Filterer) FilterGracePeriodSet(opts *bind.FilterOpts) (*ISuperOracleL2GracePeriodSetIterator, error) {

	logs, sub, err := _ISuperOracleL2.contract.FilterLogs(opts, "GracePeriodSet")
	if err != nil {
		return nil, err
	}
	return &ISuperOracleL2GracePeriodSetIterator{contract: _ISuperOracleL2.contract, event: "GracePeriodSet", logs: logs, sub: sub}, nil
}

// WatchGracePeriodSet is a free log subscription operation binding the contract event 0x5e49a0f74ce60fb80493b458c23b3d1bf1f01c47dac774d48ed470ab3a615e26.
//
// Solidity: event GracePeriodSet(address uptimeOracle, uint256 gracePeriod)
func (_ISuperOracleL2 *ISuperOracleL2Filterer) WatchGracePeriodSet(opts *bind.WatchOpts, sink chan<- *ISuperOracleL2GracePeriodSet) (event.Subscription, error) {

	logs, sub, err := _ISuperOracleL2.contract.WatchLogs(opts, "GracePeriodSet")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperOracleL2GracePeriodSet)
				if err := _ISuperOracleL2.contract.UnpackLog(event, "GracePeriodSet", log); err != nil {
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

// ParseGracePeriodSet is a log parse operation binding the contract event 0x5e49a0f74ce60fb80493b458c23b3d1bf1f01c47dac774d48ed470ab3a615e26.
//
// Solidity: event GracePeriodSet(address uptimeOracle, uint256 gracePeriod)
func (_ISuperOracleL2 *ISuperOracleL2Filterer) ParseGracePeriodSet(log types.Log) (*ISuperOracleL2GracePeriodSet, error) {
	event := new(ISuperOracleL2GracePeriodSet)
	if err := _ISuperOracleL2.contract.UnpackLog(event, "GracePeriodSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ISuperOracleL2UptimeFeedSetIterator is returned from FilterUptimeFeedSet and is used to iterate over the raw logs and unpacked data for UptimeFeedSet events raised by the ISuperOracleL2 contract.
type ISuperOracleL2UptimeFeedSetIterator struct {
	Event *ISuperOracleL2UptimeFeedSet // Event containing the contract specifics and raw log

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
func (it *ISuperOracleL2UptimeFeedSetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ISuperOracleL2UptimeFeedSet)
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
		it.Event = new(ISuperOracleL2UptimeFeedSet)
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
func (it *ISuperOracleL2UptimeFeedSetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ISuperOracleL2UptimeFeedSetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ISuperOracleL2UptimeFeedSet represents a UptimeFeedSet event raised by the ISuperOracleL2 contract.
type ISuperOracleL2UptimeFeedSet struct {
	DataOracle   common.Address
	UptimeOracle common.Address
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterUptimeFeedSet is a free log retrieval operation binding the contract event 0x0fe0439a9dbea7a284c9a008d922e254a155f584b9ad529825e6dd6d42417551.
//
// Solidity: event UptimeFeedSet(address dataOracle, address uptimeOracle)
func (_ISuperOracleL2 *ISuperOracleL2Filterer) FilterUptimeFeedSet(opts *bind.FilterOpts) (*ISuperOracleL2UptimeFeedSetIterator, error) {

	logs, sub, err := _ISuperOracleL2.contract.FilterLogs(opts, "UptimeFeedSet")
	if err != nil {
		return nil, err
	}
	return &ISuperOracleL2UptimeFeedSetIterator{contract: _ISuperOracleL2.contract, event: "UptimeFeedSet", logs: logs, sub: sub}, nil
}

// WatchUptimeFeedSet is a free log subscription operation binding the contract event 0x0fe0439a9dbea7a284c9a008d922e254a155f584b9ad529825e6dd6d42417551.
//
// Solidity: event UptimeFeedSet(address dataOracle, address uptimeOracle)
func (_ISuperOracleL2 *ISuperOracleL2Filterer) WatchUptimeFeedSet(opts *bind.WatchOpts, sink chan<- *ISuperOracleL2UptimeFeedSet) (event.Subscription, error) {

	logs, sub, err := _ISuperOracleL2.contract.WatchLogs(opts, "UptimeFeedSet")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ISuperOracleL2UptimeFeedSet)
				if err := _ISuperOracleL2.contract.UnpackLog(event, "UptimeFeedSet", log); err != nil {
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

// ParseUptimeFeedSet is a log parse operation binding the contract event 0x0fe0439a9dbea7a284c9a008d922e254a155f584b9ad529825e6dd6d42417551.
//
// Solidity: event UptimeFeedSet(address dataOracle, address uptimeOracle)
func (_ISuperOracleL2 *ISuperOracleL2Filterer) ParseUptimeFeedSet(log types.Log) (*ISuperOracleL2UptimeFeedSet, error) {
	event := new(ISuperOracleL2UptimeFeedSet)
	if err := _ISuperOracleL2.contract.UnpackLog(event, "UptimeFeedSet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
