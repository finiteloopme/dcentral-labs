// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package contract

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

// EquityContractV3Equity is an auto generated low-level Go binding around an user-defined struct.
type EquityContractV3Equity struct {
	Name         string
	Symbol       string
	DocHash      string
	Country      string
	Issuer       common.Address
	TotalSupply  *big.Int
	InitialPrice *big.Int
	Logo         string
}

// EquityMetaData contains all meta data concerning the Equity contract.
var EquityMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"UPGRADE_INTERFACE_VERSION\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addEquity\",\"inputs\":[{\"name\":\"_equity\",\"type\":\"tuple\",\"internalType\":\"structEquityContractV3.Equity\",\"components\":[{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"symbol\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"docHash\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"country\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"issuer\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"totalSupply\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"initialPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"logo\",\"type\":\"string\",\"internalType\":\"string\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"assetName\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"assetSymbol\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"assetTotalSupply\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOf\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOfBatch\",\"inputs\":[{\"name\":\"accounts\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"buy\",\"inputs\":[{\"name\":\"_id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"decimals\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAllAssetIds\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getBuyPrice\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCurrentSupply\",\"inputs\":[{\"name\":\"_id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getEquityDetailsFromId\",\"inputs\":[{\"name\":\"_id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structEquityContractV3.Equity\",\"components\":[{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"symbol\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"docHash\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"country\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"issuer\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"totalSupply\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"initialPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"logo\",\"type\":\"string\",\"internalType\":\"string\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSellPrice\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getUserAssetIds\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"initialize\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"isApprovedForAll\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"name\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proxiableUUID\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"safeBatchTransferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"values\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"safeTransferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"sell\",\"inputs\":[{\"name\":\"_id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"setApprovalForAll\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"symbol\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalEquities\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"upgradeToAndCall\",\"inputs\":[{\"name\":\"newImplementation\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"uri\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"ApprovalForAll\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AssetBought\",\"inputs\":[{\"name\":\"assetId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"buyer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"tokenCount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"price\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"name\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AssetIssued\",\"inputs\":[{\"name\":\"assetId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"totalSupply\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"initialPrice\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"name\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"symbol\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AssetSold\",\"inputs\":[{\"name\":\"assetId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"seller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"tokenCount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"price\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"name\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Initialized\",\"inputs\":[{\"name\":\"version\",\"type\":\"uint64\",\"indexed\":false,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferBatch\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"values\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferSingle\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"URI\",\"inputs\":[{\"name\":\"value\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Upgraded\",\"inputs\":[{\"name\":\"implementation\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AddressEmptyCode\",\"inputs\":[{\"name\":\"target\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InsufficientBalance\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"needed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"tokenId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidApprover\",\"inputs\":[{\"name\":\"approver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidArrayLength\",\"inputs\":[{\"name\":\"idsLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"valuesLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidOperator\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidReceiver\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidSender\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155MissingApprovalForAll\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1967InvalidImplementation\",\"inputs\":[{\"name\":\"implementation\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1967NonPayable\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FailedCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidInitialization\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NotInitializing\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"OwnableInvalidOwner\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"UUPSUnauthorizedCallContext\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UUPSUnsupportedProxiableUUID\",\"inputs\":[{\"name\":\"slot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]}]",
}

// EquityABI is the input ABI used to generate the binding from.
// Deprecated: Use EquityMetaData.ABI instead.
var EquityABI = EquityMetaData.ABI

// Equity is an auto generated Go binding around an Ethereum contract.
type Equity struct {
	EquityCaller     // Read-only binding to the contract
	EquityTransactor // Write-only binding to the contract
	EquityFilterer   // Log filterer for contract events
}

// EquityCaller is an auto generated read-only Go binding around an Ethereum contract.
type EquityCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// EquityTransactor is an auto generated write-only Go binding around an Ethereum contract.
type EquityTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// EquityFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type EquityFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// EquitySession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type EquitySession struct {
	Contract     *Equity           // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// EquityCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type EquityCallerSession struct {
	Contract *EquityCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts // Call options to use throughout this session
}

// EquityTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type EquityTransactorSession struct {
	Contract     *EquityTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// EquityRaw is an auto generated low-level Go binding around an Ethereum contract.
type EquityRaw struct {
	Contract *Equity // Generic contract binding to access the raw methods on
}

// EquityCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type EquityCallerRaw struct {
	Contract *EquityCaller // Generic read-only contract binding to access the raw methods on
}

// EquityTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type EquityTransactorRaw struct {
	Contract *EquityTransactor // Generic write-only contract binding to access the raw methods on
}

// NewEquity creates a new instance of Equity, bound to a specific deployed contract.
func NewEquity(address common.Address, backend bind.ContractBackend) (*Equity, error) {
	contract, err := bindEquity(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &Equity{EquityCaller: EquityCaller{contract: contract}, EquityTransactor: EquityTransactor{contract: contract}, EquityFilterer: EquityFilterer{contract: contract}}, nil
}

// NewEquityCaller creates a new read-only instance of Equity, bound to a specific deployed contract.
func NewEquityCaller(address common.Address, caller bind.ContractCaller) (*EquityCaller, error) {
	contract, err := bindEquity(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &EquityCaller{contract: contract}, nil
}

// NewEquityTransactor creates a new write-only instance of Equity, bound to a specific deployed contract.
func NewEquityTransactor(address common.Address, transactor bind.ContractTransactor) (*EquityTransactor, error) {
	contract, err := bindEquity(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &EquityTransactor{contract: contract}, nil
}

// NewEquityFilterer creates a new log filterer instance of Equity, bound to a specific deployed contract.
func NewEquityFilterer(address common.Address, filterer bind.ContractFilterer) (*EquityFilterer, error) {
	contract, err := bindEquity(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &EquityFilterer{contract: contract}, nil
}

// bindEquity binds a generic wrapper to an already deployed contract.
func bindEquity(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := EquityMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Equity *EquityRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Equity.Contract.EquityCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Equity *EquityRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Equity.Contract.EquityTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Equity *EquityRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Equity.Contract.EquityTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Equity *EquityCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Equity.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Equity *EquityTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Equity.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Equity *EquityTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Equity.Contract.contract.Transact(opts, method, params...)
}

// UPGRADEINTERFACEVERSION is a free data retrieval call binding the contract method 0xad3cb1cc.
//
// Solidity: function UPGRADE_INTERFACE_VERSION() view returns(string)
func (_Equity *EquityCaller) UPGRADEINTERFACEVERSION(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "UPGRADE_INTERFACE_VERSION")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// UPGRADEINTERFACEVERSION is a free data retrieval call binding the contract method 0xad3cb1cc.
//
// Solidity: function UPGRADE_INTERFACE_VERSION() view returns(string)
func (_Equity *EquitySession) UPGRADEINTERFACEVERSION() (string, error) {
	return _Equity.Contract.UPGRADEINTERFACEVERSION(&_Equity.CallOpts)
}

// UPGRADEINTERFACEVERSION is a free data retrieval call binding the contract method 0xad3cb1cc.
//
// Solidity: function UPGRADE_INTERFACE_VERSION() view returns(string)
func (_Equity *EquityCallerSession) UPGRADEINTERFACEVERSION() (string, error) {
	return _Equity.Contract.UPGRADEINTERFACEVERSION(&_Equity.CallOpts)
}

// AssetName is a free data retrieval call binding the contract method 0x01a3543d.
//
// Solidity: function assetName(uint256 id) view returns(string)
func (_Equity *EquityCaller) AssetName(opts *bind.CallOpts, id *big.Int) (string, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "assetName", id)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// AssetName is a free data retrieval call binding the contract method 0x01a3543d.
//
// Solidity: function assetName(uint256 id) view returns(string)
func (_Equity *EquitySession) AssetName(id *big.Int) (string, error) {
	return _Equity.Contract.AssetName(&_Equity.CallOpts, id)
}

// AssetName is a free data retrieval call binding the contract method 0x01a3543d.
//
// Solidity: function assetName(uint256 id) view returns(string)
func (_Equity *EquityCallerSession) AssetName(id *big.Int) (string, error) {
	return _Equity.Contract.AssetName(&_Equity.CallOpts, id)
}

// AssetSymbol is a free data retrieval call binding the contract method 0xf701fd0a.
//
// Solidity: function assetSymbol(uint256 id) view returns(string)
func (_Equity *EquityCaller) AssetSymbol(opts *bind.CallOpts, id *big.Int) (string, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "assetSymbol", id)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// AssetSymbol is a free data retrieval call binding the contract method 0xf701fd0a.
//
// Solidity: function assetSymbol(uint256 id) view returns(string)
func (_Equity *EquitySession) AssetSymbol(id *big.Int) (string, error) {
	return _Equity.Contract.AssetSymbol(&_Equity.CallOpts, id)
}

// AssetSymbol is a free data retrieval call binding the contract method 0xf701fd0a.
//
// Solidity: function assetSymbol(uint256 id) view returns(string)
func (_Equity *EquityCallerSession) AssetSymbol(id *big.Int) (string, error) {
	return _Equity.Contract.AssetSymbol(&_Equity.CallOpts, id)
}

// AssetTotalSupply is a free data retrieval call binding the contract method 0x1cce6ef5.
//
// Solidity: function assetTotalSupply(uint256 id) view returns(uint256)
func (_Equity *EquityCaller) AssetTotalSupply(opts *bind.CallOpts, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "assetTotalSupply", id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AssetTotalSupply is a free data retrieval call binding the contract method 0x1cce6ef5.
//
// Solidity: function assetTotalSupply(uint256 id) view returns(uint256)
func (_Equity *EquitySession) AssetTotalSupply(id *big.Int) (*big.Int, error) {
	return _Equity.Contract.AssetTotalSupply(&_Equity.CallOpts, id)
}

// AssetTotalSupply is a free data retrieval call binding the contract method 0x1cce6ef5.
//
// Solidity: function assetTotalSupply(uint256 id) view returns(uint256)
func (_Equity *EquityCallerSession) AssetTotalSupply(id *big.Int) (*big.Int, error) {
	return _Equity.Contract.AssetTotalSupply(&_Equity.CallOpts, id)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_Equity *EquityCaller) BalanceOf(opts *bind.CallOpts, account common.Address, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "balanceOf", account, id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_Equity *EquitySession) BalanceOf(account common.Address, id *big.Int) (*big.Int, error) {
	return _Equity.Contract.BalanceOf(&_Equity.CallOpts, account, id)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_Equity *EquityCallerSession) BalanceOf(account common.Address, id *big.Int) (*big.Int, error) {
	return _Equity.Contract.BalanceOf(&_Equity.CallOpts, account, id)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_Equity *EquityCaller) BalanceOfBatch(opts *bind.CallOpts, accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "balanceOfBatch", accounts, ids)

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_Equity *EquitySession) BalanceOfBatch(accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _Equity.Contract.BalanceOfBatch(&_Equity.CallOpts, accounts, ids)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_Equity *EquityCallerSession) BalanceOfBatch(accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _Equity.Contract.BalanceOfBatch(&_Equity.CallOpts, accounts, ids)
}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint256)
func (_Equity *EquityCaller) Decimals(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "decimals")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint256)
func (_Equity *EquitySession) Decimals() (*big.Int, error) {
	return _Equity.Contract.Decimals(&_Equity.CallOpts)
}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint256)
func (_Equity *EquityCallerSession) Decimals() (*big.Int, error) {
	return _Equity.Contract.Decimals(&_Equity.CallOpts)
}

// GetAllAssetIds is a free data retrieval call binding the contract method 0xe122f907.
//
// Solidity: function getAllAssetIds() view returns(uint256[])
func (_Equity *EquityCaller) GetAllAssetIds(opts *bind.CallOpts) ([]*big.Int, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "getAllAssetIds")

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// GetAllAssetIds is a free data retrieval call binding the contract method 0xe122f907.
//
// Solidity: function getAllAssetIds() view returns(uint256[])
func (_Equity *EquitySession) GetAllAssetIds() ([]*big.Int, error) {
	return _Equity.Contract.GetAllAssetIds(&_Equity.CallOpts)
}

// GetAllAssetIds is a free data retrieval call binding the contract method 0xe122f907.
//
// Solidity: function getAllAssetIds() view returns(uint256[])
func (_Equity *EquityCallerSession) GetAllAssetIds() ([]*big.Int, error) {
	return _Equity.Contract.GetAllAssetIds(&_Equity.CallOpts)
}

// GetBuyPrice is a free data retrieval call binding the contract method 0x08d4db14.
//
// Solidity: function getBuyPrice(uint256 id) view returns(uint256)
func (_Equity *EquityCaller) GetBuyPrice(opts *bind.CallOpts, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "getBuyPrice", id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetBuyPrice is a free data retrieval call binding the contract method 0x08d4db14.
//
// Solidity: function getBuyPrice(uint256 id) view returns(uint256)
func (_Equity *EquitySession) GetBuyPrice(id *big.Int) (*big.Int, error) {
	return _Equity.Contract.GetBuyPrice(&_Equity.CallOpts, id)
}

// GetBuyPrice is a free data retrieval call binding the contract method 0x08d4db14.
//
// Solidity: function getBuyPrice(uint256 id) view returns(uint256)
func (_Equity *EquityCallerSession) GetBuyPrice(id *big.Int) (*big.Int, error) {
	return _Equity.Contract.GetBuyPrice(&_Equity.CallOpts, id)
}

// GetCurrentSupply is a free data retrieval call binding the contract method 0x46f5303d.
//
// Solidity: function getCurrentSupply(uint256 _id) view returns(uint256)
func (_Equity *EquityCaller) GetCurrentSupply(opts *bind.CallOpts, _id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "getCurrentSupply", _id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetCurrentSupply is a free data retrieval call binding the contract method 0x46f5303d.
//
// Solidity: function getCurrentSupply(uint256 _id) view returns(uint256)
func (_Equity *EquitySession) GetCurrentSupply(_id *big.Int) (*big.Int, error) {
	return _Equity.Contract.GetCurrentSupply(&_Equity.CallOpts, _id)
}

// GetCurrentSupply is a free data retrieval call binding the contract method 0x46f5303d.
//
// Solidity: function getCurrentSupply(uint256 _id) view returns(uint256)
func (_Equity *EquityCallerSession) GetCurrentSupply(_id *big.Int) (*big.Int, error) {
	return _Equity.Contract.GetCurrentSupply(&_Equity.CallOpts, _id)
}

// GetEquityDetailsFromId is a free data retrieval call binding the contract method 0xeca35a54.
//
// Solidity: function getEquityDetailsFromId(uint256 _id) view returns((string,string,string,string,address,uint256,uint256,string))
func (_Equity *EquityCaller) GetEquityDetailsFromId(opts *bind.CallOpts, _id *big.Int) (EquityContractV3Equity, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "getEquityDetailsFromId", _id)

	if err != nil {
		return *new(EquityContractV3Equity), err
	}

	out0 := *abi.ConvertType(out[0], new(EquityContractV3Equity)).(*EquityContractV3Equity)

	return out0, err

}

// GetEquityDetailsFromId is a free data retrieval call binding the contract method 0xeca35a54.
//
// Solidity: function getEquityDetailsFromId(uint256 _id) view returns((string,string,string,string,address,uint256,uint256,string))
func (_Equity *EquitySession) GetEquityDetailsFromId(_id *big.Int) (EquityContractV3Equity, error) {
	return _Equity.Contract.GetEquityDetailsFromId(&_Equity.CallOpts, _id)
}

// GetEquityDetailsFromId is a free data retrieval call binding the contract method 0xeca35a54.
//
// Solidity: function getEquityDetailsFromId(uint256 _id) view returns((string,string,string,string,address,uint256,uint256,string))
func (_Equity *EquityCallerSession) GetEquityDetailsFromId(_id *big.Int) (EquityContractV3Equity, error) {
	return _Equity.Contract.GetEquityDetailsFromId(&_Equity.CallOpts, _id)
}

// GetSellPrice is a free data retrieval call binding the contract method 0xba730e53.
//
// Solidity: function getSellPrice(uint256 id) view returns(uint256)
func (_Equity *EquityCaller) GetSellPrice(opts *bind.CallOpts, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "getSellPrice", id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetSellPrice is a free data retrieval call binding the contract method 0xba730e53.
//
// Solidity: function getSellPrice(uint256 id) view returns(uint256)
func (_Equity *EquitySession) GetSellPrice(id *big.Int) (*big.Int, error) {
	return _Equity.Contract.GetSellPrice(&_Equity.CallOpts, id)
}

// GetSellPrice is a free data retrieval call binding the contract method 0xba730e53.
//
// Solidity: function getSellPrice(uint256 id) view returns(uint256)
func (_Equity *EquityCallerSession) GetSellPrice(id *big.Int) (*big.Int, error) {
	return _Equity.Contract.GetSellPrice(&_Equity.CallOpts, id)
}

// GetUserAssetIds is a free data retrieval call binding the contract method 0x4e883ac7.
//
// Solidity: function getUserAssetIds(address user) view returns(uint256[])
func (_Equity *EquityCaller) GetUserAssetIds(opts *bind.CallOpts, user common.Address) ([]*big.Int, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "getUserAssetIds", user)

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// GetUserAssetIds is a free data retrieval call binding the contract method 0x4e883ac7.
//
// Solidity: function getUserAssetIds(address user) view returns(uint256[])
func (_Equity *EquitySession) GetUserAssetIds(user common.Address) ([]*big.Int, error) {
	return _Equity.Contract.GetUserAssetIds(&_Equity.CallOpts, user)
}

// GetUserAssetIds is a free data retrieval call binding the contract method 0x4e883ac7.
//
// Solidity: function getUserAssetIds(address user) view returns(uint256[])
func (_Equity *EquityCallerSession) GetUserAssetIds(user common.Address) ([]*big.Int, error) {
	return _Equity.Contract.GetUserAssetIds(&_Equity.CallOpts, user)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_Equity *EquityCaller) IsApprovedForAll(opts *bind.CallOpts, account common.Address, operator common.Address) (bool, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "isApprovedForAll", account, operator)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_Equity *EquitySession) IsApprovedForAll(account common.Address, operator common.Address) (bool, error) {
	return _Equity.Contract.IsApprovedForAll(&_Equity.CallOpts, account, operator)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_Equity *EquityCallerSession) IsApprovedForAll(account common.Address, operator common.Address) (bool, error) {
	return _Equity.Contract.IsApprovedForAll(&_Equity.CallOpts, account, operator)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_Equity *EquityCaller) Name(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "name")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_Equity *EquitySession) Name() (string, error) {
	return _Equity.Contract.Name(&_Equity.CallOpts)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_Equity *EquityCallerSession) Name() (string, error) {
	return _Equity.Contract.Name(&_Equity.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Equity *EquityCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Equity *EquitySession) Owner() (common.Address, error) {
	return _Equity.Contract.Owner(&_Equity.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Equity *EquityCallerSession) Owner() (common.Address, error) {
	return _Equity.Contract.Owner(&_Equity.CallOpts)
}

// ProxiableUUID is a free data retrieval call binding the contract method 0x52d1902d.
//
// Solidity: function proxiableUUID() view returns(bytes32)
func (_Equity *EquityCaller) ProxiableUUID(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "proxiableUUID")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// ProxiableUUID is a free data retrieval call binding the contract method 0x52d1902d.
//
// Solidity: function proxiableUUID() view returns(bytes32)
func (_Equity *EquitySession) ProxiableUUID() ([32]byte, error) {
	return _Equity.Contract.ProxiableUUID(&_Equity.CallOpts)
}

// ProxiableUUID is a free data retrieval call binding the contract method 0x52d1902d.
//
// Solidity: function proxiableUUID() view returns(bytes32)
func (_Equity *EquityCallerSession) ProxiableUUID() ([32]byte, error) {
	return _Equity.Contract.ProxiableUUID(&_Equity.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Equity *EquityCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Equity *EquitySession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _Equity.Contract.SupportsInterface(&_Equity.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Equity *EquityCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _Equity.Contract.SupportsInterface(&_Equity.CallOpts, interfaceId)
}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_Equity *EquityCaller) Symbol(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "symbol")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_Equity *EquitySession) Symbol() (string, error) {
	return _Equity.Contract.Symbol(&_Equity.CallOpts)
}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_Equity *EquityCallerSession) Symbol() (string, error) {
	return _Equity.Contract.Symbol(&_Equity.CallOpts)
}

// TotalEquities is a free data retrieval call binding the contract method 0xf7d7d277.
//
// Solidity: function totalEquities() view returns(uint256)
func (_Equity *EquityCaller) TotalEquities(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "totalEquities")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalEquities is a free data retrieval call binding the contract method 0xf7d7d277.
//
// Solidity: function totalEquities() view returns(uint256)
func (_Equity *EquitySession) TotalEquities() (*big.Int, error) {
	return _Equity.Contract.TotalEquities(&_Equity.CallOpts)
}

// TotalEquities is a free data retrieval call binding the contract method 0xf7d7d277.
//
// Solidity: function totalEquities() view returns(uint256)
func (_Equity *EquityCallerSession) TotalEquities() (*big.Int, error) {
	return _Equity.Contract.TotalEquities(&_Equity.CallOpts)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_Equity *EquityCaller) Uri(opts *bind.CallOpts, arg0 *big.Int) (string, error) {
	var out []interface{}
	err := _Equity.contract.Call(opts, &out, "uri", arg0)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_Equity *EquitySession) Uri(arg0 *big.Int) (string, error) {
	return _Equity.Contract.Uri(&_Equity.CallOpts, arg0)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_Equity *EquityCallerSession) Uri(arg0 *big.Int) (string, error) {
	return _Equity.Contract.Uri(&_Equity.CallOpts, arg0)
}

// AddEquity is a paid mutator transaction binding the contract method 0xaf201651.
//
// Solidity: function addEquity((string,string,string,string,address,uint256,uint256,string) _equity) returns()
func (_Equity *EquityTransactor) AddEquity(opts *bind.TransactOpts, _equity EquityContractV3Equity) (*types.Transaction, error) {
	return _Equity.contract.Transact(opts, "addEquity", _equity)
}

// AddEquity is a paid mutator transaction binding the contract method 0xaf201651.
//
// Solidity: function addEquity((string,string,string,string,address,uint256,uint256,string) _equity) returns()
func (_Equity *EquitySession) AddEquity(_equity EquityContractV3Equity) (*types.Transaction, error) {
	return _Equity.Contract.AddEquity(&_Equity.TransactOpts, _equity)
}

// AddEquity is a paid mutator transaction binding the contract method 0xaf201651.
//
// Solidity: function addEquity((string,string,string,string,address,uint256,uint256,string) _equity) returns()
func (_Equity *EquityTransactorSession) AddEquity(_equity EquityContractV3Equity) (*types.Transaction, error) {
	return _Equity.Contract.AddEquity(&_Equity.TransactOpts, _equity)
}

// Buy is a paid mutator transaction binding the contract method 0xd96a094a.
//
// Solidity: function buy(uint256 _id) payable returns()
func (_Equity *EquityTransactor) Buy(opts *bind.TransactOpts, _id *big.Int) (*types.Transaction, error) {
	return _Equity.contract.Transact(opts, "buy", _id)
}

// Buy is a paid mutator transaction binding the contract method 0xd96a094a.
//
// Solidity: function buy(uint256 _id) payable returns()
func (_Equity *EquitySession) Buy(_id *big.Int) (*types.Transaction, error) {
	return _Equity.Contract.Buy(&_Equity.TransactOpts, _id)
}

// Buy is a paid mutator transaction binding the contract method 0xd96a094a.
//
// Solidity: function buy(uint256 _id) payable returns()
func (_Equity *EquityTransactorSession) Buy(_id *big.Int) (*types.Transaction, error) {
	return _Equity.Contract.Buy(&_Equity.TransactOpts, _id)
}

// Initialize is a paid mutator transaction binding the contract method 0x8129fc1c.
//
// Solidity: function initialize() returns()
func (_Equity *EquityTransactor) Initialize(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Equity.contract.Transact(opts, "initialize")
}

// Initialize is a paid mutator transaction binding the contract method 0x8129fc1c.
//
// Solidity: function initialize() returns()
func (_Equity *EquitySession) Initialize() (*types.Transaction, error) {
	return _Equity.Contract.Initialize(&_Equity.TransactOpts)
}

// Initialize is a paid mutator transaction binding the contract method 0x8129fc1c.
//
// Solidity: function initialize() returns()
func (_Equity *EquityTransactorSession) Initialize() (*types.Transaction, error) {
	return _Equity.Contract.Initialize(&_Equity.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_Equity *EquityTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Equity.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_Equity *EquitySession) RenounceOwnership() (*types.Transaction, error) {
	return _Equity.Contract.RenounceOwnership(&_Equity.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_Equity *EquityTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _Equity.Contract.RenounceOwnership(&_Equity.TransactOpts)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_Equity *EquityTransactor) SafeBatchTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _Equity.contract.Transact(opts, "safeBatchTransferFrom", from, to, ids, values, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_Equity *EquitySession) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _Equity.Contract.SafeBatchTransferFrom(&_Equity.TransactOpts, from, to, ids, values, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_Equity *EquityTransactorSession) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _Equity.Contract.SafeBatchTransferFrom(&_Equity.TransactOpts, from, to, ids, values, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_Equity *EquityTransactor) SafeTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _Equity.contract.Transact(opts, "safeTransferFrom", from, to, id, value, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_Equity *EquitySession) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _Equity.Contract.SafeTransferFrom(&_Equity.TransactOpts, from, to, id, value, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_Equity *EquityTransactorSession) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _Equity.Contract.SafeTransferFrom(&_Equity.TransactOpts, from, to, id, value, data)
}

// Sell is a paid mutator transaction binding the contract method 0xe4849b32.
//
// Solidity: function sell(uint256 _id) payable returns()
func (_Equity *EquityTransactor) Sell(opts *bind.TransactOpts, _id *big.Int) (*types.Transaction, error) {
	return _Equity.contract.Transact(opts, "sell", _id)
}

// Sell is a paid mutator transaction binding the contract method 0xe4849b32.
//
// Solidity: function sell(uint256 _id) payable returns()
func (_Equity *EquitySession) Sell(_id *big.Int) (*types.Transaction, error) {
	return _Equity.Contract.Sell(&_Equity.TransactOpts, _id)
}

// Sell is a paid mutator transaction binding the contract method 0xe4849b32.
//
// Solidity: function sell(uint256 _id) payable returns()
func (_Equity *EquityTransactorSession) Sell(_id *big.Int) (*types.Transaction, error) {
	return _Equity.Contract.Sell(&_Equity.TransactOpts, _id)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_Equity *EquityTransactor) SetApprovalForAll(opts *bind.TransactOpts, operator common.Address, approved bool) (*types.Transaction, error) {
	return _Equity.contract.Transact(opts, "setApprovalForAll", operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_Equity *EquitySession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _Equity.Contract.SetApprovalForAll(&_Equity.TransactOpts, operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_Equity *EquityTransactorSession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _Equity.Contract.SetApprovalForAll(&_Equity.TransactOpts, operator, approved)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_Equity *EquityTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _Equity.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_Equity *EquitySession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _Equity.Contract.TransferOwnership(&_Equity.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_Equity *EquityTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _Equity.Contract.TransferOwnership(&_Equity.TransactOpts, newOwner)
}

// UpgradeToAndCall is a paid mutator transaction binding the contract method 0x4f1ef286.
//
// Solidity: function upgradeToAndCall(address newImplementation, bytes data) payable returns()
func (_Equity *EquityTransactor) UpgradeToAndCall(opts *bind.TransactOpts, newImplementation common.Address, data []byte) (*types.Transaction, error) {
	return _Equity.contract.Transact(opts, "upgradeToAndCall", newImplementation, data)
}

// UpgradeToAndCall is a paid mutator transaction binding the contract method 0x4f1ef286.
//
// Solidity: function upgradeToAndCall(address newImplementation, bytes data) payable returns()
func (_Equity *EquitySession) UpgradeToAndCall(newImplementation common.Address, data []byte) (*types.Transaction, error) {
	return _Equity.Contract.UpgradeToAndCall(&_Equity.TransactOpts, newImplementation, data)
}

// UpgradeToAndCall is a paid mutator transaction binding the contract method 0x4f1ef286.
//
// Solidity: function upgradeToAndCall(address newImplementation, bytes data) payable returns()
func (_Equity *EquityTransactorSession) UpgradeToAndCall(newImplementation common.Address, data []byte) (*types.Transaction, error) {
	return _Equity.Contract.UpgradeToAndCall(&_Equity.TransactOpts, newImplementation, data)
}

// EquityApprovalForAllIterator is returned from FilterApprovalForAll and is used to iterate over the raw logs and unpacked data for ApprovalForAll events raised by the Equity contract.
type EquityApprovalForAllIterator struct {
	Event *EquityApprovalForAll // Event containing the contract specifics and raw log

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
func (it *EquityApprovalForAllIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(EquityApprovalForAll)
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
		it.Event = new(EquityApprovalForAll)
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
func (it *EquityApprovalForAllIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *EquityApprovalForAllIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// EquityApprovalForAll represents a ApprovalForAll event raised by the Equity contract.
type EquityApprovalForAll struct {
	Account  common.Address
	Operator common.Address
	Approved bool
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterApprovalForAll is a free log retrieval operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_Equity *EquityFilterer) FilterApprovalForAll(opts *bind.FilterOpts, account []common.Address, operator []common.Address) (*EquityApprovalForAllIterator, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _Equity.contract.FilterLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return &EquityApprovalForAllIterator{contract: _Equity.contract, event: "ApprovalForAll", logs: logs, sub: sub}, nil
}

// WatchApprovalForAll is a free log subscription operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_Equity *EquityFilterer) WatchApprovalForAll(opts *bind.WatchOpts, sink chan<- *EquityApprovalForAll, account []common.Address, operator []common.Address) (event.Subscription, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _Equity.contract.WatchLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(EquityApprovalForAll)
				if err := _Equity.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
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

// ParseApprovalForAll is a log parse operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_Equity *EquityFilterer) ParseApprovalForAll(log types.Log) (*EquityApprovalForAll, error) {
	event := new(EquityApprovalForAll)
	if err := _Equity.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// EquityAssetBoughtIterator is returned from FilterAssetBought and is used to iterate over the raw logs and unpacked data for AssetBought events raised by the Equity contract.
type EquityAssetBoughtIterator struct {
	Event *EquityAssetBought // Event containing the contract specifics and raw log

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
func (it *EquityAssetBoughtIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(EquityAssetBought)
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
		it.Event = new(EquityAssetBought)
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
func (it *EquityAssetBoughtIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *EquityAssetBoughtIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// EquityAssetBought represents a AssetBought event raised by the Equity contract.
type EquityAssetBought struct {
	AssetId    *big.Int
	Buyer      common.Address
	TokenCount *big.Int
	Price      *big.Int
	Name       string
	Timestamp  *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterAssetBought is a free log retrieval operation binding the contract event 0xc4dd2b242df23335f8c79c84c12590a02f2c96864fc80967d45a637d0c933e39.
//
// Solidity: event AssetBought(uint256 indexed assetId, address indexed buyer, uint256 tokenCount, uint256 price, string name, uint256 timestamp)
func (_Equity *EquityFilterer) FilterAssetBought(opts *bind.FilterOpts, assetId []*big.Int, buyer []common.Address) (*EquityAssetBoughtIterator, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var buyerRule []interface{}
	for _, buyerItem := range buyer {
		buyerRule = append(buyerRule, buyerItem)
	}

	logs, sub, err := _Equity.contract.FilterLogs(opts, "AssetBought", assetIdRule, buyerRule)
	if err != nil {
		return nil, err
	}
	return &EquityAssetBoughtIterator{contract: _Equity.contract, event: "AssetBought", logs: logs, sub: sub}, nil
}

// WatchAssetBought is a free log subscription operation binding the contract event 0xc4dd2b242df23335f8c79c84c12590a02f2c96864fc80967d45a637d0c933e39.
//
// Solidity: event AssetBought(uint256 indexed assetId, address indexed buyer, uint256 tokenCount, uint256 price, string name, uint256 timestamp)
func (_Equity *EquityFilterer) WatchAssetBought(opts *bind.WatchOpts, sink chan<- *EquityAssetBought, assetId []*big.Int, buyer []common.Address) (event.Subscription, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var buyerRule []interface{}
	for _, buyerItem := range buyer {
		buyerRule = append(buyerRule, buyerItem)
	}

	logs, sub, err := _Equity.contract.WatchLogs(opts, "AssetBought", assetIdRule, buyerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(EquityAssetBought)
				if err := _Equity.contract.UnpackLog(event, "AssetBought", log); err != nil {
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

// ParseAssetBought is a log parse operation binding the contract event 0xc4dd2b242df23335f8c79c84c12590a02f2c96864fc80967d45a637d0c933e39.
//
// Solidity: event AssetBought(uint256 indexed assetId, address indexed buyer, uint256 tokenCount, uint256 price, string name, uint256 timestamp)
func (_Equity *EquityFilterer) ParseAssetBought(log types.Log) (*EquityAssetBought, error) {
	event := new(EquityAssetBought)
	if err := _Equity.contract.UnpackLog(event, "AssetBought", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// EquityAssetIssuedIterator is returned from FilterAssetIssued and is used to iterate over the raw logs and unpacked data for AssetIssued events raised by the Equity contract.
type EquityAssetIssuedIterator struct {
	Event *EquityAssetIssued // Event containing the contract specifics and raw log

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
func (it *EquityAssetIssuedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(EquityAssetIssued)
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
		it.Event = new(EquityAssetIssued)
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
func (it *EquityAssetIssuedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *EquityAssetIssuedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// EquityAssetIssued represents a AssetIssued event raised by the Equity contract.
type EquityAssetIssued struct {
	AssetId      *big.Int
	To           common.Address
	TotalSupply  *big.Int
	InitialPrice *big.Int
	Name         string
	Symbol       string
	Timestamp    *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterAssetIssued is a free log retrieval operation binding the contract event 0xe91aa54204e7e68ec3c978f25679bd4982f4bcee900ee74aca5cdfa20fc9abfe.
//
// Solidity: event AssetIssued(uint256 indexed assetId, address indexed to, uint256 totalSupply, uint256 initialPrice, string name, string symbol, uint256 timestamp)
func (_Equity *EquityFilterer) FilterAssetIssued(opts *bind.FilterOpts, assetId []*big.Int, to []common.Address) (*EquityAssetIssuedIterator, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _Equity.contract.FilterLogs(opts, "AssetIssued", assetIdRule, toRule)
	if err != nil {
		return nil, err
	}
	return &EquityAssetIssuedIterator{contract: _Equity.contract, event: "AssetIssued", logs: logs, sub: sub}, nil
}

// WatchAssetIssued is a free log subscription operation binding the contract event 0xe91aa54204e7e68ec3c978f25679bd4982f4bcee900ee74aca5cdfa20fc9abfe.
//
// Solidity: event AssetIssued(uint256 indexed assetId, address indexed to, uint256 totalSupply, uint256 initialPrice, string name, string symbol, uint256 timestamp)
func (_Equity *EquityFilterer) WatchAssetIssued(opts *bind.WatchOpts, sink chan<- *EquityAssetIssued, assetId []*big.Int, to []common.Address) (event.Subscription, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _Equity.contract.WatchLogs(opts, "AssetIssued", assetIdRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(EquityAssetIssued)
				if err := _Equity.contract.UnpackLog(event, "AssetIssued", log); err != nil {
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

// ParseAssetIssued is a log parse operation binding the contract event 0xe91aa54204e7e68ec3c978f25679bd4982f4bcee900ee74aca5cdfa20fc9abfe.
//
// Solidity: event AssetIssued(uint256 indexed assetId, address indexed to, uint256 totalSupply, uint256 initialPrice, string name, string symbol, uint256 timestamp)
func (_Equity *EquityFilterer) ParseAssetIssued(log types.Log) (*EquityAssetIssued, error) {
	event := new(EquityAssetIssued)
	if err := _Equity.contract.UnpackLog(event, "AssetIssued", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// EquityAssetSoldIterator is returned from FilterAssetSold and is used to iterate over the raw logs and unpacked data for AssetSold events raised by the Equity contract.
type EquityAssetSoldIterator struct {
	Event *EquityAssetSold // Event containing the contract specifics and raw log

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
func (it *EquityAssetSoldIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(EquityAssetSold)
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
		it.Event = new(EquityAssetSold)
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
func (it *EquityAssetSoldIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *EquityAssetSoldIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// EquityAssetSold represents a AssetSold event raised by the Equity contract.
type EquityAssetSold struct {
	AssetId    *big.Int
	Seller     common.Address
	TokenCount *big.Int
	Price      *big.Int
	Name       string
	Timestamp  *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterAssetSold is a free log retrieval operation binding the contract event 0xdde523e51717d516e9022c4c6526af7c6ff2a041912e3116b1107e29ef02122f.
//
// Solidity: event AssetSold(uint256 indexed assetId, address indexed seller, uint256 tokenCount, uint256 price, string name, uint256 timestamp)
func (_Equity *EquityFilterer) FilterAssetSold(opts *bind.FilterOpts, assetId []*big.Int, seller []common.Address) (*EquityAssetSoldIterator, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var sellerRule []interface{}
	for _, sellerItem := range seller {
		sellerRule = append(sellerRule, sellerItem)
	}

	logs, sub, err := _Equity.contract.FilterLogs(opts, "AssetSold", assetIdRule, sellerRule)
	if err != nil {
		return nil, err
	}
	return &EquityAssetSoldIterator{contract: _Equity.contract, event: "AssetSold", logs: logs, sub: sub}, nil
}

// WatchAssetSold is a free log subscription operation binding the contract event 0xdde523e51717d516e9022c4c6526af7c6ff2a041912e3116b1107e29ef02122f.
//
// Solidity: event AssetSold(uint256 indexed assetId, address indexed seller, uint256 tokenCount, uint256 price, string name, uint256 timestamp)
func (_Equity *EquityFilterer) WatchAssetSold(opts *bind.WatchOpts, sink chan<- *EquityAssetSold, assetId []*big.Int, seller []common.Address) (event.Subscription, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var sellerRule []interface{}
	for _, sellerItem := range seller {
		sellerRule = append(sellerRule, sellerItem)
	}

	logs, sub, err := _Equity.contract.WatchLogs(opts, "AssetSold", assetIdRule, sellerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(EquityAssetSold)
				if err := _Equity.contract.UnpackLog(event, "AssetSold", log); err != nil {
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

// ParseAssetSold is a log parse operation binding the contract event 0xdde523e51717d516e9022c4c6526af7c6ff2a041912e3116b1107e29ef02122f.
//
// Solidity: event AssetSold(uint256 indexed assetId, address indexed seller, uint256 tokenCount, uint256 price, string name, uint256 timestamp)
func (_Equity *EquityFilterer) ParseAssetSold(log types.Log) (*EquityAssetSold, error) {
	event := new(EquityAssetSold)
	if err := _Equity.contract.UnpackLog(event, "AssetSold", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// EquityInitializedIterator is returned from FilterInitialized and is used to iterate over the raw logs and unpacked data for Initialized events raised by the Equity contract.
type EquityInitializedIterator struct {
	Event *EquityInitialized // Event containing the contract specifics and raw log

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
func (it *EquityInitializedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(EquityInitialized)
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
		it.Event = new(EquityInitialized)
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
func (it *EquityInitializedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *EquityInitializedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// EquityInitialized represents a Initialized event raised by the Equity contract.
type EquityInitialized struct {
	Version uint64
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterInitialized is a free log retrieval operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_Equity *EquityFilterer) FilterInitialized(opts *bind.FilterOpts) (*EquityInitializedIterator, error) {

	logs, sub, err := _Equity.contract.FilterLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return &EquityInitializedIterator{contract: _Equity.contract, event: "Initialized", logs: logs, sub: sub}, nil
}

// WatchInitialized is a free log subscription operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_Equity *EquityFilterer) WatchInitialized(opts *bind.WatchOpts, sink chan<- *EquityInitialized) (event.Subscription, error) {

	logs, sub, err := _Equity.contract.WatchLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(EquityInitialized)
				if err := _Equity.contract.UnpackLog(event, "Initialized", log); err != nil {
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

// ParseInitialized is a log parse operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_Equity *EquityFilterer) ParseInitialized(log types.Log) (*EquityInitialized, error) {
	event := new(EquityInitialized)
	if err := _Equity.contract.UnpackLog(event, "Initialized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// EquityOwnershipTransferredIterator is returned from FilterOwnershipTransferred and is used to iterate over the raw logs and unpacked data for OwnershipTransferred events raised by the Equity contract.
type EquityOwnershipTransferredIterator struct {
	Event *EquityOwnershipTransferred // Event containing the contract specifics and raw log

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
func (it *EquityOwnershipTransferredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(EquityOwnershipTransferred)
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
		it.Event = new(EquityOwnershipTransferred)
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
func (it *EquityOwnershipTransferredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *EquityOwnershipTransferredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// EquityOwnershipTransferred represents a OwnershipTransferred event raised by the Equity contract.
type EquityOwnershipTransferred struct {
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterOwnershipTransferred is a free log retrieval operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_Equity *EquityFilterer) FilterOwnershipTransferred(opts *bind.FilterOpts, previousOwner []common.Address, newOwner []common.Address) (*EquityOwnershipTransferredIterator, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _Equity.contract.FilterLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return &EquityOwnershipTransferredIterator{contract: _Equity.contract, event: "OwnershipTransferred", logs: logs, sub: sub}, nil
}

// WatchOwnershipTransferred is a free log subscription operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_Equity *EquityFilterer) WatchOwnershipTransferred(opts *bind.WatchOpts, sink chan<- *EquityOwnershipTransferred, previousOwner []common.Address, newOwner []common.Address) (event.Subscription, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _Equity.contract.WatchLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(EquityOwnershipTransferred)
				if err := _Equity.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
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
func (_Equity *EquityFilterer) ParseOwnershipTransferred(log types.Log) (*EquityOwnershipTransferred, error) {
	event := new(EquityOwnershipTransferred)
	if err := _Equity.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// EquityTransferBatchIterator is returned from FilterTransferBatch and is used to iterate over the raw logs and unpacked data for TransferBatch events raised by the Equity contract.
type EquityTransferBatchIterator struct {
	Event *EquityTransferBatch // Event containing the contract specifics and raw log

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
func (it *EquityTransferBatchIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(EquityTransferBatch)
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
		it.Event = new(EquityTransferBatch)
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
func (it *EquityTransferBatchIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *EquityTransferBatchIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// EquityTransferBatch represents a TransferBatch event raised by the Equity contract.
type EquityTransferBatch struct {
	Operator common.Address
	From     common.Address
	To       common.Address
	Ids      []*big.Int
	Values   []*big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterTransferBatch is a free log retrieval operation binding the contract event 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb.
//
// Solidity: event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values)
func (_Equity *EquityFilterer) FilterTransferBatch(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*EquityTransferBatchIterator, error) {

	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}
	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _Equity.contract.FilterLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &EquityTransferBatchIterator{contract: _Equity.contract, event: "TransferBatch", logs: logs, sub: sub}, nil
}

// WatchTransferBatch is a free log subscription operation binding the contract event 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb.
//
// Solidity: event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values)
func (_Equity *EquityFilterer) WatchTransferBatch(opts *bind.WatchOpts, sink chan<- *EquityTransferBatch, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}
	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _Equity.contract.WatchLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(EquityTransferBatch)
				if err := _Equity.contract.UnpackLog(event, "TransferBatch", log); err != nil {
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

// ParseTransferBatch is a log parse operation binding the contract event 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb.
//
// Solidity: event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values)
func (_Equity *EquityFilterer) ParseTransferBatch(log types.Log) (*EquityTransferBatch, error) {
	event := new(EquityTransferBatch)
	if err := _Equity.contract.UnpackLog(event, "TransferBatch", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// EquityTransferSingleIterator is returned from FilterTransferSingle and is used to iterate over the raw logs and unpacked data for TransferSingle events raised by the Equity contract.
type EquityTransferSingleIterator struct {
	Event *EquityTransferSingle // Event containing the contract specifics and raw log

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
func (it *EquityTransferSingleIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(EquityTransferSingle)
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
		it.Event = new(EquityTransferSingle)
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
func (it *EquityTransferSingleIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *EquityTransferSingleIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// EquityTransferSingle represents a TransferSingle event raised by the Equity contract.
type EquityTransferSingle struct {
	Operator common.Address
	From     common.Address
	To       common.Address
	Id       *big.Int
	Value    *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterTransferSingle is a free log retrieval operation binding the contract event 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62.
//
// Solidity: event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)
func (_Equity *EquityFilterer) FilterTransferSingle(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*EquityTransferSingleIterator, error) {

	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}
	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _Equity.contract.FilterLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &EquityTransferSingleIterator{contract: _Equity.contract, event: "TransferSingle", logs: logs, sub: sub}, nil
}

// WatchTransferSingle is a free log subscription operation binding the contract event 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62.
//
// Solidity: event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)
func (_Equity *EquityFilterer) WatchTransferSingle(opts *bind.WatchOpts, sink chan<- *EquityTransferSingle, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}
	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _Equity.contract.WatchLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(EquityTransferSingle)
				if err := _Equity.contract.UnpackLog(event, "TransferSingle", log); err != nil {
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

// ParseTransferSingle is a log parse operation binding the contract event 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62.
//
// Solidity: event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)
func (_Equity *EquityFilterer) ParseTransferSingle(log types.Log) (*EquityTransferSingle, error) {
	event := new(EquityTransferSingle)
	if err := _Equity.contract.UnpackLog(event, "TransferSingle", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// EquityURIIterator is returned from FilterURI and is used to iterate over the raw logs and unpacked data for URI events raised by the Equity contract.
type EquityURIIterator struct {
	Event *EquityURI // Event containing the contract specifics and raw log

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
func (it *EquityURIIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(EquityURI)
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
		it.Event = new(EquityURI)
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
func (it *EquityURIIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *EquityURIIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// EquityURI represents a URI event raised by the Equity contract.
type EquityURI struct {
	Value string
	Id    *big.Int
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterURI is a free log retrieval operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_Equity *EquityFilterer) FilterURI(opts *bind.FilterOpts, id []*big.Int) (*EquityURIIterator, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _Equity.contract.FilterLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return &EquityURIIterator{contract: _Equity.contract, event: "URI", logs: logs, sub: sub}, nil
}

// WatchURI is a free log subscription operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_Equity *EquityFilterer) WatchURI(opts *bind.WatchOpts, sink chan<- *EquityURI, id []*big.Int) (event.Subscription, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _Equity.contract.WatchLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(EquityURI)
				if err := _Equity.contract.UnpackLog(event, "URI", log); err != nil {
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

// ParseURI is a log parse operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_Equity *EquityFilterer) ParseURI(log types.Log) (*EquityURI, error) {
	event := new(EquityURI)
	if err := _Equity.contract.UnpackLog(event, "URI", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// EquityUpgradedIterator is returned from FilterUpgraded and is used to iterate over the raw logs and unpacked data for Upgraded events raised by the Equity contract.
type EquityUpgradedIterator struct {
	Event *EquityUpgraded // Event containing the contract specifics and raw log

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
func (it *EquityUpgradedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(EquityUpgraded)
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
		it.Event = new(EquityUpgraded)
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
func (it *EquityUpgradedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *EquityUpgradedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// EquityUpgraded represents a Upgraded event raised by the Equity contract.
type EquityUpgraded struct {
	Implementation common.Address
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterUpgraded is a free log retrieval operation binding the contract event 0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b.
//
// Solidity: event Upgraded(address indexed implementation)
func (_Equity *EquityFilterer) FilterUpgraded(opts *bind.FilterOpts, implementation []common.Address) (*EquityUpgradedIterator, error) {

	var implementationRule []interface{}
	for _, implementationItem := range implementation {
		implementationRule = append(implementationRule, implementationItem)
	}

	logs, sub, err := _Equity.contract.FilterLogs(opts, "Upgraded", implementationRule)
	if err != nil {
		return nil, err
	}
	return &EquityUpgradedIterator{contract: _Equity.contract, event: "Upgraded", logs: logs, sub: sub}, nil
}

// WatchUpgraded is a free log subscription operation binding the contract event 0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b.
//
// Solidity: event Upgraded(address indexed implementation)
func (_Equity *EquityFilterer) WatchUpgraded(opts *bind.WatchOpts, sink chan<- *EquityUpgraded, implementation []common.Address) (event.Subscription, error) {

	var implementationRule []interface{}
	for _, implementationItem := range implementation {
		implementationRule = append(implementationRule, implementationItem)
	}

	logs, sub, err := _Equity.contract.WatchLogs(opts, "Upgraded", implementationRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(EquityUpgraded)
				if err := _Equity.contract.UnpackLog(event, "Upgraded", log); err != nil {
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

// ParseUpgraded is a log parse operation binding the contract event 0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b.
//
// Solidity: event Upgraded(address indexed implementation)
func (_Equity *EquityFilterer) ParseUpgraded(log types.Log) (*EquityUpgraded, error) {
	event := new(EquityUpgraded)
	if err := _Equity.contract.UnpackLog(event, "Upgraded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
