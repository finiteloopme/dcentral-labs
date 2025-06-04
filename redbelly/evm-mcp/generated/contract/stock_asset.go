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

// StockAssetMetaData contains all meta data concerning the StockAsset contract.
var StockAssetMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"initialOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"assetName\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"assetSymbol\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"assetTotalSupply\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOf\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOfBatch\",\"inputs\":[{\"name\":\"accounts\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"buy\",\"inputs\":[{\"name\":\"_id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"createStock\",\"inputs\":[{\"name\":\"initialName\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"initialSymbol\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"initialBuyPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"initialSellPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"initialTotalSupply\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getAllAssetIds\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getBuyPrice\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSellPrice\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isApprovedForAll\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"safeBatchTransferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"values\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"safeTransferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"sell\",\"inputs\":[{\"name\":\"_id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"setApprovalForAll\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"updatePrice\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"newBuyPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"newSellPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"updateTotalSupply\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"newTotalSupply\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"uri\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"ApprovalForAll\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AssetBought\",\"inputs\":[{\"name\":\"assetId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"buyer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"tokenCount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"price\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"name\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AssetIssued\",\"inputs\":[{\"name\":\"assetId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"totalSupply\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"initialPrice\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"name\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"symbol\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AssetSold\",\"inputs\":[{\"name\":\"assetId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"seller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"tokenCount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"price\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"name\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PriceUpdated\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"newBuyPrice\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"newSellPrice\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TotalSupplyUpdated\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"newTotalSupply\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferBatch\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"values\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferSingle\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"URI\",\"inputs\":[{\"name\":\"value\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ERC1155InsufficientBalance\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"needed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"tokenId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidApprover\",\"inputs\":[{\"name\":\"approver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidArrayLength\",\"inputs\":[{\"name\":\"idsLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"valuesLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidOperator\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidReceiver\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidSender\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155MissingApprovalForAll\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableInvalidOwner\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]}]",
}

// StockAssetABI is the input ABI used to generate the binding from.
// Deprecated: Use StockAssetMetaData.ABI instead.
var StockAssetABI = StockAssetMetaData.ABI

// StockAsset is an auto generated Go binding around an Ethereum contract.
type StockAsset struct {
	StockAssetCaller     // Read-only binding to the contract
	StockAssetTransactor // Write-only binding to the contract
	StockAssetFilterer   // Log filterer for contract events
}

// StockAssetCaller is an auto generated read-only Go binding around an Ethereum contract.
type StockAssetCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// StockAssetTransactor is an auto generated write-only Go binding around an Ethereum contract.
type StockAssetTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// StockAssetFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type StockAssetFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// StockAssetSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type StockAssetSession struct {
	Contract     *StockAsset       // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// StockAssetCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type StockAssetCallerSession struct {
	Contract *StockAssetCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts     // Call options to use throughout this session
}

// StockAssetTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type StockAssetTransactorSession struct {
	Contract     *StockAssetTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts     // Transaction auth options to use throughout this session
}

// StockAssetRaw is an auto generated low-level Go binding around an Ethereum contract.
type StockAssetRaw struct {
	Contract *StockAsset // Generic contract binding to access the raw methods on
}

// StockAssetCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type StockAssetCallerRaw struct {
	Contract *StockAssetCaller // Generic read-only contract binding to access the raw methods on
}

// StockAssetTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type StockAssetTransactorRaw struct {
	Contract *StockAssetTransactor // Generic write-only contract binding to access the raw methods on
}

// NewStockAsset creates a new instance of StockAsset, bound to a specific deployed contract.
func NewStockAsset(address common.Address, backend bind.ContractBackend) (*StockAsset, error) {
	contract, err := bindStockAsset(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &StockAsset{StockAssetCaller: StockAssetCaller{contract: contract}, StockAssetTransactor: StockAssetTransactor{contract: contract}, StockAssetFilterer: StockAssetFilterer{contract: contract}}, nil
}

// NewStockAssetCaller creates a new read-only instance of StockAsset, bound to a specific deployed contract.
func NewStockAssetCaller(address common.Address, caller bind.ContractCaller) (*StockAssetCaller, error) {
	contract, err := bindStockAsset(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &StockAssetCaller{contract: contract}, nil
}

// NewStockAssetTransactor creates a new write-only instance of StockAsset, bound to a specific deployed contract.
func NewStockAssetTransactor(address common.Address, transactor bind.ContractTransactor) (*StockAssetTransactor, error) {
	contract, err := bindStockAsset(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &StockAssetTransactor{contract: contract}, nil
}

// NewStockAssetFilterer creates a new log filterer instance of StockAsset, bound to a specific deployed contract.
func NewStockAssetFilterer(address common.Address, filterer bind.ContractFilterer) (*StockAssetFilterer, error) {
	contract, err := bindStockAsset(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &StockAssetFilterer{contract: contract}, nil
}

// bindStockAsset binds a generic wrapper to an already deployed contract.
func bindStockAsset(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := StockAssetMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_StockAsset *StockAssetRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _StockAsset.Contract.StockAssetCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_StockAsset *StockAssetRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _StockAsset.Contract.StockAssetTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_StockAsset *StockAssetRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _StockAsset.Contract.StockAssetTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_StockAsset *StockAssetCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _StockAsset.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_StockAsset *StockAssetTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _StockAsset.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_StockAsset *StockAssetTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _StockAsset.Contract.contract.Transact(opts, method, params...)
}

// AssetName is a free data retrieval call binding the contract method 0x01a3543d.
//
// Solidity: function assetName(uint256 id) view returns(string)
func (_StockAsset *StockAssetCaller) AssetName(opts *bind.CallOpts, id *big.Int) (string, error) {
	var out []interface{}
	err := _StockAsset.contract.Call(opts, &out, "assetName", id)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// AssetName is a free data retrieval call binding the contract method 0x01a3543d.
//
// Solidity: function assetName(uint256 id) view returns(string)
func (_StockAsset *StockAssetSession) AssetName(id *big.Int) (string, error) {
	return _StockAsset.Contract.AssetName(&_StockAsset.CallOpts, id)
}

// AssetName is a free data retrieval call binding the contract method 0x01a3543d.
//
// Solidity: function assetName(uint256 id) view returns(string)
func (_StockAsset *StockAssetCallerSession) AssetName(id *big.Int) (string, error) {
	return _StockAsset.Contract.AssetName(&_StockAsset.CallOpts, id)
}

// AssetSymbol is a free data retrieval call binding the contract method 0xf701fd0a.
//
// Solidity: function assetSymbol(uint256 id) view returns(string)
func (_StockAsset *StockAssetCaller) AssetSymbol(opts *bind.CallOpts, id *big.Int) (string, error) {
	var out []interface{}
	err := _StockAsset.contract.Call(opts, &out, "assetSymbol", id)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// AssetSymbol is a free data retrieval call binding the contract method 0xf701fd0a.
//
// Solidity: function assetSymbol(uint256 id) view returns(string)
func (_StockAsset *StockAssetSession) AssetSymbol(id *big.Int) (string, error) {
	return _StockAsset.Contract.AssetSymbol(&_StockAsset.CallOpts, id)
}

// AssetSymbol is a free data retrieval call binding the contract method 0xf701fd0a.
//
// Solidity: function assetSymbol(uint256 id) view returns(string)
func (_StockAsset *StockAssetCallerSession) AssetSymbol(id *big.Int) (string, error) {
	return _StockAsset.Contract.AssetSymbol(&_StockAsset.CallOpts, id)
}

// AssetTotalSupply is a free data retrieval call binding the contract method 0x1cce6ef5.
//
// Solidity: function assetTotalSupply(uint256 id) view returns(uint256)
func (_StockAsset *StockAssetCaller) AssetTotalSupply(opts *bind.CallOpts, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _StockAsset.contract.Call(opts, &out, "assetTotalSupply", id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AssetTotalSupply is a free data retrieval call binding the contract method 0x1cce6ef5.
//
// Solidity: function assetTotalSupply(uint256 id) view returns(uint256)
func (_StockAsset *StockAssetSession) AssetTotalSupply(id *big.Int) (*big.Int, error) {
	return _StockAsset.Contract.AssetTotalSupply(&_StockAsset.CallOpts, id)
}

// AssetTotalSupply is a free data retrieval call binding the contract method 0x1cce6ef5.
//
// Solidity: function assetTotalSupply(uint256 id) view returns(uint256)
func (_StockAsset *StockAssetCallerSession) AssetTotalSupply(id *big.Int) (*big.Int, error) {
	return _StockAsset.Contract.AssetTotalSupply(&_StockAsset.CallOpts, id)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_StockAsset *StockAssetCaller) BalanceOf(opts *bind.CallOpts, account common.Address, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _StockAsset.contract.Call(opts, &out, "balanceOf", account, id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_StockAsset *StockAssetSession) BalanceOf(account common.Address, id *big.Int) (*big.Int, error) {
	return _StockAsset.Contract.BalanceOf(&_StockAsset.CallOpts, account, id)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_StockAsset *StockAssetCallerSession) BalanceOf(account common.Address, id *big.Int) (*big.Int, error) {
	return _StockAsset.Contract.BalanceOf(&_StockAsset.CallOpts, account, id)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_StockAsset *StockAssetCaller) BalanceOfBatch(opts *bind.CallOpts, accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	var out []interface{}
	err := _StockAsset.contract.Call(opts, &out, "balanceOfBatch", accounts, ids)

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_StockAsset *StockAssetSession) BalanceOfBatch(accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _StockAsset.Contract.BalanceOfBatch(&_StockAsset.CallOpts, accounts, ids)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_StockAsset *StockAssetCallerSession) BalanceOfBatch(accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _StockAsset.Contract.BalanceOfBatch(&_StockAsset.CallOpts, accounts, ids)
}

// GetAllAssetIds is a free data retrieval call binding the contract method 0xe122f907.
//
// Solidity: function getAllAssetIds() view returns(uint256[])
func (_StockAsset *StockAssetCaller) GetAllAssetIds(opts *bind.CallOpts) ([]*big.Int, error) {
	var out []interface{}
	err := _StockAsset.contract.Call(opts, &out, "getAllAssetIds")

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// GetAllAssetIds is a free data retrieval call binding the contract method 0xe122f907.
//
// Solidity: function getAllAssetIds() view returns(uint256[])
func (_StockAsset *StockAssetSession) GetAllAssetIds() ([]*big.Int, error) {
	return _StockAsset.Contract.GetAllAssetIds(&_StockAsset.CallOpts)
}

// GetAllAssetIds is a free data retrieval call binding the contract method 0xe122f907.
//
// Solidity: function getAllAssetIds() view returns(uint256[])
func (_StockAsset *StockAssetCallerSession) GetAllAssetIds() ([]*big.Int, error) {
	return _StockAsset.Contract.GetAllAssetIds(&_StockAsset.CallOpts)
}

// GetBuyPrice is a free data retrieval call binding the contract method 0x08d4db14.
//
// Solidity: function getBuyPrice(uint256 id) view returns(uint256)
func (_StockAsset *StockAssetCaller) GetBuyPrice(opts *bind.CallOpts, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _StockAsset.contract.Call(opts, &out, "getBuyPrice", id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetBuyPrice is a free data retrieval call binding the contract method 0x08d4db14.
//
// Solidity: function getBuyPrice(uint256 id) view returns(uint256)
func (_StockAsset *StockAssetSession) GetBuyPrice(id *big.Int) (*big.Int, error) {
	return _StockAsset.Contract.GetBuyPrice(&_StockAsset.CallOpts, id)
}

// GetBuyPrice is a free data retrieval call binding the contract method 0x08d4db14.
//
// Solidity: function getBuyPrice(uint256 id) view returns(uint256)
func (_StockAsset *StockAssetCallerSession) GetBuyPrice(id *big.Int) (*big.Int, error) {
	return _StockAsset.Contract.GetBuyPrice(&_StockAsset.CallOpts, id)
}

// GetSellPrice is a free data retrieval call binding the contract method 0xba730e53.
//
// Solidity: function getSellPrice(uint256 id) view returns(uint256)
func (_StockAsset *StockAssetCaller) GetSellPrice(opts *bind.CallOpts, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _StockAsset.contract.Call(opts, &out, "getSellPrice", id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetSellPrice is a free data retrieval call binding the contract method 0xba730e53.
//
// Solidity: function getSellPrice(uint256 id) view returns(uint256)
func (_StockAsset *StockAssetSession) GetSellPrice(id *big.Int) (*big.Int, error) {
	return _StockAsset.Contract.GetSellPrice(&_StockAsset.CallOpts, id)
}

// GetSellPrice is a free data retrieval call binding the contract method 0xba730e53.
//
// Solidity: function getSellPrice(uint256 id) view returns(uint256)
func (_StockAsset *StockAssetCallerSession) GetSellPrice(id *big.Int) (*big.Int, error) {
	return _StockAsset.Contract.GetSellPrice(&_StockAsset.CallOpts, id)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_StockAsset *StockAssetCaller) IsApprovedForAll(opts *bind.CallOpts, account common.Address, operator common.Address) (bool, error) {
	var out []interface{}
	err := _StockAsset.contract.Call(opts, &out, "isApprovedForAll", account, operator)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_StockAsset *StockAssetSession) IsApprovedForAll(account common.Address, operator common.Address) (bool, error) {
	return _StockAsset.Contract.IsApprovedForAll(&_StockAsset.CallOpts, account, operator)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_StockAsset *StockAssetCallerSession) IsApprovedForAll(account common.Address, operator common.Address) (bool, error) {
	return _StockAsset.Contract.IsApprovedForAll(&_StockAsset.CallOpts, account, operator)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_StockAsset *StockAssetCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _StockAsset.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_StockAsset *StockAssetSession) Owner() (common.Address, error) {
	return _StockAsset.Contract.Owner(&_StockAsset.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_StockAsset *StockAssetCallerSession) Owner() (common.Address, error) {
	return _StockAsset.Contract.Owner(&_StockAsset.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_StockAsset *StockAssetCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _StockAsset.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_StockAsset *StockAssetSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _StockAsset.Contract.SupportsInterface(&_StockAsset.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_StockAsset *StockAssetCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _StockAsset.Contract.SupportsInterface(&_StockAsset.CallOpts, interfaceId)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 id) view returns(string)
func (_StockAsset *StockAssetCaller) Uri(opts *bind.CallOpts, id *big.Int) (string, error) {
	var out []interface{}
	err := _StockAsset.contract.Call(opts, &out, "uri", id)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 id) view returns(string)
func (_StockAsset *StockAssetSession) Uri(id *big.Int) (string, error) {
	return _StockAsset.Contract.Uri(&_StockAsset.CallOpts, id)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 id) view returns(string)
func (_StockAsset *StockAssetCallerSession) Uri(id *big.Int) (string, error) {
	return _StockAsset.Contract.Uri(&_StockAsset.CallOpts, id)
}

// Buy is a paid mutator transaction binding the contract method 0xd96a094a.
//
// Solidity: function buy(uint256 _id) payable returns()
func (_StockAsset *StockAssetTransactor) Buy(opts *bind.TransactOpts, _id *big.Int) (*types.Transaction, error) {
	return _StockAsset.contract.Transact(opts, "buy", _id)
}

// Buy is a paid mutator transaction binding the contract method 0xd96a094a.
//
// Solidity: function buy(uint256 _id) payable returns()
func (_StockAsset *StockAssetSession) Buy(_id *big.Int) (*types.Transaction, error) {
	return _StockAsset.Contract.Buy(&_StockAsset.TransactOpts, _id)
}

// Buy is a paid mutator transaction binding the contract method 0xd96a094a.
//
// Solidity: function buy(uint256 _id) payable returns()
func (_StockAsset *StockAssetTransactorSession) Buy(_id *big.Int) (*types.Transaction, error) {
	return _StockAsset.Contract.Buy(&_StockAsset.TransactOpts, _id)
}

// CreateStock is a paid mutator transaction binding the contract method 0xbc08cd73.
//
// Solidity: function createStock(string initialName, string initialSymbol, uint256 initialBuyPrice, uint256 initialSellPrice, uint256 initialTotalSupply) returns(uint256)
func (_StockAsset *StockAssetTransactor) CreateStock(opts *bind.TransactOpts, initialName string, initialSymbol string, initialBuyPrice *big.Int, initialSellPrice *big.Int, initialTotalSupply *big.Int) (*types.Transaction, error) {
	return _StockAsset.contract.Transact(opts, "createStock", initialName, initialSymbol, initialBuyPrice, initialSellPrice, initialTotalSupply)
}

// CreateStock is a paid mutator transaction binding the contract method 0xbc08cd73.
//
// Solidity: function createStock(string initialName, string initialSymbol, uint256 initialBuyPrice, uint256 initialSellPrice, uint256 initialTotalSupply) returns(uint256)
func (_StockAsset *StockAssetSession) CreateStock(initialName string, initialSymbol string, initialBuyPrice *big.Int, initialSellPrice *big.Int, initialTotalSupply *big.Int) (*types.Transaction, error) {
	return _StockAsset.Contract.CreateStock(&_StockAsset.TransactOpts, initialName, initialSymbol, initialBuyPrice, initialSellPrice, initialTotalSupply)
}

// CreateStock is a paid mutator transaction binding the contract method 0xbc08cd73.
//
// Solidity: function createStock(string initialName, string initialSymbol, uint256 initialBuyPrice, uint256 initialSellPrice, uint256 initialTotalSupply) returns(uint256)
func (_StockAsset *StockAssetTransactorSession) CreateStock(initialName string, initialSymbol string, initialBuyPrice *big.Int, initialSellPrice *big.Int, initialTotalSupply *big.Int) (*types.Transaction, error) {
	return _StockAsset.Contract.CreateStock(&_StockAsset.TransactOpts, initialName, initialSymbol, initialBuyPrice, initialSellPrice, initialTotalSupply)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_StockAsset *StockAssetTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _StockAsset.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_StockAsset *StockAssetSession) RenounceOwnership() (*types.Transaction, error) {
	return _StockAsset.Contract.RenounceOwnership(&_StockAsset.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_StockAsset *StockAssetTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _StockAsset.Contract.RenounceOwnership(&_StockAsset.TransactOpts)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_StockAsset *StockAssetTransactor) SafeBatchTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _StockAsset.contract.Transact(opts, "safeBatchTransferFrom", from, to, ids, values, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_StockAsset *StockAssetSession) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _StockAsset.Contract.SafeBatchTransferFrom(&_StockAsset.TransactOpts, from, to, ids, values, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_StockAsset *StockAssetTransactorSession) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _StockAsset.Contract.SafeBatchTransferFrom(&_StockAsset.TransactOpts, from, to, ids, values, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_StockAsset *StockAssetTransactor) SafeTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _StockAsset.contract.Transact(opts, "safeTransferFrom", from, to, id, value, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_StockAsset *StockAssetSession) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _StockAsset.Contract.SafeTransferFrom(&_StockAsset.TransactOpts, from, to, id, value, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_StockAsset *StockAssetTransactorSession) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _StockAsset.Contract.SafeTransferFrom(&_StockAsset.TransactOpts, from, to, id, value, data)
}

// Sell is a paid mutator transaction binding the contract method 0xe4849b32.
//
// Solidity: function sell(uint256 _id) payable returns()
func (_StockAsset *StockAssetTransactor) Sell(opts *bind.TransactOpts, _id *big.Int) (*types.Transaction, error) {
	return _StockAsset.contract.Transact(opts, "sell", _id)
}

// Sell is a paid mutator transaction binding the contract method 0xe4849b32.
//
// Solidity: function sell(uint256 _id) payable returns()
func (_StockAsset *StockAssetSession) Sell(_id *big.Int) (*types.Transaction, error) {
	return _StockAsset.Contract.Sell(&_StockAsset.TransactOpts, _id)
}

// Sell is a paid mutator transaction binding the contract method 0xe4849b32.
//
// Solidity: function sell(uint256 _id) payable returns()
func (_StockAsset *StockAssetTransactorSession) Sell(_id *big.Int) (*types.Transaction, error) {
	return _StockAsset.Contract.Sell(&_StockAsset.TransactOpts, _id)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_StockAsset *StockAssetTransactor) SetApprovalForAll(opts *bind.TransactOpts, operator common.Address, approved bool) (*types.Transaction, error) {
	return _StockAsset.contract.Transact(opts, "setApprovalForAll", operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_StockAsset *StockAssetSession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _StockAsset.Contract.SetApprovalForAll(&_StockAsset.TransactOpts, operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_StockAsset *StockAssetTransactorSession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _StockAsset.Contract.SetApprovalForAll(&_StockAsset.TransactOpts, operator, approved)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_StockAsset *StockAssetTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _StockAsset.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_StockAsset *StockAssetSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _StockAsset.Contract.TransferOwnership(&_StockAsset.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_StockAsset *StockAssetTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _StockAsset.Contract.TransferOwnership(&_StockAsset.TransactOpts, newOwner)
}

// UpdatePrice is a paid mutator transaction binding the contract method 0x0f436129.
//
// Solidity: function updatePrice(uint256 id, uint256 newBuyPrice, uint256 newSellPrice) returns()
func (_StockAsset *StockAssetTransactor) UpdatePrice(opts *bind.TransactOpts, id *big.Int, newBuyPrice *big.Int, newSellPrice *big.Int) (*types.Transaction, error) {
	return _StockAsset.contract.Transact(opts, "updatePrice", id, newBuyPrice, newSellPrice)
}

// UpdatePrice is a paid mutator transaction binding the contract method 0x0f436129.
//
// Solidity: function updatePrice(uint256 id, uint256 newBuyPrice, uint256 newSellPrice) returns()
func (_StockAsset *StockAssetSession) UpdatePrice(id *big.Int, newBuyPrice *big.Int, newSellPrice *big.Int) (*types.Transaction, error) {
	return _StockAsset.Contract.UpdatePrice(&_StockAsset.TransactOpts, id, newBuyPrice, newSellPrice)
}

// UpdatePrice is a paid mutator transaction binding the contract method 0x0f436129.
//
// Solidity: function updatePrice(uint256 id, uint256 newBuyPrice, uint256 newSellPrice) returns()
func (_StockAsset *StockAssetTransactorSession) UpdatePrice(id *big.Int, newBuyPrice *big.Int, newSellPrice *big.Int) (*types.Transaction, error) {
	return _StockAsset.Contract.UpdatePrice(&_StockAsset.TransactOpts, id, newBuyPrice, newSellPrice)
}

// UpdateTotalSupply is a paid mutator transaction binding the contract method 0xf8b4ab7a.
//
// Solidity: function updateTotalSupply(uint256 id, uint256 newTotalSupply) returns()
func (_StockAsset *StockAssetTransactor) UpdateTotalSupply(opts *bind.TransactOpts, id *big.Int, newTotalSupply *big.Int) (*types.Transaction, error) {
	return _StockAsset.contract.Transact(opts, "updateTotalSupply", id, newTotalSupply)
}

// UpdateTotalSupply is a paid mutator transaction binding the contract method 0xf8b4ab7a.
//
// Solidity: function updateTotalSupply(uint256 id, uint256 newTotalSupply) returns()
func (_StockAsset *StockAssetSession) UpdateTotalSupply(id *big.Int, newTotalSupply *big.Int) (*types.Transaction, error) {
	return _StockAsset.Contract.UpdateTotalSupply(&_StockAsset.TransactOpts, id, newTotalSupply)
}

// UpdateTotalSupply is a paid mutator transaction binding the contract method 0xf8b4ab7a.
//
// Solidity: function updateTotalSupply(uint256 id, uint256 newTotalSupply) returns()
func (_StockAsset *StockAssetTransactorSession) UpdateTotalSupply(id *big.Int, newTotalSupply *big.Int) (*types.Transaction, error) {
	return _StockAsset.Contract.UpdateTotalSupply(&_StockAsset.TransactOpts, id, newTotalSupply)
}

// StockAssetApprovalForAllIterator is returned from FilterApprovalForAll and is used to iterate over the raw logs and unpacked data for ApprovalForAll events raised by the StockAsset contract.
type StockAssetApprovalForAllIterator struct {
	Event *StockAssetApprovalForAll // Event containing the contract specifics and raw log

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
func (it *StockAssetApprovalForAllIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(StockAssetApprovalForAll)
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
		it.Event = new(StockAssetApprovalForAll)
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
func (it *StockAssetApprovalForAllIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *StockAssetApprovalForAllIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// StockAssetApprovalForAll represents a ApprovalForAll event raised by the StockAsset contract.
type StockAssetApprovalForAll struct {
	Account  common.Address
	Operator common.Address
	Approved bool
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterApprovalForAll is a free log retrieval operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_StockAsset *StockAssetFilterer) FilterApprovalForAll(opts *bind.FilterOpts, account []common.Address, operator []common.Address) (*StockAssetApprovalForAllIterator, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _StockAsset.contract.FilterLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return &StockAssetApprovalForAllIterator{contract: _StockAsset.contract, event: "ApprovalForAll", logs: logs, sub: sub}, nil
}

// WatchApprovalForAll is a free log subscription operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_StockAsset *StockAssetFilterer) WatchApprovalForAll(opts *bind.WatchOpts, sink chan<- *StockAssetApprovalForAll, account []common.Address, operator []common.Address) (event.Subscription, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _StockAsset.contract.WatchLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(StockAssetApprovalForAll)
				if err := _StockAsset.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
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
func (_StockAsset *StockAssetFilterer) ParseApprovalForAll(log types.Log) (*StockAssetApprovalForAll, error) {
	event := new(StockAssetApprovalForAll)
	if err := _StockAsset.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// StockAssetAssetBoughtIterator is returned from FilterAssetBought and is used to iterate over the raw logs and unpacked data for AssetBought events raised by the StockAsset contract.
type StockAssetAssetBoughtIterator struct {
	Event *StockAssetAssetBought // Event containing the contract specifics and raw log

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
func (it *StockAssetAssetBoughtIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(StockAssetAssetBought)
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
		it.Event = new(StockAssetAssetBought)
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
func (it *StockAssetAssetBoughtIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *StockAssetAssetBoughtIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// StockAssetAssetBought represents a AssetBought event raised by the StockAsset contract.
type StockAssetAssetBought struct {
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
func (_StockAsset *StockAssetFilterer) FilterAssetBought(opts *bind.FilterOpts, assetId []*big.Int, buyer []common.Address) (*StockAssetAssetBoughtIterator, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var buyerRule []interface{}
	for _, buyerItem := range buyer {
		buyerRule = append(buyerRule, buyerItem)
	}

	logs, sub, err := _StockAsset.contract.FilterLogs(opts, "AssetBought", assetIdRule, buyerRule)
	if err != nil {
		return nil, err
	}
	return &StockAssetAssetBoughtIterator{contract: _StockAsset.contract, event: "AssetBought", logs: logs, sub: sub}, nil
}

// WatchAssetBought is a free log subscription operation binding the contract event 0xc4dd2b242df23335f8c79c84c12590a02f2c96864fc80967d45a637d0c933e39.
//
// Solidity: event AssetBought(uint256 indexed assetId, address indexed buyer, uint256 tokenCount, uint256 price, string name, uint256 timestamp)
func (_StockAsset *StockAssetFilterer) WatchAssetBought(opts *bind.WatchOpts, sink chan<- *StockAssetAssetBought, assetId []*big.Int, buyer []common.Address) (event.Subscription, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var buyerRule []interface{}
	for _, buyerItem := range buyer {
		buyerRule = append(buyerRule, buyerItem)
	}

	logs, sub, err := _StockAsset.contract.WatchLogs(opts, "AssetBought", assetIdRule, buyerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(StockAssetAssetBought)
				if err := _StockAsset.contract.UnpackLog(event, "AssetBought", log); err != nil {
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
func (_StockAsset *StockAssetFilterer) ParseAssetBought(log types.Log) (*StockAssetAssetBought, error) {
	event := new(StockAssetAssetBought)
	if err := _StockAsset.contract.UnpackLog(event, "AssetBought", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// StockAssetAssetIssuedIterator is returned from FilterAssetIssued and is used to iterate over the raw logs and unpacked data for AssetIssued events raised by the StockAsset contract.
type StockAssetAssetIssuedIterator struct {
	Event *StockAssetAssetIssued // Event containing the contract specifics and raw log

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
func (it *StockAssetAssetIssuedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(StockAssetAssetIssued)
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
		it.Event = new(StockAssetAssetIssued)
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
func (it *StockAssetAssetIssuedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *StockAssetAssetIssuedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// StockAssetAssetIssued represents a AssetIssued event raised by the StockAsset contract.
type StockAssetAssetIssued struct {
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
func (_StockAsset *StockAssetFilterer) FilterAssetIssued(opts *bind.FilterOpts, assetId []*big.Int, to []common.Address) (*StockAssetAssetIssuedIterator, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _StockAsset.contract.FilterLogs(opts, "AssetIssued", assetIdRule, toRule)
	if err != nil {
		return nil, err
	}
	return &StockAssetAssetIssuedIterator{contract: _StockAsset.contract, event: "AssetIssued", logs: logs, sub: sub}, nil
}

// WatchAssetIssued is a free log subscription operation binding the contract event 0xe91aa54204e7e68ec3c978f25679bd4982f4bcee900ee74aca5cdfa20fc9abfe.
//
// Solidity: event AssetIssued(uint256 indexed assetId, address indexed to, uint256 totalSupply, uint256 initialPrice, string name, string symbol, uint256 timestamp)
func (_StockAsset *StockAssetFilterer) WatchAssetIssued(opts *bind.WatchOpts, sink chan<- *StockAssetAssetIssued, assetId []*big.Int, to []common.Address) (event.Subscription, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _StockAsset.contract.WatchLogs(opts, "AssetIssued", assetIdRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(StockAssetAssetIssued)
				if err := _StockAsset.contract.UnpackLog(event, "AssetIssued", log); err != nil {
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
func (_StockAsset *StockAssetFilterer) ParseAssetIssued(log types.Log) (*StockAssetAssetIssued, error) {
	event := new(StockAssetAssetIssued)
	if err := _StockAsset.contract.UnpackLog(event, "AssetIssued", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// StockAssetAssetSoldIterator is returned from FilterAssetSold and is used to iterate over the raw logs and unpacked data for AssetSold events raised by the StockAsset contract.
type StockAssetAssetSoldIterator struct {
	Event *StockAssetAssetSold // Event containing the contract specifics and raw log

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
func (it *StockAssetAssetSoldIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(StockAssetAssetSold)
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
		it.Event = new(StockAssetAssetSold)
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
func (it *StockAssetAssetSoldIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *StockAssetAssetSoldIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// StockAssetAssetSold represents a AssetSold event raised by the StockAsset contract.
type StockAssetAssetSold struct {
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
func (_StockAsset *StockAssetFilterer) FilterAssetSold(opts *bind.FilterOpts, assetId []*big.Int, seller []common.Address) (*StockAssetAssetSoldIterator, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var sellerRule []interface{}
	for _, sellerItem := range seller {
		sellerRule = append(sellerRule, sellerItem)
	}

	logs, sub, err := _StockAsset.contract.FilterLogs(opts, "AssetSold", assetIdRule, sellerRule)
	if err != nil {
		return nil, err
	}
	return &StockAssetAssetSoldIterator{contract: _StockAsset.contract, event: "AssetSold", logs: logs, sub: sub}, nil
}

// WatchAssetSold is a free log subscription operation binding the contract event 0xdde523e51717d516e9022c4c6526af7c6ff2a041912e3116b1107e29ef02122f.
//
// Solidity: event AssetSold(uint256 indexed assetId, address indexed seller, uint256 tokenCount, uint256 price, string name, uint256 timestamp)
func (_StockAsset *StockAssetFilterer) WatchAssetSold(opts *bind.WatchOpts, sink chan<- *StockAssetAssetSold, assetId []*big.Int, seller []common.Address) (event.Subscription, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var sellerRule []interface{}
	for _, sellerItem := range seller {
		sellerRule = append(sellerRule, sellerItem)
	}

	logs, sub, err := _StockAsset.contract.WatchLogs(opts, "AssetSold", assetIdRule, sellerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(StockAssetAssetSold)
				if err := _StockAsset.contract.UnpackLog(event, "AssetSold", log); err != nil {
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
func (_StockAsset *StockAssetFilterer) ParseAssetSold(log types.Log) (*StockAssetAssetSold, error) {
	event := new(StockAssetAssetSold)
	if err := _StockAsset.contract.UnpackLog(event, "AssetSold", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// StockAssetOwnershipTransferredIterator is returned from FilterOwnershipTransferred and is used to iterate over the raw logs and unpacked data for OwnershipTransferred events raised by the StockAsset contract.
type StockAssetOwnershipTransferredIterator struct {
	Event *StockAssetOwnershipTransferred // Event containing the contract specifics and raw log

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
func (it *StockAssetOwnershipTransferredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(StockAssetOwnershipTransferred)
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
		it.Event = new(StockAssetOwnershipTransferred)
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
func (it *StockAssetOwnershipTransferredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *StockAssetOwnershipTransferredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// StockAssetOwnershipTransferred represents a OwnershipTransferred event raised by the StockAsset contract.
type StockAssetOwnershipTransferred struct {
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterOwnershipTransferred is a free log retrieval operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_StockAsset *StockAssetFilterer) FilterOwnershipTransferred(opts *bind.FilterOpts, previousOwner []common.Address, newOwner []common.Address) (*StockAssetOwnershipTransferredIterator, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _StockAsset.contract.FilterLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return &StockAssetOwnershipTransferredIterator{contract: _StockAsset.contract, event: "OwnershipTransferred", logs: logs, sub: sub}, nil
}

// WatchOwnershipTransferred is a free log subscription operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_StockAsset *StockAssetFilterer) WatchOwnershipTransferred(opts *bind.WatchOpts, sink chan<- *StockAssetOwnershipTransferred, previousOwner []common.Address, newOwner []common.Address) (event.Subscription, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _StockAsset.contract.WatchLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(StockAssetOwnershipTransferred)
				if err := _StockAsset.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
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
func (_StockAsset *StockAssetFilterer) ParseOwnershipTransferred(log types.Log) (*StockAssetOwnershipTransferred, error) {
	event := new(StockAssetOwnershipTransferred)
	if err := _StockAsset.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// StockAssetPriceUpdatedIterator is returned from FilterPriceUpdated and is used to iterate over the raw logs and unpacked data for PriceUpdated events raised by the StockAsset contract.
type StockAssetPriceUpdatedIterator struct {
	Event *StockAssetPriceUpdated // Event containing the contract specifics and raw log

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
func (it *StockAssetPriceUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(StockAssetPriceUpdated)
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
		it.Event = new(StockAssetPriceUpdated)
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
func (it *StockAssetPriceUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *StockAssetPriceUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// StockAssetPriceUpdated represents a PriceUpdated event raised by the StockAsset contract.
type StockAssetPriceUpdated struct {
	Id           *big.Int
	NewBuyPrice  *big.Int
	NewSellPrice *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterPriceUpdated is a free log retrieval operation binding the contract event 0x15819dd2fd9f6418b142e798d08a18d0bf06ea368f4480b7b0d3f75bd966bc48.
//
// Solidity: event PriceUpdated(uint256 indexed id, uint256 newBuyPrice, uint256 newSellPrice)
func (_StockAsset *StockAssetFilterer) FilterPriceUpdated(opts *bind.FilterOpts, id []*big.Int) (*StockAssetPriceUpdatedIterator, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _StockAsset.contract.FilterLogs(opts, "PriceUpdated", idRule)
	if err != nil {
		return nil, err
	}
	return &StockAssetPriceUpdatedIterator{contract: _StockAsset.contract, event: "PriceUpdated", logs: logs, sub: sub}, nil
}

// WatchPriceUpdated is a free log subscription operation binding the contract event 0x15819dd2fd9f6418b142e798d08a18d0bf06ea368f4480b7b0d3f75bd966bc48.
//
// Solidity: event PriceUpdated(uint256 indexed id, uint256 newBuyPrice, uint256 newSellPrice)
func (_StockAsset *StockAssetFilterer) WatchPriceUpdated(opts *bind.WatchOpts, sink chan<- *StockAssetPriceUpdated, id []*big.Int) (event.Subscription, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _StockAsset.contract.WatchLogs(opts, "PriceUpdated", idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(StockAssetPriceUpdated)
				if err := _StockAsset.contract.UnpackLog(event, "PriceUpdated", log); err != nil {
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

// ParsePriceUpdated is a log parse operation binding the contract event 0x15819dd2fd9f6418b142e798d08a18d0bf06ea368f4480b7b0d3f75bd966bc48.
//
// Solidity: event PriceUpdated(uint256 indexed id, uint256 newBuyPrice, uint256 newSellPrice)
func (_StockAsset *StockAssetFilterer) ParsePriceUpdated(log types.Log) (*StockAssetPriceUpdated, error) {
	event := new(StockAssetPriceUpdated)
	if err := _StockAsset.contract.UnpackLog(event, "PriceUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// StockAssetTotalSupplyUpdatedIterator is returned from FilterTotalSupplyUpdated and is used to iterate over the raw logs and unpacked data for TotalSupplyUpdated events raised by the StockAsset contract.
type StockAssetTotalSupplyUpdatedIterator struct {
	Event *StockAssetTotalSupplyUpdated // Event containing the contract specifics and raw log

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
func (it *StockAssetTotalSupplyUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(StockAssetTotalSupplyUpdated)
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
		it.Event = new(StockAssetTotalSupplyUpdated)
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
func (it *StockAssetTotalSupplyUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *StockAssetTotalSupplyUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// StockAssetTotalSupplyUpdated represents a TotalSupplyUpdated event raised by the StockAsset contract.
type StockAssetTotalSupplyUpdated struct {
	Id             *big.Int
	NewTotalSupply *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterTotalSupplyUpdated is a free log retrieval operation binding the contract event 0xd847752640337969f783ba291f56251d6165ba92dd3d27984ad0f81995aef0b6.
//
// Solidity: event TotalSupplyUpdated(uint256 indexed id, uint256 newTotalSupply)
func (_StockAsset *StockAssetFilterer) FilterTotalSupplyUpdated(opts *bind.FilterOpts, id []*big.Int) (*StockAssetTotalSupplyUpdatedIterator, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _StockAsset.contract.FilterLogs(opts, "TotalSupplyUpdated", idRule)
	if err != nil {
		return nil, err
	}
	return &StockAssetTotalSupplyUpdatedIterator{contract: _StockAsset.contract, event: "TotalSupplyUpdated", logs: logs, sub: sub}, nil
}

// WatchTotalSupplyUpdated is a free log subscription operation binding the contract event 0xd847752640337969f783ba291f56251d6165ba92dd3d27984ad0f81995aef0b6.
//
// Solidity: event TotalSupplyUpdated(uint256 indexed id, uint256 newTotalSupply)
func (_StockAsset *StockAssetFilterer) WatchTotalSupplyUpdated(opts *bind.WatchOpts, sink chan<- *StockAssetTotalSupplyUpdated, id []*big.Int) (event.Subscription, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _StockAsset.contract.WatchLogs(opts, "TotalSupplyUpdated", idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(StockAssetTotalSupplyUpdated)
				if err := _StockAsset.contract.UnpackLog(event, "TotalSupplyUpdated", log); err != nil {
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

// ParseTotalSupplyUpdated is a log parse operation binding the contract event 0xd847752640337969f783ba291f56251d6165ba92dd3d27984ad0f81995aef0b6.
//
// Solidity: event TotalSupplyUpdated(uint256 indexed id, uint256 newTotalSupply)
func (_StockAsset *StockAssetFilterer) ParseTotalSupplyUpdated(log types.Log) (*StockAssetTotalSupplyUpdated, error) {
	event := new(StockAssetTotalSupplyUpdated)
	if err := _StockAsset.contract.UnpackLog(event, "TotalSupplyUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// StockAssetTransferBatchIterator is returned from FilterTransferBatch and is used to iterate over the raw logs and unpacked data for TransferBatch events raised by the StockAsset contract.
type StockAssetTransferBatchIterator struct {
	Event *StockAssetTransferBatch // Event containing the contract specifics and raw log

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
func (it *StockAssetTransferBatchIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(StockAssetTransferBatch)
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
		it.Event = new(StockAssetTransferBatch)
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
func (it *StockAssetTransferBatchIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *StockAssetTransferBatchIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// StockAssetTransferBatch represents a TransferBatch event raised by the StockAsset contract.
type StockAssetTransferBatch struct {
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
func (_StockAsset *StockAssetFilterer) FilterTransferBatch(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*StockAssetTransferBatchIterator, error) {

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

	logs, sub, err := _StockAsset.contract.FilterLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &StockAssetTransferBatchIterator{contract: _StockAsset.contract, event: "TransferBatch", logs: logs, sub: sub}, nil
}

// WatchTransferBatch is a free log subscription operation binding the contract event 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb.
//
// Solidity: event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values)
func (_StockAsset *StockAssetFilterer) WatchTransferBatch(opts *bind.WatchOpts, sink chan<- *StockAssetTransferBatch, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _StockAsset.contract.WatchLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(StockAssetTransferBatch)
				if err := _StockAsset.contract.UnpackLog(event, "TransferBatch", log); err != nil {
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
func (_StockAsset *StockAssetFilterer) ParseTransferBatch(log types.Log) (*StockAssetTransferBatch, error) {
	event := new(StockAssetTransferBatch)
	if err := _StockAsset.contract.UnpackLog(event, "TransferBatch", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// StockAssetTransferSingleIterator is returned from FilterTransferSingle and is used to iterate over the raw logs and unpacked data for TransferSingle events raised by the StockAsset contract.
type StockAssetTransferSingleIterator struct {
	Event *StockAssetTransferSingle // Event containing the contract specifics and raw log

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
func (it *StockAssetTransferSingleIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(StockAssetTransferSingle)
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
		it.Event = new(StockAssetTransferSingle)
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
func (it *StockAssetTransferSingleIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *StockAssetTransferSingleIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// StockAssetTransferSingle represents a TransferSingle event raised by the StockAsset contract.
type StockAssetTransferSingle struct {
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
func (_StockAsset *StockAssetFilterer) FilterTransferSingle(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*StockAssetTransferSingleIterator, error) {

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

	logs, sub, err := _StockAsset.contract.FilterLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &StockAssetTransferSingleIterator{contract: _StockAsset.contract, event: "TransferSingle", logs: logs, sub: sub}, nil
}

// WatchTransferSingle is a free log subscription operation binding the contract event 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62.
//
// Solidity: event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)
func (_StockAsset *StockAssetFilterer) WatchTransferSingle(opts *bind.WatchOpts, sink chan<- *StockAssetTransferSingle, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _StockAsset.contract.WatchLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(StockAssetTransferSingle)
				if err := _StockAsset.contract.UnpackLog(event, "TransferSingle", log); err != nil {
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
func (_StockAsset *StockAssetFilterer) ParseTransferSingle(log types.Log) (*StockAssetTransferSingle, error) {
	event := new(StockAssetTransferSingle)
	if err := _StockAsset.contract.UnpackLog(event, "TransferSingle", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// StockAssetURIIterator is returned from FilterURI and is used to iterate over the raw logs and unpacked data for URI events raised by the StockAsset contract.
type StockAssetURIIterator struct {
	Event *StockAssetURI // Event containing the contract specifics and raw log

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
func (it *StockAssetURIIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(StockAssetURI)
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
		it.Event = new(StockAssetURI)
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
func (it *StockAssetURIIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *StockAssetURIIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// StockAssetURI represents a URI event raised by the StockAsset contract.
type StockAssetURI struct {
	Value string
	Id    *big.Int
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterURI is a free log retrieval operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_StockAsset *StockAssetFilterer) FilterURI(opts *bind.FilterOpts, id []*big.Int) (*StockAssetURIIterator, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _StockAsset.contract.FilterLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return &StockAssetURIIterator{contract: _StockAsset.contract, event: "URI", logs: logs, sub: sub}, nil
}

// WatchURI is a free log subscription operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_StockAsset *StockAssetFilterer) WatchURI(opts *bind.WatchOpts, sink chan<- *StockAssetURI, id []*big.Int) (event.Subscription, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _StockAsset.contract.WatchLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(StockAssetURI)
				if err := _StockAsset.contract.UnpackLog(event, "URI", log); err != nil {
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
func (_StockAsset *StockAssetFilterer) ParseURI(log types.Log) (*StockAssetURI, error) {
	event := new(StockAssetURI)
	if err := _StockAsset.contract.UnpackLog(event, "URI", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
