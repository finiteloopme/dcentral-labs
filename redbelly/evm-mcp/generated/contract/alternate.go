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

// AlternateAssetsV1AlternateAsset is an auto generated low-level Go binding around an user-defined struct.
type AlternateAssetsV1AlternateAsset struct {
	Name         string
	Symbol       string
	DocHash      string
	Country      string
	Issuer       common.Address
	TotalSupply  *big.Int
	InitialPrice *big.Int
	Logo         string
}

// AlternateMetaData contains all meta data concerning the Alternate contract.
var AlternateMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"UPGRADE_INTERFACE_VERSION\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addAltAsset\",\"inputs\":[{\"name\":\"_altAsset\",\"type\":\"tuple\",\"internalType\":\"structAlternateAssetsV1.AlternateAsset\",\"components\":[{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"symbol\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"docHash\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"country\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"issuer\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"totalSupply\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"initialPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"logo\",\"type\":\"string\",\"internalType\":\"string\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"assetName\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"assetSymbol\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"assetTotalSupply\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOf\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOfBatch\",\"inputs\":[{\"name\":\"accounts\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"buy\",\"inputs\":[{\"name\":\"_id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"decimals\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAllAssetIds\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getBuyPrice\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCurrentSupply\",\"inputs\":[{\"name\":\"_id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSellPrice\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getUserAssetIds\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getaltAssetsDetailsFromId\",\"inputs\":[{\"name\":\"_id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structAlternateAssetsV1.AlternateAsset\",\"components\":[{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"symbol\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"docHash\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"country\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"issuer\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"totalSupply\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"initialPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"logo\",\"type\":\"string\",\"internalType\":\"string\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"initialize\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"isApprovedForAll\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"name\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proxiableUUID\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"safeBatchTransferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"values\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"safeTransferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"sell\",\"inputs\":[{\"name\":\"_id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"setApprovalForAll\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"symbol\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalAltAssets\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"upgradeToAndCall\",\"inputs\":[{\"name\":\"newImplementation\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"uri\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"ApprovalForAll\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AssetBought\",\"inputs\":[{\"name\":\"assetId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"buyer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"tokenCount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"price\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"name\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AssetIssued\",\"inputs\":[{\"name\":\"assetId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"totalSupply\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"initialPrice\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"name\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"symbol\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AssetSold\",\"inputs\":[{\"name\":\"assetId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"seller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"tokenCount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"price\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"name\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Initialized\",\"inputs\":[{\"name\":\"version\",\"type\":\"uint64\",\"indexed\":false,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferBatch\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"values\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferSingle\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"URI\",\"inputs\":[{\"name\":\"value\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Upgraded\",\"inputs\":[{\"name\":\"implementation\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AddressEmptyCode\",\"inputs\":[{\"name\":\"target\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InsufficientBalance\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"needed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"tokenId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidApprover\",\"inputs\":[{\"name\":\"approver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidArrayLength\",\"inputs\":[{\"name\":\"idsLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"valuesLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidOperator\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidReceiver\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidSender\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155MissingApprovalForAll\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1967InvalidImplementation\",\"inputs\":[{\"name\":\"implementation\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1967NonPayable\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FailedCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidInitialization\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NotInitializing\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"OwnableInvalidOwner\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"UUPSUnauthorizedCallContext\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UUPSUnsupportedProxiableUUID\",\"inputs\":[{\"name\":\"slot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]}]",
}

// AlternateABI is the input ABI used to generate the binding from.
// Deprecated: Use AlternateMetaData.ABI instead.
var AlternateABI = AlternateMetaData.ABI

// Alternate is an auto generated Go binding around an Ethereum contract.
type Alternate struct {
	AlternateCaller     // Read-only binding to the contract
	AlternateTransactor // Write-only binding to the contract
	AlternateFilterer   // Log filterer for contract events
}

// AlternateCaller is an auto generated read-only Go binding around an Ethereum contract.
type AlternateCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// AlternateTransactor is an auto generated write-only Go binding around an Ethereum contract.
type AlternateTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// AlternateFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type AlternateFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// AlternateSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type AlternateSession struct {
	Contract     *Alternate        // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// AlternateCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type AlternateCallerSession struct {
	Contract *AlternateCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts    // Call options to use throughout this session
}

// AlternateTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type AlternateTransactorSession struct {
	Contract     *AlternateTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts    // Transaction auth options to use throughout this session
}

// AlternateRaw is an auto generated low-level Go binding around an Ethereum contract.
type AlternateRaw struct {
	Contract *Alternate // Generic contract binding to access the raw methods on
}

// AlternateCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type AlternateCallerRaw struct {
	Contract *AlternateCaller // Generic read-only contract binding to access the raw methods on
}

// AlternateTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type AlternateTransactorRaw struct {
	Contract *AlternateTransactor // Generic write-only contract binding to access the raw methods on
}

// NewAlternate creates a new instance of Alternate, bound to a specific deployed contract.
func NewAlternate(address common.Address, backend bind.ContractBackend) (*Alternate, error) {
	contract, err := bindAlternate(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &Alternate{AlternateCaller: AlternateCaller{contract: contract}, AlternateTransactor: AlternateTransactor{contract: contract}, AlternateFilterer: AlternateFilterer{contract: contract}}, nil
}

// NewAlternateCaller creates a new read-only instance of Alternate, bound to a specific deployed contract.
func NewAlternateCaller(address common.Address, caller bind.ContractCaller) (*AlternateCaller, error) {
	contract, err := bindAlternate(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &AlternateCaller{contract: contract}, nil
}

// NewAlternateTransactor creates a new write-only instance of Alternate, bound to a specific deployed contract.
func NewAlternateTransactor(address common.Address, transactor bind.ContractTransactor) (*AlternateTransactor, error) {
	contract, err := bindAlternate(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &AlternateTransactor{contract: contract}, nil
}

// NewAlternateFilterer creates a new log filterer instance of Alternate, bound to a specific deployed contract.
func NewAlternateFilterer(address common.Address, filterer bind.ContractFilterer) (*AlternateFilterer, error) {
	contract, err := bindAlternate(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &AlternateFilterer{contract: contract}, nil
}

// bindAlternate binds a generic wrapper to an already deployed contract.
func bindAlternate(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := AlternateMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Alternate *AlternateRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Alternate.Contract.AlternateCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Alternate *AlternateRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Alternate.Contract.AlternateTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Alternate *AlternateRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Alternate.Contract.AlternateTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Alternate *AlternateCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Alternate.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Alternate *AlternateTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Alternate.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Alternate *AlternateTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Alternate.Contract.contract.Transact(opts, method, params...)
}

// UPGRADEINTERFACEVERSION is a free data retrieval call binding the contract method 0xad3cb1cc.
//
// Solidity: function UPGRADE_INTERFACE_VERSION() view returns(string)
func (_Alternate *AlternateCaller) UPGRADEINTERFACEVERSION(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "UPGRADE_INTERFACE_VERSION")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// UPGRADEINTERFACEVERSION is a free data retrieval call binding the contract method 0xad3cb1cc.
//
// Solidity: function UPGRADE_INTERFACE_VERSION() view returns(string)
func (_Alternate *AlternateSession) UPGRADEINTERFACEVERSION() (string, error) {
	return _Alternate.Contract.UPGRADEINTERFACEVERSION(&_Alternate.CallOpts)
}

// UPGRADEINTERFACEVERSION is a free data retrieval call binding the contract method 0xad3cb1cc.
//
// Solidity: function UPGRADE_INTERFACE_VERSION() view returns(string)
func (_Alternate *AlternateCallerSession) UPGRADEINTERFACEVERSION() (string, error) {
	return _Alternate.Contract.UPGRADEINTERFACEVERSION(&_Alternate.CallOpts)
}

// AssetName is a free data retrieval call binding the contract method 0x01a3543d.
//
// Solidity: function assetName(uint256 id) view returns(string)
func (_Alternate *AlternateCaller) AssetName(opts *bind.CallOpts, id *big.Int) (string, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "assetName", id)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// AssetName is a free data retrieval call binding the contract method 0x01a3543d.
//
// Solidity: function assetName(uint256 id) view returns(string)
func (_Alternate *AlternateSession) AssetName(id *big.Int) (string, error) {
	return _Alternate.Contract.AssetName(&_Alternate.CallOpts, id)
}

// AssetName is a free data retrieval call binding the contract method 0x01a3543d.
//
// Solidity: function assetName(uint256 id) view returns(string)
func (_Alternate *AlternateCallerSession) AssetName(id *big.Int) (string, error) {
	return _Alternate.Contract.AssetName(&_Alternate.CallOpts, id)
}

// AssetSymbol is a free data retrieval call binding the contract method 0xf701fd0a.
//
// Solidity: function assetSymbol(uint256 id) view returns(string)
func (_Alternate *AlternateCaller) AssetSymbol(opts *bind.CallOpts, id *big.Int) (string, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "assetSymbol", id)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// AssetSymbol is a free data retrieval call binding the contract method 0xf701fd0a.
//
// Solidity: function assetSymbol(uint256 id) view returns(string)
func (_Alternate *AlternateSession) AssetSymbol(id *big.Int) (string, error) {
	return _Alternate.Contract.AssetSymbol(&_Alternate.CallOpts, id)
}

// AssetSymbol is a free data retrieval call binding the contract method 0xf701fd0a.
//
// Solidity: function assetSymbol(uint256 id) view returns(string)
func (_Alternate *AlternateCallerSession) AssetSymbol(id *big.Int) (string, error) {
	return _Alternate.Contract.AssetSymbol(&_Alternate.CallOpts, id)
}

// AssetTotalSupply is a free data retrieval call binding the contract method 0x1cce6ef5.
//
// Solidity: function assetTotalSupply(uint256 id) view returns(uint256)
func (_Alternate *AlternateCaller) AssetTotalSupply(opts *bind.CallOpts, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "assetTotalSupply", id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AssetTotalSupply is a free data retrieval call binding the contract method 0x1cce6ef5.
//
// Solidity: function assetTotalSupply(uint256 id) view returns(uint256)
func (_Alternate *AlternateSession) AssetTotalSupply(id *big.Int) (*big.Int, error) {
	return _Alternate.Contract.AssetTotalSupply(&_Alternate.CallOpts, id)
}

// AssetTotalSupply is a free data retrieval call binding the contract method 0x1cce6ef5.
//
// Solidity: function assetTotalSupply(uint256 id) view returns(uint256)
func (_Alternate *AlternateCallerSession) AssetTotalSupply(id *big.Int) (*big.Int, error) {
	return _Alternate.Contract.AssetTotalSupply(&_Alternate.CallOpts, id)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_Alternate *AlternateCaller) BalanceOf(opts *bind.CallOpts, account common.Address, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "balanceOf", account, id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_Alternate *AlternateSession) BalanceOf(account common.Address, id *big.Int) (*big.Int, error) {
	return _Alternate.Contract.BalanceOf(&_Alternate.CallOpts, account, id)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_Alternate *AlternateCallerSession) BalanceOf(account common.Address, id *big.Int) (*big.Int, error) {
	return _Alternate.Contract.BalanceOf(&_Alternate.CallOpts, account, id)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_Alternate *AlternateCaller) BalanceOfBatch(opts *bind.CallOpts, accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "balanceOfBatch", accounts, ids)

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_Alternate *AlternateSession) BalanceOfBatch(accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _Alternate.Contract.BalanceOfBatch(&_Alternate.CallOpts, accounts, ids)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_Alternate *AlternateCallerSession) BalanceOfBatch(accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _Alternate.Contract.BalanceOfBatch(&_Alternate.CallOpts, accounts, ids)
}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint256)
func (_Alternate *AlternateCaller) Decimals(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "decimals")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint256)
func (_Alternate *AlternateSession) Decimals() (*big.Int, error) {
	return _Alternate.Contract.Decimals(&_Alternate.CallOpts)
}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint256)
func (_Alternate *AlternateCallerSession) Decimals() (*big.Int, error) {
	return _Alternate.Contract.Decimals(&_Alternate.CallOpts)
}

// GetAllAssetIds is a free data retrieval call binding the contract method 0xe122f907.
//
// Solidity: function getAllAssetIds() view returns(uint256[])
func (_Alternate *AlternateCaller) GetAllAssetIds(opts *bind.CallOpts) ([]*big.Int, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "getAllAssetIds")

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// GetAllAssetIds is a free data retrieval call binding the contract method 0xe122f907.
//
// Solidity: function getAllAssetIds() view returns(uint256[])
func (_Alternate *AlternateSession) GetAllAssetIds() ([]*big.Int, error) {
	return _Alternate.Contract.GetAllAssetIds(&_Alternate.CallOpts)
}

// GetAllAssetIds is a free data retrieval call binding the contract method 0xe122f907.
//
// Solidity: function getAllAssetIds() view returns(uint256[])
func (_Alternate *AlternateCallerSession) GetAllAssetIds() ([]*big.Int, error) {
	return _Alternate.Contract.GetAllAssetIds(&_Alternate.CallOpts)
}

// GetBuyPrice is a free data retrieval call binding the contract method 0x08d4db14.
//
// Solidity: function getBuyPrice(uint256 id) view returns(uint256)
func (_Alternate *AlternateCaller) GetBuyPrice(opts *bind.CallOpts, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "getBuyPrice", id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetBuyPrice is a free data retrieval call binding the contract method 0x08d4db14.
//
// Solidity: function getBuyPrice(uint256 id) view returns(uint256)
func (_Alternate *AlternateSession) GetBuyPrice(id *big.Int) (*big.Int, error) {
	return _Alternate.Contract.GetBuyPrice(&_Alternate.CallOpts, id)
}

// GetBuyPrice is a free data retrieval call binding the contract method 0x08d4db14.
//
// Solidity: function getBuyPrice(uint256 id) view returns(uint256)
func (_Alternate *AlternateCallerSession) GetBuyPrice(id *big.Int) (*big.Int, error) {
	return _Alternate.Contract.GetBuyPrice(&_Alternate.CallOpts, id)
}

// GetCurrentSupply is a free data retrieval call binding the contract method 0x46f5303d.
//
// Solidity: function getCurrentSupply(uint256 _id) view returns(uint256)
func (_Alternate *AlternateCaller) GetCurrentSupply(opts *bind.CallOpts, _id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "getCurrentSupply", _id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetCurrentSupply is a free data retrieval call binding the contract method 0x46f5303d.
//
// Solidity: function getCurrentSupply(uint256 _id) view returns(uint256)
func (_Alternate *AlternateSession) GetCurrentSupply(_id *big.Int) (*big.Int, error) {
	return _Alternate.Contract.GetCurrentSupply(&_Alternate.CallOpts, _id)
}

// GetCurrentSupply is a free data retrieval call binding the contract method 0x46f5303d.
//
// Solidity: function getCurrentSupply(uint256 _id) view returns(uint256)
func (_Alternate *AlternateCallerSession) GetCurrentSupply(_id *big.Int) (*big.Int, error) {
	return _Alternate.Contract.GetCurrentSupply(&_Alternate.CallOpts, _id)
}

// GetSellPrice is a free data retrieval call binding the contract method 0xba730e53.
//
// Solidity: function getSellPrice(uint256 id) view returns(uint256)
func (_Alternate *AlternateCaller) GetSellPrice(opts *bind.CallOpts, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "getSellPrice", id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetSellPrice is a free data retrieval call binding the contract method 0xba730e53.
//
// Solidity: function getSellPrice(uint256 id) view returns(uint256)
func (_Alternate *AlternateSession) GetSellPrice(id *big.Int) (*big.Int, error) {
	return _Alternate.Contract.GetSellPrice(&_Alternate.CallOpts, id)
}

// GetSellPrice is a free data retrieval call binding the contract method 0xba730e53.
//
// Solidity: function getSellPrice(uint256 id) view returns(uint256)
func (_Alternate *AlternateCallerSession) GetSellPrice(id *big.Int) (*big.Int, error) {
	return _Alternate.Contract.GetSellPrice(&_Alternate.CallOpts, id)
}

// GetUserAssetIds is a free data retrieval call binding the contract method 0x4e883ac7.
//
// Solidity: function getUserAssetIds(address user) view returns(uint256[])
func (_Alternate *AlternateCaller) GetUserAssetIds(opts *bind.CallOpts, user common.Address) ([]*big.Int, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "getUserAssetIds", user)

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// GetUserAssetIds is a free data retrieval call binding the contract method 0x4e883ac7.
//
// Solidity: function getUserAssetIds(address user) view returns(uint256[])
func (_Alternate *AlternateSession) GetUserAssetIds(user common.Address) ([]*big.Int, error) {
	return _Alternate.Contract.GetUserAssetIds(&_Alternate.CallOpts, user)
}

// GetUserAssetIds is a free data retrieval call binding the contract method 0x4e883ac7.
//
// Solidity: function getUserAssetIds(address user) view returns(uint256[])
func (_Alternate *AlternateCallerSession) GetUserAssetIds(user common.Address) ([]*big.Int, error) {
	return _Alternate.Contract.GetUserAssetIds(&_Alternate.CallOpts, user)
}

// GetaltAssetsDetailsFromId is a free data retrieval call binding the contract method 0x2540ee93.
//
// Solidity: function getaltAssetsDetailsFromId(uint256 _id) view returns((string,string,string,string,address,uint256,uint256,string))
func (_Alternate *AlternateCaller) GetaltAssetsDetailsFromId(opts *bind.CallOpts, _id *big.Int) (AlternateAssetsV1AlternateAsset, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "getaltAssetsDetailsFromId", _id)

	if err != nil {
		return *new(AlternateAssetsV1AlternateAsset), err
	}

	out0 := *abi.ConvertType(out[0], new(AlternateAssetsV1AlternateAsset)).(*AlternateAssetsV1AlternateAsset)

	return out0, err

}

// GetaltAssetsDetailsFromId is a free data retrieval call binding the contract method 0x2540ee93.
//
// Solidity: function getaltAssetsDetailsFromId(uint256 _id) view returns((string,string,string,string,address,uint256,uint256,string))
func (_Alternate *AlternateSession) GetaltAssetsDetailsFromId(_id *big.Int) (AlternateAssetsV1AlternateAsset, error) {
	return _Alternate.Contract.GetaltAssetsDetailsFromId(&_Alternate.CallOpts, _id)
}

// GetaltAssetsDetailsFromId is a free data retrieval call binding the contract method 0x2540ee93.
//
// Solidity: function getaltAssetsDetailsFromId(uint256 _id) view returns((string,string,string,string,address,uint256,uint256,string))
func (_Alternate *AlternateCallerSession) GetaltAssetsDetailsFromId(_id *big.Int) (AlternateAssetsV1AlternateAsset, error) {
	return _Alternate.Contract.GetaltAssetsDetailsFromId(&_Alternate.CallOpts, _id)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_Alternate *AlternateCaller) IsApprovedForAll(opts *bind.CallOpts, account common.Address, operator common.Address) (bool, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "isApprovedForAll", account, operator)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_Alternate *AlternateSession) IsApprovedForAll(account common.Address, operator common.Address) (bool, error) {
	return _Alternate.Contract.IsApprovedForAll(&_Alternate.CallOpts, account, operator)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_Alternate *AlternateCallerSession) IsApprovedForAll(account common.Address, operator common.Address) (bool, error) {
	return _Alternate.Contract.IsApprovedForAll(&_Alternate.CallOpts, account, operator)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_Alternate *AlternateCaller) Name(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "name")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_Alternate *AlternateSession) Name() (string, error) {
	return _Alternate.Contract.Name(&_Alternate.CallOpts)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_Alternate *AlternateCallerSession) Name() (string, error) {
	return _Alternate.Contract.Name(&_Alternate.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Alternate *AlternateCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Alternate *AlternateSession) Owner() (common.Address, error) {
	return _Alternate.Contract.Owner(&_Alternate.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Alternate *AlternateCallerSession) Owner() (common.Address, error) {
	return _Alternate.Contract.Owner(&_Alternate.CallOpts)
}

// ProxiableUUID is a free data retrieval call binding the contract method 0x52d1902d.
//
// Solidity: function proxiableUUID() view returns(bytes32)
func (_Alternate *AlternateCaller) ProxiableUUID(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "proxiableUUID")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// ProxiableUUID is a free data retrieval call binding the contract method 0x52d1902d.
//
// Solidity: function proxiableUUID() view returns(bytes32)
func (_Alternate *AlternateSession) ProxiableUUID() ([32]byte, error) {
	return _Alternate.Contract.ProxiableUUID(&_Alternate.CallOpts)
}

// ProxiableUUID is a free data retrieval call binding the contract method 0x52d1902d.
//
// Solidity: function proxiableUUID() view returns(bytes32)
func (_Alternate *AlternateCallerSession) ProxiableUUID() ([32]byte, error) {
	return _Alternate.Contract.ProxiableUUID(&_Alternate.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Alternate *AlternateCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Alternate *AlternateSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _Alternate.Contract.SupportsInterface(&_Alternate.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Alternate *AlternateCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _Alternate.Contract.SupportsInterface(&_Alternate.CallOpts, interfaceId)
}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_Alternate *AlternateCaller) Symbol(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "symbol")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_Alternate *AlternateSession) Symbol() (string, error) {
	return _Alternate.Contract.Symbol(&_Alternate.CallOpts)
}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_Alternate *AlternateCallerSession) Symbol() (string, error) {
	return _Alternate.Contract.Symbol(&_Alternate.CallOpts)
}

// TotalAltAssets is a free data retrieval call binding the contract method 0xd7101bcf.
//
// Solidity: function totalAltAssets() view returns(uint256)
func (_Alternate *AlternateCaller) TotalAltAssets(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "totalAltAssets")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalAltAssets is a free data retrieval call binding the contract method 0xd7101bcf.
//
// Solidity: function totalAltAssets() view returns(uint256)
func (_Alternate *AlternateSession) TotalAltAssets() (*big.Int, error) {
	return _Alternate.Contract.TotalAltAssets(&_Alternate.CallOpts)
}

// TotalAltAssets is a free data retrieval call binding the contract method 0xd7101bcf.
//
// Solidity: function totalAltAssets() view returns(uint256)
func (_Alternate *AlternateCallerSession) TotalAltAssets() (*big.Int, error) {
	return _Alternate.Contract.TotalAltAssets(&_Alternate.CallOpts)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_Alternate *AlternateCaller) Uri(opts *bind.CallOpts, arg0 *big.Int) (string, error) {
	var out []interface{}
	err := _Alternate.contract.Call(opts, &out, "uri", arg0)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_Alternate *AlternateSession) Uri(arg0 *big.Int) (string, error) {
	return _Alternate.Contract.Uri(&_Alternate.CallOpts, arg0)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_Alternate *AlternateCallerSession) Uri(arg0 *big.Int) (string, error) {
	return _Alternate.Contract.Uri(&_Alternate.CallOpts, arg0)
}

// AddAltAsset is a paid mutator transaction binding the contract method 0x6c518d32.
//
// Solidity: function addAltAsset((string,string,string,string,address,uint256,uint256,string) _altAsset) returns()
func (_Alternate *AlternateTransactor) AddAltAsset(opts *bind.TransactOpts, _altAsset AlternateAssetsV1AlternateAsset) (*types.Transaction, error) {
	return _Alternate.contract.Transact(opts, "addAltAsset", _altAsset)
}

// AddAltAsset is a paid mutator transaction binding the contract method 0x6c518d32.
//
// Solidity: function addAltAsset((string,string,string,string,address,uint256,uint256,string) _altAsset) returns()
func (_Alternate *AlternateSession) AddAltAsset(_altAsset AlternateAssetsV1AlternateAsset) (*types.Transaction, error) {
	return _Alternate.Contract.AddAltAsset(&_Alternate.TransactOpts, _altAsset)
}

// AddAltAsset is a paid mutator transaction binding the contract method 0x6c518d32.
//
// Solidity: function addAltAsset((string,string,string,string,address,uint256,uint256,string) _altAsset) returns()
func (_Alternate *AlternateTransactorSession) AddAltAsset(_altAsset AlternateAssetsV1AlternateAsset) (*types.Transaction, error) {
	return _Alternate.Contract.AddAltAsset(&_Alternate.TransactOpts, _altAsset)
}

// Buy is a paid mutator transaction binding the contract method 0xd96a094a.
//
// Solidity: function buy(uint256 _id) payable returns()
func (_Alternate *AlternateTransactor) Buy(opts *bind.TransactOpts, _id *big.Int) (*types.Transaction, error) {
	return _Alternate.contract.Transact(opts, "buy", _id)
}

// Buy is a paid mutator transaction binding the contract method 0xd96a094a.
//
// Solidity: function buy(uint256 _id) payable returns()
func (_Alternate *AlternateSession) Buy(_id *big.Int) (*types.Transaction, error) {
	return _Alternate.Contract.Buy(&_Alternate.TransactOpts, _id)
}

// Buy is a paid mutator transaction binding the contract method 0xd96a094a.
//
// Solidity: function buy(uint256 _id) payable returns()
func (_Alternate *AlternateTransactorSession) Buy(_id *big.Int) (*types.Transaction, error) {
	return _Alternate.Contract.Buy(&_Alternate.TransactOpts, _id)
}

// Initialize is a paid mutator transaction binding the contract method 0x8129fc1c.
//
// Solidity: function initialize() returns()
func (_Alternate *AlternateTransactor) Initialize(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Alternate.contract.Transact(opts, "initialize")
}

// Initialize is a paid mutator transaction binding the contract method 0x8129fc1c.
//
// Solidity: function initialize() returns()
func (_Alternate *AlternateSession) Initialize() (*types.Transaction, error) {
	return _Alternate.Contract.Initialize(&_Alternate.TransactOpts)
}

// Initialize is a paid mutator transaction binding the contract method 0x8129fc1c.
//
// Solidity: function initialize() returns()
func (_Alternate *AlternateTransactorSession) Initialize() (*types.Transaction, error) {
	return _Alternate.Contract.Initialize(&_Alternate.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_Alternate *AlternateTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Alternate.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_Alternate *AlternateSession) RenounceOwnership() (*types.Transaction, error) {
	return _Alternate.Contract.RenounceOwnership(&_Alternate.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_Alternate *AlternateTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _Alternate.Contract.RenounceOwnership(&_Alternate.TransactOpts)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_Alternate *AlternateTransactor) SafeBatchTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _Alternate.contract.Transact(opts, "safeBatchTransferFrom", from, to, ids, values, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_Alternate *AlternateSession) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _Alternate.Contract.SafeBatchTransferFrom(&_Alternate.TransactOpts, from, to, ids, values, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_Alternate *AlternateTransactorSession) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _Alternate.Contract.SafeBatchTransferFrom(&_Alternate.TransactOpts, from, to, ids, values, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_Alternate *AlternateTransactor) SafeTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _Alternate.contract.Transact(opts, "safeTransferFrom", from, to, id, value, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_Alternate *AlternateSession) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _Alternate.Contract.SafeTransferFrom(&_Alternate.TransactOpts, from, to, id, value, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_Alternate *AlternateTransactorSession) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _Alternate.Contract.SafeTransferFrom(&_Alternate.TransactOpts, from, to, id, value, data)
}

// Sell is a paid mutator transaction binding the contract method 0xe4849b32.
//
// Solidity: function sell(uint256 _id) payable returns()
func (_Alternate *AlternateTransactor) Sell(opts *bind.TransactOpts, _id *big.Int) (*types.Transaction, error) {
	return _Alternate.contract.Transact(opts, "sell", _id)
}

// Sell is a paid mutator transaction binding the contract method 0xe4849b32.
//
// Solidity: function sell(uint256 _id) payable returns()
func (_Alternate *AlternateSession) Sell(_id *big.Int) (*types.Transaction, error) {
	return _Alternate.Contract.Sell(&_Alternate.TransactOpts, _id)
}

// Sell is a paid mutator transaction binding the contract method 0xe4849b32.
//
// Solidity: function sell(uint256 _id) payable returns()
func (_Alternate *AlternateTransactorSession) Sell(_id *big.Int) (*types.Transaction, error) {
	return _Alternate.Contract.Sell(&_Alternate.TransactOpts, _id)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_Alternate *AlternateTransactor) SetApprovalForAll(opts *bind.TransactOpts, operator common.Address, approved bool) (*types.Transaction, error) {
	return _Alternate.contract.Transact(opts, "setApprovalForAll", operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_Alternate *AlternateSession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _Alternate.Contract.SetApprovalForAll(&_Alternate.TransactOpts, operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_Alternate *AlternateTransactorSession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _Alternate.Contract.SetApprovalForAll(&_Alternate.TransactOpts, operator, approved)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_Alternate *AlternateTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _Alternate.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_Alternate *AlternateSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _Alternate.Contract.TransferOwnership(&_Alternate.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_Alternate *AlternateTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _Alternate.Contract.TransferOwnership(&_Alternate.TransactOpts, newOwner)
}

// UpgradeToAndCall is a paid mutator transaction binding the contract method 0x4f1ef286.
//
// Solidity: function upgradeToAndCall(address newImplementation, bytes data) payable returns()
func (_Alternate *AlternateTransactor) UpgradeToAndCall(opts *bind.TransactOpts, newImplementation common.Address, data []byte) (*types.Transaction, error) {
	return _Alternate.contract.Transact(opts, "upgradeToAndCall", newImplementation, data)
}

// UpgradeToAndCall is a paid mutator transaction binding the contract method 0x4f1ef286.
//
// Solidity: function upgradeToAndCall(address newImplementation, bytes data) payable returns()
func (_Alternate *AlternateSession) UpgradeToAndCall(newImplementation common.Address, data []byte) (*types.Transaction, error) {
	return _Alternate.Contract.UpgradeToAndCall(&_Alternate.TransactOpts, newImplementation, data)
}

// UpgradeToAndCall is a paid mutator transaction binding the contract method 0x4f1ef286.
//
// Solidity: function upgradeToAndCall(address newImplementation, bytes data) payable returns()
func (_Alternate *AlternateTransactorSession) UpgradeToAndCall(newImplementation common.Address, data []byte) (*types.Transaction, error) {
	return _Alternate.Contract.UpgradeToAndCall(&_Alternate.TransactOpts, newImplementation, data)
}

// AlternateApprovalForAllIterator is returned from FilterApprovalForAll and is used to iterate over the raw logs and unpacked data for ApprovalForAll events raised by the Alternate contract.
type AlternateApprovalForAllIterator struct {
	Event *AlternateApprovalForAll // Event containing the contract specifics and raw log

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
func (it *AlternateApprovalForAllIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AlternateApprovalForAll)
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
		it.Event = new(AlternateApprovalForAll)
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
func (it *AlternateApprovalForAllIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AlternateApprovalForAllIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AlternateApprovalForAll represents a ApprovalForAll event raised by the Alternate contract.
type AlternateApprovalForAll struct {
	Account  common.Address
	Operator common.Address
	Approved bool
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterApprovalForAll is a free log retrieval operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_Alternate *AlternateFilterer) FilterApprovalForAll(opts *bind.FilterOpts, account []common.Address, operator []common.Address) (*AlternateApprovalForAllIterator, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _Alternate.contract.FilterLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return &AlternateApprovalForAllIterator{contract: _Alternate.contract, event: "ApprovalForAll", logs: logs, sub: sub}, nil
}

// WatchApprovalForAll is a free log subscription operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_Alternate *AlternateFilterer) WatchApprovalForAll(opts *bind.WatchOpts, sink chan<- *AlternateApprovalForAll, account []common.Address, operator []common.Address) (event.Subscription, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _Alternate.contract.WatchLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AlternateApprovalForAll)
				if err := _Alternate.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
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
func (_Alternate *AlternateFilterer) ParseApprovalForAll(log types.Log) (*AlternateApprovalForAll, error) {
	event := new(AlternateApprovalForAll)
	if err := _Alternate.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AlternateAssetBoughtIterator is returned from FilterAssetBought and is used to iterate over the raw logs and unpacked data for AssetBought events raised by the Alternate contract.
type AlternateAssetBoughtIterator struct {
	Event *AlternateAssetBought // Event containing the contract specifics and raw log

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
func (it *AlternateAssetBoughtIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AlternateAssetBought)
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
		it.Event = new(AlternateAssetBought)
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
func (it *AlternateAssetBoughtIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AlternateAssetBoughtIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AlternateAssetBought represents a AssetBought event raised by the Alternate contract.
type AlternateAssetBought struct {
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
func (_Alternate *AlternateFilterer) FilterAssetBought(opts *bind.FilterOpts, assetId []*big.Int, buyer []common.Address) (*AlternateAssetBoughtIterator, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var buyerRule []interface{}
	for _, buyerItem := range buyer {
		buyerRule = append(buyerRule, buyerItem)
	}

	logs, sub, err := _Alternate.contract.FilterLogs(opts, "AssetBought", assetIdRule, buyerRule)
	if err != nil {
		return nil, err
	}
	return &AlternateAssetBoughtIterator{contract: _Alternate.contract, event: "AssetBought", logs: logs, sub: sub}, nil
}

// WatchAssetBought is a free log subscription operation binding the contract event 0xc4dd2b242df23335f8c79c84c12590a02f2c96864fc80967d45a637d0c933e39.
//
// Solidity: event AssetBought(uint256 indexed assetId, address indexed buyer, uint256 tokenCount, uint256 price, string name, uint256 timestamp)
func (_Alternate *AlternateFilterer) WatchAssetBought(opts *bind.WatchOpts, sink chan<- *AlternateAssetBought, assetId []*big.Int, buyer []common.Address) (event.Subscription, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var buyerRule []interface{}
	for _, buyerItem := range buyer {
		buyerRule = append(buyerRule, buyerItem)
	}

	logs, sub, err := _Alternate.contract.WatchLogs(opts, "AssetBought", assetIdRule, buyerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AlternateAssetBought)
				if err := _Alternate.contract.UnpackLog(event, "AssetBought", log); err != nil {
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
func (_Alternate *AlternateFilterer) ParseAssetBought(log types.Log) (*AlternateAssetBought, error) {
	event := new(AlternateAssetBought)
	if err := _Alternate.contract.UnpackLog(event, "AssetBought", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AlternateAssetIssuedIterator is returned from FilterAssetIssued and is used to iterate over the raw logs and unpacked data for AssetIssued events raised by the Alternate contract.
type AlternateAssetIssuedIterator struct {
	Event *AlternateAssetIssued // Event containing the contract specifics and raw log

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
func (it *AlternateAssetIssuedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AlternateAssetIssued)
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
		it.Event = new(AlternateAssetIssued)
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
func (it *AlternateAssetIssuedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AlternateAssetIssuedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AlternateAssetIssued represents a AssetIssued event raised by the Alternate contract.
type AlternateAssetIssued struct {
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
func (_Alternate *AlternateFilterer) FilterAssetIssued(opts *bind.FilterOpts, assetId []*big.Int, to []common.Address) (*AlternateAssetIssuedIterator, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _Alternate.contract.FilterLogs(opts, "AssetIssued", assetIdRule, toRule)
	if err != nil {
		return nil, err
	}
	return &AlternateAssetIssuedIterator{contract: _Alternate.contract, event: "AssetIssued", logs: logs, sub: sub}, nil
}

// WatchAssetIssued is a free log subscription operation binding the contract event 0xe91aa54204e7e68ec3c978f25679bd4982f4bcee900ee74aca5cdfa20fc9abfe.
//
// Solidity: event AssetIssued(uint256 indexed assetId, address indexed to, uint256 totalSupply, uint256 initialPrice, string name, string symbol, uint256 timestamp)
func (_Alternate *AlternateFilterer) WatchAssetIssued(opts *bind.WatchOpts, sink chan<- *AlternateAssetIssued, assetId []*big.Int, to []common.Address) (event.Subscription, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _Alternate.contract.WatchLogs(opts, "AssetIssued", assetIdRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AlternateAssetIssued)
				if err := _Alternate.contract.UnpackLog(event, "AssetIssued", log); err != nil {
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
func (_Alternate *AlternateFilterer) ParseAssetIssued(log types.Log) (*AlternateAssetIssued, error) {
	event := new(AlternateAssetIssued)
	if err := _Alternate.contract.UnpackLog(event, "AssetIssued", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AlternateAssetSoldIterator is returned from FilterAssetSold and is used to iterate over the raw logs and unpacked data for AssetSold events raised by the Alternate contract.
type AlternateAssetSoldIterator struct {
	Event *AlternateAssetSold // Event containing the contract specifics and raw log

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
func (it *AlternateAssetSoldIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AlternateAssetSold)
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
		it.Event = new(AlternateAssetSold)
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
func (it *AlternateAssetSoldIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AlternateAssetSoldIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AlternateAssetSold represents a AssetSold event raised by the Alternate contract.
type AlternateAssetSold struct {
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
func (_Alternate *AlternateFilterer) FilterAssetSold(opts *bind.FilterOpts, assetId []*big.Int, seller []common.Address) (*AlternateAssetSoldIterator, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var sellerRule []interface{}
	for _, sellerItem := range seller {
		sellerRule = append(sellerRule, sellerItem)
	}

	logs, sub, err := _Alternate.contract.FilterLogs(opts, "AssetSold", assetIdRule, sellerRule)
	if err != nil {
		return nil, err
	}
	return &AlternateAssetSoldIterator{contract: _Alternate.contract, event: "AssetSold", logs: logs, sub: sub}, nil
}

// WatchAssetSold is a free log subscription operation binding the contract event 0xdde523e51717d516e9022c4c6526af7c6ff2a041912e3116b1107e29ef02122f.
//
// Solidity: event AssetSold(uint256 indexed assetId, address indexed seller, uint256 tokenCount, uint256 price, string name, uint256 timestamp)
func (_Alternate *AlternateFilterer) WatchAssetSold(opts *bind.WatchOpts, sink chan<- *AlternateAssetSold, assetId []*big.Int, seller []common.Address) (event.Subscription, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var sellerRule []interface{}
	for _, sellerItem := range seller {
		sellerRule = append(sellerRule, sellerItem)
	}

	logs, sub, err := _Alternate.contract.WatchLogs(opts, "AssetSold", assetIdRule, sellerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AlternateAssetSold)
				if err := _Alternate.contract.UnpackLog(event, "AssetSold", log); err != nil {
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
func (_Alternate *AlternateFilterer) ParseAssetSold(log types.Log) (*AlternateAssetSold, error) {
	event := new(AlternateAssetSold)
	if err := _Alternate.contract.UnpackLog(event, "AssetSold", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AlternateInitializedIterator is returned from FilterInitialized and is used to iterate over the raw logs and unpacked data for Initialized events raised by the Alternate contract.
type AlternateInitializedIterator struct {
	Event *AlternateInitialized // Event containing the contract specifics and raw log

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
func (it *AlternateInitializedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AlternateInitialized)
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
		it.Event = new(AlternateInitialized)
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
func (it *AlternateInitializedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AlternateInitializedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AlternateInitialized represents a Initialized event raised by the Alternate contract.
type AlternateInitialized struct {
	Version uint64
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterInitialized is a free log retrieval operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_Alternate *AlternateFilterer) FilterInitialized(opts *bind.FilterOpts) (*AlternateInitializedIterator, error) {

	logs, sub, err := _Alternate.contract.FilterLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return &AlternateInitializedIterator{contract: _Alternate.contract, event: "Initialized", logs: logs, sub: sub}, nil
}

// WatchInitialized is a free log subscription operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_Alternate *AlternateFilterer) WatchInitialized(opts *bind.WatchOpts, sink chan<- *AlternateInitialized) (event.Subscription, error) {

	logs, sub, err := _Alternate.contract.WatchLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AlternateInitialized)
				if err := _Alternate.contract.UnpackLog(event, "Initialized", log); err != nil {
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
func (_Alternate *AlternateFilterer) ParseInitialized(log types.Log) (*AlternateInitialized, error) {
	event := new(AlternateInitialized)
	if err := _Alternate.contract.UnpackLog(event, "Initialized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AlternateOwnershipTransferredIterator is returned from FilterOwnershipTransferred and is used to iterate over the raw logs and unpacked data for OwnershipTransferred events raised by the Alternate contract.
type AlternateOwnershipTransferredIterator struct {
	Event *AlternateOwnershipTransferred // Event containing the contract specifics and raw log

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
func (it *AlternateOwnershipTransferredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AlternateOwnershipTransferred)
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
		it.Event = new(AlternateOwnershipTransferred)
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
func (it *AlternateOwnershipTransferredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AlternateOwnershipTransferredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AlternateOwnershipTransferred represents a OwnershipTransferred event raised by the Alternate contract.
type AlternateOwnershipTransferred struct {
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterOwnershipTransferred is a free log retrieval operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_Alternate *AlternateFilterer) FilterOwnershipTransferred(opts *bind.FilterOpts, previousOwner []common.Address, newOwner []common.Address) (*AlternateOwnershipTransferredIterator, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _Alternate.contract.FilterLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return &AlternateOwnershipTransferredIterator{contract: _Alternate.contract, event: "OwnershipTransferred", logs: logs, sub: sub}, nil
}

// WatchOwnershipTransferred is a free log subscription operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_Alternate *AlternateFilterer) WatchOwnershipTransferred(opts *bind.WatchOpts, sink chan<- *AlternateOwnershipTransferred, previousOwner []common.Address, newOwner []common.Address) (event.Subscription, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _Alternate.contract.WatchLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AlternateOwnershipTransferred)
				if err := _Alternate.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
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
func (_Alternate *AlternateFilterer) ParseOwnershipTransferred(log types.Log) (*AlternateOwnershipTransferred, error) {
	event := new(AlternateOwnershipTransferred)
	if err := _Alternate.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AlternateTransferBatchIterator is returned from FilterTransferBatch and is used to iterate over the raw logs and unpacked data for TransferBatch events raised by the Alternate contract.
type AlternateTransferBatchIterator struct {
	Event *AlternateTransferBatch // Event containing the contract specifics and raw log

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
func (it *AlternateTransferBatchIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AlternateTransferBatch)
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
		it.Event = new(AlternateTransferBatch)
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
func (it *AlternateTransferBatchIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AlternateTransferBatchIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AlternateTransferBatch represents a TransferBatch event raised by the Alternate contract.
type AlternateTransferBatch struct {
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
func (_Alternate *AlternateFilterer) FilterTransferBatch(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*AlternateTransferBatchIterator, error) {

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

	logs, sub, err := _Alternate.contract.FilterLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &AlternateTransferBatchIterator{contract: _Alternate.contract, event: "TransferBatch", logs: logs, sub: sub}, nil
}

// WatchTransferBatch is a free log subscription operation binding the contract event 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb.
//
// Solidity: event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values)
func (_Alternate *AlternateFilterer) WatchTransferBatch(opts *bind.WatchOpts, sink chan<- *AlternateTransferBatch, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _Alternate.contract.WatchLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AlternateTransferBatch)
				if err := _Alternate.contract.UnpackLog(event, "TransferBatch", log); err != nil {
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
func (_Alternate *AlternateFilterer) ParseTransferBatch(log types.Log) (*AlternateTransferBatch, error) {
	event := new(AlternateTransferBatch)
	if err := _Alternate.contract.UnpackLog(event, "TransferBatch", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AlternateTransferSingleIterator is returned from FilterTransferSingle and is used to iterate over the raw logs and unpacked data for TransferSingle events raised by the Alternate contract.
type AlternateTransferSingleIterator struct {
	Event *AlternateTransferSingle // Event containing the contract specifics and raw log

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
func (it *AlternateTransferSingleIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AlternateTransferSingle)
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
		it.Event = new(AlternateTransferSingle)
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
func (it *AlternateTransferSingleIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AlternateTransferSingleIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AlternateTransferSingle represents a TransferSingle event raised by the Alternate contract.
type AlternateTransferSingle struct {
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
func (_Alternate *AlternateFilterer) FilterTransferSingle(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*AlternateTransferSingleIterator, error) {

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

	logs, sub, err := _Alternate.contract.FilterLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &AlternateTransferSingleIterator{contract: _Alternate.contract, event: "TransferSingle", logs: logs, sub: sub}, nil
}

// WatchTransferSingle is a free log subscription operation binding the contract event 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62.
//
// Solidity: event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)
func (_Alternate *AlternateFilterer) WatchTransferSingle(opts *bind.WatchOpts, sink chan<- *AlternateTransferSingle, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _Alternate.contract.WatchLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AlternateTransferSingle)
				if err := _Alternate.contract.UnpackLog(event, "TransferSingle", log); err != nil {
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
func (_Alternate *AlternateFilterer) ParseTransferSingle(log types.Log) (*AlternateTransferSingle, error) {
	event := new(AlternateTransferSingle)
	if err := _Alternate.contract.UnpackLog(event, "TransferSingle", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AlternateURIIterator is returned from FilterURI and is used to iterate over the raw logs and unpacked data for URI events raised by the Alternate contract.
type AlternateURIIterator struct {
	Event *AlternateURI // Event containing the contract specifics and raw log

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
func (it *AlternateURIIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AlternateURI)
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
		it.Event = new(AlternateURI)
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
func (it *AlternateURIIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AlternateURIIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AlternateURI represents a URI event raised by the Alternate contract.
type AlternateURI struct {
	Value string
	Id    *big.Int
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterURI is a free log retrieval operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_Alternate *AlternateFilterer) FilterURI(opts *bind.FilterOpts, id []*big.Int) (*AlternateURIIterator, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _Alternate.contract.FilterLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return &AlternateURIIterator{contract: _Alternate.contract, event: "URI", logs: logs, sub: sub}, nil
}

// WatchURI is a free log subscription operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_Alternate *AlternateFilterer) WatchURI(opts *bind.WatchOpts, sink chan<- *AlternateURI, id []*big.Int) (event.Subscription, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _Alternate.contract.WatchLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AlternateURI)
				if err := _Alternate.contract.UnpackLog(event, "URI", log); err != nil {
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
func (_Alternate *AlternateFilterer) ParseURI(log types.Log) (*AlternateURI, error) {
	event := new(AlternateURI)
	if err := _Alternate.contract.UnpackLog(event, "URI", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AlternateUpgradedIterator is returned from FilterUpgraded and is used to iterate over the raw logs and unpacked data for Upgraded events raised by the Alternate contract.
type AlternateUpgradedIterator struct {
	Event *AlternateUpgraded // Event containing the contract specifics and raw log

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
func (it *AlternateUpgradedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AlternateUpgraded)
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
		it.Event = new(AlternateUpgraded)
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
func (it *AlternateUpgradedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AlternateUpgradedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AlternateUpgraded represents a Upgraded event raised by the Alternate contract.
type AlternateUpgraded struct {
	Implementation common.Address
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterUpgraded is a free log retrieval operation binding the contract event 0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b.
//
// Solidity: event Upgraded(address indexed implementation)
func (_Alternate *AlternateFilterer) FilterUpgraded(opts *bind.FilterOpts, implementation []common.Address) (*AlternateUpgradedIterator, error) {

	var implementationRule []interface{}
	for _, implementationItem := range implementation {
		implementationRule = append(implementationRule, implementationItem)
	}

	logs, sub, err := _Alternate.contract.FilterLogs(opts, "Upgraded", implementationRule)
	if err != nil {
		return nil, err
	}
	return &AlternateUpgradedIterator{contract: _Alternate.contract, event: "Upgraded", logs: logs, sub: sub}, nil
}

// WatchUpgraded is a free log subscription operation binding the contract event 0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b.
//
// Solidity: event Upgraded(address indexed implementation)
func (_Alternate *AlternateFilterer) WatchUpgraded(opts *bind.WatchOpts, sink chan<- *AlternateUpgraded, implementation []common.Address) (event.Subscription, error) {

	var implementationRule []interface{}
	for _, implementationItem := range implementation {
		implementationRule = append(implementationRule, implementationItem)
	}

	logs, sub, err := _Alternate.contract.WatchLogs(opts, "Upgraded", implementationRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AlternateUpgraded)
				if err := _Alternate.contract.UnpackLog(event, "Upgraded", log); err != nil {
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
func (_Alternate *AlternateFilterer) ParseUpgraded(log types.Log) (*AlternateUpgraded, error) {
	event := new(AlternateUpgraded)
	if err := _Alternate.contract.UnpackLog(event, "Upgraded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
