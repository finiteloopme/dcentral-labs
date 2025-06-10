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

// AddPropertyInArrayOtherDetails is an auto generated low-level Go binding around an user-defined struct.
type AddPropertyInArrayOtherDetails struct {
	ImageURI      string
	Neighbourhood string
	State         string
	City          string
	Description   string
	NumberOfBhk   *big.Int
	InteriorSize  *big.Int
	Archived      bool
}

// AddPropertyInArrayOtherPropertyUpdate is an auto generated low-level Go binding around an user-defined struct.
type AddPropertyInArrayOtherPropertyUpdate struct {
	Index         *big.Int
	InteriorSize  *big.Int
	NumberofBhk   *big.Int
	Neighbourhood string
	State         string
	City          string
	Description   string
}

// AddPropertyInArrayProperty is an auto generated low-level Go binding around an user-defined struct.
type AddPropertyInArrayProperty struct {
	Title       string
	Category    string
	Subcategory string
	Location    string
	Document    string
	Country     string
	Condition   string
	LotSize     *big.Int
	Price       *big.Int
	NumberOfNft *big.Int
}

// AddPropertyInArrayPropertyUpdate is an auto generated low-level Go binding around an user-defined struct.
type AddPropertyInArrayPropertyUpdate struct {
	Index       *big.Int
	Price       *big.Int
	Category    string
	Subcategory string
	Title       string
	Location    string
	Country     string
	Condition   string
	LotSize     *big.Int
}

// AddPropertyInArraySearchParams is an auto generated low-level Go binding around an user-defined struct.
type AddPropertyInArraySearchParams struct {
	Category  string
	Condition string
	Country   string
	Price     []*big.Int
	Area      []*big.Int
}

// PropertyMetaData contains all meta data concerning the Property contract.
var PropertyMetaData = &bind.MetaData{
	ABI: "[{\"inputs\":[{\"internalType\":\"address\",\"name\":\"target\",\"type\":\"address\"}],\"name\":\"AddressEmptyCode\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"sender\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"balance\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"needed\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"}],\"name\":\"ERC1155InsufficientBalance\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"approver\",\"type\":\"address\"}],\"name\":\"ERC1155InvalidApprover\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"idsLength\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"valuesLength\",\"type\":\"uint256\"}],\"name\":\"ERC1155InvalidArrayLength\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"operator\",\"type\":\"address\"}],\"name\":\"ERC1155InvalidOperator\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"receiver\",\"type\":\"address\"}],\"name\":\"ERC1155InvalidReceiver\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"sender\",\"type\":\"address\"}],\"name\":\"ERC1155InvalidSender\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"operator\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"}],\"name\":\"ERC1155MissingApprovalForAll\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"operator\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"id\",\"type\":\"uint256\"}],\"name\":\"ERC1155MissingApprovalForToken\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"implementation\",\"type\":\"address\"}],\"name\":\"ERC1967InvalidImplementation\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"ERC1967NonPayable\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"FailedInnerCall\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"InvalidInitialization\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"NotInitializing\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"}],\"name\":\"OwnableInvalidOwner\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\"}],\"name\":\"OwnableUnauthorizedAccount\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"UUPSUnauthorizedCallContext\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"slot\",\"type\":\"bytes32\"}],\"name\":\"UUPSUnsupportedProxiableUUID\",\"type\":\"error\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"_owner\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"_spender\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"uint256\",\"name\":\"_id\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"_oldValue\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"_value\",\"type\":\"uint256\"}],\"name\":\"Approval\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"operator\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"bool\",\"name\":\"approved\",\"type\":\"bool\"}],\"name\":\"ApprovalForAll\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"uint256\",\"name\":\"assetId\",\"type\":\"uint256\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"buyer\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"tokenCount\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"string\",\"name\":\"name\",\"type\":\"string\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"timestamp\",\"type\":\"uint256\"}],\"name\":\"AssetBought\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"uint256\",\"name\":\"assetId\",\"type\":\"uint256\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"totalSupply\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"initialPrice\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"string\",\"name\":\"name\",\"type\":\"string\"},{\"indexed\":false,\"internalType\":\"string\",\"name\":\"symbol\",\"type\":\"string\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"timestamp\",\"type\":\"uint256\"}],\"name\":\"AssetIssued\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"uint256\",\"name\":\"assetId\",\"type\":\"uint256\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"seller\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"tokenCount\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"string\",\"name\":\"name\",\"type\":\"string\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"timestamp\",\"type\":\"uint256\"}],\"name\":\"AssetSold\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"uint256\",\"name\":\"id\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"string\",\"name\":\"reason\",\"type\":\"string\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"newPrice\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"currentSellPrice\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"currentBuyPrice\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"afterSellPrice\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"afterBuyPrice\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"disasterTime\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"oldBasePrice\",\"type\":\"uint256\"}],\"name\":\"Disaster\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"uint64\",\"name\":\"version\",\"type\":\"uint64\"}],\"name\":\"Initialized\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"previousOwner\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"newOwner\",\"type\":\"address\"}],\"name\":\"OwnershipTransferred\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"}],\"name\":\"PropertyAdd\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"userAddress\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"string\",\"name\":\"transactionType\",\"type\":\"string\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"timestamp\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\"},{\"indexed\":true,\"internalType\":\"uint256\",\"name\":\"id\",\"type\":\"uint256\"}],\"name\":\"PropertyBuySell\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"}],\"name\":\"PropertyEdit\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"operator\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"from\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"uint256[]\",\"name\":\"ids\",\"type\":\"uint256[]\"},{\"indexed\":false,\"internalType\":\"uint256[]\",\"name\":\"values\",\"type\":\"uint256[]\"}],\"name\":\"TransferBatch\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"operator\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"from\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"id\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"value\",\"type\":\"uint256\"}],\"name\":\"TransferSingle\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"string\",\"name\":\"value\",\"type\":\"string\"},{\"indexed\":true,\"internalType\":\"uint256\",\"name\":\"id\",\"type\":\"uint256\"}],\"name\":\"URI\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"implementation\",\"type\":\"address\"}],\"name\":\"Upgraded\",\"type\":\"event\"},{\"inputs\":[],\"name\":\"UPGRADE_INTERFACE_VERSION\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"_symbol\",\"type\":\"string\"},{\"components\":[{\"internalType\":\"string\",\"name\":\"title\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"category\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"subcategory\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"location\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"document\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"country\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"condition\",\"type\":\"string\"},{\"internalType\":\"uint256\",\"name\":\"lotSize\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"numberOfNft\",\"type\":\"uint256\"}],\"internalType\":\"structaddPropertyInArray.Property\",\"name\":\"propertyDetails\",\"type\":\"tuple\"}],\"name\":\"addPropertyDetails\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"components\":[{\"internalType\":\"string\",\"name\":\"imageURI\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"neighbourhood\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"state\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"city\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"description\",\"type\":\"string\"},{\"internalType\":\"uint256\",\"name\":\"numberOfBhk\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"interiorSize\",\"type\":\"uint256\"},{\"internalType\":\"bool\",\"name\":\"archived\",\"type\":\"bool\"}],\"internalType\":\"structaddPropertyInArray.OtherDetails\",\"name\":\"_otherDetails\",\"type\":\"tuple\"}],\"name\":\"addPropertyOtherDetails\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"name\":\"allDisasters\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"reason\",\"type\":\"string\"},{\"internalType\":\"uint256\",\"name\":\"id\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"timeOfDisaster\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"name\":\"allProperties\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"title\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"category\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"subcategory\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"location\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"document\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"country\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"condition\",\"type\":\"string\"},{\"internalType\":\"uint256\",\"name\":\"lotSize\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"numberOfNft\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"name\":\"allPropertiesDetails\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"imageURI\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"neighbourhood\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"state\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"city\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"description\",\"type\":\"string\"},{\"internalType\":\"uint256\",\"name\":\"numberOfBhk\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"interiorSize\",\"type\":\"uint256\"},{\"internalType\":\"bool\",\"name\":\"archived\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"_owner\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"_spender\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"_id\",\"type\":\"uint256\"}],\"name\":\"allowance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"_spender\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"_id\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"_currentValue\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"_value\",\"type\":\"uint256\"}],\"name\":\"approve\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_tokenId\",\"type\":\"uint256\"}],\"name\":\"archiveProperty\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"id\",\"type\":\"uint256\"}],\"name\":\"assetName\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"id\",\"type\":\"uint256\"}],\"name\":\"assetSymbol\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"id\",\"type\":\"uint256\"}],\"name\":\"assetTotalSupply\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"id\",\"type\":\"uint256\"}],\"name\":\"balanceOf\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address[]\",\"name\":\"accounts\",\"type\":\"address[]\"},{\"internalType\":\"uint256[]\",\"name\":\"ids\",\"type\":\"uint256[]\"}],\"name\":\"balanceOfBatch\",\"outputs\":[{\"internalType\":\"uint256[]\",\"name\":\"\",\"type\":\"uint256[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_id\",\"type\":\"uint256\"}],\"name\":\"buy\",\"outputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"count\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_id\",\"type\":\"uint256\"},{\"internalType\":\"string\",\"name\":\"_reason\",\"type\":\"string\"},{\"internalType\":\"uint256\",\"name\":\"_newPrice\",\"type\":\"uint256\"}],\"name\":\"disasterManagement\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getAllAssetIds\",\"outputs\":[{\"internalType\":\"uint256[]\",\"name\":\"\",\"type\":\"uint256[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_id\",\"type\":\"uint256\"}],\"name\":\"getBuyPrice\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_id\",\"type\":\"uint256\"}],\"name\":\"getSellPrice\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"user\",\"type\":\"address\"}],\"name\":\"getUserAssetIds\",\"outputs\":[{\"internalType\":\"uint256[]\",\"name\":\"\",\"type\":\"uint256[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"contractGovernmentInterface\",\"name\":\"_govt\",\"type\":\"address\"}],\"name\":\"initialize\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"operator\",\"type\":\"address\"}],\"name\":\"isApprovedForAll\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"name\":\"keys\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"latestDisaster\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"reason\",\"type\":\"string\"},{\"internalType\":\"uint256\",\"name\":\"id\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"latestDisasterDetail\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"reason\",\"type\":\"string\"},{\"internalType\":\"uint256\",\"name\":\"id\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"timeOfDisaster\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"name\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"name\":\"ownedProperties\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"owner\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"proxiableUUID\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"renounceOwnership\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"from\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\"},{\"internalType\":\"uint256[]\",\"name\":\"ids\",\"type\":\"uint256[]\"},{\"internalType\":\"uint256[]\",\"name\":\"values\",\"type\":\"uint256[]\"},{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\"}],\"name\":\"safeBatchTransferFrom\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"from\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"id\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"value\",\"type\":\"uint256\"},{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\"}],\"name\":\"safeTransferFrom\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"components\":[{\"internalType\":\"string\",\"name\":\"category\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"condition\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"country\",\"type\":\"string\"},{\"internalType\":\"uint256[]\",\"name\":\"price\",\"type\":\"uint256[]\"},{\"internalType\":\"uint256[]\",\"name\":\"area\",\"type\":\"uint256[]\"}],\"internalType\":\"structaddPropertyInArray.SearchParams\",\"name\":\"_searchParams\",\"type\":\"tuple\"}],\"name\":\"searchProperty\",\"outputs\":[{\"internalType\":\"uint256[]\",\"name\":\"\",\"type\":\"uint256[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_id\",\"type\":\"uint256\"}],\"name\":\"sell\",\"outputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"operator\",\"type\":\"address\"},{\"internalType\":\"bool\",\"name\":\"approved\",\"type\":\"bool\"}],\"name\":\"setApprovalForAll\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"name\":\"supply\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"strength\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes4\",\"name\":\"interfaceId\",\"type\":\"bytes4\"}],\"name\":\"supportsInterface\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"symbol\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_id\",\"type\":\"uint256\"}],\"name\":\"totalBuyAmount\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"newOwner\",\"type\":\"address\"}],\"name\":\"transferOwnership\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"components\":[{\"internalType\":\"uint256\",\"name\":\"index\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\"},{\"internalType\":\"string\",\"name\":\"category\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"subcategory\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"title\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"location\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"country\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"condition\",\"type\":\"string\"},{\"internalType\":\"uint256\",\"name\":\"lotSize\",\"type\":\"uint256\"}],\"internalType\":\"structaddPropertyInArray.PropertyUpdate\",\"name\":\"_updateData\",\"type\":\"tuple\"}],\"name\":\"updateProperty\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"components\":[{\"internalType\":\"uint256\",\"name\":\"index\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"interiorSize\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"numberofBhk\",\"type\":\"uint256\"},{\"internalType\":\"string\",\"name\":\"neighbourhood\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"state\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"city\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"description\",\"type\":\"string\"}],\"internalType\":\"structaddPropertyInArray.OtherPropertyUpdate\",\"name\":\"_otherUpdate\",\"type\":\"tuple\"}],\"name\":\"updatePropertyDetails\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"newImplementation\",\"type\":\"address\"},{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\"}],\"name\":\"upgradeToAndCall\",\"outputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"name\":\"uri\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"withdraw\",\"outputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\"}]",
}

// PropertyABI is the input ABI used to generate the binding from.
// Deprecated: Use PropertyMetaData.ABI instead.
var PropertyABI = PropertyMetaData.ABI

// Property is an auto generated Go binding around an Ethereum contract.
type Property struct {
	PropertyCaller     // Read-only binding to the contract
	PropertyTransactor // Write-only binding to the contract
	PropertyFilterer   // Log filterer for contract events
}

// PropertyCaller is an auto generated read-only Go binding around an Ethereum contract.
type PropertyCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// PropertyTransactor is an auto generated write-only Go binding around an Ethereum contract.
type PropertyTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// PropertyFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type PropertyFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// PropertySession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type PropertySession struct {
	Contract     *Property         // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// PropertyCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type PropertyCallerSession struct {
	Contract *PropertyCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts   // Call options to use throughout this session
}

// PropertyTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type PropertyTransactorSession struct {
	Contract     *PropertyTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts   // Transaction auth options to use throughout this session
}

// PropertyRaw is an auto generated low-level Go binding around an Ethereum contract.
type PropertyRaw struct {
	Contract *Property // Generic contract binding to access the raw methods on
}

// PropertyCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type PropertyCallerRaw struct {
	Contract *PropertyCaller // Generic read-only contract binding to access the raw methods on
}

// PropertyTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type PropertyTransactorRaw struct {
	Contract *PropertyTransactor // Generic write-only contract binding to access the raw methods on
}

// NewProperty creates a new instance of Property, bound to a specific deployed contract.
func NewProperty(address common.Address, backend bind.ContractBackend) (*Property, error) {
	contract, err := bindProperty(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &Property{PropertyCaller: PropertyCaller{contract: contract}, PropertyTransactor: PropertyTransactor{contract: contract}, PropertyFilterer: PropertyFilterer{contract: contract}}, nil
}

// NewPropertyCaller creates a new read-only instance of Property, bound to a specific deployed contract.
func NewPropertyCaller(address common.Address, caller bind.ContractCaller) (*PropertyCaller, error) {
	contract, err := bindProperty(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &PropertyCaller{contract: contract}, nil
}

// NewPropertyTransactor creates a new write-only instance of Property, bound to a specific deployed contract.
func NewPropertyTransactor(address common.Address, transactor bind.ContractTransactor) (*PropertyTransactor, error) {
	contract, err := bindProperty(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &PropertyTransactor{contract: contract}, nil
}

// NewPropertyFilterer creates a new log filterer instance of Property, bound to a specific deployed contract.
func NewPropertyFilterer(address common.Address, filterer bind.ContractFilterer) (*PropertyFilterer, error) {
	contract, err := bindProperty(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &PropertyFilterer{contract: contract}, nil
}

// bindProperty binds a generic wrapper to an already deployed contract.
func bindProperty(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := PropertyMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Property *PropertyRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Property.Contract.PropertyCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Property *PropertyRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Property.Contract.PropertyTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Property *PropertyRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Property.Contract.PropertyTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Property *PropertyCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Property.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Property *PropertyTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Property.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Property *PropertyTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Property.Contract.contract.Transact(opts, method, params...)
}

// UPGRADEINTERFACEVERSION is a free data retrieval call binding the contract method 0xad3cb1cc.
//
// Solidity: function UPGRADE_INTERFACE_VERSION() view returns(string)
func (_Property *PropertyCaller) UPGRADEINTERFACEVERSION(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "UPGRADE_INTERFACE_VERSION")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// UPGRADEINTERFACEVERSION is a free data retrieval call binding the contract method 0xad3cb1cc.
//
// Solidity: function UPGRADE_INTERFACE_VERSION() view returns(string)
func (_Property *PropertySession) UPGRADEINTERFACEVERSION() (string, error) {
	return _Property.Contract.UPGRADEINTERFACEVERSION(&_Property.CallOpts)
}

// UPGRADEINTERFACEVERSION is a free data retrieval call binding the contract method 0xad3cb1cc.
//
// Solidity: function UPGRADE_INTERFACE_VERSION() view returns(string)
func (_Property *PropertyCallerSession) UPGRADEINTERFACEVERSION() (string, error) {
	return _Property.Contract.UPGRADEINTERFACEVERSION(&_Property.CallOpts)
}

// AllDisasters is a free data retrieval call binding the contract method 0xd2f347f0.
//
// Solidity: function allDisasters(uint256 ) view returns(string reason, uint256 id, uint256 timeOfDisaster)
func (_Property *PropertyCaller) AllDisasters(opts *bind.CallOpts, arg0 *big.Int) (struct {
	Reason         string
	Id             *big.Int
	TimeOfDisaster *big.Int
}, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "allDisasters", arg0)

	outstruct := new(struct {
		Reason         string
		Id             *big.Int
		TimeOfDisaster *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Reason = *abi.ConvertType(out[0], new(string)).(*string)
	outstruct.Id = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.TimeOfDisaster = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// AllDisasters is a free data retrieval call binding the contract method 0xd2f347f0.
//
// Solidity: function allDisasters(uint256 ) view returns(string reason, uint256 id, uint256 timeOfDisaster)
func (_Property *PropertySession) AllDisasters(arg0 *big.Int) (struct {
	Reason         string
	Id             *big.Int
	TimeOfDisaster *big.Int
}, error) {
	return _Property.Contract.AllDisasters(&_Property.CallOpts, arg0)
}

// AllDisasters is a free data retrieval call binding the contract method 0xd2f347f0.
//
// Solidity: function allDisasters(uint256 ) view returns(string reason, uint256 id, uint256 timeOfDisaster)
func (_Property *PropertyCallerSession) AllDisasters(arg0 *big.Int) (struct {
	Reason         string
	Id             *big.Int
	TimeOfDisaster *big.Int
}, error) {
	return _Property.Contract.AllDisasters(&_Property.CallOpts, arg0)
}

// AllProperties is a free data retrieval call binding the contract method 0xf32adadc.
//
// Solidity: function allProperties(uint256 ) view returns(string title, string category, string subcategory, string location, string document, string country, string condition, uint256 lotSize, uint256 price, uint256 numberOfNft)
func (_Property *PropertyCaller) AllProperties(opts *bind.CallOpts, arg0 *big.Int) (struct {
	Title       string
	Category    string
	Subcategory string
	Location    string
	Document    string
	Country     string
	Condition   string
	LotSize     *big.Int
	Price       *big.Int
	NumberOfNft *big.Int
}, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "allProperties", arg0)

	outstruct := new(struct {
		Title       string
		Category    string
		Subcategory string
		Location    string
		Document    string
		Country     string
		Condition   string
		LotSize     *big.Int
		Price       *big.Int
		NumberOfNft *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Title = *abi.ConvertType(out[0], new(string)).(*string)
	outstruct.Category = *abi.ConvertType(out[1], new(string)).(*string)
	outstruct.Subcategory = *abi.ConvertType(out[2], new(string)).(*string)
	outstruct.Location = *abi.ConvertType(out[3], new(string)).(*string)
	outstruct.Document = *abi.ConvertType(out[4], new(string)).(*string)
	outstruct.Country = *abi.ConvertType(out[5], new(string)).(*string)
	outstruct.Condition = *abi.ConvertType(out[6], new(string)).(*string)
	outstruct.LotSize = *abi.ConvertType(out[7], new(*big.Int)).(**big.Int)
	outstruct.Price = *abi.ConvertType(out[8], new(*big.Int)).(**big.Int)
	outstruct.NumberOfNft = *abi.ConvertType(out[9], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// AllProperties is a free data retrieval call binding the contract method 0xf32adadc.
//
// Solidity: function allProperties(uint256 ) view returns(string title, string category, string subcategory, string location, string document, string country, string condition, uint256 lotSize, uint256 price, uint256 numberOfNft)
func (_Property *PropertySession) AllProperties(arg0 *big.Int) (struct {
	Title       string
	Category    string
	Subcategory string
	Location    string
	Document    string
	Country     string
	Condition   string
	LotSize     *big.Int
	Price       *big.Int
	NumberOfNft *big.Int
}, error) {
	return _Property.Contract.AllProperties(&_Property.CallOpts, arg0)
}

// AllProperties is a free data retrieval call binding the contract method 0xf32adadc.
//
// Solidity: function allProperties(uint256 ) view returns(string title, string category, string subcategory, string location, string document, string country, string condition, uint256 lotSize, uint256 price, uint256 numberOfNft)
func (_Property *PropertyCallerSession) AllProperties(arg0 *big.Int) (struct {
	Title       string
	Category    string
	Subcategory string
	Location    string
	Document    string
	Country     string
	Condition   string
	LotSize     *big.Int
	Price       *big.Int
	NumberOfNft *big.Int
}, error) {
	return _Property.Contract.AllProperties(&_Property.CallOpts, arg0)
}

// AllPropertiesDetails is a free data retrieval call binding the contract method 0x304245fc.
//
// Solidity: function allPropertiesDetails(uint256 ) view returns(string imageURI, string neighbourhood, string state, string city, string description, uint256 numberOfBhk, uint256 interiorSize, bool archived)
func (_Property *PropertyCaller) AllPropertiesDetails(opts *bind.CallOpts, arg0 *big.Int) (struct {
	ImageURI      string
	Neighbourhood string
	State         string
	City          string
	Description   string
	NumberOfBhk   *big.Int
	InteriorSize  *big.Int
	Archived      bool
}, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "allPropertiesDetails", arg0)

	outstruct := new(struct {
		ImageURI      string
		Neighbourhood string
		State         string
		City          string
		Description   string
		NumberOfBhk   *big.Int
		InteriorSize  *big.Int
		Archived      bool
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.ImageURI = *abi.ConvertType(out[0], new(string)).(*string)
	outstruct.Neighbourhood = *abi.ConvertType(out[1], new(string)).(*string)
	outstruct.State = *abi.ConvertType(out[2], new(string)).(*string)
	outstruct.City = *abi.ConvertType(out[3], new(string)).(*string)
	outstruct.Description = *abi.ConvertType(out[4], new(string)).(*string)
	outstruct.NumberOfBhk = *abi.ConvertType(out[5], new(*big.Int)).(**big.Int)
	outstruct.InteriorSize = *abi.ConvertType(out[6], new(*big.Int)).(**big.Int)
	outstruct.Archived = *abi.ConvertType(out[7], new(bool)).(*bool)

	return *outstruct, err

}

// AllPropertiesDetails is a free data retrieval call binding the contract method 0x304245fc.
//
// Solidity: function allPropertiesDetails(uint256 ) view returns(string imageURI, string neighbourhood, string state, string city, string description, uint256 numberOfBhk, uint256 interiorSize, bool archived)
func (_Property *PropertySession) AllPropertiesDetails(arg0 *big.Int) (struct {
	ImageURI      string
	Neighbourhood string
	State         string
	City          string
	Description   string
	NumberOfBhk   *big.Int
	InteriorSize  *big.Int
	Archived      bool
}, error) {
	return _Property.Contract.AllPropertiesDetails(&_Property.CallOpts, arg0)
}

// AllPropertiesDetails is a free data retrieval call binding the contract method 0x304245fc.
//
// Solidity: function allPropertiesDetails(uint256 ) view returns(string imageURI, string neighbourhood, string state, string city, string description, uint256 numberOfBhk, uint256 interiorSize, bool archived)
func (_Property *PropertyCallerSession) AllPropertiesDetails(arg0 *big.Int) (struct {
	ImageURI      string
	Neighbourhood string
	State         string
	City          string
	Description   string
	NumberOfBhk   *big.Int
	InteriorSize  *big.Int
	Archived      bool
}, error) {
	return _Property.Contract.AllPropertiesDetails(&_Property.CallOpts, arg0)
}

// Allowance is a free data retrieval call binding the contract method 0x598af9e7.
//
// Solidity: function allowance(address _owner, address _spender, uint256 _id) view returns(uint256)
func (_Property *PropertyCaller) Allowance(opts *bind.CallOpts, _owner common.Address, _spender common.Address, _id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "allowance", _owner, _spender, _id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Allowance is a free data retrieval call binding the contract method 0x598af9e7.
//
// Solidity: function allowance(address _owner, address _spender, uint256 _id) view returns(uint256)
func (_Property *PropertySession) Allowance(_owner common.Address, _spender common.Address, _id *big.Int) (*big.Int, error) {
	return _Property.Contract.Allowance(&_Property.CallOpts, _owner, _spender, _id)
}

// Allowance is a free data retrieval call binding the contract method 0x598af9e7.
//
// Solidity: function allowance(address _owner, address _spender, uint256 _id) view returns(uint256)
func (_Property *PropertyCallerSession) Allowance(_owner common.Address, _spender common.Address, _id *big.Int) (*big.Int, error) {
	return _Property.Contract.Allowance(&_Property.CallOpts, _owner, _spender, _id)
}

// AssetName is a free data retrieval call binding the contract method 0x01a3543d.
//
// Solidity: function assetName(uint256 id) view returns(string)
func (_Property *PropertyCaller) AssetName(opts *bind.CallOpts, id *big.Int) (string, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "assetName", id)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// AssetName is a free data retrieval call binding the contract method 0x01a3543d.
//
// Solidity: function assetName(uint256 id) view returns(string)
func (_Property *PropertySession) AssetName(id *big.Int) (string, error) {
	return _Property.Contract.AssetName(&_Property.CallOpts, id)
}

// AssetName is a free data retrieval call binding the contract method 0x01a3543d.
//
// Solidity: function assetName(uint256 id) view returns(string)
func (_Property *PropertyCallerSession) AssetName(id *big.Int) (string, error) {
	return _Property.Contract.AssetName(&_Property.CallOpts, id)
}

// AssetSymbol is a free data retrieval call binding the contract method 0xf701fd0a.
//
// Solidity: function assetSymbol(uint256 id) view returns(string)
func (_Property *PropertyCaller) AssetSymbol(opts *bind.CallOpts, id *big.Int) (string, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "assetSymbol", id)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// AssetSymbol is a free data retrieval call binding the contract method 0xf701fd0a.
//
// Solidity: function assetSymbol(uint256 id) view returns(string)
func (_Property *PropertySession) AssetSymbol(id *big.Int) (string, error) {
	return _Property.Contract.AssetSymbol(&_Property.CallOpts, id)
}

// AssetSymbol is a free data retrieval call binding the contract method 0xf701fd0a.
//
// Solidity: function assetSymbol(uint256 id) view returns(string)
func (_Property *PropertyCallerSession) AssetSymbol(id *big.Int) (string, error) {
	return _Property.Contract.AssetSymbol(&_Property.CallOpts, id)
}

// AssetTotalSupply is a free data retrieval call binding the contract method 0x1cce6ef5.
//
// Solidity: function assetTotalSupply(uint256 id) view returns(uint256)
func (_Property *PropertyCaller) AssetTotalSupply(opts *bind.CallOpts, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "assetTotalSupply", id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AssetTotalSupply is a free data retrieval call binding the contract method 0x1cce6ef5.
//
// Solidity: function assetTotalSupply(uint256 id) view returns(uint256)
func (_Property *PropertySession) AssetTotalSupply(id *big.Int) (*big.Int, error) {
	return _Property.Contract.AssetTotalSupply(&_Property.CallOpts, id)
}

// AssetTotalSupply is a free data retrieval call binding the contract method 0x1cce6ef5.
//
// Solidity: function assetTotalSupply(uint256 id) view returns(uint256)
func (_Property *PropertyCallerSession) AssetTotalSupply(id *big.Int) (*big.Int, error) {
	return _Property.Contract.AssetTotalSupply(&_Property.CallOpts, id)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_Property *PropertyCaller) BalanceOf(opts *bind.CallOpts, account common.Address, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "balanceOf", account, id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_Property *PropertySession) BalanceOf(account common.Address, id *big.Int) (*big.Int, error) {
	return _Property.Contract.BalanceOf(&_Property.CallOpts, account, id)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_Property *PropertyCallerSession) BalanceOf(account common.Address, id *big.Int) (*big.Int, error) {
	return _Property.Contract.BalanceOf(&_Property.CallOpts, account, id)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_Property *PropertyCaller) BalanceOfBatch(opts *bind.CallOpts, accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "balanceOfBatch", accounts, ids)

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_Property *PropertySession) BalanceOfBatch(accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _Property.Contract.BalanceOfBatch(&_Property.CallOpts, accounts, ids)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_Property *PropertyCallerSession) BalanceOfBatch(accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _Property.Contract.BalanceOfBatch(&_Property.CallOpts, accounts, ids)
}

// Count is a free data retrieval call binding the contract method 0x06661abd.
//
// Solidity: function count() view returns(uint256)
func (_Property *PropertyCaller) Count(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "count")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Count is a free data retrieval call binding the contract method 0x06661abd.
//
// Solidity: function count() view returns(uint256)
func (_Property *PropertySession) Count() (*big.Int, error) {
	return _Property.Contract.Count(&_Property.CallOpts)
}

// Count is a free data retrieval call binding the contract method 0x06661abd.
//
// Solidity: function count() view returns(uint256)
func (_Property *PropertyCallerSession) Count() (*big.Int, error) {
	return _Property.Contract.Count(&_Property.CallOpts)
}

// GetAllAssetIds is a free data retrieval call binding the contract method 0xe122f907.
//
// Solidity: function getAllAssetIds() view returns(uint256[])
func (_Property *PropertyCaller) GetAllAssetIds(opts *bind.CallOpts) ([]*big.Int, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "getAllAssetIds")

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// GetAllAssetIds is a free data retrieval call binding the contract method 0xe122f907.
//
// Solidity: function getAllAssetIds() view returns(uint256[])
func (_Property *PropertySession) GetAllAssetIds() ([]*big.Int, error) {
	return _Property.Contract.GetAllAssetIds(&_Property.CallOpts)
}

// GetAllAssetIds is a free data retrieval call binding the contract method 0xe122f907.
//
// Solidity: function getAllAssetIds() view returns(uint256[])
func (_Property *PropertyCallerSession) GetAllAssetIds() ([]*big.Int, error) {
	return _Property.Contract.GetAllAssetIds(&_Property.CallOpts)
}

// GetBuyPrice is a free data retrieval call binding the contract method 0x08d4db14.
//
// Solidity: function getBuyPrice(uint256 _id) view returns(uint256)
func (_Property *PropertyCaller) GetBuyPrice(opts *bind.CallOpts, _id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "getBuyPrice", _id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetBuyPrice is a free data retrieval call binding the contract method 0x08d4db14.
//
// Solidity: function getBuyPrice(uint256 _id) view returns(uint256)
func (_Property *PropertySession) GetBuyPrice(_id *big.Int) (*big.Int, error) {
	return _Property.Contract.GetBuyPrice(&_Property.CallOpts, _id)
}

// GetBuyPrice is a free data retrieval call binding the contract method 0x08d4db14.
//
// Solidity: function getBuyPrice(uint256 _id) view returns(uint256)
func (_Property *PropertyCallerSession) GetBuyPrice(_id *big.Int) (*big.Int, error) {
	return _Property.Contract.GetBuyPrice(&_Property.CallOpts, _id)
}

// GetSellPrice is a free data retrieval call binding the contract method 0xba730e53.
//
// Solidity: function getSellPrice(uint256 _id) view returns(uint256)
func (_Property *PropertyCaller) GetSellPrice(opts *bind.CallOpts, _id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "getSellPrice", _id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetSellPrice is a free data retrieval call binding the contract method 0xba730e53.
//
// Solidity: function getSellPrice(uint256 _id) view returns(uint256)
func (_Property *PropertySession) GetSellPrice(_id *big.Int) (*big.Int, error) {
	return _Property.Contract.GetSellPrice(&_Property.CallOpts, _id)
}

// GetSellPrice is a free data retrieval call binding the contract method 0xba730e53.
//
// Solidity: function getSellPrice(uint256 _id) view returns(uint256)
func (_Property *PropertyCallerSession) GetSellPrice(_id *big.Int) (*big.Int, error) {
	return _Property.Contract.GetSellPrice(&_Property.CallOpts, _id)
}

// GetUserAssetIds is a free data retrieval call binding the contract method 0x4e883ac7.
//
// Solidity: function getUserAssetIds(address user) view returns(uint256[])
func (_Property *PropertyCaller) GetUserAssetIds(opts *bind.CallOpts, user common.Address) ([]*big.Int, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "getUserAssetIds", user)

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// GetUserAssetIds is a free data retrieval call binding the contract method 0x4e883ac7.
//
// Solidity: function getUserAssetIds(address user) view returns(uint256[])
func (_Property *PropertySession) GetUserAssetIds(user common.Address) ([]*big.Int, error) {
	return _Property.Contract.GetUserAssetIds(&_Property.CallOpts, user)
}

// GetUserAssetIds is a free data retrieval call binding the contract method 0x4e883ac7.
//
// Solidity: function getUserAssetIds(address user) view returns(uint256[])
func (_Property *PropertyCallerSession) GetUserAssetIds(user common.Address) ([]*big.Int, error) {
	return _Property.Contract.GetUserAssetIds(&_Property.CallOpts, user)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_Property *PropertyCaller) IsApprovedForAll(opts *bind.CallOpts, account common.Address, operator common.Address) (bool, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "isApprovedForAll", account, operator)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_Property *PropertySession) IsApprovedForAll(account common.Address, operator common.Address) (bool, error) {
	return _Property.Contract.IsApprovedForAll(&_Property.CallOpts, account, operator)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_Property *PropertyCallerSession) IsApprovedForAll(account common.Address, operator common.Address) (bool, error) {
	return _Property.Contract.IsApprovedForAll(&_Property.CallOpts, account, operator)
}

// Keys is a free data retrieval call binding the contract method 0x0cb6aaf1.
//
// Solidity: function keys(uint256 ) view returns(uint256)
func (_Property *PropertyCaller) Keys(opts *bind.CallOpts, arg0 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "keys", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Keys is a free data retrieval call binding the contract method 0x0cb6aaf1.
//
// Solidity: function keys(uint256 ) view returns(uint256)
func (_Property *PropertySession) Keys(arg0 *big.Int) (*big.Int, error) {
	return _Property.Contract.Keys(&_Property.CallOpts, arg0)
}

// Keys is a free data retrieval call binding the contract method 0x0cb6aaf1.
//
// Solidity: function keys(uint256 ) view returns(uint256)
func (_Property *PropertyCallerSession) Keys(arg0 *big.Int) (*big.Int, error) {
	return _Property.Contract.Keys(&_Property.CallOpts, arg0)
}

// LatestDisaster is a free data retrieval call binding the contract method 0x4e47fa84.
//
// Solidity: function latestDisaster() view returns(string reason, uint256 id)
func (_Property *PropertyCaller) LatestDisaster(opts *bind.CallOpts) (struct {
	Reason string
	Id     *big.Int
}, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "latestDisaster")

	outstruct := new(struct {
		Reason string
		Id     *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Reason = *abi.ConvertType(out[0], new(string)).(*string)
	outstruct.Id = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// LatestDisaster is a free data retrieval call binding the contract method 0x4e47fa84.
//
// Solidity: function latestDisaster() view returns(string reason, uint256 id)
func (_Property *PropertySession) LatestDisaster() (struct {
	Reason string
	Id     *big.Int
}, error) {
	return _Property.Contract.LatestDisaster(&_Property.CallOpts)
}

// LatestDisaster is a free data retrieval call binding the contract method 0x4e47fa84.
//
// Solidity: function latestDisaster() view returns(string reason, uint256 id)
func (_Property *PropertyCallerSession) LatestDisaster() (struct {
	Reason string
	Id     *big.Int
}, error) {
	return _Property.Contract.LatestDisaster(&_Property.CallOpts)
}

// LatestDisasterDetail is a free data retrieval call binding the contract method 0xfdf3ce33.
//
// Solidity: function latestDisasterDetail() view returns(string reason, uint256 id, uint256 timeOfDisaster)
func (_Property *PropertyCaller) LatestDisasterDetail(opts *bind.CallOpts) (struct {
	Reason         string
	Id             *big.Int
	TimeOfDisaster *big.Int
}, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "latestDisasterDetail")

	outstruct := new(struct {
		Reason         string
		Id             *big.Int
		TimeOfDisaster *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Reason = *abi.ConvertType(out[0], new(string)).(*string)
	outstruct.Id = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.TimeOfDisaster = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// LatestDisasterDetail is a free data retrieval call binding the contract method 0xfdf3ce33.
//
// Solidity: function latestDisasterDetail() view returns(string reason, uint256 id, uint256 timeOfDisaster)
func (_Property *PropertySession) LatestDisasterDetail() (struct {
	Reason         string
	Id             *big.Int
	TimeOfDisaster *big.Int
}, error) {
	return _Property.Contract.LatestDisasterDetail(&_Property.CallOpts)
}

// LatestDisasterDetail is a free data retrieval call binding the contract method 0xfdf3ce33.
//
// Solidity: function latestDisasterDetail() view returns(string reason, uint256 id, uint256 timeOfDisaster)
func (_Property *PropertyCallerSession) LatestDisasterDetail() (struct {
	Reason         string
	Id             *big.Int
	TimeOfDisaster *big.Int
}, error) {
	return _Property.Contract.LatestDisasterDetail(&_Property.CallOpts)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_Property *PropertyCaller) Name(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "name")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_Property *PropertySession) Name() (string, error) {
	return _Property.Contract.Name(&_Property.CallOpts)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_Property *PropertyCallerSession) Name() (string, error) {
	return _Property.Contract.Name(&_Property.CallOpts)
}

// OwnedProperties is a free data retrieval call binding the contract method 0xb6040c10.
//
// Solidity: function ownedProperties(address , uint256 ) view returns(uint256)
func (_Property *PropertyCaller) OwnedProperties(opts *bind.CallOpts, arg0 common.Address, arg1 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "ownedProperties", arg0, arg1)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// OwnedProperties is a free data retrieval call binding the contract method 0xb6040c10.
//
// Solidity: function ownedProperties(address , uint256 ) view returns(uint256)
func (_Property *PropertySession) OwnedProperties(arg0 common.Address, arg1 *big.Int) (*big.Int, error) {
	return _Property.Contract.OwnedProperties(&_Property.CallOpts, arg0, arg1)
}

// OwnedProperties is a free data retrieval call binding the contract method 0xb6040c10.
//
// Solidity: function ownedProperties(address , uint256 ) view returns(uint256)
func (_Property *PropertyCallerSession) OwnedProperties(arg0 common.Address, arg1 *big.Int) (*big.Int, error) {
	return _Property.Contract.OwnedProperties(&_Property.CallOpts, arg0, arg1)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Property *PropertyCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Property *PropertySession) Owner() (common.Address, error) {
	return _Property.Contract.Owner(&_Property.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Property *PropertyCallerSession) Owner() (common.Address, error) {
	return _Property.Contract.Owner(&_Property.CallOpts)
}

// ProxiableUUID is a free data retrieval call binding the contract method 0x52d1902d.
//
// Solidity: function proxiableUUID() view returns(bytes32)
func (_Property *PropertyCaller) ProxiableUUID(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "proxiableUUID")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// ProxiableUUID is a free data retrieval call binding the contract method 0x52d1902d.
//
// Solidity: function proxiableUUID() view returns(bytes32)
func (_Property *PropertySession) ProxiableUUID() ([32]byte, error) {
	return _Property.Contract.ProxiableUUID(&_Property.CallOpts)
}

// ProxiableUUID is a free data retrieval call binding the contract method 0x52d1902d.
//
// Solidity: function proxiableUUID() view returns(bytes32)
func (_Property *PropertyCallerSession) ProxiableUUID() ([32]byte, error) {
	return _Property.Contract.ProxiableUUID(&_Property.CallOpts)
}

// SearchProperty is a free data retrieval call binding the contract method 0x73118265.
//
// Solidity: function searchProperty((string,string,string,uint256[],uint256[]) _searchParams) view returns(uint256[])
func (_Property *PropertyCaller) SearchProperty(opts *bind.CallOpts, _searchParams AddPropertyInArraySearchParams) ([]*big.Int, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "searchProperty", _searchParams)

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// SearchProperty is a free data retrieval call binding the contract method 0x73118265.
//
// Solidity: function searchProperty((string,string,string,uint256[],uint256[]) _searchParams) view returns(uint256[])
func (_Property *PropertySession) SearchProperty(_searchParams AddPropertyInArraySearchParams) ([]*big.Int, error) {
	return _Property.Contract.SearchProperty(&_Property.CallOpts, _searchParams)
}

// SearchProperty is a free data retrieval call binding the contract method 0x73118265.
//
// Solidity: function searchProperty((string,string,string,uint256[],uint256[]) _searchParams) view returns(uint256[])
func (_Property *PropertyCallerSession) SearchProperty(_searchParams AddPropertyInArraySearchParams) ([]*big.Int, error) {
	return _Property.Contract.SearchProperty(&_Property.CallOpts, _searchParams)
}

// Supply is a free data retrieval call binding the contract method 0x35403023.
//
// Solidity: function supply(uint256 ) view returns(uint256 strength)
func (_Property *PropertyCaller) Supply(opts *bind.CallOpts, arg0 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "supply", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Supply is a free data retrieval call binding the contract method 0x35403023.
//
// Solidity: function supply(uint256 ) view returns(uint256 strength)
func (_Property *PropertySession) Supply(arg0 *big.Int) (*big.Int, error) {
	return _Property.Contract.Supply(&_Property.CallOpts, arg0)
}

// Supply is a free data retrieval call binding the contract method 0x35403023.
//
// Solidity: function supply(uint256 ) view returns(uint256 strength)
func (_Property *PropertyCallerSession) Supply(arg0 *big.Int) (*big.Int, error) {
	return _Property.Contract.Supply(&_Property.CallOpts, arg0)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Property *PropertyCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Property *PropertySession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _Property.Contract.SupportsInterface(&_Property.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Property *PropertyCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _Property.Contract.SupportsInterface(&_Property.CallOpts, interfaceId)
}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_Property *PropertyCaller) Symbol(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "symbol")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_Property *PropertySession) Symbol() (string, error) {
	return _Property.Contract.Symbol(&_Property.CallOpts)
}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_Property *PropertyCallerSession) Symbol() (string, error) {
	return _Property.Contract.Symbol(&_Property.CallOpts)
}

// TotalBuyAmount is a free data retrieval call binding the contract method 0x7b0acf2b.
//
// Solidity: function totalBuyAmount(uint256 _id) view returns(uint256)
func (_Property *PropertyCaller) TotalBuyAmount(opts *bind.CallOpts, _id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "totalBuyAmount", _id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalBuyAmount is a free data retrieval call binding the contract method 0x7b0acf2b.
//
// Solidity: function totalBuyAmount(uint256 _id) view returns(uint256)
func (_Property *PropertySession) TotalBuyAmount(_id *big.Int) (*big.Int, error) {
	return _Property.Contract.TotalBuyAmount(&_Property.CallOpts, _id)
}

// TotalBuyAmount is a free data retrieval call binding the contract method 0x7b0acf2b.
//
// Solidity: function totalBuyAmount(uint256 _id) view returns(uint256)
func (_Property *PropertyCallerSession) TotalBuyAmount(_id *big.Int) (*big.Int, error) {
	return _Property.Contract.TotalBuyAmount(&_Property.CallOpts, _id)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_Property *PropertyCaller) Uri(opts *bind.CallOpts, arg0 *big.Int) (string, error) {
	var out []interface{}
	err := _Property.contract.Call(opts, &out, "uri", arg0)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_Property *PropertySession) Uri(arg0 *big.Int) (string, error) {
	return _Property.Contract.Uri(&_Property.CallOpts, arg0)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_Property *PropertyCallerSession) Uri(arg0 *big.Int) (string, error) {
	return _Property.Contract.Uri(&_Property.CallOpts, arg0)
}

// AddPropertyDetails is a paid mutator transaction binding the contract method 0x4aaad965.
//
// Solidity: function addPropertyDetails(string _symbol, (string,string,string,string,string,string,string,uint256,uint256,uint256) propertyDetails) returns()
func (_Property *PropertyTransactor) AddPropertyDetails(opts *bind.TransactOpts, _symbol string, propertyDetails AddPropertyInArrayProperty) (*types.Transaction, error) {
	return _Property.contract.Transact(opts, "addPropertyDetails", _symbol, propertyDetails)
}

// AddPropertyDetails is a paid mutator transaction binding the contract method 0x4aaad965.
//
// Solidity: function addPropertyDetails(string _symbol, (string,string,string,string,string,string,string,uint256,uint256,uint256) propertyDetails) returns()
func (_Property *PropertySession) AddPropertyDetails(_symbol string, propertyDetails AddPropertyInArrayProperty) (*types.Transaction, error) {
	return _Property.Contract.AddPropertyDetails(&_Property.TransactOpts, _symbol, propertyDetails)
}

// AddPropertyDetails is a paid mutator transaction binding the contract method 0x4aaad965.
//
// Solidity: function addPropertyDetails(string _symbol, (string,string,string,string,string,string,string,uint256,uint256,uint256) propertyDetails) returns()
func (_Property *PropertyTransactorSession) AddPropertyDetails(_symbol string, propertyDetails AddPropertyInArrayProperty) (*types.Transaction, error) {
	return _Property.Contract.AddPropertyDetails(&_Property.TransactOpts, _symbol, propertyDetails)
}

// AddPropertyOtherDetails is a paid mutator transaction binding the contract method 0x3b687e7a.
//
// Solidity: function addPropertyOtherDetails((string,string,string,string,string,uint256,uint256,bool) _otherDetails) returns()
func (_Property *PropertyTransactor) AddPropertyOtherDetails(opts *bind.TransactOpts, _otherDetails AddPropertyInArrayOtherDetails) (*types.Transaction, error) {
	return _Property.contract.Transact(opts, "addPropertyOtherDetails", _otherDetails)
}

// AddPropertyOtherDetails is a paid mutator transaction binding the contract method 0x3b687e7a.
//
// Solidity: function addPropertyOtherDetails((string,string,string,string,string,uint256,uint256,bool) _otherDetails) returns()
func (_Property *PropertySession) AddPropertyOtherDetails(_otherDetails AddPropertyInArrayOtherDetails) (*types.Transaction, error) {
	return _Property.Contract.AddPropertyOtherDetails(&_Property.TransactOpts, _otherDetails)
}

// AddPropertyOtherDetails is a paid mutator transaction binding the contract method 0x3b687e7a.
//
// Solidity: function addPropertyOtherDetails((string,string,string,string,string,uint256,uint256,bool) _otherDetails) returns()
func (_Property *PropertyTransactorSession) AddPropertyOtherDetails(_otherDetails AddPropertyInArrayOtherDetails) (*types.Transaction, error) {
	return _Property.Contract.AddPropertyOtherDetails(&_Property.TransactOpts, _otherDetails)
}

// Approve is a paid mutator transaction binding the contract method 0x4f4df442.
//
// Solidity: function approve(address _spender, uint256 _id, uint256 _currentValue, uint256 _value) returns()
func (_Property *PropertyTransactor) Approve(opts *bind.TransactOpts, _spender common.Address, _id *big.Int, _currentValue *big.Int, _value *big.Int) (*types.Transaction, error) {
	return _Property.contract.Transact(opts, "approve", _spender, _id, _currentValue, _value)
}

// Approve is a paid mutator transaction binding the contract method 0x4f4df442.
//
// Solidity: function approve(address _spender, uint256 _id, uint256 _currentValue, uint256 _value) returns()
func (_Property *PropertySession) Approve(_spender common.Address, _id *big.Int, _currentValue *big.Int, _value *big.Int) (*types.Transaction, error) {
	return _Property.Contract.Approve(&_Property.TransactOpts, _spender, _id, _currentValue, _value)
}

// Approve is a paid mutator transaction binding the contract method 0x4f4df442.
//
// Solidity: function approve(address _spender, uint256 _id, uint256 _currentValue, uint256 _value) returns()
func (_Property *PropertyTransactorSession) Approve(_spender common.Address, _id *big.Int, _currentValue *big.Int, _value *big.Int) (*types.Transaction, error) {
	return _Property.Contract.Approve(&_Property.TransactOpts, _spender, _id, _currentValue, _value)
}

// ArchiveProperty is a paid mutator transaction binding the contract method 0xc4107aed.
//
// Solidity: function archiveProperty(uint256 _tokenId) returns()
func (_Property *PropertyTransactor) ArchiveProperty(opts *bind.TransactOpts, _tokenId *big.Int) (*types.Transaction, error) {
	return _Property.contract.Transact(opts, "archiveProperty", _tokenId)
}

// ArchiveProperty is a paid mutator transaction binding the contract method 0xc4107aed.
//
// Solidity: function archiveProperty(uint256 _tokenId) returns()
func (_Property *PropertySession) ArchiveProperty(_tokenId *big.Int) (*types.Transaction, error) {
	return _Property.Contract.ArchiveProperty(&_Property.TransactOpts, _tokenId)
}

// ArchiveProperty is a paid mutator transaction binding the contract method 0xc4107aed.
//
// Solidity: function archiveProperty(uint256 _tokenId) returns()
func (_Property *PropertyTransactorSession) ArchiveProperty(_tokenId *big.Int) (*types.Transaction, error) {
	return _Property.Contract.ArchiveProperty(&_Property.TransactOpts, _tokenId)
}

// Buy is a paid mutator transaction binding the contract method 0xd96a094a.
//
// Solidity: function buy(uint256 _id) payable returns()
func (_Property *PropertyTransactor) Buy(opts *bind.TransactOpts, _id *big.Int) (*types.Transaction, error) {
	return _Property.contract.Transact(opts, "buy", _id)
}

// Buy is a paid mutator transaction binding the contract method 0xd96a094a.
//
// Solidity: function buy(uint256 _id) payable returns()
func (_Property *PropertySession) Buy(_id *big.Int) (*types.Transaction, error) {
	return _Property.Contract.Buy(&_Property.TransactOpts, _id)
}

// Buy is a paid mutator transaction binding the contract method 0xd96a094a.
//
// Solidity: function buy(uint256 _id) payable returns()
func (_Property *PropertyTransactorSession) Buy(_id *big.Int) (*types.Transaction, error) {
	return _Property.Contract.Buy(&_Property.TransactOpts, _id)
}

// DisasterManagement is a paid mutator transaction binding the contract method 0x91f2a5df.
//
// Solidity: function disasterManagement(uint256 _id, string _reason, uint256 _newPrice) returns()
func (_Property *PropertyTransactor) DisasterManagement(opts *bind.TransactOpts, _id *big.Int, _reason string, _newPrice *big.Int) (*types.Transaction, error) {
	return _Property.contract.Transact(opts, "disasterManagement", _id, _reason, _newPrice)
}

// DisasterManagement is a paid mutator transaction binding the contract method 0x91f2a5df.
//
// Solidity: function disasterManagement(uint256 _id, string _reason, uint256 _newPrice) returns()
func (_Property *PropertySession) DisasterManagement(_id *big.Int, _reason string, _newPrice *big.Int) (*types.Transaction, error) {
	return _Property.Contract.DisasterManagement(&_Property.TransactOpts, _id, _reason, _newPrice)
}

// DisasterManagement is a paid mutator transaction binding the contract method 0x91f2a5df.
//
// Solidity: function disasterManagement(uint256 _id, string _reason, uint256 _newPrice) returns()
func (_Property *PropertyTransactorSession) DisasterManagement(_id *big.Int, _reason string, _newPrice *big.Int) (*types.Transaction, error) {
	return _Property.Contract.DisasterManagement(&_Property.TransactOpts, _id, _reason, _newPrice)
}

// Initialize is a paid mutator transaction binding the contract method 0xc4d66de8.
//
// Solidity: function initialize(address _govt) returns()
func (_Property *PropertyTransactor) Initialize(opts *bind.TransactOpts, _govt common.Address) (*types.Transaction, error) {
	return _Property.contract.Transact(opts, "initialize", _govt)
}

// Initialize is a paid mutator transaction binding the contract method 0xc4d66de8.
//
// Solidity: function initialize(address _govt) returns()
func (_Property *PropertySession) Initialize(_govt common.Address) (*types.Transaction, error) {
	return _Property.Contract.Initialize(&_Property.TransactOpts, _govt)
}

// Initialize is a paid mutator transaction binding the contract method 0xc4d66de8.
//
// Solidity: function initialize(address _govt) returns()
func (_Property *PropertyTransactorSession) Initialize(_govt common.Address) (*types.Transaction, error) {
	return _Property.Contract.Initialize(&_Property.TransactOpts, _govt)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_Property *PropertyTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Property.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_Property *PropertySession) RenounceOwnership() (*types.Transaction, error) {
	return _Property.Contract.RenounceOwnership(&_Property.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_Property *PropertyTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _Property.Contract.RenounceOwnership(&_Property.TransactOpts)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_Property *PropertyTransactor) SafeBatchTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _Property.contract.Transact(opts, "safeBatchTransferFrom", from, to, ids, values, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_Property *PropertySession) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _Property.Contract.SafeBatchTransferFrom(&_Property.TransactOpts, from, to, ids, values, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_Property *PropertyTransactorSession) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _Property.Contract.SafeBatchTransferFrom(&_Property.TransactOpts, from, to, ids, values, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_Property *PropertyTransactor) SafeTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _Property.contract.Transact(opts, "safeTransferFrom", from, to, id, value, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_Property *PropertySession) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _Property.Contract.SafeTransferFrom(&_Property.TransactOpts, from, to, id, value, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_Property *PropertyTransactorSession) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _Property.Contract.SafeTransferFrom(&_Property.TransactOpts, from, to, id, value, data)
}

// Sell is a paid mutator transaction binding the contract method 0xe4849b32.
//
// Solidity: function sell(uint256 _id) payable returns()
func (_Property *PropertyTransactor) Sell(opts *bind.TransactOpts, _id *big.Int) (*types.Transaction, error) {
	return _Property.contract.Transact(opts, "sell", _id)
}

// Sell is a paid mutator transaction binding the contract method 0xe4849b32.
//
// Solidity: function sell(uint256 _id) payable returns()
func (_Property *PropertySession) Sell(_id *big.Int) (*types.Transaction, error) {
	return _Property.Contract.Sell(&_Property.TransactOpts, _id)
}

// Sell is a paid mutator transaction binding the contract method 0xe4849b32.
//
// Solidity: function sell(uint256 _id) payable returns()
func (_Property *PropertyTransactorSession) Sell(_id *big.Int) (*types.Transaction, error) {
	return _Property.Contract.Sell(&_Property.TransactOpts, _id)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_Property *PropertyTransactor) SetApprovalForAll(opts *bind.TransactOpts, operator common.Address, approved bool) (*types.Transaction, error) {
	return _Property.contract.Transact(opts, "setApprovalForAll", operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_Property *PropertySession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _Property.Contract.SetApprovalForAll(&_Property.TransactOpts, operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_Property *PropertyTransactorSession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _Property.Contract.SetApprovalForAll(&_Property.TransactOpts, operator, approved)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_Property *PropertyTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _Property.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_Property *PropertySession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _Property.Contract.TransferOwnership(&_Property.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_Property *PropertyTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _Property.Contract.TransferOwnership(&_Property.TransactOpts, newOwner)
}

// UpdateProperty is a paid mutator transaction binding the contract method 0x7f72b75d.
//
// Solidity: function updateProperty((uint256,uint256,string,string,string,string,string,string,uint256) _updateData) returns()
func (_Property *PropertyTransactor) UpdateProperty(opts *bind.TransactOpts, _updateData AddPropertyInArrayPropertyUpdate) (*types.Transaction, error) {
	return _Property.contract.Transact(opts, "updateProperty", _updateData)
}

// UpdateProperty is a paid mutator transaction binding the contract method 0x7f72b75d.
//
// Solidity: function updateProperty((uint256,uint256,string,string,string,string,string,string,uint256) _updateData) returns()
func (_Property *PropertySession) UpdateProperty(_updateData AddPropertyInArrayPropertyUpdate) (*types.Transaction, error) {
	return _Property.Contract.UpdateProperty(&_Property.TransactOpts, _updateData)
}

// UpdateProperty is a paid mutator transaction binding the contract method 0x7f72b75d.
//
// Solidity: function updateProperty((uint256,uint256,string,string,string,string,string,string,uint256) _updateData) returns()
func (_Property *PropertyTransactorSession) UpdateProperty(_updateData AddPropertyInArrayPropertyUpdate) (*types.Transaction, error) {
	return _Property.Contract.UpdateProperty(&_Property.TransactOpts, _updateData)
}

// UpdatePropertyDetails is a paid mutator transaction binding the contract method 0xfd890dd3.
//
// Solidity: function updatePropertyDetails((uint256,uint256,uint256,string,string,string,string) _otherUpdate) returns()
func (_Property *PropertyTransactor) UpdatePropertyDetails(opts *bind.TransactOpts, _otherUpdate AddPropertyInArrayOtherPropertyUpdate) (*types.Transaction, error) {
	return _Property.contract.Transact(opts, "updatePropertyDetails", _otherUpdate)
}

// UpdatePropertyDetails is a paid mutator transaction binding the contract method 0xfd890dd3.
//
// Solidity: function updatePropertyDetails((uint256,uint256,uint256,string,string,string,string) _otherUpdate) returns()
func (_Property *PropertySession) UpdatePropertyDetails(_otherUpdate AddPropertyInArrayOtherPropertyUpdate) (*types.Transaction, error) {
	return _Property.Contract.UpdatePropertyDetails(&_Property.TransactOpts, _otherUpdate)
}

// UpdatePropertyDetails is a paid mutator transaction binding the contract method 0xfd890dd3.
//
// Solidity: function updatePropertyDetails((uint256,uint256,uint256,string,string,string,string) _otherUpdate) returns()
func (_Property *PropertyTransactorSession) UpdatePropertyDetails(_otherUpdate AddPropertyInArrayOtherPropertyUpdate) (*types.Transaction, error) {
	return _Property.Contract.UpdatePropertyDetails(&_Property.TransactOpts, _otherUpdate)
}

// UpgradeToAndCall is a paid mutator transaction binding the contract method 0x4f1ef286.
//
// Solidity: function upgradeToAndCall(address newImplementation, bytes data) payable returns()
func (_Property *PropertyTransactor) UpgradeToAndCall(opts *bind.TransactOpts, newImplementation common.Address, data []byte) (*types.Transaction, error) {
	return _Property.contract.Transact(opts, "upgradeToAndCall", newImplementation, data)
}

// UpgradeToAndCall is a paid mutator transaction binding the contract method 0x4f1ef286.
//
// Solidity: function upgradeToAndCall(address newImplementation, bytes data) payable returns()
func (_Property *PropertySession) UpgradeToAndCall(newImplementation common.Address, data []byte) (*types.Transaction, error) {
	return _Property.Contract.UpgradeToAndCall(&_Property.TransactOpts, newImplementation, data)
}

// UpgradeToAndCall is a paid mutator transaction binding the contract method 0x4f1ef286.
//
// Solidity: function upgradeToAndCall(address newImplementation, bytes data) payable returns()
func (_Property *PropertyTransactorSession) UpgradeToAndCall(newImplementation common.Address, data []byte) (*types.Transaction, error) {
	return _Property.Contract.UpgradeToAndCall(&_Property.TransactOpts, newImplementation, data)
}

// Withdraw is a paid mutator transaction binding the contract method 0x3ccfd60b.
//
// Solidity: function withdraw() payable returns()
func (_Property *PropertyTransactor) Withdraw(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Property.contract.Transact(opts, "withdraw")
}

// Withdraw is a paid mutator transaction binding the contract method 0x3ccfd60b.
//
// Solidity: function withdraw() payable returns()
func (_Property *PropertySession) Withdraw() (*types.Transaction, error) {
	return _Property.Contract.Withdraw(&_Property.TransactOpts)
}

// Withdraw is a paid mutator transaction binding the contract method 0x3ccfd60b.
//
// Solidity: function withdraw() payable returns()
func (_Property *PropertyTransactorSession) Withdraw() (*types.Transaction, error) {
	return _Property.Contract.Withdraw(&_Property.TransactOpts)
}

// PropertyApprovalIterator is returned from FilterApproval and is used to iterate over the raw logs and unpacked data for Approval events raised by the Property contract.
type PropertyApprovalIterator struct {
	Event *PropertyApproval // Event containing the contract specifics and raw log

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
func (it *PropertyApprovalIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PropertyApproval)
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
		it.Event = new(PropertyApproval)
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
func (it *PropertyApprovalIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PropertyApprovalIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PropertyApproval represents a Approval event raised by the Property contract.
type PropertyApproval struct {
	Owner    common.Address
	Spender  common.Address
	Id       *big.Int
	OldValue *big.Int
	Value    *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterApproval is a free log retrieval operation binding the contract event 0x3a9c85c6b31f7a9d7fe1478f53e1be42e85db97ca30d1789cfef9196dbc472c9.
//
// Solidity: event Approval(address indexed _owner, address indexed _spender, uint256 indexed _id, uint256 _oldValue, uint256 _value)
func (_Property *PropertyFilterer) FilterApproval(opts *bind.FilterOpts, _owner []common.Address, _spender []common.Address, _id []*big.Int) (*PropertyApprovalIterator, error) {

	var _ownerRule []interface{}
	for _, _ownerItem := range _owner {
		_ownerRule = append(_ownerRule, _ownerItem)
	}
	var _spenderRule []interface{}
	for _, _spenderItem := range _spender {
		_spenderRule = append(_spenderRule, _spenderItem)
	}
	var _idRule []interface{}
	for _, _idItem := range _id {
		_idRule = append(_idRule, _idItem)
	}

	logs, sub, err := _Property.contract.FilterLogs(opts, "Approval", _ownerRule, _spenderRule, _idRule)
	if err != nil {
		return nil, err
	}
	return &PropertyApprovalIterator{contract: _Property.contract, event: "Approval", logs: logs, sub: sub}, nil
}

// WatchApproval is a free log subscription operation binding the contract event 0x3a9c85c6b31f7a9d7fe1478f53e1be42e85db97ca30d1789cfef9196dbc472c9.
//
// Solidity: event Approval(address indexed _owner, address indexed _spender, uint256 indexed _id, uint256 _oldValue, uint256 _value)
func (_Property *PropertyFilterer) WatchApproval(opts *bind.WatchOpts, sink chan<- *PropertyApproval, _owner []common.Address, _spender []common.Address, _id []*big.Int) (event.Subscription, error) {

	var _ownerRule []interface{}
	for _, _ownerItem := range _owner {
		_ownerRule = append(_ownerRule, _ownerItem)
	}
	var _spenderRule []interface{}
	for _, _spenderItem := range _spender {
		_spenderRule = append(_spenderRule, _spenderItem)
	}
	var _idRule []interface{}
	for _, _idItem := range _id {
		_idRule = append(_idRule, _idItem)
	}

	logs, sub, err := _Property.contract.WatchLogs(opts, "Approval", _ownerRule, _spenderRule, _idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PropertyApproval)
				if err := _Property.contract.UnpackLog(event, "Approval", log); err != nil {
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

// ParseApproval is a log parse operation binding the contract event 0x3a9c85c6b31f7a9d7fe1478f53e1be42e85db97ca30d1789cfef9196dbc472c9.
//
// Solidity: event Approval(address indexed _owner, address indexed _spender, uint256 indexed _id, uint256 _oldValue, uint256 _value)
func (_Property *PropertyFilterer) ParseApproval(log types.Log) (*PropertyApproval, error) {
	event := new(PropertyApproval)
	if err := _Property.contract.UnpackLog(event, "Approval", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// PropertyApprovalForAllIterator is returned from FilterApprovalForAll and is used to iterate over the raw logs and unpacked data for ApprovalForAll events raised by the Property contract.
type PropertyApprovalForAllIterator struct {
	Event *PropertyApprovalForAll // Event containing the contract specifics and raw log

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
func (it *PropertyApprovalForAllIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PropertyApprovalForAll)
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
		it.Event = new(PropertyApprovalForAll)
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
func (it *PropertyApprovalForAllIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PropertyApprovalForAllIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PropertyApprovalForAll represents a ApprovalForAll event raised by the Property contract.
type PropertyApprovalForAll struct {
	Account  common.Address
	Operator common.Address
	Approved bool
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterApprovalForAll is a free log retrieval operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_Property *PropertyFilterer) FilterApprovalForAll(opts *bind.FilterOpts, account []common.Address, operator []common.Address) (*PropertyApprovalForAllIterator, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _Property.contract.FilterLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return &PropertyApprovalForAllIterator{contract: _Property.contract, event: "ApprovalForAll", logs: logs, sub: sub}, nil
}

// WatchApprovalForAll is a free log subscription operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_Property *PropertyFilterer) WatchApprovalForAll(opts *bind.WatchOpts, sink chan<- *PropertyApprovalForAll, account []common.Address, operator []common.Address) (event.Subscription, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _Property.contract.WatchLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PropertyApprovalForAll)
				if err := _Property.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
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
func (_Property *PropertyFilterer) ParseApprovalForAll(log types.Log) (*PropertyApprovalForAll, error) {
	event := new(PropertyApprovalForAll)
	if err := _Property.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// PropertyAssetBoughtIterator is returned from FilterAssetBought and is used to iterate over the raw logs and unpacked data for AssetBought events raised by the Property contract.
type PropertyAssetBoughtIterator struct {
	Event *PropertyAssetBought // Event containing the contract specifics and raw log

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
func (it *PropertyAssetBoughtIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PropertyAssetBought)
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
		it.Event = new(PropertyAssetBought)
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
func (it *PropertyAssetBoughtIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PropertyAssetBoughtIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PropertyAssetBought represents a AssetBought event raised by the Property contract.
type PropertyAssetBought struct {
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
func (_Property *PropertyFilterer) FilterAssetBought(opts *bind.FilterOpts, assetId []*big.Int, buyer []common.Address) (*PropertyAssetBoughtIterator, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var buyerRule []interface{}
	for _, buyerItem := range buyer {
		buyerRule = append(buyerRule, buyerItem)
	}

	logs, sub, err := _Property.contract.FilterLogs(opts, "AssetBought", assetIdRule, buyerRule)
	if err != nil {
		return nil, err
	}
	return &PropertyAssetBoughtIterator{contract: _Property.contract, event: "AssetBought", logs: logs, sub: sub}, nil
}

// WatchAssetBought is a free log subscription operation binding the contract event 0xc4dd2b242df23335f8c79c84c12590a02f2c96864fc80967d45a637d0c933e39.
//
// Solidity: event AssetBought(uint256 indexed assetId, address indexed buyer, uint256 tokenCount, uint256 price, string name, uint256 timestamp)
func (_Property *PropertyFilterer) WatchAssetBought(opts *bind.WatchOpts, sink chan<- *PropertyAssetBought, assetId []*big.Int, buyer []common.Address) (event.Subscription, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var buyerRule []interface{}
	for _, buyerItem := range buyer {
		buyerRule = append(buyerRule, buyerItem)
	}

	logs, sub, err := _Property.contract.WatchLogs(opts, "AssetBought", assetIdRule, buyerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PropertyAssetBought)
				if err := _Property.contract.UnpackLog(event, "AssetBought", log); err != nil {
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
func (_Property *PropertyFilterer) ParseAssetBought(log types.Log) (*PropertyAssetBought, error) {
	event := new(PropertyAssetBought)
	if err := _Property.contract.UnpackLog(event, "AssetBought", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// PropertyAssetIssuedIterator is returned from FilterAssetIssued and is used to iterate over the raw logs and unpacked data for AssetIssued events raised by the Property contract.
type PropertyAssetIssuedIterator struct {
	Event *PropertyAssetIssued // Event containing the contract specifics and raw log

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
func (it *PropertyAssetIssuedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PropertyAssetIssued)
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
		it.Event = new(PropertyAssetIssued)
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
func (it *PropertyAssetIssuedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PropertyAssetIssuedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PropertyAssetIssued represents a AssetIssued event raised by the Property contract.
type PropertyAssetIssued struct {
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
func (_Property *PropertyFilterer) FilterAssetIssued(opts *bind.FilterOpts, assetId []*big.Int, to []common.Address) (*PropertyAssetIssuedIterator, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _Property.contract.FilterLogs(opts, "AssetIssued", assetIdRule, toRule)
	if err != nil {
		return nil, err
	}
	return &PropertyAssetIssuedIterator{contract: _Property.contract, event: "AssetIssued", logs: logs, sub: sub}, nil
}

// WatchAssetIssued is a free log subscription operation binding the contract event 0xe91aa54204e7e68ec3c978f25679bd4982f4bcee900ee74aca5cdfa20fc9abfe.
//
// Solidity: event AssetIssued(uint256 indexed assetId, address indexed to, uint256 totalSupply, uint256 initialPrice, string name, string symbol, uint256 timestamp)
func (_Property *PropertyFilterer) WatchAssetIssued(opts *bind.WatchOpts, sink chan<- *PropertyAssetIssued, assetId []*big.Int, to []common.Address) (event.Subscription, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _Property.contract.WatchLogs(opts, "AssetIssued", assetIdRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PropertyAssetIssued)
				if err := _Property.contract.UnpackLog(event, "AssetIssued", log); err != nil {
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
func (_Property *PropertyFilterer) ParseAssetIssued(log types.Log) (*PropertyAssetIssued, error) {
	event := new(PropertyAssetIssued)
	if err := _Property.contract.UnpackLog(event, "AssetIssued", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// PropertyAssetSoldIterator is returned from FilterAssetSold and is used to iterate over the raw logs and unpacked data for AssetSold events raised by the Property contract.
type PropertyAssetSoldIterator struct {
	Event *PropertyAssetSold // Event containing the contract specifics and raw log

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
func (it *PropertyAssetSoldIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PropertyAssetSold)
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
		it.Event = new(PropertyAssetSold)
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
func (it *PropertyAssetSoldIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PropertyAssetSoldIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PropertyAssetSold represents a AssetSold event raised by the Property contract.
type PropertyAssetSold struct {
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
func (_Property *PropertyFilterer) FilterAssetSold(opts *bind.FilterOpts, assetId []*big.Int, seller []common.Address) (*PropertyAssetSoldIterator, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var sellerRule []interface{}
	for _, sellerItem := range seller {
		sellerRule = append(sellerRule, sellerItem)
	}

	logs, sub, err := _Property.contract.FilterLogs(opts, "AssetSold", assetIdRule, sellerRule)
	if err != nil {
		return nil, err
	}
	return &PropertyAssetSoldIterator{contract: _Property.contract, event: "AssetSold", logs: logs, sub: sub}, nil
}

// WatchAssetSold is a free log subscription operation binding the contract event 0xdde523e51717d516e9022c4c6526af7c6ff2a041912e3116b1107e29ef02122f.
//
// Solidity: event AssetSold(uint256 indexed assetId, address indexed seller, uint256 tokenCount, uint256 price, string name, uint256 timestamp)
func (_Property *PropertyFilterer) WatchAssetSold(opts *bind.WatchOpts, sink chan<- *PropertyAssetSold, assetId []*big.Int, seller []common.Address) (event.Subscription, error) {

	var assetIdRule []interface{}
	for _, assetIdItem := range assetId {
		assetIdRule = append(assetIdRule, assetIdItem)
	}
	var sellerRule []interface{}
	for _, sellerItem := range seller {
		sellerRule = append(sellerRule, sellerItem)
	}

	logs, sub, err := _Property.contract.WatchLogs(opts, "AssetSold", assetIdRule, sellerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PropertyAssetSold)
				if err := _Property.contract.UnpackLog(event, "AssetSold", log); err != nil {
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
func (_Property *PropertyFilterer) ParseAssetSold(log types.Log) (*PropertyAssetSold, error) {
	event := new(PropertyAssetSold)
	if err := _Property.contract.UnpackLog(event, "AssetSold", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// PropertyDisasterIterator is returned from FilterDisaster and is used to iterate over the raw logs and unpacked data for Disaster events raised by the Property contract.
type PropertyDisasterIterator struct {
	Event *PropertyDisaster // Event containing the contract specifics and raw log

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
func (it *PropertyDisasterIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PropertyDisaster)
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
		it.Event = new(PropertyDisaster)
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
func (it *PropertyDisasterIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PropertyDisasterIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PropertyDisaster represents a Disaster event raised by the Property contract.
type PropertyDisaster struct {
	Id               *big.Int
	Reason           string
	NewPrice         *big.Int
	CurrentSellPrice *big.Int
	CurrentBuyPrice  *big.Int
	AfterSellPrice   *big.Int
	AfterBuyPrice    *big.Int
	DisasterTime     *big.Int
	OldBasePrice     *big.Int
	Raw              types.Log // Blockchain specific contextual infos
}

// FilterDisaster is a free log retrieval operation binding the contract event 0x93d6b0639fc63105a777de13f7b5f5056ba48fa570e51e65e7ebbdf213ff315f.
//
// Solidity: event Disaster(uint256 indexed id, string reason, uint256 newPrice, uint256 currentSellPrice, uint256 currentBuyPrice, uint256 afterSellPrice, uint256 afterBuyPrice, uint256 disasterTime, uint256 oldBasePrice)
func (_Property *PropertyFilterer) FilterDisaster(opts *bind.FilterOpts, id []*big.Int) (*PropertyDisasterIterator, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _Property.contract.FilterLogs(opts, "Disaster", idRule)
	if err != nil {
		return nil, err
	}
	return &PropertyDisasterIterator{contract: _Property.contract, event: "Disaster", logs: logs, sub: sub}, nil
}

// WatchDisaster is a free log subscription operation binding the contract event 0x93d6b0639fc63105a777de13f7b5f5056ba48fa570e51e65e7ebbdf213ff315f.
//
// Solidity: event Disaster(uint256 indexed id, string reason, uint256 newPrice, uint256 currentSellPrice, uint256 currentBuyPrice, uint256 afterSellPrice, uint256 afterBuyPrice, uint256 disasterTime, uint256 oldBasePrice)
func (_Property *PropertyFilterer) WatchDisaster(opts *bind.WatchOpts, sink chan<- *PropertyDisaster, id []*big.Int) (event.Subscription, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _Property.contract.WatchLogs(opts, "Disaster", idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PropertyDisaster)
				if err := _Property.contract.UnpackLog(event, "Disaster", log); err != nil {
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

// ParseDisaster is a log parse operation binding the contract event 0x93d6b0639fc63105a777de13f7b5f5056ba48fa570e51e65e7ebbdf213ff315f.
//
// Solidity: event Disaster(uint256 indexed id, string reason, uint256 newPrice, uint256 currentSellPrice, uint256 currentBuyPrice, uint256 afterSellPrice, uint256 afterBuyPrice, uint256 disasterTime, uint256 oldBasePrice)
func (_Property *PropertyFilterer) ParseDisaster(log types.Log) (*PropertyDisaster, error) {
	event := new(PropertyDisaster)
	if err := _Property.contract.UnpackLog(event, "Disaster", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// PropertyInitializedIterator is returned from FilterInitialized and is used to iterate over the raw logs and unpacked data for Initialized events raised by the Property contract.
type PropertyInitializedIterator struct {
	Event *PropertyInitialized // Event containing the contract specifics and raw log

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
func (it *PropertyInitializedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PropertyInitialized)
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
		it.Event = new(PropertyInitialized)
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
func (it *PropertyInitializedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PropertyInitializedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PropertyInitialized represents a Initialized event raised by the Property contract.
type PropertyInitialized struct {
	Version uint64
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterInitialized is a free log retrieval operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_Property *PropertyFilterer) FilterInitialized(opts *bind.FilterOpts) (*PropertyInitializedIterator, error) {

	logs, sub, err := _Property.contract.FilterLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return &PropertyInitializedIterator{contract: _Property.contract, event: "Initialized", logs: logs, sub: sub}, nil
}

// WatchInitialized is a free log subscription operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_Property *PropertyFilterer) WatchInitialized(opts *bind.WatchOpts, sink chan<- *PropertyInitialized) (event.Subscription, error) {

	logs, sub, err := _Property.contract.WatchLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PropertyInitialized)
				if err := _Property.contract.UnpackLog(event, "Initialized", log); err != nil {
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
func (_Property *PropertyFilterer) ParseInitialized(log types.Log) (*PropertyInitialized, error) {
	event := new(PropertyInitialized)
	if err := _Property.contract.UnpackLog(event, "Initialized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// PropertyOwnershipTransferredIterator is returned from FilterOwnershipTransferred and is used to iterate over the raw logs and unpacked data for OwnershipTransferred events raised by the Property contract.
type PropertyOwnershipTransferredIterator struct {
	Event *PropertyOwnershipTransferred // Event containing the contract specifics and raw log

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
func (it *PropertyOwnershipTransferredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PropertyOwnershipTransferred)
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
		it.Event = new(PropertyOwnershipTransferred)
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
func (it *PropertyOwnershipTransferredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PropertyOwnershipTransferredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PropertyOwnershipTransferred represents a OwnershipTransferred event raised by the Property contract.
type PropertyOwnershipTransferred struct {
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterOwnershipTransferred is a free log retrieval operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_Property *PropertyFilterer) FilterOwnershipTransferred(opts *bind.FilterOpts, previousOwner []common.Address, newOwner []common.Address) (*PropertyOwnershipTransferredIterator, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _Property.contract.FilterLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return &PropertyOwnershipTransferredIterator{contract: _Property.contract, event: "OwnershipTransferred", logs: logs, sub: sub}, nil
}

// WatchOwnershipTransferred is a free log subscription operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_Property *PropertyFilterer) WatchOwnershipTransferred(opts *bind.WatchOpts, sink chan<- *PropertyOwnershipTransferred, previousOwner []common.Address, newOwner []common.Address) (event.Subscription, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _Property.contract.WatchLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PropertyOwnershipTransferred)
				if err := _Property.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
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
func (_Property *PropertyFilterer) ParseOwnershipTransferred(log types.Log) (*PropertyOwnershipTransferred, error) {
	event := new(PropertyOwnershipTransferred)
	if err := _Property.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// PropertyPropertyAddIterator is returned from FilterPropertyAdd and is used to iterate over the raw logs and unpacked data for PropertyAdd events raised by the Property contract.
type PropertyPropertyAddIterator struct {
	Event *PropertyPropertyAdd // Event containing the contract specifics and raw log

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
func (it *PropertyPropertyAddIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PropertyPropertyAdd)
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
		it.Event = new(PropertyPropertyAdd)
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
func (it *PropertyPropertyAddIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PropertyPropertyAddIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PropertyPropertyAdd represents a PropertyAdd event raised by the Property contract.
type PropertyPropertyAdd struct {
	Owner   common.Address
	TokenId *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterPropertyAdd is a free log retrieval operation binding the contract event 0xa65f419edcf4188d5bd76ed50cda64a220452969a9520dbd8938a1dfff1cd5ec.
//
// Solidity: event PropertyAdd(address indexed owner, uint256 indexed tokenId)
func (_Property *PropertyFilterer) FilterPropertyAdd(opts *bind.FilterOpts, owner []common.Address, tokenId []*big.Int) (*PropertyPropertyAddIterator, error) {

	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}
	var tokenIdRule []interface{}
	for _, tokenIdItem := range tokenId {
		tokenIdRule = append(tokenIdRule, tokenIdItem)
	}

	logs, sub, err := _Property.contract.FilterLogs(opts, "PropertyAdd", ownerRule, tokenIdRule)
	if err != nil {
		return nil, err
	}
	return &PropertyPropertyAddIterator{contract: _Property.contract, event: "PropertyAdd", logs: logs, sub: sub}, nil
}

// WatchPropertyAdd is a free log subscription operation binding the contract event 0xa65f419edcf4188d5bd76ed50cda64a220452969a9520dbd8938a1dfff1cd5ec.
//
// Solidity: event PropertyAdd(address indexed owner, uint256 indexed tokenId)
func (_Property *PropertyFilterer) WatchPropertyAdd(opts *bind.WatchOpts, sink chan<- *PropertyPropertyAdd, owner []common.Address, tokenId []*big.Int) (event.Subscription, error) {

	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}
	var tokenIdRule []interface{}
	for _, tokenIdItem := range tokenId {
		tokenIdRule = append(tokenIdRule, tokenIdItem)
	}

	logs, sub, err := _Property.contract.WatchLogs(opts, "PropertyAdd", ownerRule, tokenIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PropertyPropertyAdd)
				if err := _Property.contract.UnpackLog(event, "PropertyAdd", log); err != nil {
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

// ParsePropertyAdd is a log parse operation binding the contract event 0xa65f419edcf4188d5bd76ed50cda64a220452969a9520dbd8938a1dfff1cd5ec.
//
// Solidity: event PropertyAdd(address indexed owner, uint256 indexed tokenId)
func (_Property *PropertyFilterer) ParsePropertyAdd(log types.Log) (*PropertyPropertyAdd, error) {
	event := new(PropertyPropertyAdd)
	if err := _Property.contract.UnpackLog(event, "PropertyAdd", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// PropertyPropertyBuySellIterator is returned from FilterPropertyBuySell and is used to iterate over the raw logs and unpacked data for PropertyBuySell events raised by the Property contract.
type PropertyPropertyBuySellIterator struct {
	Event *PropertyPropertyBuySell // Event containing the contract specifics and raw log

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
func (it *PropertyPropertyBuySellIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PropertyPropertyBuySell)
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
		it.Event = new(PropertyPropertyBuySell)
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
func (it *PropertyPropertyBuySellIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PropertyPropertyBuySellIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PropertyPropertyBuySell represents a PropertyBuySell event raised by the Property contract.
type PropertyPropertyBuySell struct {
	UserAddress     common.Address
	TransactionType string
	Timestamp       *big.Int
	Price           *big.Int
	Id              *big.Int
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterPropertyBuySell is a free log retrieval operation binding the contract event 0x583076466e88572f92891f98899cc3badd72d1e39606edf09068152c7164850c.
//
// Solidity: event PropertyBuySell(address indexed userAddress, string transactionType, uint256 timestamp, uint256 price, uint256 indexed id)
func (_Property *PropertyFilterer) FilterPropertyBuySell(opts *bind.FilterOpts, userAddress []common.Address, id []*big.Int) (*PropertyPropertyBuySellIterator, error) {

	var userAddressRule []interface{}
	for _, userAddressItem := range userAddress {
		userAddressRule = append(userAddressRule, userAddressItem)
	}

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _Property.contract.FilterLogs(opts, "PropertyBuySell", userAddressRule, idRule)
	if err != nil {
		return nil, err
	}
	return &PropertyPropertyBuySellIterator{contract: _Property.contract, event: "PropertyBuySell", logs: logs, sub: sub}, nil
}

// WatchPropertyBuySell is a free log subscription operation binding the contract event 0x583076466e88572f92891f98899cc3badd72d1e39606edf09068152c7164850c.
//
// Solidity: event PropertyBuySell(address indexed userAddress, string transactionType, uint256 timestamp, uint256 price, uint256 indexed id)
func (_Property *PropertyFilterer) WatchPropertyBuySell(opts *bind.WatchOpts, sink chan<- *PropertyPropertyBuySell, userAddress []common.Address, id []*big.Int) (event.Subscription, error) {

	var userAddressRule []interface{}
	for _, userAddressItem := range userAddress {
		userAddressRule = append(userAddressRule, userAddressItem)
	}

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _Property.contract.WatchLogs(opts, "PropertyBuySell", userAddressRule, idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PropertyPropertyBuySell)
				if err := _Property.contract.UnpackLog(event, "PropertyBuySell", log); err != nil {
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

// ParsePropertyBuySell is a log parse operation binding the contract event 0x583076466e88572f92891f98899cc3badd72d1e39606edf09068152c7164850c.
//
// Solidity: event PropertyBuySell(address indexed userAddress, string transactionType, uint256 timestamp, uint256 price, uint256 indexed id)
func (_Property *PropertyFilterer) ParsePropertyBuySell(log types.Log) (*PropertyPropertyBuySell, error) {
	event := new(PropertyPropertyBuySell)
	if err := _Property.contract.UnpackLog(event, "PropertyBuySell", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// PropertyPropertyEditIterator is returned from FilterPropertyEdit and is used to iterate over the raw logs and unpacked data for PropertyEdit events raised by the Property contract.
type PropertyPropertyEditIterator struct {
	Event *PropertyPropertyEdit // Event containing the contract specifics and raw log

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
func (it *PropertyPropertyEditIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PropertyPropertyEdit)
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
		it.Event = new(PropertyPropertyEdit)
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
func (it *PropertyPropertyEditIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PropertyPropertyEditIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PropertyPropertyEdit represents a PropertyEdit event raised by the Property contract.
type PropertyPropertyEdit struct {
	Owner   common.Address
	TokenId *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterPropertyEdit is a free log retrieval operation binding the contract event 0x85c05da55e90670991aa1f1d03fc51c24347a3d7f24b450bcd863eb788230627.
//
// Solidity: event PropertyEdit(address indexed owner, uint256 indexed tokenId)
func (_Property *PropertyFilterer) FilterPropertyEdit(opts *bind.FilterOpts, owner []common.Address, tokenId []*big.Int) (*PropertyPropertyEditIterator, error) {

	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}
	var tokenIdRule []interface{}
	for _, tokenIdItem := range tokenId {
		tokenIdRule = append(tokenIdRule, tokenIdItem)
	}

	logs, sub, err := _Property.contract.FilterLogs(opts, "PropertyEdit", ownerRule, tokenIdRule)
	if err != nil {
		return nil, err
	}
	return &PropertyPropertyEditIterator{contract: _Property.contract, event: "PropertyEdit", logs: logs, sub: sub}, nil
}

// WatchPropertyEdit is a free log subscription operation binding the contract event 0x85c05da55e90670991aa1f1d03fc51c24347a3d7f24b450bcd863eb788230627.
//
// Solidity: event PropertyEdit(address indexed owner, uint256 indexed tokenId)
func (_Property *PropertyFilterer) WatchPropertyEdit(opts *bind.WatchOpts, sink chan<- *PropertyPropertyEdit, owner []common.Address, tokenId []*big.Int) (event.Subscription, error) {

	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}
	var tokenIdRule []interface{}
	for _, tokenIdItem := range tokenId {
		tokenIdRule = append(tokenIdRule, tokenIdItem)
	}

	logs, sub, err := _Property.contract.WatchLogs(opts, "PropertyEdit", ownerRule, tokenIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PropertyPropertyEdit)
				if err := _Property.contract.UnpackLog(event, "PropertyEdit", log); err != nil {
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

// ParsePropertyEdit is a log parse operation binding the contract event 0x85c05da55e90670991aa1f1d03fc51c24347a3d7f24b450bcd863eb788230627.
//
// Solidity: event PropertyEdit(address indexed owner, uint256 indexed tokenId)
func (_Property *PropertyFilterer) ParsePropertyEdit(log types.Log) (*PropertyPropertyEdit, error) {
	event := new(PropertyPropertyEdit)
	if err := _Property.contract.UnpackLog(event, "PropertyEdit", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// PropertyTransferBatchIterator is returned from FilterTransferBatch and is used to iterate over the raw logs and unpacked data for TransferBatch events raised by the Property contract.
type PropertyTransferBatchIterator struct {
	Event *PropertyTransferBatch // Event containing the contract specifics and raw log

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
func (it *PropertyTransferBatchIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PropertyTransferBatch)
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
		it.Event = new(PropertyTransferBatch)
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
func (it *PropertyTransferBatchIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PropertyTransferBatchIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PropertyTransferBatch represents a TransferBatch event raised by the Property contract.
type PropertyTransferBatch struct {
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
func (_Property *PropertyFilterer) FilterTransferBatch(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*PropertyTransferBatchIterator, error) {

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

	logs, sub, err := _Property.contract.FilterLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &PropertyTransferBatchIterator{contract: _Property.contract, event: "TransferBatch", logs: logs, sub: sub}, nil
}

// WatchTransferBatch is a free log subscription operation binding the contract event 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb.
//
// Solidity: event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values)
func (_Property *PropertyFilterer) WatchTransferBatch(opts *bind.WatchOpts, sink chan<- *PropertyTransferBatch, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _Property.contract.WatchLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PropertyTransferBatch)
				if err := _Property.contract.UnpackLog(event, "TransferBatch", log); err != nil {
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
func (_Property *PropertyFilterer) ParseTransferBatch(log types.Log) (*PropertyTransferBatch, error) {
	event := new(PropertyTransferBatch)
	if err := _Property.contract.UnpackLog(event, "TransferBatch", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// PropertyTransferSingleIterator is returned from FilterTransferSingle and is used to iterate over the raw logs and unpacked data for TransferSingle events raised by the Property contract.
type PropertyTransferSingleIterator struct {
	Event *PropertyTransferSingle // Event containing the contract specifics and raw log

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
func (it *PropertyTransferSingleIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PropertyTransferSingle)
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
		it.Event = new(PropertyTransferSingle)
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
func (it *PropertyTransferSingleIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PropertyTransferSingleIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PropertyTransferSingle represents a TransferSingle event raised by the Property contract.
type PropertyTransferSingle struct {
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
func (_Property *PropertyFilterer) FilterTransferSingle(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*PropertyTransferSingleIterator, error) {

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

	logs, sub, err := _Property.contract.FilterLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &PropertyTransferSingleIterator{contract: _Property.contract, event: "TransferSingle", logs: logs, sub: sub}, nil
}

// WatchTransferSingle is a free log subscription operation binding the contract event 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62.
//
// Solidity: event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)
func (_Property *PropertyFilterer) WatchTransferSingle(opts *bind.WatchOpts, sink chan<- *PropertyTransferSingle, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _Property.contract.WatchLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PropertyTransferSingle)
				if err := _Property.contract.UnpackLog(event, "TransferSingle", log); err != nil {
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
func (_Property *PropertyFilterer) ParseTransferSingle(log types.Log) (*PropertyTransferSingle, error) {
	event := new(PropertyTransferSingle)
	if err := _Property.contract.UnpackLog(event, "TransferSingle", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// PropertyURIIterator is returned from FilterURI and is used to iterate over the raw logs and unpacked data for URI events raised by the Property contract.
type PropertyURIIterator struct {
	Event *PropertyURI // Event containing the contract specifics and raw log

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
func (it *PropertyURIIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PropertyURI)
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
		it.Event = new(PropertyURI)
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
func (it *PropertyURIIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PropertyURIIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PropertyURI represents a URI event raised by the Property contract.
type PropertyURI struct {
	Value string
	Id    *big.Int
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterURI is a free log retrieval operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_Property *PropertyFilterer) FilterURI(opts *bind.FilterOpts, id []*big.Int) (*PropertyURIIterator, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _Property.contract.FilterLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return &PropertyURIIterator{contract: _Property.contract, event: "URI", logs: logs, sub: sub}, nil
}

// WatchURI is a free log subscription operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_Property *PropertyFilterer) WatchURI(opts *bind.WatchOpts, sink chan<- *PropertyURI, id []*big.Int) (event.Subscription, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _Property.contract.WatchLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PropertyURI)
				if err := _Property.contract.UnpackLog(event, "URI", log); err != nil {
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
func (_Property *PropertyFilterer) ParseURI(log types.Log) (*PropertyURI, error) {
	event := new(PropertyURI)
	if err := _Property.contract.UnpackLog(event, "URI", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// PropertyUpgradedIterator is returned from FilterUpgraded and is used to iterate over the raw logs and unpacked data for Upgraded events raised by the Property contract.
type PropertyUpgradedIterator struct {
	Event *PropertyUpgraded // Event containing the contract specifics and raw log

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
func (it *PropertyUpgradedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PropertyUpgraded)
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
		it.Event = new(PropertyUpgraded)
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
func (it *PropertyUpgradedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PropertyUpgradedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PropertyUpgraded represents a Upgraded event raised by the Property contract.
type PropertyUpgraded struct {
	Implementation common.Address
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterUpgraded is a free log retrieval operation binding the contract event 0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b.
//
// Solidity: event Upgraded(address indexed implementation)
func (_Property *PropertyFilterer) FilterUpgraded(opts *bind.FilterOpts, implementation []common.Address) (*PropertyUpgradedIterator, error) {

	var implementationRule []interface{}
	for _, implementationItem := range implementation {
		implementationRule = append(implementationRule, implementationItem)
	}

	logs, sub, err := _Property.contract.FilterLogs(opts, "Upgraded", implementationRule)
	if err != nil {
		return nil, err
	}
	return &PropertyUpgradedIterator{contract: _Property.contract, event: "Upgraded", logs: logs, sub: sub}, nil
}

// WatchUpgraded is a free log subscription operation binding the contract event 0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b.
//
// Solidity: event Upgraded(address indexed implementation)
func (_Property *PropertyFilterer) WatchUpgraded(opts *bind.WatchOpts, sink chan<- *PropertyUpgraded, implementation []common.Address) (event.Subscription, error) {

	var implementationRule []interface{}
	for _, implementationItem := range implementation {
		implementationRule = append(implementationRule, implementationItem)
	}

	logs, sub, err := _Property.contract.WatchLogs(opts, "Upgraded", implementationRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PropertyUpgraded)
				if err := _Property.contract.UnpackLog(event, "Upgraded", log); err != nil {
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
func (_Property *PropertyFilterer) ParseUpgraded(log types.Log) (*PropertyUpgraded, error) {
	event := new(PropertyUpgraded)
	if err := _Property.contract.UnpackLog(event, "Upgraded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
