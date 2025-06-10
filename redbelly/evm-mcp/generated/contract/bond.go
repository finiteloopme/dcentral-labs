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

// BondsContractV1Bond is an auto generated low-level Go binding around an user-defined struct.
type BondsContractV1Bond struct {
	Name         string
	Symbol       string
	DocHash      string
	Country      string
	Issuer       common.Address
	TotalSupply  *big.Int
	InitialPrice *big.Int
	Logo         string
}

// BondMetaData contains all meta data concerning the Bond contract.
var BondMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"UPGRADE_INTERFACE_VERSION\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addBond\",\"inputs\":[{\"name\":\"_bond\",\"type\":\"tuple\",\"internalType\":\"structBondsContractV1.Bond\",\"components\":[{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"symbol\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"docHash\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"country\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"issuer\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"totalSupply\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"initialPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"logo\",\"type\":\"string\",\"internalType\":\"string\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"assetName\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"assetSymbol\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"assetTotalSupply\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOf\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOfBatch\",\"inputs\":[{\"name\":\"accounts\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"buy\",\"inputs\":[{\"name\":\"_id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"decimals\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAllAssetIds\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getBondsDetailsFromId\",\"inputs\":[{\"name\":\"_id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structBondsContractV1.Bond\",\"components\":[{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"symbol\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"docHash\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"country\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"issuer\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"totalSupply\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"initialPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"logo\",\"type\":\"string\",\"internalType\":\"string\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getBuyPrice\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCurrentSupply\",\"inputs\":[{\"name\":\"_id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSellPrice\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getUserAssetIds\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"initialize\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"isApprovedForAll\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"name\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proxiableUUID\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"safeBatchTransferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"values\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"safeTransferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"sell\",\"inputs\":[{\"name\":\"_id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"setApprovalForAll\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"symbol\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalBonds\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"upgradeToAndCall\",\"inputs\":[{\"name\":\"newImplementation\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"uri\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"ApprovalForAll\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AssetBought\",\"inputs\":[{\"name\":\"assetId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"buyer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"tokenCount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"price\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"name\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AssetIssued\",\"inputs\":[{\"name\":\"assetId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"totalSupply\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"initialPrice\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"name\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"symbol\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AssetSold\",\"inputs\":[{\"name\":\"assetId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"seller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"tokenCount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"price\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"name\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Initialized\",\"inputs\":[{\"name\":\"version\",\"type\":\"uint64\",\"indexed\":false,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferBatch\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"values\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferSingle\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"URI\",\"inputs\":[{\"name\":\"value\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Upgraded\",\"inputs\":[{\"name\":\"implementation\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AddressEmptyCode\",\"inputs\":[{\"name\":\"target\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InsufficientBalance\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"needed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"tokenId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidApprover\",\"inputs\":[{\"name\":\"approver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidArrayLength\",\"inputs\":[{\"name\":\"idsLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"valuesLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidOperator\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidReceiver\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidSender\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155MissingApprovalForAll\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1967InvalidImplementation\",\"inputs\":[{\"name\":\"implementation\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1967NonPayable\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FailedCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidInitialization\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NotInitializing\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"OwnableInvalidOwner\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"UUPSUnauthorizedCallContext\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UUPSUnsupportedProxiableUUID\",\"inputs\":[{\"name\":\"slot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]}]",
}

// BondABI is the input ABI used to generate the binding from.
// Deprecated: Use BondMetaData.ABI instead.
var BondABI = BondMetaData.ABI

// Bond is an auto generated Go binding around an Ethereum contract.
type Bond struct {
	BondCaller     // Read-only binding to the contract
	BondTransactor // Write-only binding to the contract
	BondFilterer   // Log filterer for contract events
}

// BondCaller is an auto generated read-only Go binding around an Ethereum contract.
type BondCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// BondTransactor is an auto generated write-only Go binding around an Ethereum contract.
type BondTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// BondFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type BondFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// BondSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type BondSession struct {
	Contract     *Bond             // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// BondCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type BondCallerSession struct {
	Contract *BondCaller   // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts // Call options to use throughout this session
}

// BondTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type BondTransactorSession struct {
	Contract     *BondTransactor   // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// BondRaw is an auto generated low-level Go binding around an Ethereum contract.
type BondRaw struct {
	Contract *Bond // Generic contract binding to access the raw methods on
}

// BondCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type BondCallerRaw struct {
	Contract *BondCaller // Generic read-only contract binding to access the raw methods on
}

// BondTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type BondTransactorRaw struct {
	Contract *BondTransactor // Generic write-only contract binding to access the raw methods on
}

// NewBond creates a new instance of Bond, bound to a specific deployed contract.
func NewBond(address common.Address, backend bind.ContractBackend) (*Bond, error) {
	contract, err := bindBond(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &Bond{BondCaller: BondCaller{contract: contract}, BondTransactor: BondTransactor{contract: contract}, BondFilterer: BondFilterer{contract: contract}}, nil
}

// NewBondCaller creates a new read-only instance of Bond, bound to a specific deployed contract.
func NewBondCaller(address common.Address, caller bind.ContractCaller) (*BondCaller, error) {
	contract, err := bindBond(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &BondCaller{contract: contract}, nil
}

// NewBondTransactor creates a new write-only instance of Bond, bound to a specific deployed contract.
func NewBondTransactor(address common.Address, transactor bind.ContractTransactor) (*BondTransactor, error) {
	contract, err := bindBond(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &BondTransactor{contract: contract}, nil
}

// NewBondFilterer creates a new log filterer instance of Bond, bound to a specific deployed contract.
func NewBondFilterer(address common.Address, filterer bind.ContractFilterer) (*BondFilterer, error) {
	contract, err := bindBond(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &BondFilterer{contract: contract}, nil
}

// bindBond binds a generic wrapper to an already deployed contract.
func bindBond(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := BondMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Bond *BondRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Bond.Contract.BondCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Bond *BondRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Bond.Contract.BondTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Bond *BondRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Bond.Contract.BondTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Bond *BondCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Bond.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Bond *BondTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Bond.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Bond *BondTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Bond.Contract.contract.Transact(opts, method, params...)
}

// UPGRADEINTERFACEVERSION is a free data retrieval call binding the contract method 0xad3cb1cc.
//
// Solidity: function UPGRADE_INTERFACE_VERSION() view returns(string)
func (_Bond *BondCaller) UPGRADEINTERFACEVERSION(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "UPGRADE_INTERFACE_VERSION")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// UPGRADEINTERFACEVERSION is a free data retrieval call binding the contract method 0xad3cb1cc.
//
// Solidity: function UPGRADE_INTERFACE_VERSION() view returns(string)
func (_Bond *BondSession) UPGRADEINTERFACEVERSION() (string, error) {
	return _Bond.Contract.UPGRADEINTERFACEVERSION(&_Bond.CallOpts)
}

// UPGRADEINTERFACEVERSION is a free data retrieval call binding the contract method 0xad3cb1cc.
//
// Solidity: function UPGRADE_INTERFACE_VERSION() view returns(string)
func (_Bond *BondCallerSession) UPGRADEINTERFACEVERSION() (string, error) {
	return _Bond.Contract.UPGRADEINTERFACEVERSION(&_Bond.CallOpts)
}

// AssetName is a free data retrieval call binding the contract method 0x01a3543d.
//
// Solidity: function assetName(uint256 id) view returns(string)
func (_Bond *BondCaller) AssetName(opts *bind.CallOpts, id *big.Int) (string, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "assetName", id)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// AssetName is a free data retrieval call binding the contract method 0x01a3543d.
//
// Solidity: function assetName(uint256 id) view returns(string)
func (_Bond *BondSession) AssetName(id *big.Int) (string, error) {
	return _Bond.Contract.AssetName(&_Bond.CallOpts, id)
}

// AssetName is a free data retrieval call binding the contract method 0x01a3543d.
//
// Solidity: function assetName(uint256 id) view returns(string)
func (_Bond *BondCallerSession) AssetName(id *big.Int) (string, error) {
	return _Bond.Contract.AssetName(&_Bond.CallOpts, id)
}

// AssetSymbol is a free data retrieval call binding the contract method 0xf701fd0a.
//
// Solidity: function assetSymbol(uint256 id) view returns(string)
func (_Bond *BondCaller) AssetSymbol(opts *bind.CallOpts, id *big.Int) (string, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "assetSymbol", id)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// AssetSymbol is a free data retrieval call binding the contract method 0xf701fd0a.
//
// Solidity: function assetSymbol(uint256 id) view returns(string)
func (_Bond *BondSession) AssetSymbol(id *big.Int) (string, error) {
	return _Bond.Contract.AssetSymbol(&_Bond.CallOpts, id)
}

// AssetSymbol is a free data retrieval call binding the contract method 0xf701fd0a.
//
// Solidity: function assetSymbol(uint256 id) view returns(string)
func (_Bond *BondCallerSession) AssetSymbol(id *big.Int) (string, error) {
	return _Bond.Contract.AssetSymbol(&_Bond.CallOpts, id)
}

// AssetTotalSupply is a free data retrieval call binding the contract method 0x1cce6ef5.
//
// Solidity: function assetTotalSupply(uint256 id) view returns(uint256)
func (_Bond *BondCaller) AssetTotalSupply(opts *bind.CallOpts, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "assetTotalSupply", id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AssetTotalSupply is a free data retrieval call binding the contract method 0x1cce6ef5.
//
// Solidity: function assetTotalSupply(uint256 id) view returns(uint256)
func (_Bond *BondSession) AssetTotalSupply(id *big.Int) (*big.Int, error) {
	return _Bond.Contract.AssetTotalSupply(&_Bond.CallOpts, id)
}

// AssetTotalSupply is a free data retrieval call binding the contract method 0x1cce6ef5.
//
// Solidity: function assetTotalSupply(uint256 id) view returns(uint256)
func (_Bond *BondCallerSession) AssetTotalSupply(id *big.Int) (*big.Int, error) {
	return _Bond.Contract.AssetTotalSupply(&_Bond.CallOpts, id)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_Bond *BondCaller) BalanceOf(opts *bind.CallOpts, account common.Address, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "balanceOf", account, id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_Bond *BondSession) BalanceOf(account common.Address, id *big.Int) (*big.Int, error) {
	return _Bond.Contract.BalanceOf(&_Bond.CallOpts, account, id)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_Bond *BondCallerSession) BalanceOf(account common.Address, id *big.Int) (*big.Int, error) {
	return _Bond.Contract.BalanceOf(&_Bond.CallOpts, account, id)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_Bond *BondCaller) BalanceOfBatch(opts *bind.CallOpts, accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "balanceOfBatch", accounts, ids)

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_Bond *BondSession) BalanceOfBatch(accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _Bond.Contract.BalanceOfBatch(&_Bond.CallOpts, accounts, ids)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_Bond *BondCallerSession) BalanceOfBatch(accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _Bond.Contract.BalanceOfBatch(&_Bond.CallOpts, accounts, ids)
}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint256)
func (_Bond *BondCaller) Decimals(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "decimals")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint256)
func (_Bond *BondSession) Decimals() (*big.Int, error) {
	return _Bond.Contract.Decimals(&_Bond.CallOpts)
}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint256)
func (_Bond *BondCallerSession) Decimals() (*big.Int, error) {
	return _Bond.Contract.Decimals(&_Bond.CallOpts)
}

// GetAllAssetIds is a free data retrieval call binding the contract method 0xe122f907.
//
// Solidity: function getAllAssetIds() view returns(uint256[])
func (_Bond *BondCaller) GetAllAssetIds(opts *bind.CallOpts) ([]*big.Int, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "getAllAssetIds")

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// GetAllAssetIds is a free data retrieval call binding the contract method 0xe122f907.
//
// Solidity: function getAllAssetIds() view returns(uint256[])
func (_Bond *BondSession) GetAllAssetIds() ([]*big.Int, error) {
	return _Bond.Contract.GetAllAssetIds(&_Bond.CallOpts)
}

// GetAllAssetIds is a free data retrieval call binding the contract method 0xe122f907.
//
// Solidity: function getAllAssetIds() view returns(uint256[])
func (_Bond *BondCallerSession) GetAllAssetIds() ([]*big.Int, error) {
	return _Bond.Contract.GetAllAssetIds(&_Bond.CallOpts)
}

// GetBondsDetailsFromId is a free data retrieval call binding the contract method 0x05f3c777.
//
// Solidity: function getBondsDetailsFromId(uint256 _id) view returns((string,string,string,string,address,uint256,uint256,string))
func (_Bond *BondCaller) GetBondsDetailsFromId(opts *bind.CallOpts, _id *big.Int) (BondsContractV1Bond, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "getBondsDetailsFromId", _id)

	if err != nil {
		return *new(BondsContractV1Bond), err
	}

	out0 := *abi.ConvertType(out[0], new(BondsContractV1Bond)).(*BondsContractV1Bond)

	return out0, err

}

// GetBondsDetailsFromId is a free data retrieval call binding the contract method 0x05f3c777.
//
// Solidity: function getBondsDetailsFromId(uint256 _id) view returns((string,string,string,string,address,uint256,uint256,string))
func (_Bond *BondSession) GetBondsDetailsFromId(_id *big.Int) (BondsContractV1Bond, error) {
	return _Bond.Contract.GetBondsDetailsFromId(&_Bond.CallOpts, _id)
}

// GetBondsDetailsFromId is a free data retrieval call binding the contract method 0x05f3c777.
//
// Solidity: function getBondsDetailsFromId(uint256 _id) view returns((string,string,string,string,address,uint256,uint256,string))
func (_Bond *BondCallerSession) GetBondsDetailsFromId(_id *big.Int) (BondsContractV1Bond, error) {
	return _Bond.Contract.GetBondsDetailsFromId(&_Bond.CallOpts, _id)
}

// GetBuyPrice is a free data retrieval call binding the contract method 0x08d4db14.
//
// Solidity: function getBuyPrice(uint256 id) view returns(uint256)
func (_Bond *BondCaller) GetBuyPrice(opts *bind.CallOpts, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "getBuyPrice", id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetBuyPrice is a free data retrieval call binding the contract method 0x08d4db14.
//
// Solidity: function getBuyPrice(uint256 id) view returns(uint256)
func (_Bond *BondSession) GetBuyPrice(id *big.Int) (*big.Int, error) {
	return _Bond.Contract.GetBuyPrice(&_Bond.CallOpts, id)
}

// GetBuyPrice is a free data retrieval call binding the contract method 0x08d4db14.
//
// Solidity: function getBuyPrice(uint256 id) view returns(uint256)
func (_Bond *BondCallerSession) GetBuyPrice(id *big.Int) (*big.Int, error) {
	return _Bond.Contract.GetBuyPrice(&_Bond.CallOpts, id)
}

// GetCurrentSupply is a free data retrieval call binding the contract method 0x46f5303d.
//
// Solidity: function getCurrentSupply(uint256 _id) view returns(uint256)
func (_Bond *BondCaller) GetCurrentSupply(opts *bind.CallOpts, _id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "getCurrentSupply", _id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetCurrentSupply is a free data retrieval call binding the contract method 0x46f5303d.
//
// Solidity: function getCurrentSupply(uint256 _id) view returns(uint256)
func (_Bond *BondSession) GetCurrentSupply(_id *big.Int) (*big.Int, error) {
	return _Bond.Contract.GetCurrentSupply(&_Bond.CallOpts, _id)
}

// GetCurrentSupply is a free data retrieval call binding the contract method 0x46f5303d.
//
// Solidity: function getCurrentSupply(uint256 _id) view returns(uint256)
func (_Bond *BondCallerSession) GetCurrentSupply(_id *big.Int) (*big.Int, error) {
	return _Bond.Contract.GetCurrentSupply(&_Bond.CallOpts, _id)
}

// GetSellPrice is a free data retrieval call binding the contract method 0xba730e53.
//
// Solidity: function getSellPrice(uint256 id) view returns(uint256)
func (_Bond *BondCaller) GetSellPrice(opts *bind.CallOpts, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "getSellPrice", id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetSellPrice is a free data retrieval call binding the contract method 0xba730e53.
//
// Solidity: function getSellPrice(uint256 id) view returns(uint256)
func (_Bond *BondSession) GetSellPrice(id *big.Int) (*big.Int, error) {
	return _Bond.Contract.GetSellPrice(&_Bond.CallOpts, id)
}

// GetSellPrice is a free data retrieval call binding the contract method 0xba730e53.
//
// Solidity: function getSellPrice(uint256 id) view returns(uint256)
func (_Bond *BondCallerSession) GetSellPrice(id *big.Int) (*big.Int, error) {
	return _Bond.Contract.GetSellPrice(&_Bond.CallOpts, id)
}

// GetUserAssetIds is a free data retrieval call binding the contract method 0x4e883ac7.
//
// Solidity: function getUserAssetIds(address user) view returns(uint256[])
func (_Bond *BondCaller) GetUserAssetIds(opts *bind.CallOpts, user common.Address) ([]*big.Int, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "getUserAssetIds", user)

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// GetUserAssetIds is a free data retrieval call binding the contract method 0x4e883ac7.
//
// Solidity: function getUserAssetIds(address user) view returns(uint256[])
func (_Bond *BondSession) GetUserAssetIds(user common.Address) ([]*big.Int, error) {
	return _Bond.Contract.GetUserAssetIds(&_Bond.CallOpts, user)
}

// GetUserAssetIds is a free data retrieval call binding the contract method 0x4e883ac7.
//
// Solidity: function getUserAssetIds(address user) view returns(uint256[])
func (_Bond *BondCallerSession) GetUserAssetIds(user common.Address) ([]*big.Int, error) {
	return _Bond.Contract.GetUserAssetIds(&_Bond.CallOpts, user)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_Bond *BondCaller) IsApprovedForAll(opts *bind.CallOpts, account common.Address, operator common.Address) (bool, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "isApprovedForAll", account, operator)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_Bond *BondSession) IsApprovedForAll(account common.Address, operator common.Address) (bool, error) {
	return _Bond.Contract.IsApprovedForAll(&_Bond.CallOpts, account, operator)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_Bond *BondCallerSession) IsApprovedForAll(account common.Address, operator common.Address) (bool, error) {
	return _Bond.Contract.IsApprovedForAll(&_Bond.CallOpts, account, operator)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_Bond *BondCaller) Name(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "name")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_Bond *BondSession) Name() (string, error) {
	return _Bond.Contract.Name(&_Bond.CallOpts)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_Bond *BondCallerSession) Name() (string, error) {
	return _Bond.Contract.Name(&_Bond.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Bond *BondCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Bond *BondSession) Owner() (common.Address, error) {
	return _Bond.Contract.Owner(&_Bond.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Bond *BondCallerSession) Owner() (common.Address, error) {
	return _Bond.Contract.Owner(&_Bond.CallOpts)
}

// ProxiableUUID is a free data retrieval call binding the contract method 0x52d1902d.
//
// Solidity: function proxiableUUID() view returns(bytes32)
func (_Bond *BondCaller) ProxiableUUID(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "proxiableUUID")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// ProxiableUUID is a free data retrieval call binding the contract method 0x52d1902d.
//
// Solidity: function proxiableUUID() view returns(bytes32)
func (_Bond *BondSession) ProxiableUUID() ([32]byte, error) {
	return _Bond.Contract.ProxiableUUID(&_Bond.CallOpts)
}

// ProxiableUUID is a free data retrieval call binding the contract method 0x52d1902d.
//
// Solidity: function proxiableUUID() view returns(bytes32)
func (_Bond *BondCallerSession) ProxiableUUID() ([32]byte, error) {
	return _Bond.Contract.ProxiableUUID(&_Bond.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Bond *BondCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Bond *BondSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _Bond.Contract.SupportsInterface(&_Bond.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Bond *BondCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _Bond.Contract.SupportsInterface(&_Bond.CallOpts, interfaceId)
}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_Bond *BondCaller) Symbol(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "symbol")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_Bond *BondSession) Symbol() (string, error) {
	return _Bond.Contract.Symbol(&_Bond.CallOpts)
}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_Bond *BondCallerSession) Symbol() (string, error) {
	return _Bond.Contract.Symbol(&_Bond.CallOpts)
}

// TotalBonds is a free data retrieval call binding the contract method 0xf263c470.
//
// Solidity: function totalBonds() view returns(uint256)
func (_Bond *BondCaller) TotalBonds(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "totalBonds")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalBonds is a free data retrieval call binding the contract method 0xf263c470.
//
// Solidity: function totalBonds() view returns(uint256)
func (_Bond *BondSession) TotalBonds() (*big.Int, error) {
	return _Bond.Contract.TotalBonds(&_Bond.CallOpts)
}

// TotalBonds is a free data retrieval call binding the contract method 0xf263c470.
//
// Solidity: function totalBonds() view returns(uint256)
func (_Bond *BondCallerSession) TotalBonds() (*big.Int, error) {
	return _Bond.Contract.TotalBonds(&_Bond.CallOpts)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_Bond *BondCaller) Uri(opts *bind.CallOpts, arg0 *big.Int) (string, error) {
	var out []interface{}
	err := _Bond.contract.Call(opts, &out, "uri", arg0)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_Bond *BondSession) Uri(arg0 *big.Int) (string, error) {
	return _Bond.Contract.Uri(&_Bond.CallOpts, arg0)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_Bond *BondCallerSession) Uri(arg0 *big.Int) (string, error) {
	return _Bond.Contract.Uri(&_Bond.CallOpts, arg0)
}

// AddBond is a paid mutator transaction binding the contract method 0x58b9dc92.
//
// Solidity: function addBond((string,string,string,string,address,uint256,uint256,string) _bond) returns()
func (_Bond *BondTransactor) AddBond(opts *bind.TransactOpts, _bond BondsContractV1Bond) (*types.Transaction, error) {
	return _Bond.contract.Transact(opts, "addBond", _bond)
}

// AddBond is a paid mutator transaction binding the contract method 0x58b9dc92.
//
// Solidity: function addBond((string,string,string,string,address,uint256,uint256,string) _bond) returns()
func (_Bond *BondSession) AddBond(_bond BondsContractV1Bond) (*types.Transaction, error) {
	return _Bond.Contract.AddBond(&_Bond.TransactOpts, _bond)
}

// AddBond is a paid mutator transaction binding the contract method 0x58b9dc92.
//
// Solidity: function addBond((string,string,string,string,address,uint256,uint256,string) _bond) returns()
func (_Bond *BondTransactorSession) AddBond(_bond BondsContractV1Bond) (*types.Transaction, error) {
	return _Bond.Contract.AddBond(&_Bond.TransactOpts, _bond)
}

// Buy is a paid mutator transaction binding the contract method 0xd96a094a.
//
// Solidity: function buy(uint256 _id) payable returns()
func (_Bond *BondTransactor) Buy(opts *bind.TransactOpts, _id *big.Int) (*types.Transaction, error) {
	return _Bond.contract.Transact(opts, "buy", _id)
}

// Buy is a paid mutator transaction binding the contract method 0xd96a094a.
//
// Solidity: function buy(uint256 _id) payable returns()
func (_Bond *BondSession) Buy(_id *big.Int) (*types.Transaction, error) {
	return _Bond.Contract.Buy(&_Bond.TransactOpts, _id)
}

// Buy is a paid mutator transaction binding the contract method 0xd96a094a.
//
// Solidity: function buy(uint256 _id) payable returns()
func (_Bond *BondTransactorSession) Buy(_id *big.Int) (*types.Transaction, error) {
	return _Bond.Contract.Buy(&_Bond.TransactOpts, _id)
}

// Initialize is a paid mutator transaction binding the contract method 0x8129fc1c.
//
// Solidity: function initialize() returns()
func (_Bond *BondTransactor) Initialize(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Bond.contract.Transact(opts, "initialize")
}

// Initialize is a paid mutator transaction binding the contract method 0x8129fc1c.
//
// Solidity: function initialize() returns()
func (_Bond *BondSession) Initialize() (*types.Transaction, error) {
	return _Bond.Contract.Initialize(&_Bond.TransactOpts)
}

// Initialize is a paid mutator transaction binding the contract method 0x8129fc1c.
//
// Solidity: function initialize() returns()
func (_Bond *BondTransactorSession) Initialize() (*types.Transaction, error) {
	return _Bond.Contract.Initialize(&_Bond.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_Bond *BondTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Bond.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_Bond *BondSession) RenounceOwnership() (*types.Transaction, error) {
	return _Bond.Contract.RenounceOwnership(&_Bond.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_Bond *BondTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _Bond.Contract.RenounceOwnership(&_Bond.TransactOpts)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_Bond *BondTransactor) SafeBatchTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _Bond.contract.Transact(opts, "safeBatchTransferFrom", from, to, ids, values, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_Bond *BondSession) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _Bond.Contract.SafeBatchTransferFrom(&_Bond.TransactOpts, from, to, ids, values, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_Bond *BondTransactorSession) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _Bond.Contract.SafeBatchTransferFrom(&_Bond.TransactOpts, from, to, ids, values, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_Bond *BondTransactor) SafeTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _Bond.contract.Transact(opts, "safeTransferFrom", from, to, id, value, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_Bond *BondSession) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _Bond.Contract.SafeTransferFrom(&_Bond.TransactOpts, from, to, id, value, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_Bond *BondTransactorSession) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _Bond.Contract.SafeTransferFrom(&_Bond.TransactOpts, from, to, id, value, data)
}

// Sell is a paid mutator transaction binding the contract method 0xe4849b32.
//
// Solidity: function sell(uint256 _id) payable returns()
func (_Bond *BondTransactor) Sell(opts *bind.TransactOpts, _id *big.Int) (*types.Transaction, error) {
	return _Bond.contract.Transact(opts, "sell", _id)
}

// Sell is a paid mutator transaction binding the contract method 0xe4849b32.
//
// Solidity: function sell(uint256 _id) payable returns()
func (_Bond *BondSession) Sell(_id *big.Int) (*types.Transaction, error) {
	return _Bond.Contract.Sell(&_Bond.TransactOpts, _id)
}

// Sell is a paid mutator transaction binding the contract method 0xe4849b32.
//
// Solidity: function sell(uint256 _id) payable returns()
func (_Bond *BondTransactorSession) Sell(_id *big.Int) (*types.Transaction, error) {
	return _Bond.Contract.Sell(&_Bond.TransactOpts, _id)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_Bond *BondTransactor) SetApprovalForAll(opts *bind.TransactOpts, operator common.Address, approved bool) (*types.Transaction, error) {
	return _Bond.contract.Transact(opts, "setApprovalForAll", operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_Bond *BondSession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _Bond.Contract.SetApprovalForAll(&_Bond.TransactOpts, operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_Bond *BondTransactorSession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _Bond.Contract.SetApprovalForAll(&_Bond.TransactOpts, operator, approved)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_Bond *BondTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _Bond.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_Bond *BondSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _Bond.Contract.TransferOwnership(&_Bond.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_Bond *BondTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _Bond.Contract.TransferOwnership(&_Bond.TransactOpts, newOwner)
}

// UpgradeToAndCall is a paid mutator transaction binding the contract method 0x4f1ef286.
//
// Solidity: function upgradeToAndCall(address newImplementation, bytes data) payable returns()
func (_Bond *BondTransactor) UpgradeToAndCall(opts *bind.TransactOpts, newImplementation common.Address, data []byte) (*types.Transaction, error) {
	return _Bond.contract.Transact(opts, "upgradeToAndCall", newImplementation, data)
}

// UpgradeToAndCall is a paid mutator transaction binding the contract method 0x4f1ef286.
//
// Solidity: function upgradeToAndCall(address newImplementation, bytes data) payable returns()
func (_Bond *BondSession) UpgradeToAndCall(newImplementation common.Address, data []byte) (*types.Transaction, error) {
	return _Bond.Contract.UpgradeToAndCall(&_Bond.TransactOpts, newImplementation, data)
}

// UpgradeToAndCall is a paid mutator transaction binding the contract method 0x4f1ef286.
//
// Solidity: function upgradeToAndCall(address newImplementation, bytes data) payable returns()
func (_Bond *BondTransactorSession) UpgradeToAndCall(newImplementation common.Address, data []byte) (*types.Transaction, error) {
	return _Bond.Contract.UpgradeToAndCall(&_Bond.TransactOpts, newImplementation, data)
}

// BondApprovalForAllIterator is returned from FilterApprovalForAll and is used to iterate over the raw logs and unpacked data for ApprovalForAll events raised by the Bond contract.
type BondApprovalForAllIterator struct {
	Event *BondApprovalForAll // Event containing the contract specifics and raw log

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
func (it *BondApprovalForAllIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(BondApprovalForAll)
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
		it.Event = new(BondApprovalForAll)
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
func (it *BondApprovalForAllIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *BondApprovalForAllIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// BondApprovalForAll represents a ApprovalForAll event raised by the Bond contract.
type BondApprovalForAll struct {
	Account  common.Address
	Operator common.Address
	Approved bool
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterApprovalForAll is a free log retrieval operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_Bond *BondFilterer) FilterApprovalForAll(opts *bind.FilterOpts, account []common.Address, operator []common.Address) (*BondApprovalForAllIterator, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _Bond.contract.FilterLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return &BondApprovalForAllIterator{contract: _Bond.contract, event: "ApprovalForAll", logs: logs, sub: sub}, nil
}

// WatchApprovalForAll is a free log subscription operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_Bond *BondFilterer) WatchApprovalForAll(opts *bind.WatchOpts, sink chan<- *BondApprovalForAll, account []common.Address, operator []common.Address) (event.Subscription, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _Bond.contract.WatchLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(BondApprovalForAll)
				if err := _Bond.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
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
func (_Bond *BondFilterer) ParseApprovalForAll(log types.Log) (*BondApprovalForAll, error) {
	event := new(BondApprovalForAll)
	if err := _Bond.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// BondAssetBoughtIterator is returned from FilterAssetBought and is used to iterate over the raw logs and unpacked data for AssetBought events raised by the Bond contract.
type BondAssetBoughtIterator struct {
	Event *BondAssetBought // Event containing the contract specifics and raw log

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
func (it *BondAssetBoughtIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(BondAssetBought)
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
		it.Event = new(BondAssetBought)
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
func (it *BondAssetBoughtIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *BondAssetBoughtIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// BondAssetBought represents a AssetBought event raised by the Bond contract.
type BondAssetBought struct {
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
func (_Bond *BondFilterer) FilterAssetBought(opts *bind.FilterOpts, assetId []*big.Int, buyer []common.Address) (*BondAssetBoughtIterator, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var buyerRule []interface{}
	for _, buyerItem := range buyer {
		buyerRule = append(buyerRule, buyerItem)
	}

	logs, sub, err := _Bond.contract.FilterLogs(opts, "AssetBought", assetIdRule, buyerRule)
	if err != nil {
		return nil, err
	}
	return &BondAssetBoughtIterator{contract: _Bond.contract, event: "AssetBought", logs: logs, sub: sub}, nil
}

// WatchAssetBought is a free log subscription operation binding the contract event 0xc4dd2b242df23335f8c79c84c12590a02f2c96864fc80967d45a637d0c933e39.
//
// Solidity: event AssetBought(uint256 indexed assetId, address indexed buyer, uint256 tokenCount, uint256 price, string name, uint256 timestamp)
func (_Bond *BondFilterer) WatchAssetBought(opts *bind.WatchOpts, sink chan<- *BondAssetBought, assetId []*big.Int, buyer []common.Address) (event.Subscription, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var buyerRule []interface{}
	for _, buyerItem := range buyer {
		buyerRule = append(buyerRule, buyerItem)
	}

	logs, sub, err := _Bond.contract.WatchLogs(opts, "AssetBought", assetIdRule, buyerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(BondAssetBought)
				if err := _Bond.contract.UnpackLog(event, "AssetBought", log); err != nil {
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
func (_Bond *BondFilterer) ParseAssetBought(log types.Log) (*BondAssetBought, error) {
	event := new(BondAssetBought)
	if err := _Bond.contract.UnpackLog(event, "AssetBought", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// BondAssetIssuedIterator is returned from FilterAssetIssued and is used to iterate over the raw logs and unpacked data for AssetIssued events raised by the Bond contract.
type BondAssetIssuedIterator struct {
	Event *BondAssetIssued // Event containing the contract specifics and raw log

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
func (it *BondAssetIssuedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(BondAssetIssued)
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
		it.Event = new(BondAssetIssued)
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
func (it *BondAssetIssuedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *BondAssetIssuedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// BondAssetIssued represents a AssetIssued event raised by the Bond contract.
type BondAssetIssued struct {
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
func (_Bond *BondFilterer) FilterAssetIssued(opts *bind.FilterOpts, assetId []*big.Int, to []common.Address) (*BondAssetIssuedIterator, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _Bond.contract.FilterLogs(opts, "AssetIssued", assetIdRule, toRule)
	if err != nil {
		return nil, err
	}
	return &BondAssetIssuedIterator{contract: _Bond.contract, event: "AssetIssued", logs: logs, sub: sub}, nil
}

// WatchAssetIssued is a free log subscription operation binding the contract event 0xe91aa54204e7e68ec3c978f25679bd4982f4bcee900ee74aca5cdfa20fc9abfe.
//
// Solidity: event AssetIssued(uint256 indexed assetId, address indexed to, uint256 totalSupply, uint256 initialPrice, string name, string symbol, uint256 timestamp)
func (_Bond *BondFilterer) WatchAssetIssued(opts *bind.WatchOpts, sink chan<- *BondAssetIssued, assetId []*big.Int, to []common.Address) (event.Subscription, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _Bond.contract.WatchLogs(opts, "AssetIssued", assetIdRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(BondAssetIssued)
				if err := _Bond.contract.UnpackLog(event, "AssetIssued", log); err != nil {
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
func (_Bond *BondFilterer) ParseAssetIssued(log types.Log) (*BondAssetIssued, error) {
	event := new(BondAssetIssued)
	if err := _Bond.contract.UnpackLog(event, "AssetIssued", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// BondAssetSoldIterator is returned from FilterAssetSold and is used to iterate over the raw logs and unpacked data for AssetSold events raised by the Bond contract.
type BondAssetSoldIterator struct {
	Event *BondAssetSold // Event containing the contract specifics and raw log

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
func (it *BondAssetSoldIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(BondAssetSold)
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
		it.Event = new(BondAssetSold)
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
func (it *BondAssetSoldIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *BondAssetSoldIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// BondAssetSold represents a AssetSold event raised by the Bond contract.
type BondAssetSold struct {
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
func (_Bond *BondFilterer) FilterAssetSold(opts *bind.FilterOpts, assetId []*big.Int, seller []common.Address) (*BondAssetSoldIterator, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var sellerRule []interface{}
	for _, sellerItem := range seller {
		sellerRule = append(sellerRule, sellerItem)
	}

	logs, sub, err := _Bond.contract.FilterLogs(opts, "AssetSold", assetIdRule, sellerRule)
	if err != nil {
		return nil, err
	}
	return &BondAssetSoldIterator{contract: _Bond.contract, event: "AssetSold", logs: logs, sub: sub}, nil
}

// WatchAssetSold is a free log subscription operation binding the contract event 0xdde523e51717d516e9022c4c6526af7c6ff2a041912e3116b1107e29ef02122f.
//
// Solidity: event AssetSold(uint256 indexed assetId, address indexed seller, uint256 tokenCount, uint256 price, string name, uint256 timestamp)
func (_Bond *BondFilterer) WatchAssetSold(opts *bind.WatchOpts, sink chan<- *BondAssetSold, assetId []*big.Int, seller []common.Address) (event.Subscription, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var sellerRule []interface{}
	for _, sellerItem := range seller {
		sellerRule = append(sellerRule, sellerItem)
	}

	logs, sub, err := _Bond.contract.WatchLogs(opts, "AssetSold", assetIdRule, sellerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(BondAssetSold)
				if err := _Bond.contract.UnpackLog(event, "AssetSold", log); err != nil {
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
func (_Bond *BondFilterer) ParseAssetSold(log types.Log) (*BondAssetSold, error) {
	event := new(BondAssetSold)
	if err := _Bond.contract.UnpackLog(event, "AssetSold", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// BondInitializedIterator is returned from FilterInitialized and is used to iterate over the raw logs and unpacked data for Initialized events raised by the Bond contract.
type BondInitializedIterator struct {
	Event *BondInitialized // Event containing the contract specifics and raw log

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
func (it *BondInitializedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(BondInitialized)
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
		it.Event = new(BondInitialized)
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
func (it *BondInitializedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *BondInitializedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// BondInitialized represents a Initialized event raised by the Bond contract.
type BondInitialized struct {
	Version uint64
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterInitialized is a free log retrieval operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_Bond *BondFilterer) FilterInitialized(opts *bind.FilterOpts) (*BondInitializedIterator, error) {

	logs, sub, err := _Bond.contract.FilterLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return &BondInitializedIterator{contract: _Bond.contract, event: "Initialized", logs: logs, sub: sub}, nil
}

// WatchInitialized is a free log subscription operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_Bond *BondFilterer) WatchInitialized(opts *bind.WatchOpts, sink chan<- *BondInitialized) (event.Subscription, error) {

	logs, sub, err := _Bond.contract.WatchLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(BondInitialized)
				if err := _Bond.contract.UnpackLog(event, "Initialized", log); err != nil {
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
func (_Bond *BondFilterer) ParseInitialized(log types.Log) (*BondInitialized, error) {
	event := new(BondInitialized)
	if err := _Bond.contract.UnpackLog(event, "Initialized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// BondOwnershipTransferredIterator is returned from FilterOwnershipTransferred and is used to iterate over the raw logs and unpacked data for OwnershipTransferred events raised by the Bond contract.
type BondOwnershipTransferredIterator struct {
	Event *BondOwnershipTransferred // Event containing the contract specifics and raw log

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
func (it *BondOwnershipTransferredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(BondOwnershipTransferred)
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
		it.Event = new(BondOwnershipTransferred)
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
func (it *BondOwnershipTransferredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *BondOwnershipTransferredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// BondOwnershipTransferred represents a OwnershipTransferred event raised by the Bond contract.
type BondOwnershipTransferred struct {
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterOwnershipTransferred is a free log retrieval operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_Bond *BondFilterer) FilterOwnershipTransferred(opts *bind.FilterOpts, previousOwner []common.Address, newOwner []common.Address) (*BondOwnershipTransferredIterator, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _Bond.contract.FilterLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return &BondOwnershipTransferredIterator{contract: _Bond.contract, event: "OwnershipTransferred", logs: logs, sub: sub}, nil
}

// WatchOwnershipTransferred is a free log subscription operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_Bond *BondFilterer) WatchOwnershipTransferred(opts *bind.WatchOpts, sink chan<- *BondOwnershipTransferred, previousOwner []common.Address, newOwner []common.Address) (event.Subscription, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _Bond.contract.WatchLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(BondOwnershipTransferred)
				if err := _Bond.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
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
func (_Bond *BondFilterer) ParseOwnershipTransferred(log types.Log) (*BondOwnershipTransferred, error) {
	event := new(BondOwnershipTransferred)
	if err := _Bond.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// BondTransferBatchIterator is returned from FilterTransferBatch and is used to iterate over the raw logs and unpacked data for TransferBatch events raised by the Bond contract.
type BondTransferBatchIterator struct {
	Event *BondTransferBatch // Event containing the contract specifics and raw log

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
func (it *BondTransferBatchIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(BondTransferBatch)
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
		it.Event = new(BondTransferBatch)
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
func (it *BondTransferBatchIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *BondTransferBatchIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// BondTransferBatch represents a TransferBatch event raised by the Bond contract.
type BondTransferBatch struct {
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
func (_Bond *BondFilterer) FilterTransferBatch(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*BondTransferBatchIterator, error) {

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

	logs, sub, err := _Bond.contract.FilterLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &BondTransferBatchIterator{contract: _Bond.contract, event: "TransferBatch", logs: logs, sub: sub}, nil
}

// WatchTransferBatch is a free log subscription operation binding the contract event 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb.
//
// Solidity: event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values)
func (_Bond *BondFilterer) WatchTransferBatch(opts *bind.WatchOpts, sink chan<- *BondTransferBatch, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _Bond.contract.WatchLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(BondTransferBatch)
				if err := _Bond.contract.UnpackLog(event, "TransferBatch", log); err != nil {
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
func (_Bond *BondFilterer) ParseTransferBatch(log types.Log) (*BondTransferBatch, error) {
	event := new(BondTransferBatch)
	if err := _Bond.contract.UnpackLog(event, "TransferBatch", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// BondTransferSingleIterator is returned from FilterTransferSingle and is used to iterate over the raw logs and unpacked data for TransferSingle events raised by the Bond contract.
type BondTransferSingleIterator struct {
	Event *BondTransferSingle // Event containing the contract specifics and raw log

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
func (it *BondTransferSingleIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(BondTransferSingle)
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
		it.Event = new(BondTransferSingle)
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
func (it *BondTransferSingleIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *BondTransferSingleIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// BondTransferSingle represents a TransferSingle event raised by the Bond contract.
type BondTransferSingle struct {
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
func (_Bond *BondFilterer) FilterTransferSingle(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*BondTransferSingleIterator, error) {

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

	logs, sub, err := _Bond.contract.FilterLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &BondTransferSingleIterator{contract: _Bond.contract, event: "TransferSingle", logs: logs, sub: sub}, nil
}

// WatchTransferSingle is a free log subscription operation binding the contract event 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62.
//
// Solidity: event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)
func (_Bond *BondFilterer) WatchTransferSingle(opts *bind.WatchOpts, sink chan<- *BondTransferSingle, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _Bond.contract.WatchLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(BondTransferSingle)
				if err := _Bond.contract.UnpackLog(event, "TransferSingle", log); err != nil {
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
func (_Bond *BondFilterer) ParseTransferSingle(log types.Log) (*BondTransferSingle, error) {
	event := new(BondTransferSingle)
	if err := _Bond.contract.UnpackLog(event, "TransferSingle", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// BondURIIterator is returned from FilterURI and is used to iterate over the raw logs and unpacked data for URI events raised by the Bond contract.
type BondURIIterator struct {
	Event *BondURI // Event containing the contract specifics and raw log

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
func (it *BondURIIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(BondURI)
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
		it.Event = new(BondURI)
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
func (it *BondURIIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *BondURIIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// BondURI represents a URI event raised by the Bond contract.
type BondURI struct {
	Value string
	Id    *big.Int
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterURI is a free log retrieval operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_Bond *BondFilterer) FilterURI(opts *bind.FilterOpts, id []*big.Int) (*BondURIIterator, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _Bond.contract.FilterLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return &BondURIIterator{contract: _Bond.contract, event: "URI", logs: logs, sub: sub}, nil
}

// WatchURI is a free log subscription operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_Bond *BondFilterer) WatchURI(opts *bind.WatchOpts, sink chan<- *BondURI, id []*big.Int) (event.Subscription, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _Bond.contract.WatchLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(BondURI)
				if err := _Bond.contract.UnpackLog(event, "URI", log); err != nil {
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
func (_Bond *BondFilterer) ParseURI(log types.Log) (*BondURI, error) {
	event := new(BondURI)
	if err := _Bond.contract.UnpackLog(event, "URI", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// BondUpgradedIterator is returned from FilterUpgraded and is used to iterate over the raw logs and unpacked data for Upgraded events raised by the Bond contract.
type BondUpgradedIterator struct {
	Event *BondUpgraded // Event containing the contract specifics and raw log

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
func (it *BondUpgradedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(BondUpgraded)
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
		it.Event = new(BondUpgraded)
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
func (it *BondUpgradedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *BondUpgradedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// BondUpgraded represents a Upgraded event raised by the Bond contract.
type BondUpgraded struct {
	Implementation common.Address
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterUpgraded is a free log retrieval operation binding the contract event 0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b.
//
// Solidity: event Upgraded(address indexed implementation)
func (_Bond *BondFilterer) FilterUpgraded(opts *bind.FilterOpts, implementation []common.Address) (*BondUpgradedIterator, error) {

	var implementationRule []interface{}
	for _, implementationItem := range implementation {
		implementationRule = append(implementationRule, implementationItem)
	}

	logs, sub, err := _Bond.contract.FilterLogs(opts, "Upgraded", implementationRule)
	if err != nil {
		return nil, err
	}
	return &BondUpgradedIterator{contract: _Bond.contract, event: "Upgraded", logs: logs, sub: sub}, nil
}

// WatchUpgraded is a free log subscription operation binding the contract event 0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b.
//
// Solidity: event Upgraded(address indexed implementation)
func (_Bond *BondFilterer) WatchUpgraded(opts *bind.WatchOpts, sink chan<- *BondUpgraded, implementation []common.Address) (event.Subscription, error) {

	var implementationRule []interface{}
	for _, implementationItem := range implementation {
		implementationRule = append(implementationRule, implementationItem)
	}

	logs, sub, err := _Bond.contract.WatchLogs(opts, "Upgraded", implementationRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(BondUpgraded)
				if err := _Bond.contract.UnpackLog(event, "Upgraded", log); err != nil {
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
func (_Bond *BondFilterer) ParseUpgraded(log types.Log) (*BondUpgraded, error) {
	event := new(BondUpgraded)
	if err := _Bond.contract.UnpackLog(event, "Upgraded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
