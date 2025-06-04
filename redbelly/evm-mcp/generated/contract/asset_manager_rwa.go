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

// IAssetManagerAsset is an auto generated low-level Go binding around an user-defined struct.
type IAssetManagerAsset struct {
	Name            string
	AssetId         *big.Int
	ContractAddress common.Address
	Category        string
}

// IAssetManagerCategoryValue is an auto generated low-level Go binding around an user-defined struct.
type IAssetManagerCategoryValue struct {
	Category   string
	TotalValue *big.Int
}

// AssetManagerRWAMetaData contains all meta data concerning the AssetManagerRWA contract.
var AssetManagerRWAMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"initialName\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"createPortfolio\",\"inputs\":[{\"name\":\"riskProfile\",\"type\":\"uint8\",\"internalType\":\"enumIAssetManager.RiskProfile\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getAllAssets\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"tuple[]\",\"internalType\":\"structIAssetManager.Asset[]\",\"components\":[{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"assetId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"contractAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"category\",\"type\":\"string\",\"internalType\":\"string\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAsset\",\"inputs\":[{\"name\":\"assetId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structIAssetManager.Asset\",\"components\":[{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"assetId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"contractAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"category\",\"type\":\"string\",\"internalType\":\"string\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getPortfolio\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"assetIds\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"quantities\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"userRiskProfile\",\"type\":\"uint8\",\"internalType\":\"enumIAssetManager.RiskProfile\"},{\"name\":\"currentValue\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"lastUpdated\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"riskAnalysis\",\"type\":\"uint8\",\"internalType\":\"enumIAssetManager.RiskProfile\"},{\"name\":\"categoryValuesReturn\",\"type\":\"tuple[]\",\"internalType\":\"structIAssetManager.CategoryValue[]\",\"components\":[{\"name\":\"category\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"totalValue\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"managerName\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"name\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"refreshPortfolio\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newAssetIds\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"newQuantities\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"newCurrentValue\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"newRiskAnalysis\",\"type\":\"uint8\",\"internalType\":\"enumIAssetManager.RiskProfile\"},{\"name\":\"newCategoryValues\",\"type\":\"tuple[]\",\"internalType\":\"structIAssetManager.CategoryValue[]\",\"components\":[{\"name\":\"category\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"totalValue\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"registerAsset\",\"inputs\":[{\"name\":\"assetName\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"contractAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"category\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"AssetRegistered\",\"inputs\":[{\"name\":\"assetId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"name\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"contractAddress\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PortfolioUpdated\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"currentValue\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"riskAnalysis\",\"type\":\"uint8\",\"indexed\":false,\"internalType\":\"enumIAssetManager.RiskProfile\"}],\"anonymous\":false}]",
}

// AssetManagerRWAABI is the input ABI used to generate the binding from.
// Deprecated: Use AssetManagerRWAMetaData.ABI instead.
var AssetManagerRWAABI = AssetManagerRWAMetaData.ABI

// AssetManagerRWA is an auto generated Go binding around an Ethereum contract.
type AssetManagerRWA struct {
	AssetManagerRWACaller     // Read-only binding to the contract
	AssetManagerRWATransactor // Write-only binding to the contract
	AssetManagerRWAFilterer   // Log filterer for contract events
}

// AssetManagerRWACaller is an auto generated read-only Go binding around an Ethereum contract.
type AssetManagerRWACaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// AssetManagerRWATransactor is an auto generated write-only Go binding around an Ethereum contract.
type AssetManagerRWATransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// AssetManagerRWAFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type AssetManagerRWAFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// AssetManagerRWASession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type AssetManagerRWASession struct {
	Contract     *AssetManagerRWA  // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// AssetManagerRWACallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type AssetManagerRWACallerSession struct {
	Contract *AssetManagerRWACaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts          // Call options to use throughout this session
}

// AssetManagerRWATransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type AssetManagerRWATransactorSession struct {
	Contract     *AssetManagerRWATransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts          // Transaction auth options to use throughout this session
}

// AssetManagerRWARaw is an auto generated low-level Go binding around an Ethereum contract.
type AssetManagerRWARaw struct {
	Contract *AssetManagerRWA // Generic contract binding to access the raw methods on
}

// AssetManagerRWACallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type AssetManagerRWACallerRaw struct {
	Contract *AssetManagerRWACaller // Generic read-only contract binding to access the raw methods on
}

// AssetManagerRWATransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type AssetManagerRWATransactorRaw struct {
	Contract *AssetManagerRWATransactor // Generic write-only contract binding to access the raw methods on
}

// NewAssetManagerRWA creates a new instance of AssetManagerRWA, bound to a specific deployed contract.
func NewAssetManagerRWA(address common.Address, backend bind.ContractBackend) (*AssetManagerRWA, error) {
	contract, err := bindAssetManagerRWA(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &AssetManagerRWA{AssetManagerRWACaller: AssetManagerRWACaller{contract: contract}, AssetManagerRWATransactor: AssetManagerRWATransactor{contract: contract}, AssetManagerRWAFilterer: AssetManagerRWAFilterer{contract: contract}}, nil
}

// NewAssetManagerRWACaller creates a new read-only instance of AssetManagerRWA, bound to a specific deployed contract.
func NewAssetManagerRWACaller(address common.Address, caller bind.ContractCaller) (*AssetManagerRWACaller, error) {
	contract, err := bindAssetManagerRWA(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &AssetManagerRWACaller{contract: contract}, nil
}

// NewAssetManagerRWATransactor creates a new write-only instance of AssetManagerRWA, bound to a specific deployed contract.
func NewAssetManagerRWATransactor(address common.Address, transactor bind.ContractTransactor) (*AssetManagerRWATransactor, error) {
	contract, err := bindAssetManagerRWA(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &AssetManagerRWATransactor{contract: contract}, nil
}

// NewAssetManagerRWAFilterer creates a new log filterer instance of AssetManagerRWA, bound to a specific deployed contract.
func NewAssetManagerRWAFilterer(address common.Address, filterer bind.ContractFilterer) (*AssetManagerRWAFilterer, error) {
	contract, err := bindAssetManagerRWA(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &AssetManagerRWAFilterer{contract: contract}, nil
}

// bindAssetManagerRWA binds a generic wrapper to an already deployed contract.
func bindAssetManagerRWA(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := AssetManagerRWAMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_AssetManagerRWA *AssetManagerRWARaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _AssetManagerRWA.Contract.AssetManagerRWACaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_AssetManagerRWA *AssetManagerRWARaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _AssetManagerRWA.Contract.AssetManagerRWATransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_AssetManagerRWA *AssetManagerRWARaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _AssetManagerRWA.Contract.AssetManagerRWATransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_AssetManagerRWA *AssetManagerRWACallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _AssetManagerRWA.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_AssetManagerRWA *AssetManagerRWATransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _AssetManagerRWA.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_AssetManagerRWA *AssetManagerRWATransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _AssetManagerRWA.Contract.contract.Transact(opts, method, params...)
}

// GetAllAssets is a free data retrieval call binding the contract method 0x2acada4d.
//
// Solidity: function getAllAssets() view returns((string,uint256,address,string)[])
func (_AssetManagerRWA *AssetManagerRWACaller) GetAllAssets(opts *bind.CallOpts) ([]IAssetManagerAsset, error) {
	var out []interface{}
	err := _AssetManagerRWA.contract.Call(opts, &out, "getAllAssets")

	if err != nil {
		return *new([]IAssetManagerAsset), err
	}

	out0 := *abi.ConvertType(out[0], new([]IAssetManagerAsset)).(*[]IAssetManagerAsset)

	return out0, err

}

// GetAllAssets is a free data retrieval call binding the contract method 0x2acada4d.
//
// Solidity: function getAllAssets() view returns((string,uint256,address,string)[])
func (_AssetManagerRWA *AssetManagerRWASession) GetAllAssets() ([]IAssetManagerAsset, error) {
	return _AssetManagerRWA.Contract.GetAllAssets(&_AssetManagerRWA.CallOpts)
}

// GetAllAssets is a free data retrieval call binding the contract method 0x2acada4d.
//
// Solidity: function getAllAssets() view returns((string,uint256,address,string)[])
func (_AssetManagerRWA *AssetManagerRWACallerSession) GetAllAssets() ([]IAssetManagerAsset, error) {
	return _AssetManagerRWA.Contract.GetAllAssets(&_AssetManagerRWA.CallOpts)
}

// GetAsset is a free data retrieval call binding the contract method 0xeac8f5b8.
//
// Solidity: function getAsset(uint256 assetId) view returns((string,uint256,address,string))
func (_AssetManagerRWA *AssetManagerRWACaller) GetAsset(opts *bind.CallOpts, assetId *big.Int) (IAssetManagerAsset, error) {
	var out []interface{}
	err := _AssetManagerRWA.contract.Call(opts, &out, "getAsset", assetId)

	if err != nil {
		return *new(IAssetManagerAsset), err
	}

	out0 := *abi.ConvertType(out[0], new(IAssetManagerAsset)).(*IAssetManagerAsset)

	return out0, err

}

// GetAsset is a free data retrieval call binding the contract method 0xeac8f5b8.
//
// Solidity: function getAsset(uint256 assetId) view returns((string,uint256,address,string))
func (_AssetManagerRWA *AssetManagerRWASession) GetAsset(assetId *big.Int) (IAssetManagerAsset, error) {
	return _AssetManagerRWA.Contract.GetAsset(&_AssetManagerRWA.CallOpts, assetId)
}

// GetAsset is a free data retrieval call binding the contract method 0xeac8f5b8.
//
// Solidity: function getAsset(uint256 assetId) view returns((string,uint256,address,string))
func (_AssetManagerRWA *AssetManagerRWACallerSession) GetAsset(assetId *big.Int) (IAssetManagerAsset, error) {
	return _AssetManagerRWA.Contract.GetAsset(&_AssetManagerRWA.CallOpts, assetId)
}

// GetPortfolio is a free data retrieval call binding the contract method 0xeb22ae11.
//
// Solidity: function getPortfolio(address user) view returns(uint256[] assetIds, uint256[] quantities, uint8 userRiskProfile, uint256 currentValue, uint256 lastUpdated, uint8 riskAnalysis, (string,uint256)[] categoryValuesReturn)
func (_AssetManagerRWA *AssetManagerRWACaller) GetPortfolio(opts *bind.CallOpts, user common.Address) (struct {
	AssetIds             []*big.Int
	Quantities           []*big.Int
	UserRiskProfile      uint8
	CurrentValue         *big.Int
	LastUpdated          *big.Int
	RiskAnalysis         uint8
	CategoryValuesReturn []IAssetManagerCategoryValue
}, error) {
	var out []interface{}
	err := _AssetManagerRWA.contract.Call(opts, &out, "getPortfolio", user)

	outstruct := new(struct {
		AssetIds             []*big.Int
		Quantities           []*big.Int
		UserRiskProfile      uint8
		CurrentValue         *big.Int
		LastUpdated          *big.Int
		RiskAnalysis         uint8
		CategoryValuesReturn []IAssetManagerCategoryValue
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.AssetIds = *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)
	outstruct.Quantities = *abi.ConvertType(out[1], new([]*big.Int)).(*[]*big.Int)
	outstruct.UserRiskProfile = *abi.ConvertType(out[2], new(uint8)).(*uint8)
	outstruct.CurrentValue = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)
	outstruct.LastUpdated = *abi.ConvertType(out[4], new(*big.Int)).(**big.Int)
	outstruct.RiskAnalysis = *abi.ConvertType(out[5], new(uint8)).(*uint8)
	outstruct.CategoryValuesReturn = *abi.ConvertType(out[6], new([]IAssetManagerCategoryValue)).(*[]IAssetManagerCategoryValue)

	return *outstruct, err

}

// GetPortfolio is a free data retrieval call binding the contract method 0xeb22ae11.
//
// Solidity: function getPortfolio(address user) view returns(uint256[] assetIds, uint256[] quantities, uint8 userRiskProfile, uint256 currentValue, uint256 lastUpdated, uint8 riskAnalysis, (string,uint256)[] categoryValuesReturn)
func (_AssetManagerRWA *AssetManagerRWASession) GetPortfolio(user common.Address) (struct {
	AssetIds             []*big.Int
	Quantities           []*big.Int
	UserRiskProfile      uint8
	CurrentValue         *big.Int
	LastUpdated          *big.Int
	RiskAnalysis         uint8
	CategoryValuesReturn []IAssetManagerCategoryValue
}, error) {
	return _AssetManagerRWA.Contract.GetPortfolio(&_AssetManagerRWA.CallOpts, user)
}

// GetPortfolio is a free data retrieval call binding the contract method 0xeb22ae11.
//
// Solidity: function getPortfolio(address user) view returns(uint256[] assetIds, uint256[] quantities, uint8 userRiskProfile, uint256 currentValue, uint256 lastUpdated, uint8 riskAnalysis, (string,uint256)[] categoryValuesReturn)
func (_AssetManagerRWA *AssetManagerRWACallerSession) GetPortfolio(user common.Address) (struct {
	AssetIds             []*big.Int
	Quantities           []*big.Int
	UserRiskProfile      uint8
	CurrentValue         *big.Int
	LastUpdated          *big.Int
	RiskAnalysis         uint8
	CategoryValuesReturn []IAssetManagerCategoryValue
}, error) {
	return _AssetManagerRWA.Contract.GetPortfolio(&_AssetManagerRWA.CallOpts, user)
}

// ManagerName is a free data retrieval call binding the contract method 0xfed4416a.
//
// Solidity: function managerName() view returns(string)
func (_AssetManagerRWA *AssetManagerRWACaller) ManagerName(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _AssetManagerRWA.contract.Call(opts, &out, "managerName")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// ManagerName is a free data retrieval call binding the contract method 0xfed4416a.
//
// Solidity: function managerName() view returns(string)
func (_AssetManagerRWA *AssetManagerRWASession) ManagerName() (string, error) {
	return _AssetManagerRWA.Contract.ManagerName(&_AssetManagerRWA.CallOpts)
}

// ManagerName is a free data retrieval call binding the contract method 0xfed4416a.
//
// Solidity: function managerName() view returns(string)
func (_AssetManagerRWA *AssetManagerRWACallerSession) ManagerName() (string, error) {
	return _AssetManagerRWA.Contract.ManagerName(&_AssetManagerRWA.CallOpts)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_AssetManagerRWA *AssetManagerRWACaller) Name(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _AssetManagerRWA.contract.Call(opts, &out, "name")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_AssetManagerRWA *AssetManagerRWASession) Name() (string, error) {
	return _AssetManagerRWA.Contract.Name(&_AssetManagerRWA.CallOpts)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_AssetManagerRWA *AssetManagerRWACallerSession) Name() (string, error) {
	return _AssetManagerRWA.Contract.Name(&_AssetManagerRWA.CallOpts)
}

// CreatePortfolio is a paid mutator transaction binding the contract method 0xcf06524c.
//
// Solidity: function createPortfolio(uint8 riskProfile) returns()
func (_AssetManagerRWA *AssetManagerRWATransactor) CreatePortfolio(opts *bind.TransactOpts, riskProfile uint8) (*types.Transaction, error) {
	return _AssetManagerRWA.contract.Transact(opts, "createPortfolio", riskProfile)
}

// CreatePortfolio is a paid mutator transaction binding the contract method 0xcf06524c.
//
// Solidity: function createPortfolio(uint8 riskProfile) returns()
func (_AssetManagerRWA *AssetManagerRWASession) CreatePortfolio(riskProfile uint8) (*types.Transaction, error) {
	return _AssetManagerRWA.Contract.CreatePortfolio(&_AssetManagerRWA.TransactOpts, riskProfile)
}

// CreatePortfolio is a paid mutator transaction binding the contract method 0xcf06524c.
//
// Solidity: function createPortfolio(uint8 riskProfile) returns()
func (_AssetManagerRWA *AssetManagerRWATransactorSession) CreatePortfolio(riskProfile uint8) (*types.Transaction, error) {
	return _AssetManagerRWA.Contract.CreatePortfolio(&_AssetManagerRWA.TransactOpts, riskProfile)
}

// RefreshPortfolio is a paid mutator transaction binding the contract method 0x24037ccc.
//
// Solidity: function refreshPortfolio(address user, uint256[] newAssetIds, uint256[] newQuantities, uint256 newCurrentValue, uint8 newRiskAnalysis, (string,uint256)[] newCategoryValues) returns()
func (_AssetManagerRWA *AssetManagerRWATransactor) RefreshPortfolio(opts *bind.TransactOpts, user common.Address, newAssetIds []*big.Int, newQuantities []*big.Int, newCurrentValue *big.Int, newRiskAnalysis uint8, newCategoryValues []IAssetManagerCategoryValue) (*types.Transaction, error) {
	return _AssetManagerRWA.contract.Transact(opts, "refreshPortfolio", user, newAssetIds, newQuantities, newCurrentValue, newRiskAnalysis, newCategoryValues)
}

// RefreshPortfolio is a paid mutator transaction binding the contract method 0x24037ccc.
//
// Solidity: function refreshPortfolio(address user, uint256[] newAssetIds, uint256[] newQuantities, uint256 newCurrentValue, uint8 newRiskAnalysis, (string,uint256)[] newCategoryValues) returns()
func (_AssetManagerRWA *AssetManagerRWASession) RefreshPortfolio(user common.Address, newAssetIds []*big.Int, newQuantities []*big.Int, newCurrentValue *big.Int, newRiskAnalysis uint8, newCategoryValues []IAssetManagerCategoryValue) (*types.Transaction, error) {
	return _AssetManagerRWA.Contract.RefreshPortfolio(&_AssetManagerRWA.TransactOpts, user, newAssetIds, newQuantities, newCurrentValue, newRiskAnalysis, newCategoryValues)
}

// RefreshPortfolio is a paid mutator transaction binding the contract method 0x24037ccc.
//
// Solidity: function refreshPortfolio(address user, uint256[] newAssetIds, uint256[] newQuantities, uint256 newCurrentValue, uint8 newRiskAnalysis, (string,uint256)[] newCategoryValues) returns()
func (_AssetManagerRWA *AssetManagerRWATransactorSession) RefreshPortfolio(user common.Address, newAssetIds []*big.Int, newQuantities []*big.Int, newCurrentValue *big.Int, newRiskAnalysis uint8, newCategoryValues []IAssetManagerCategoryValue) (*types.Transaction, error) {
	return _AssetManagerRWA.Contract.RefreshPortfolio(&_AssetManagerRWA.TransactOpts, user, newAssetIds, newQuantities, newCurrentValue, newRiskAnalysis, newCategoryValues)
}

// RegisterAsset is a paid mutator transaction binding the contract method 0xa5a6f96c.
//
// Solidity: function registerAsset(string assetName, address contractAddress, string category) returns(uint256)
func (_AssetManagerRWA *AssetManagerRWATransactor) RegisterAsset(opts *bind.TransactOpts, assetName string, contractAddress common.Address, category string) (*types.Transaction, error) {
	return _AssetManagerRWA.contract.Transact(opts, "registerAsset", assetName, contractAddress, category)
}

// RegisterAsset is a paid mutator transaction binding the contract method 0xa5a6f96c.
//
// Solidity: function registerAsset(string assetName, address contractAddress, string category) returns(uint256)
func (_AssetManagerRWA *AssetManagerRWASession) RegisterAsset(assetName string, contractAddress common.Address, category string) (*types.Transaction, error) {
	return _AssetManagerRWA.Contract.RegisterAsset(&_AssetManagerRWA.TransactOpts, assetName, contractAddress, category)
}

// RegisterAsset is a paid mutator transaction binding the contract method 0xa5a6f96c.
//
// Solidity: function registerAsset(string assetName, address contractAddress, string category) returns(uint256)
func (_AssetManagerRWA *AssetManagerRWATransactorSession) RegisterAsset(assetName string, contractAddress common.Address, category string) (*types.Transaction, error) {
	return _AssetManagerRWA.Contract.RegisterAsset(&_AssetManagerRWA.TransactOpts, assetName, contractAddress, category)
}

// AssetManagerRWAAssetRegisteredIterator is returned from FilterAssetRegistered and is used to iterate over the raw logs and unpacked data for AssetRegistered events raised by the AssetManagerRWA contract.
type AssetManagerRWAAssetRegisteredIterator struct {
	Event *AssetManagerRWAAssetRegistered // Event containing the contract specifics and raw log

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
func (it *AssetManagerRWAAssetRegisteredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AssetManagerRWAAssetRegistered)
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
		it.Event = new(AssetManagerRWAAssetRegistered)
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
func (it *AssetManagerRWAAssetRegisteredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AssetManagerRWAAssetRegisteredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AssetManagerRWAAssetRegistered represents a AssetRegistered event raised by the AssetManagerRWA contract.
type AssetManagerRWAAssetRegistered struct {
	AssetId         *big.Int
	Name            string
	ContractAddress common.Address
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterAssetRegistered is a free log retrieval operation binding the contract event 0x6a0b77574001a7b16fb6fab947b7490f63408e142d8d53475dabe971f4bce520.
//
// Solidity: event AssetRegistered(uint256 indexed assetId, string name, address contractAddress)
func (_AssetManagerRWA *AssetManagerRWAFilterer) FilterAssetRegistered(opts *bind.FilterOpts, assetId []*big.Int) (*AssetManagerRWAAssetRegisteredIterator, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}

	logs, sub, err := _AssetManagerRWA.contract.FilterLogs(opts, "AssetRegistered", assetIdRule)
	if err != nil {
		return nil, err
	}
	return &AssetManagerRWAAssetRegisteredIterator{contract: _AssetManagerRWA.contract, event: "AssetRegistered", logs: logs, sub: sub}, nil
}

// WatchAssetRegistered is a free log subscription operation binding the contract event 0x6a0b77574001a7b16fb6fab947b7490f63408e142d8d53475dabe971f4bce520.
//
// Solidity: event AssetRegistered(uint256 indexed assetId, string name, address contractAddress)
func (_AssetManagerRWA *AssetManagerRWAFilterer) WatchAssetRegistered(opts *bind.WatchOpts, sink chan<- *AssetManagerRWAAssetRegistered, assetId []*big.Int) (event.Subscription, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}

	logs, sub, err := _AssetManagerRWA.contract.WatchLogs(opts, "AssetRegistered", assetIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AssetManagerRWAAssetRegistered)
				if err := _AssetManagerRWA.contract.UnpackLog(event, "AssetRegistered", log); err != nil {
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

// ParseAssetRegistered is a log parse operation binding the contract event 0x6a0b77574001a7b16fb6fab947b7490f63408e142d8d53475dabe971f4bce520.
//
// Solidity: event AssetRegistered(uint256 indexed assetId, string name, address contractAddress)
func (_AssetManagerRWA *AssetManagerRWAFilterer) ParseAssetRegistered(log types.Log) (*AssetManagerRWAAssetRegistered, error) {
	event := new(AssetManagerRWAAssetRegistered)
	if err := _AssetManagerRWA.contract.UnpackLog(event, "AssetRegistered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AssetManagerRWAPortfolioUpdatedIterator is returned from FilterPortfolioUpdated and is used to iterate over the raw logs and unpacked data for PortfolioUpdated events raised by the AssetManagerRWA contract.
type AssetManagerRWAPortfolioUpdatedIterator struct {
	Event *AssetManagerRWAPortfolioUpdated // Event containing the contract specifics and raw log

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
func (it *AssetManagerRWAPortfolioUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AssetManagerRWAPortfolioUpdated)
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
		it.Event = new(AssetManagerRWAPortfolioUpdated)
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
func (it *AssetManagerRWAPortfolioUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AssetManagerRWAPortfolioUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AssetManagerRWAPortfolioUpdated represents a PortfolioUpdated event raised by the AssetManagerRWA contract.
type AssetManagerRWAPortfolioUpdated struct {
	User         common.Address
	CurrentValue *big.Int
	RiskAnalysis uint8
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterPortfolioUpdated is a free log retrieval operation binding the contract event 0x6b953c97672e90b989640e4dab582a9e9ab906e534cc7af39046496eeb508ec5.
//
// Solidity: event PortfolioUpdated(address indexed user, uint256 currentValue, uint8 riskAnalysis)
func (_AssetManagerRWA *AssetManagerRWAFilterer) FilterPortfolioUpdated(opts *bind.FilterOpts, user []common.Address) (*AssetManagerRWAPortfolioUpdatedIterator, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}

	logs, sub, err := _AssetManagerRWA.contract.FilterLogs(opts, "PortfolioUpdated", userRule)
	if err != nil {
		return nil, err
	}
	return &AssetManagerRWAPortfolioUpdatedIterator{contract: _AssetManagerRWA.contract, event: "PortfolioUpdated", logs: logs, sub: sub}, nil
}

// WatchPortfolioUpdated is a free log subscription operation binding the contract event 0x6b953c97672e90b989640e4dab582a9e9ab906e534cc7af39046496eeb508ec5.
//
// Solidity: event PortfolioUpdated(address indexed user, uint256 currentValue, uint8 riskAnalysis)
func (_AssetManagerRWA *AssetManagerRWAFilterer) WatchPortfolioUpdated(opts *bind.WatchOpts, sink chan<- *AssetManagerRWAPortfolioUpdated, user []common.Address) (event.Subscription, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}

	logs, sub, err := _AssetManagerRWA.contract.WatchLogs(opts, "PortfolioUpdated", userRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AssetManagerRWAPortfolioUpdated)
				if err := _AssetManagerRWA.contract.UnpackLog(event, "PortfolioUpdated", log); err != nil {
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

// ParsePortfolioUpdated is a log parse operation binding the contract event 0x6b953c97672e90b989640e4dab582a9e9ab906e534cc7af39046496eeb508ec5.
//
// Solidity: event PortfolioUpdated(address indexed user, uint256 currentValue, uint8 riskAnalysis)
func (_AssetManagerRWA *AssetManagerRWAFilterer) ParsePortfolioUpdated(log types.Log) (*AssetManagerRWAPortfolioUpdated, error) {
	event := new(AssetManagerRWAPortfolioUpdated)
	if err := _AssetManagerRWA.contract.UnpackLog(event, "PortfolioUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
