// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package ECDSAPPSOracle

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

// IECDSAPPSOracleValidationParams is an auto generated low-level Go binding around an user-defined struct.
type IECDSAPPSOracleValidationParams struct {
	Strategy  common.Address
	Proofs    [][]byte
	Pps       *big.Int
	Timestamp *big.Int
}

// ECDSAPPSOracleMetaData contains all meta data concerning the ECDSAPPSOracle contract.
var ECDSAPPSOracleMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"superGovernor_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"name_\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"version_\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"MAX_STRATEGIES\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_GOVERNOR\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISuperGovernor\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"UPDATE_PPS_TYPEHASH\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"domainSeparator\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"eip712Domain\",\"inputs\":[],\"outputs\":[{\"name\":\"fields\",\"type\":\"bytes1\",\"internalType\":\"bytes1\"},{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"version\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"chainId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"verifyingContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"salt\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"extensions\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"noncePerStrategy\",\"inputs\":[{\"name\":\"_strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"_nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"updatePPS\",\"inputs\":[{\"name\":\"args\",\"type\":\"tuple\",\"internalType\":\"structIECDSAPPSOracle.UpdatePPSArgs\",\"components\":[{\"name\":\"strategies\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"proofsArray\",\"type\":\"bytes[][]\",\"internalType\":\"bytes[][]\"},{\"name\":\"ppss\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"timestamps\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"validateProofs\",\"inputs\":[{\"name\":\"params\",\"type\":\"tuple\",\"internalType\":\"structIECDSAPPSOracle.ValidationParams\",\"components\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"proofs\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"},{\"name\":\"pps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"outputs\":[],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validateProofs\",\"inputs\":[{\"name\":\"params\",\"type\":\"tuple\",\"internalType\":\"structIECDSAPPSOracle.ValidationParams\",\"components\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"proofs\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"},{\"name\":\"pps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"requiredQuorum\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"BatchForwardPPSFailed\",\"inputs\":[{\"name\":\"reason\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"BatchForwardPPSFailedLowLevel\",\"inputs\":[{\"name\":\"lowLevelData\",\"type\":\"bytes\",\"indexed\":false,\"internalType\":\"bytes\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EIP712DomainChanged\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"InsufficientGasForForward\",\"inputs\":[{\"name\":\"gasLeft\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"requiredGas\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PPSValidated\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"pps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ProofValidationFailed\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"reason\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ProofValidationFailedLowLevel\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"data\",\"type\":\"bytes\",\"indexed\":false,\"internalType\":\"bytes\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ARRAY_LENGTH_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ECDSAInvalidSignature\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ECDSAInvalidSignatureLength\",\"inputs\":[{\"name\":\"length\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ECDSAInvalidSignatureS\",\"inputs\":[{\"name\":\"s\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"HIGH_PPS_DEVIATION\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_GAS_FOR_EXTERNAL_CALL\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_VALIDATOR_PARTICIPATION\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_PROOF\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_TIMESTAMP\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_TOTAL_VALIDATORS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_VALIDATOR\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_VALIDATOR_SET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidShortString\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MAX_STRATEGIES_EXCEEDED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PPS_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"QUORUM_NOT_MET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"STRATEGY_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"StringTooLong\",\"inputs\":[{\"name\":\"str\",\"type\":\"string\",\"internalType\":\"string\"}]},{\"type\":\"error\",\"name\":\"VALIDATOR_COUNT_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_LENGTH_ARRAY\",\"inputs\":[]}]",
}

// ECDSAPPSOracleABI is the input ABI used to generate the binding from.
// Deprecated: Use ECDSAPPSOracleMetaData.ABI instead.
var ECDSAPPSOracleABI = ECDSAPPSOracleMetaData.ABI

// ECDSAPPSOracle is an auto generated Go binding around an Ethereum contract.
type ECDSAPPSOracle struct {
	ECDSAPPSOracleCaller     // Read-only binding to the contract
	ECDSAPPSOracleTransactor // Write-only binding to the contract
	ECDSAPPSOracleFilterer   // Log filterer for contract events
}

// ECDSAPPSOracleCaller is an auto generated read-only Go binding around an Ethereum contract.
type ECDSAPPSOracleCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ECDSAPPSOracleTransactor is an auto generated write-only Go binding around an Ethereum contract.
type ECDSAPPSOracleTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ECDSAPPSOracleFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type ECDSAPPSOracleFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ECDSAPPSOracleSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type ECDSAPPSOracleSession struct {
	Contract     *ECDSAPPSOracle   // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// ECDSAPPSOracleCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type ECDSAPPSOracleCallerSession struct {
	Contract *ECDSAPPSOracleCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts         // Call options to use throughout this session
}

// ECDSAPPSOracleTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type ECDSAPPSOracleTransactorSession struct {
	Contract     *ECDSAPPSOracleTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts         // Transaction auth options to use throughout this session
}

// ECDSAPPSOracleRaw is an auto generated low-level Go binding around an Ethereum contract.
type ECDSAPPSOracleRaw struct {
	Contract *ECDSAPPSOracle // Generic contract binding to access the raw methods on
}

// ECDSAPPSOracleCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type ECDSAPPSOracleCallerRaw struct {
	Contract *ECDSAPPSOracleCaller // Generic read-only contract binding to access the raw methods on
}

// ECDSAPPSOracleTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type ECDSAPPSOracleTransactorRaw struct {
	Contract *ECDSAPPSOracleTransactor // Generic write-only contract binding to access the raw methods on
}

// NewECDSAPPSOracle creates a new instance of ECDSAPPSOracle, bound to a specific deployed contract.
func NewECDSAPPSOracle(address common.Address, backend bind.ContractBackend) (*ECDSAPPSOracle, error) {
	contract, err := bindECDSAPPSOracle(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &ECDSAPPSOracle{ECDSAPPSOracleCaller: ECDSAPPSOracleCaller{contract: contract}, ECDSAPPSOracleTransactor: ECDSAPPSOracleTransactor{contract: contract}, ECDSAPPSOracleFilterer: ECDSAPPSOracleFilterer{contract: contract}}, nil
}

// NewECDSAPPSOracleCaller creates a new read-only instance of ECDSAPPSOracle, bound to a specific deployed contract.
func NewECDSAPPSOracleCaller(address common.Address, caller bind.ContractCaller) (*ECDSAPPSOracleCaller, error) {
	contract, err := bindECDSAPPSOracle(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &ECDSAPPSOracleCaller{contract: contract}, nil
}

// NewECDSAPPSOracleTransactor creates a new write-only instance of ECDSAPPSOracle, bound to a specific deployed contract.
func NewECDSAPPSOracleTransactor(address common.Address, transactor bind.ContractTransactor) (*ECDSAPPSOracleTransactor, error) {
	contract, err := bindECDSAPPSOracle(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &ECDSAPPSOracleTransactor{contract: contract}, nil
}

// NewECDSAPPSOracleFilterer creates a new log filterer instance of ECDSAPPSOracle, bound to a specific deployed contract.
func NewECDSAPPSOracleFilterer(address common.Address, filterer bind.ContractFilterer) (*ECDSAPPSOracleFilterer, error) {
	contract, err := bindECDSAPPSOracle(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &ECDSAPPSOracleFilterer{contract: contract}, nil
}

// bindECDSAPPSOracle binds a generic wrapper to an already deployed contract.
func bindECDSAPPSOracle(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := ECDSAPPSOracleMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_ECDSAPPSOracle *ECDSAPPSOracleRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _ECDSAPPSOracle.Contract.ECDSAPPSOracleCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_ECDSAPPSOracle *ECDSAPPSOracleRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ECDSAPPSOracle.Contract.ECDSAPPSOracleTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_ECDSAPPSOracle *ECDSAPPSOracleRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _ECDSAPPSOracle.Contract.ECDSAPPSOracleTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_ECDSAPPSOracle *ECDSAPPSOracleCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _ECDSAPPSOracle.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_ECDSAPPSOracle *ECDSAPPSOracleTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ECDSAPPSOracle.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_ECDSAPPSOracle *ECDSAPPSOracleTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _ECDSAPPSOracle.Contract.contract.Transact(opts, method, params...)
}

// MAXSTRATEGIES is a free data retrieval call binding the contract method 0x767f06ae.
//
// Solidity: function MAX_STRATEGIES() view returns(uint256)
func (_ECDSAPPSOracle *ECDSAPPSOracleCaller) MAXSTRATEGIES(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ECDSAPPSOracle.contract.Call(opts, &out, "MAX_STRATEGIES")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MAXSTRATEGIES is a free data retrieval call binding the contract method 0x767f06ae.
//
// Solidity: function MAX_STRATEGIES() view returns(uint256)
func (_ECDSAPPSOracle *ECDSAPPSOracleSession) MAXSTRATEGIES() (*big.Int, error) {
	return _ECDSAPPSOracle.Contract.MAXSTRATEGIES(&_ECDSAPPSOracle.CallOpts)
}

// MAXSTRATEGIES is a free data retrieval call binding the contract method 0x767f06ae.
//
// Solidity: function MAX_STRATEGIES() view returns(uint256)
func (_ECDSAPPSOracle *ECDSAPPSOracleCallerSession) MAXSTRATEGIES() (*big.Int, error) {
	return _ECDSAPPSOracle.Contract.MAXSTRATEGIES(&_ECDSAPPSOracle.CallOpts)
}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_ECDSAPPSOracle *ECDSAPPSOracleCaller) SUPERGOVERNOR(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _ECDSAPPSOracle.contract.Call(opts, &out, "SUPER_GOVERNOR")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_ECDSAPPSOracle *ECDSAPPSOracleSession) SUPERGOVERNOR() (common.Address, error) {
	return _ECDSAPPSOracle.Contract.SUPERGOVERNOR(&_ECDSAPPSOracle.CallOpts)
}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_ECDSAPPSOracle *ECDSAPPSOracleCallerSession) SUPERGOVERNOR() (common.Address, error) {
	return _ECDSAPPSOracle.Contract.SUPERGOVERNOR(&_ECDSAPPSOracle.CallOpts)
}

// UPDATEPPSTYPEHASH is a free data retrieval call binding the contract method 0xe2c42656.
//
// Solidity: function UPDATE_PPS_TYPEHASH() view returns(bytes32)
func (_ECDSAPPSOracle *ECDSAPPSOracleCaller) UPDATEPPSTYPEHASH(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _ECDSAPPSOracle.contract.Call(opts, &out, "UPDATE_PPS_TYPEHASH")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// UPDATEPPSTYPEHASH is a free data retrieval call binding the contract method 0xe2c42656.
//
// Solidity: function UPDATE_PPS_TYPEHASH() view returns(bytes32)
func (_ECDSAPPSOracle *ECDSAPPSOracleSession) UPDATEPPSTYPEHASH() ([32]byte, error) {
	return _ECDSAPPSOracle.Contract.UPDATEPPSTYPEHASH(&_ECDSAPPSOracle.CallOpts)
}

// UPDATEPPSTYPEHASH is a free data retrieval call binding the contract method 0xe2c42656.
//
// Solidity: function UPDATE_PPS_TYPEHASH() view returns(bytes32)
func (_ECDSAPPSOracle *ECDSAPPSOracleCallerSession) UPDATEPPSTYPEHASH() ([32]byte, error) {
	return _ECDSAPPSOracle.Contract.UPDATEPPSTYPEHASH(&_ECDSAPPSOracle.CallOpts)
}

// DomainSeparator is a free data retrieval call binding the contract method 0xf698da25.
//
// Solidity: function domainSeparator() view returns(bytes32)
func (_ECDSAPPSOracle *ECDSAPPSOracleCaller) DomainSeparator(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _ECDSAPPSOracle.contract.Call(opts, &out, "domainSeparator")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DomainSeparator is a free data retrieval call binding the contract method 0xf698da25.
//
// Solidity: function domainSeparator() view returns(bytes32)
func (_ECDSAPPSOracle *ECDSAPPSOracleSession) DomainSeparator() ([32]byte, error) {
	return _ECDSAPPSOracle.Contract.DomainSeparator(&_ECDSAPPSOracle.CallOpts)
}

// DomainSeparator is a free data retrieval call binding the contract method 0xf698da25.
//
// Solidity: function domainSeparator() view returns(bytes32)
func (_ECDSAPPSOracle *ECDSAPPSOracleCallerSession) DomainSeparator() ([32]byte, error) {
	return _ECDSAPPSOracle.Contract.DomainSeparator(&_ECDSAPPSOracle.CallOpts)
}

// Eip712Domain is a free data retrieval call binding the contract method 0x84b0196e.
//
// Solidity: function eip712Domain() view returns(bytes1 fields, string name, string version, uint256 chainId, address verifyingContract, bytes32 salt, uint256[] extensions)
func (_ECDSAPPSOracle *ECDSAPPSOracleCaller) Eip712Domain(opts *bind.CallOpts) (struct {
	Fields            [1]byte
	Name              string
	Version           string
	ChainId           *big.Int
	VerifyingContract common.Address
	Salt              [32]byte
	Extensions        []*big.Int
}, error) {
	var out []interface{}
	err := _ECDSAPPSOracle.contract.Call(opts, &out, "eip712Domain")

	outstruct := new(struct {
		Fields            [1]byte
		Name              string
		Version           string
		ChainId           *big.Int
		VerifyingContract common.Address
		Salt              [32]byte
		Extensions        []*big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Fields = *abi.ConvertType(out[0], new([1]byte)).(*[1]byte)
	outstruct.Name = *abi.ConvertType(out[1], new(string)).(*string)
	outstruct.Version = *abi.ConvertType(out[2], new(string)).(*string)
	outstruct.ChainId = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)
	outstruct.VerifyingContract = *abi.ConvertType(out[4], new(common.Address)).(*common.Address)
	outstruct.Salt = *abi.ConvertType(out[5], new([32]byte)).(*[32]byte)
	outstruct.Extensions = *abi.ConvertType(out[6], new([]*big.Int)).(*[]*big.Int)

	return *outstruct, err

}

// Eip712Domain is a free data retrieval call binding the contract method 0x84b0196e.
//
// Solidity: function eip712Domain() view returns(bytes1 fields, string name, string version, uint256 chainId, address verifyingContract, bytes32 salt, uint256[] extensions)
func (_ECDSAPPSOracle *ECDSAPPSOracleSession) Eip712Domain() (struct {
	Fields            [1]byte
	Name              string
	Version           string
	ChainId           *big.Int
	VerifyingContract common.Address
	Salt              [32]byte
	Extensions        []*big.Int
}, error) {
	return _ECDSAPPSOracle.Contract.Eip712Domain(&_ECDSAPPSOracle.CallOpts)
}

// Eip712Domain is a free data retrieval call binding the contract method 0x84b0196e.
//
// Solidity: function eip712Domain() view returns(bytes1 fields, string name, string version, uint256 chainId, address verifyingContract, bytes32 salt, uint256[] extensions)
func (_ECDSAPPSOracle *ECDSAPPSOracleCallerSession) Eip712Domain() (struct {
	Fields            [1]byte
	Name              string
	Version           string
	ChainId           *big.Int
	VerifyingContract common.Address
	Salt              [32]byte
	Extensions        []*big.Int
}, error) {
	return _ECDSAPPSOracle.Contract.Eip712Domain(&_ECDSAPPSOracle.CallOpts)
}

// NoncePerStrategy is a free data retrieval call binding the contract method 0xe1e86edc.
//
// Solidity: function noncePerStrategy(address _strategy) view returns(uint256 _nonce)
func (_ECDSAPPSOracle *ECDSAPPSOracleCaller) NoncePerStrategy(opts *bind.CallOpts, _strategy common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ECDSAPPSOracle.contract.Call(opts, &out, "noncePerStrategy", _strategy)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// NoncePerStrategy is a free data retrieval call binding the contract method 0xe1e86edc.
//
// Solidity: function noncePerStrategy(address _strategy) view returns(uint256 _nonce)
func (_ECDSAPPSOracle *ECDSAPPSOracleSession) NoncePerStrategy(_strategy common.Address) (*big.Int, error) {
	return _ECDSAPPSOracle.Contract.NoncePerStrategy(&_ECDSAPPSOracle.CallOpts, _strategy)
}

// NoncePerStrategy is a free data retrieval call binding the contract method 0xe1e86edc.
//
// Solidity: function noncePerStrategy(address _strategy) view returns(uint256 _nonce)
func (_ECDSAPPSOracle *ECDSAPPSOracleCallerSession) NoncePerStrategy(_strategy common.Address) (*big.Int, error) {
	return _ECDSAPPSOracle.Contract.NoncePerStrategy(&_ECDSAPPSOracle.CallOpts, _strategy)
}

// ValidateProofs is a free data retrieval call binding the contract method 0x5857209c.
//
// Solidity: function validateProofs((address,bytes[],uint256,uint256) params) view returns()
func (_ECDSAPPSOracle *ECDSAPPSOracleCaller) ValidateProofs(opts *bind.CallOpts, params IECDSAPPSOracleValidationParams) error {
	var out []interface{}
	err := _ECDSAPPSOracle.contract.Call(opts, &out, "validateProofs", params)

	if err != nil {
		return err
	}

	return err

}

// ValidateProofs is a free data retrieval call binding the contract method 0x5857209c.
//
// Solidity: function validateProofs((address,bytes[],uint256,uint256) params) view returns()
func (_ECDSAPPSOracle *ECDSAPPSOracleSession) ValidateProofs(params IECDSAPPSOracleValidationParams) error {
	return _ECDSAPPSOracle.Contract.ValidateProofs(&_ECDSAPPSOracle.CallOpts, params)
}

// ValidateProofs is a free data retrieval call binding the contract method 0x5857209c.
//
// Solidity: function validateProofs((address,bytes[],uint256,uint256) params) view returns()
func (_ECDSAPPSOracle *ECDSAPPSOracleCallerSession) ValidateProofs(params IECDSAPPSOracleValidationParams) error {
	return _ECDSAPPSOracle.Contract.ValidateProofs(&_ECDSAPPSOracle.CallOpts, params)
}

// ValidateProofs0 is a free data retrieval call binding the contract method 0xf6af120a.
//
// Solidity: function validateProofs((address,bytes[],uint256,uint256) params, uint256 requiredQuorum) view returns()
func (_ECDSAPPSOracle *ECDSAPPSOracleCaller) ValidateProofs0(opts *bind.CallOpts, params IECDSAPPSOracleValidationParams, requiredQuorum *big.Int) error {
	var out []interface{}
	err := _ECDSAPPSOracle.contract.Call(opts, &out, "validateProofs0", params, requiredQuorum)

	if err != nil {
		return err
	}

	return err

}

// ValidateProofs0 is a free data retrieval call binding the contract method 0xf6af120a.
//
// Solidity: function validateProofs((address,bytes[],uint256,uint256) params, uint256 requiredQuorum) view returns()
func (_ECDSAPPSOracle *ECDSAPPSOracleSession) ValidateProofs0(params IECDSAPPSOracleValidationParams, requiredQuorum *big.Int) error {
	return _ECDSAPPSOracle.Contract.ValidateProofs0(&_ECDSAPPSOracle.CallOpts, params, requiredQuorum)
}

// ValidateProofs0 is a free data retrieval call binding the contract method 0xf6af120a.
//
// Solidity: function validateProofs((address,bytes[],uint256,uint256) params, uint256 requiredQuorum) view returns()
func (_ECDSAPPSOracle *ECDSAPPSOracleCallerSession) ValidateProofs0(params IECDSAPPSOracleValidationParams, requiredQuorum *big.Int) error {
	return _ECDSAPPSOracle.Contract.ValidateProofs0(&_ECDSAPPSOracle.CallOpts, params, requiredQuorum)
}

// UpdatePPS is a paid mutator transaction binding the contract method 0x029365f8.
//
// Solidity: function updatePPS((address[],bytes[][],uint256[],uint256[]) args) returns()
func (_ECDSAPPSOracle *ECDSAPPSOracleTransactor) UpdatePPS(opts *bind.TransactOpts, args IECDSAPPSOracleUpdatePPSArgs) (*types.Transaction, error) {
	return _ECDSAPPSOracle.contract.Transact(opts, "updatePPS", args)
}

// UpdatePPS is a paid mutator transaction binding the contract method 0x029365f8.
//
// Solidity: function updatePPS((address[],bytes[][],uint256[],uint256[]) args) returns()
func (_ECDSAPPSOracle *ECDSAPPSOracleSession) UpdatePPS(args IECDSAPPSOracleUpdatePPSArgs) (*types.Transaction, error) {
	return _ECDSAPPSOracle.Contract.UpdatePPS(&_ECDSAPPSOracle.TransactOpts, args)
}

// UpdatePPS is a paid mutator transaction binding the contract method 0x029365f8.
//
// Solidity: function updatePPS((address[],bytes[][],uint256[],uint256[]) args) returns()
func (_ECDSAPPSOracle *ECDSAPPSOracleTransactorSession) UpdatePPS(args IECDSAPPSOracleUpdatePPSArgs) (*types.Transaction, error) {
	return _ECDSAPPSOracle.Contract.UpdatePPS(&_ECDSAPPSOracle.TransactOpts, args)
}

// ECDSAPPSOracleBatchForwardPPSFailedIterator is returned from FilterBatchForwardPPSFailed and is used to iterate over the raw logs and unpacked data for BatchForwardPPSFailed events raised by the ECDSAPPSOracle contract.
type ECDSAPPSOracleBatchForwardPPSFailedIterator struct {
	Event *ECDSAPPSOracleBatchForwardPPSFailed // Event containing the contract specifics and raw log

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
func (it *ECDSAPPSOracleBatchForwardPPSFailedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ECDSAPPSOracleBatchForwardPPSFailed)
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
		it.Event = new(ECDSAPPSOracleBatchForwardPPSFailed)
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
func (it *ECDSAPPSOracleBatchForwardPPSFailedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ECDSAPPSOracleBatchForwardPPSFailedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ECDSAPPSOracleBatchForwardPPSFailed represents a BatchForwardPPSFailed event raised by the ECDSAPPSOracle contract.
type ECDSAPPSOracleBatchForwardPPSFailed struct {
	Reason string
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterBatchForwardPPSFailed is a free log retrieval operation binding the contract event 0x76327474cf24da9a3ca187cce345d66144c7edc1bea0b4595fb2e0a15bbf3bf9.
//
// Solidity: event BatchForwardPPSFailed(string reason)
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) FilterBatchForwardPPSFailed(opts *bind.FilterOpts) (*ECDSAPPSOracleBatchForwardPPSFailedIterator, error) {

	logs, sub, err := _ECDSAPPSOracle.contract.FilterLogs(opts, "BatchForwardPPSFailed")
	if err != nil {
		return nil, err
	}
	return &ECDSAPPSOracleBatchForwardPPSFailedIterator{contract: _ECDSAPPSOracle.contract, event: "BatchForwardPPSFailed", logs: logs, sub: sub}, nil
}

// WatchBatchForwardPPSFailed is a free log subscription operation binding the contract event 0x76327474cf24da9a3ca187cce345d66144c7edc1bea0b4595fb2e0a15bbf3bf9.
//
// Solidity: event BatchForwardPPSFailed(string reason)
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) WatchBatchForwardPPSFailed(opts *bind.WatchOpts, sink chan<- *ECDSAPPSOracleBatchForwardPPSFailed) (event.Subscription, error) {

	logs, sub, err := _ECDSAPPSOracle.contract.WatchLogs(opts, "BatchForwardPPSFailed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ECDSAPPSOracleBatchForwardPPSFailed)
				if err := _ECDSAPPSOracle.contract.UnpackLog(event, "BatchForwardPPSFailed", log); err != nil {
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

// ParseBatchForwardPPSFailed is a log parse operation binding the contract event 0x76327474cf24da9a3ca187cce345d66144c7edc1bea0b4595fb2e0a15bbf3bf9.
//
// Solidity: event BatchForwardPPSFailed(string reason)
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) ParseBatchForwardPPSFailed(log types.Log) (*ECDSAPPSOracleBatchForwardPPSFailed, error) {
	event := new(ECDSAPPSOracleBatchForwardPPSFailed)
	if err := _ECDSAPPSOracle.contract.UnpackLog(event, "BatchForwardPPSFailed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ECDSAPPSOracleBatchForwardPPSFailedLowLevelIterator is returned from FilterBatchForwardPPSFailedLowLevel and is used to iterate over the raw logs and unpacked data for BatchForwardPPSFailedLowLevel events raised by the ECDSAPPSOracle contract.
type ECDSAPPSOracleBatchForwardPPSFailedLowLevelIterator struct {
	Event *ECDSAPPSOracleBatchForwardPPSFailedLowLevel // Event containing the contract specifics and raw log

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
func (it *ECDSAPPSOracleBatchForwardPPSFailedLowLevelIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ECDSAPPSOracleBatchForwardPPSFailedLowLevel)
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
		it.Event = new(ECDSAPPSOracleBatchForwardPPSFailedLowLevel)
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
func (it *ECDSAPPSOracleBatchForwardPPSFailedLowLevelIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ECDSAPPSOracleBatchForwardPPSFailedLowLevelIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ECDSAPPSOracleBatchForwardPPSFailedLowLevel represents a BatchForwardPPSFailedLowLevel event raised by the ECDSAPPSOracle contract.
type ECDSAPPSOracleBatchForwardPPSFailedLowLevel struct {
	LowLevelData []byte
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterBatchForwardPPSFailedLowLevel is a free log retrieval operation binding the contract event 0xa52bfbf922afe2d72308fa5c2c094b23921d8c0d8511e1b6f7767aa3c32255d8.
//
// Solidity: event BatchForwardPPSFailedLowLevel(bytes lowLevelData)
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) FilterBatchForwardPPSFailedLowLevel(opts *bind.FilterOpts) (*ECDSAPPSOracleBatchForwardPPSFailedLowLevelIterator, error) {

	logs, sub, err := _ECDSAPPSOracle.contract.FilterLogs(opts, "BatchForwardPPSFailedLowLevel")
	if err != nil {
		return nil, err
	}
	return &ECDSAPPSOracleBatchForwardPPSFailedLowLevelIterator{contract: _ECDSAPPSOracle.contract, event: "BatchForwardPPSFailedLowLevel", logs: logs, sub: sub}, nil
}

// WatchBatchForwardPPSFailedLowLevel is a free log subscription operation binding the contract event 0xa52bfbf922afe2d72308fa5c2c094b23921d8c0d8511e1b6f7767aa3c32255d8.
//
// Solidity: event BatchForwardPPSFailedLowLevel(bytes lowLevelData)
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) WatchBatchForwardPPSFailedLowLevel(opts *bind.WatchOpts, sink chan<- *ECDSAPPSOracleBatchForwardPPSFailedLowLevel) (event.Subscription, error) {

	logs, sub, err := _ECDSAPPSOracle.contract.WatchLogs(opts, "BatchForwardPPSFailedLowLevel")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ECDSAPPSOracleBatchForwardPPSFailedLowLevel)
				if err := _ECDSAPPSOracle.contract.UnpackLog(event, "BatchForwardPPSFailedLowLevel", log); err != nil {
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

// ParseBatchForwardPPSFailedLowLevel is a log parse operation binding the contract event 0xa52bfbf922afe2d72308fa5c2c094b23921d8c0d8511e1b6f7767aa3c32255d8.
//
// Solidity: event BatchForwardPPSFailedLowLevel(bytes lowLevelData)
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) ParseBatchForwardPPSFailedLowLevel(log types.Log) (*ECDSAPPSOracleBatchForwardPPSFailedLowLevel, error) {
	event := new(ECDSAPPSOracleBatchForwardPPSFailedLowLevel)
	if err := _ECDSAPPSOracle.contract.UnpackLog(event, "BatchForwardPPSFailedLowLevel", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ECDSAPPSOracleEIP712DomainChangedIterator is returned from FilterEIP712DomainChanged and is used to iterate over the raw logs and unpacked data for EIP712DomainChanged events raised by the ECDSAPPSOracle contract.
type ECDSAPPSOracleEIP712DomainChangedIterator struct {
	Event *ECDSAPPSOracleEIP712DomainChanged // Event containing the contract specifics and raw log

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
func (it *ECDSAPPSOracleEIP712DomainChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ECDSAPPSOracleEIP712DomainChanged)
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
		it.Event = new(ECDSAPPSOracleEIP712DomainChanged)
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
func (it *ECDSAPPSOracleEIP712DomainChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ECDSAPPSOracleEIP712DomainChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ECDSAPPSOracleEIP712DomainChanged represents a EIP712DomainChanged event raised by the ECDSAPPSOracle contract.
type ECDSAPPSOracleEIP712DomainChanged struct {
	Raw types.Log // Blockchain specific contextual infos
}

// FilterEIP712DomainChanged is a free log retrieval operation binding the contract event 0x0a6387c9ea3628b88a633bb4f3b151770f70085117a15f9bf3787cda53f13d31.
//
// Solidity: event EIP712DomainChanged()
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) FilterEIP712DomainChanged(opts *bind.FilterOpts) (*ECDSAPPSOracleEIP712DomainChangedIterator, error) {

	logs, sub, err := _ECDSAPPSOracle.contract.FilterLogs(opts, "EIP712DomainChanged")
	if err != nil {
		return nil, err
	}
	return &ECDSAPPSOracleEIP712DomainChangedIterator{contract: _ECDSAPPSOracle.contract, event: "EIP712DomainChanged", logs: logs, sub: sub}, nil
}

// WatchEIP712DomainChanged is a free log subscription operation binding the contract event 0x0a6387c9ea3628b88a633bb4f3b151770f70085117a15f9bf3787cda53f13d31.
//
// Solidity: event EIP712DomainChanged()
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) WatchEIP712DomainChanged(opts *bind.WatchOpts, sink chan<- *ECDSAPPSOracleEIP712DomainChanged) (event.Subscription, error) {

	logs, sub, err := _ECDSAPPSOracle.contract.WatchLogs(opts, "EIP712DomainChanged")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ECDSAPPSOracleEIP712DomainChanged)
				if err := _ECDSAPPSOracle.contract.UnpackLog(event, "EIP712DomainChanged", log); err != nil {
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
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) ParseEIP712DomainChanged(log types.Log) (*ECDSAPPSOracleEIP712DomainChanged, error) {
	event := new(ECDSAPPSOracleEIP712DomainChanged)
	if err := _ECDSAPPSOracle.contract.UnpackLog(event, "EIP712DomainChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ECDSAPPSOracleInsufficientGasForForwardIterator is returned from FilterInsufficientGasForForward and is used to iterate over the raw logs and unpacked data for InsufficientGasForForward events raised by the ECDSAPPSOracle contract.
type ECDSAPPSOracleInsufficientGasForForwardIterator struct {
	Event *ECDSAPPSOracleInsufficientGasForForward // Event containing the contract specifics and raw log

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
func (it *ECDSAPPSOracleInsufficientGasForForwardIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ECDSAPPSOracleInsufficientGasForForward)
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
		it.Event = new(ECDSAPPSOracleInsufficientGasForForward)
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
func (it *ECDSAPPSOracleInsufficientGasForForwardIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ECDSAPPSOracleInsufficientGasForForwardIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ECDSAPPSOracleInsufficientGasForForward represents a InsufficientGasForForward event raised by the ECDSAPPSOracle contract.
type ECDSAPPSOracleInsufficientGasForForward struct {
	GasLeft     *big.Int
	RequiredGas *big.Int
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterInsufficientGasForForward is a free log retrieval operation binding the contract event 0x92a29f6ec9a5c0291fa4acf5fdccec764f8931ce4cc00a2e1fb04a1e36062a11.
//
// Solidity: event InsufficientGasForForward(uint256 gasLeft, uint256 requiredGas)
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) FilterInsufficientGasForForward(opts *bind.FilterOpts) (*ECDSAPPSOracleInsufficientGasForForwardIterator, error) {

	logs, sub, err := _ECDSAPPSOracle.contract.FilterLogs(opts, "InsufficientGasForForward")
	if err != nil {
		return nil, err
	}
	return &ECDSAPPSOracleInsufficientGasForForwardIterator{contract: _ECDSAPPSOracle.contract, event: "InsufficientGasForForward", logs: logs, sub: sub}, nil
}

// WatchInsufficientGasForForward is a free log subscription operation binding the contract event 0x92a29f6ec9a5c0291fa4acf5fdccec764f8931ce4cc00a2e1fb04a1e36062a11.
//
// Solidity: event InsufficientGasForForward(uint256 gasLeft, uint256 requiredGas)
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) WatchInsufficientGasForForward(opts *bind.WatchOpts, sink chan<- *ECDSAPPSOracleInsufficientGasForForward) (event.Subscription, error) {

	logs, sub, err := _ECDSAPPSOracle.contract.WatchLogs(opts, "InsufficientGasForForward")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ECDSAPPSOracleInsufficientGasForForward)
				if err := _ECDSAPPSOracle.contract.UnpackLog(event, "InsufficientGasForForward", log); err != nil {
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

// ParseInsufficientGasForForward is a log parse operation binding the contract event 0x92a29f6ec9a5c0291fa4acf5fdccec764f8931ce4cc00a2e1fb04a1e36062a11.
//
// Solidity: event InsufficientGasForForward(uint256 gasLeft, uint256 requiredGas)
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) ParseInsufficientGasForForward(log types.Log) (*ECDSAPPSOracleInsufficientGasForForward, error) {
	event := new(ECDSAPPSOracleInsufficientGasForForward)
	if err := _ECDSAPPSOracle.contract.UnpackLog(event, "InsufficientGasForForward", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ECDSAPPSOraclePPSValidatedIterator is returned from FilterPPSValidated and is used to iterate over the raw logs and unpacked data for PPSValidated events raised by the ECDSAPPSOracle contract.
type ECDSAPPSOraclePPSValidatedIterator struct {
	Event *ECDSAPPSOraclePPSValidated // Event containing the contract specifics and raw log

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
func (it *ECDSAPPSOraclePPSValidatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ECDSAPPSOraclePPSValidated)
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
		it.Event = new(ECDSAPPSOraclePPSValidated)
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
func (it *ECDSAPPSOraclePPSValidatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ECDSAPPSOraclePPSValidatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ECDSAPPSOraclePPSValidated represents a PPSValidated event raised by the ECDSAPPSOracle contract.
type ECDSAPPSOraclePPSValidated struct {
	Strategy  common.Address
	Pps       *big.Int
	Timestamp *big.Int
	Sender    common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterPPSValidated is a free log retrieval operation binding the contract event 0x455651cacfcf0fff04803db9c24e2a1b544f1daec4209dbc4b6a6168299045fe.
//
// Solidity: event PPSValidated(address indexed strategy, uint256 pps, uint256 timestamp, address indexed sender)
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) FilterPPSValidated(opts *bind.FilterOpts, strategy []common.Address, sender []common.Address) (*ECDSAPPSOraclePPSValidatedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _ECDSAPPSOracle.contract.FilterLogs(opts, "PPSValidated", strategyRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &ECDSAPPSOraclePPSValidatedIterator{contract: _ECDSAPPSOracle.contract, event: "PPSValidated", logs: logs, sub: sub}, nil
}

// WatchPPSValidated is a free log subscription operation binding the contract event 0x455651cacfcf0fff04803db9c24e2a1b544f1daec4209dbc4b6a6168299045fe.
//
// Solidity: event PPSValidated(address indexed strategy, uint256 pps, uint256 timestamp, address indexed sender)
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) WatchPPSValidated(opts *bind.WatchOpts, sink chan<- *ECDSAPPSOraclePPSValidated, strategy []common.Address, sender []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _ECDSAPPSOracle.contract.WatchLogs(opts, "PPSValidated", strategyRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ECDSAPPSOraclePPSValidated)
				if err := _ECDSAPPSOracle.contract.UnpackLog(event, "PPSValidated", log); err != nil {
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

// ParsePPSValidated is a log parse operation binding the contract event 0x455651cacfcf0fff04803db9c24e2a1b544f1daec4209dbc4b6a6168299045fe.
//
// Solidity: event PPSValidated(address indexed strategy, uint256 pps, uint256 timestamp, address indexed sender)
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) ParsePPSValidated(log types.Log) (*ECDSAPPSOraclePPSValidated, error) {
	event := new(ECDSAPPSOraclePPSValidated)
	if err := _ECDSAPPSOracle.contract.UnpackLog(event, "PPSValidated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ECDSAPPSOracleProofValidationFailedIterator is returned from FilterProofValidationFailed and is used to iterate over the raw logs and unpacked data for ProofValidationFailed events raised by the ECDSAPPSOracle contract.
type ECDSAPPSOracleProofValidationFailedIterator struct {
	Event *ECDSAPPSOracleProofValidationFailed // Event containing the contract specifics and raw log

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
func (it *ECDSAPPSOracleProofValidationFailedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ECDSAPPSOracleProofValidationFailed)
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
		it.Event = new(ECDSAPPSOracleProofValidationFailed)
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
func (it *ECDSAPPSOracleProofValidationFailedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ECDSAPPSOracleProofValidationFailedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ECDSAPPSOracleProofValidationFailed represents a ProofValidationFailed event raised by the ECDSAPPSOracle contract.
type ECDSAPPSOracleProofValidationFailed struct {
	Strategy common.Address
	Reason   string
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterProofValidationFailed is a free log retrieval operation binding the contract event 0xd515726916f48939288f55b95c9c10f4b3b63b7ed16b334257d4a1f91d67bb37.
//
// Solidity: event ProofValidationFailed(address indexed strategy, string reason)
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) FilterProofValidationFailed(opts *bind.FilterOpts, strategy []common.Address) (*ECDSAPPSOracleProofValidationFailedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ECDSAPPSOracle.contract.FilterLogs(opts, "ProofValidationFailed", strategyRule)
	if err != nil {
		return nil, err
	}
	return &ECDSAPPSOracleProofValidationFailedIterator{contract: _ECDSAPPSOracle.contract, event: "ProofValidationFailed", logs: logs, sub: sub}, nil
}

// WatchProofValidationFailed is a free log subscription operation binding the contract event 0xd515726916f48939288f55b95c9c10f4b3b63b7ed16b334257d4a1f91d67bb37.
//
// Solidity: event ProofValidationFailed(address indexed strategy, string reason)
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) WatchProofValidationFailed(opts *bind.WatchOpts, sink chan<- *ECDSAPPSOracleProofValidationFailed, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ECDSAPPSOracle.contract.WatchLogs(opts, "ProofValidationFailed", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ECDSAPPSOracleProofValidationFailed)
				if err := _ECDSAPPSOracle.contract.UnpackLog(event, "ProofValidationFailed", log); err != nil {
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

// ParseProofValidationFailed is a log parse operation binding the contract event 0xd515726916f48939288f55b95c9c10f4b3b63b7ed16b334257d4a1f91d67bb37.
//
// Solidity: event ProofValidationFailed(address indexed strategy, string reason)
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) ParseProofValidationFailed(log types.Log) (*ECDSAPPSOracleProofValidationFailed, error) {
	event := new(ECDSAPPSOracleProofValidationFailed)
	if err := _ECDSAPPSOracle.contract.UnpackLog(event, "ProofValidationFailed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ECDSAPPSOracleProofValidationFailedLowLevelIterator is returned from FilterProofValidationFailedLowLevel and is used to iterate over the raw logs and unpacked data for ProofValidationFailedLowLevel events raised by the ECDSAPPSOracle contract.
type ECDSAPPSOracleProofValidationFailedLowLevelIterator struct {
	Event *ECDSAPPSOracleProofValidationFailedLowLevel // Event containing the contract specifics and raw log

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
func (it *ECDSAPPSOracleProofValidationFailedLowLevelIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ECDSAPPSOracleProofValidationFailedLowLevel)
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
		it.Event = new(ECDSAPPSOracleProofValidationFailedLowLevel)
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
func (it *ECDSAPPSOracleProofValidationFailedLowLevelIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ECDSAPPSOracleProofValidationFailedLowLevelIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ECDSAPPSOracleProofValidationFailedLowLevel represents a ProofValidationFailedLowLevel event raised by the ECDSAPPSOracle contract.
type ECDSAPPSOracleProofValidationFailedLowLevel struct {
	Strategy common.Address
	Data     []byte
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterProofValidationFailedLowLevel is a free log retrieval operation binding the contract event 0x0120ac3ec8e7663a13f8db6b3b68d56bc1176068ea11b71dca46ed12288bbca0.
//
// Solidity: event ProofValidationFailedLowLevel(address indexed strategy, bytes data)
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) FilterProofValidationFailedLowLevel(opts *bind.FilterOpts, strategy []common.Address) (*ECDSAPPSOracleProofValidationFailedLowLevelIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ECDSAPPSOracle.contract.FilterLogs(opts, "ProofValidationFailedLowLevel", strategyRule)
	if err != nil {
		return nil, err
	}
	return &ECDSAPPSOracleProofValidationFailedLowLevelIterator{contract: _ECDSAPPSOracle.contract, event: "ProofValidationFailedLowLevel", logs: logs, sub: sub}, nil
}

// WatchProofValidationFailedLowLevel is a free log subscription operation binding the contract event 0x0120ac3ec8e7663a13f8db6b3b68d56bc1176068ea11b71dca46ed12288bbca0.
//
// Solidity: event ProofValidationFailedLowLevel(address indexed strategy, bytes data)
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) WatchProofValidationFailedLowLevel(opts *bind.WatchOpts, sink chan<- *ECDSAPPSOracleProofValidationFailedLowLevel, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _ECDSAPPSOracle.contract.WatchLogs(opts, "ProofValidationFailedLowLevel", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ECDSAPPSOracleProofValidationFailedLowLevel)
				if err := _ECDSAPPSOracle.contract.UnpackLog(event, "ProofValidationFailedLowLevel", log); err != nil {
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

// ParseProofValidationFailedLowLevel is a log parse operation binding the contract event 0x0120ac3ec8e7663a13f8db6b3b68d56bc1176068ea11b71dca46ed12288bbca0.
//
// Solidity: event ProofValidationFailedLowLevel(address indexed strategy, bytes data)
func (_ECDSAPPSOracle *ECDSAPPSOracleFilterer) ParseProofValidationFailedLowLevel(log types.Log) (*ECDSAPPSOracleProofValidationFailedLowLevel, error) {
	event := new(ECDSAPPSOracleProofValidationFailedLowLevel)
	if err := _ECDSAPPSOracle.contract.UnpackLog(event, "ProofValidationFailedLowLevel", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
