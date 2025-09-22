// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package bindings

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

// PaymentFacilitatorCartMandate is an auto generated low-level Go binding around an user-defined struct.
type PaymentFacilitatorCartMandate struct {
	Merchant common.Address
	Token    common.Address
	Amount   *big.Int
}

// PaymentFacilitatorIntentMandate is an auto generated low-level Go binding around an user-defined struct.
type PaymentFacilitatorIntentMandate struct {
	Task     [32]byte
	Token    common.Address
	MaxPrice *big.Int
	Expires  *big.Int
	Nonce    *big.Int
}

// PaymentFacilitatorMetaData contains all meta data concerning the PaymentFacilitator contract.
var PaymentFacilitatorMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"CART_MANDATE_TYPEHASH\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"INTENT_MANDATE_TYPEHASH\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"domainSeparatorV4\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"eip712Domain\",\"inputs\":[],\"outputs\":[{\"name\":\"fields\",\"type\":\"bytes1\",\"internalType\":\"bytes1\"},{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"version\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"chainId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"verifyingContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"salt\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"extensions\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"executePurchase\",\"inputs\":[{\"name\":\"intent\",\"type\":\"tuple\",\"internalType\":\"structPaymentFacilitator.IntentMandate\",\"components\":[{\"name\":\"task\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"maxPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expires\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"cart\",\"type\":\"tuple\",\"internalType\":\"structPaymentFacilitator.CartMandate\",\"components\":[{\"name\":\"merchant\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"userSignature\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"cartSignature\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"usedNonces\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"EIP712DomainChanged\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PurchaseExecuted\",\"inputs\":[{\"name\":\"merchant\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"token\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"intentNonce\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ECDSAInvalidSignature\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ECDSAInvalidSignatureLength\",\"inputs\":[{\"name\":\"length\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ECDSAInvalidSignatureS\",\"inputs\":[{\"name\":\"s\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"IntentExpired\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidCartSignature\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidShortString\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidSignature\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidToken\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NonceAlreadyUsed\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PriceTooHigh\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"StringTooLong\",\"inputs\":[{\"name\":\"str\",\"type\":\"string\",\"internalType\":\"string\"}]}]",
	Bin: "0x6101606040523461014357604051610018604082610147565b601281526020810190712830bcb6b2b73a2330b1b4b634ba30ba37b960711b825260405191610048604084610147565b600183526020830191603160f81b83526100618161017e565b6101205261006e84610314565b61014052519020918260e05251902080610100524660a0526040519060208201927f8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f8452604083015260608201524660808201523060a082015260a081526100d760c082610147565b5190206080523060c052600280546001600160a01b03191633179055604051610b78908161044d823960805181610713015260a051816107d0015260c051816106dd015260e05181610762015261010051816107880152610120518160dc015261014051816101050152f35b5f80fd5b601f909101601f19168101906001600160401b0382119082101761016a57604052565b634e487b7160e01b5f52604160045260245ffd5b908151602081105f146101f8575090601f8151116101b85760208151910151602082106101a9571790565b5f198260200360031b1b161790565b604460209160405192839163305a27a960e01b83528160048401528051918291826024860152018484015e5f828201840152601f01601f19168101030190fd5b6001600160401b03811161016a575f54600181811c9116801561030a575b60208210146102f657601f81116102c4575b50602092601f821160011461026557928192935f9261025a575b50508160011b915f199060031b1c1916175f5560ff90565b015190505f80610242565b601f198216935f8052805f20915f5b8681106102ac5750836001959610610294575b505050811b015f5560ff90565b01515f1960f88460031b161c191690555f8080610287565b91926020600181928685015181550194019201610274565b5f8052601f60205f20910160051c810190601f830160051c015b8181106102eb5750610228565b5f81556001016102de565b634e487b7160e01b5f52602260045260245ffd5b90607f1690610216565b908151602081105f1461033f575090601f8151116101b85760208151910151602082106101a9571790565b6001600160401b03811161016a57600154600181811c91168015610442575b60208210146102f657601f811161040f575b50602092601f82116001146103ae57928192935f926103a3575b50508160011b915f199060031b1c19161760015560ff90565b015190505f8061038a565b601f1982169360015f52805f20915f5b8681106103f757508360019596106103df575b505050811b0160015560ff90565b01515f1960f88460031b161c191690555f80806103d1565b919260206001819286850151815501940192016103be565b60015f52601f60205f20910160051c810190601f830160051c015b8181106104375750610370565b5f815560010161042a565b90607f169061035e56fe6080806040526004361015610012575f80fd5b5f3560e01c9081632671fd2414610592575080632effed55146105585780636d4fedb0146101de57806378e890ba146101bc57806384b0196e146100c45780638da5cb5b1461009c5763feb6172414610069575f80fd5b34610098576020366003190112610098576004355f526003602052602060ff60405f2054166040519015158152f35b5f80fd5b34610098575f366003190112610098576002546040516001600160a01b039091168152602090f35b34610098575f366003190112610098576101606101007f00000000000000000000000000000000000000000000000000000000000000006108ca565b6101297f00000000000000000000000000000000000000000000000000000000000000006109f0565b602061016e6040519261013c838561061c565b5f84525f368137604051958695600f60f81b875260e08588015260e08701906105f8565b9085820360408701526105f8565b4660608501523060808501525f60a085015283810360c08501528180845192838152019301915f5b8281106101a557505050500390f35b835185528695509381019392810192600101610196565b34610098575f3660031901126100985760206101d66106da565b604051908152f35b3461009857366003190161014081126100985760a0136100985760603660a3190112610098576101043567ffffffffffffffff8111610098576102259036906004016105ca565b906101243567ffffffffffffffff8111610098576102479036906004016105ca565b610252929192610698565b906102e96102e06102da604435956102d26064359660405160208101917fb51032b96aac6ade0f3718dd24b0fad8620c0d12e2bcddddfcab4af598e87d368352600435604083015260018060a01b031660608201528960808201528860a082015260843560c082015260c081526102ca60e08261061c565b5190206107f6565b983691610652565b8761081c565b90929192610856565b6002546001600160a01b03908116911603610549576102e061038a916103846103106106ae565b9661037c61031c6106c4565b604080517fe8e756ae7dde734accd0a5169ea52d11598ae6a4668eecd14d78babe16661d6e602082019081526001600160a01b039c8d16928201929092529a90911660608b015260e4356080808c018290528b52996102ca60a08261061c565b923691610652565b9061081c565b6001600160a01b0361039a6106ae565b166001600160a01b039091160361053a57421161052b57811161051c576103bf6106c4565b6001600160a01b036103cf610698565b166001600160a01b039091160361050d57815f52600360205260ff60405f2054166104ff575f828152600360205260409020805460ff191660011790556001600160a01b0361041c6106c4565b6002549116906020906001600160a01b031660646104386106ae565b915f60405195869485936323b872dd60e01b8552600485015260018060a01b031660248401528760448401525af180156104f4576104bd575b5061047a6106ae565b907f45638f9aaf623132810520da36d3347c87c81eb5dd05db4d00e7a5a33c22c6b360206104a66106c4565b6040519384526001600160a01b03908116941692a4005b6020813d6020116104ec575b816104d66020938361061c565b8101031261009857518015158114610471575f80fd5b3d91506104c9565b6040513d5f823e3d90fd5b623f613760e71b5f5260045ffd5b63c1ab6dc160e01b5f5260045ffd5b63127f08c960e11b5f5260045ffd5b631022c88d60e21b5f5260045ffd5b6335c1650360e21b5f5260045ffd5b638baa579f60e01b5f5260045ffd5b34610098575f3660031901126100985760206040517fe8e756ae7dde734accd0a5169ea52d11598ae6a4668eecd14d78babe16661d6e8152f35b34610098575f36600319011261009857807fb51032b96aac6ade0f3718dd24b0fad8620c0d12e2bcddddfcab4af598e87d3660209252f35b9181601f840112156100985782359167ffffffffffffffff8311610098576020838186019501011161009857565b805180835260209291819084018484015e5f828201840152601f01601f1916010190565b90601f8019910116810190811067ffffffffffffffff82111761063e57604052565b634e487b7160e01b5f52604160045260245ffd5b92919267ffffffffffffffff821161063e576040519161067c601f8201601f19166020018461061c565b829481845281830111610098578281602093845f960137010152565b6024356001600160a01b03811681036100985790565b60a4356001600160a01b03811681036100985790565b60c4356001600160a01b03811681036100985790565b307f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031614806107cd575b15610735577f000000000000000000000000000000000000000000000000000000000000000090565b60405160208101907f8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f82527f000000000000000000000000000000000000000000000000000000000000000060408201527f000000000000000000000000000000000000000000000000000000000000000060608201524660808201523060a082015260a081526107c760c08261061c565b51902090565b507f0000000000000000000000000000000000000000000000000000000000000000461461070c565b6042906108016106da565b906040519161190160f01b8352600283015260228201522090565b815191906041830361084c576108459250602082015190606060408401519301515f1a90610ac0565b9192909190565b50505f9160029190565b60048110156108b65780610868575050565b6001810361087f5763f645eedf60e01b5f5260045ffd5b6002810361089a575063fce698f760e01b5f5260045260245ffd5b6003146108a45750565b6335e2f38360e21b5f5260045260245ffd5b634e487b7160e01b5f52602160045260245ffd5b60ff81146109105760ff811690601f821161090157604051916108ee60408461061c565b6020808452838101919036833783525290565b632cd44ac360e21b5f5260045ffd5b506040515f5f548060011c91600182169182156109e6575b6020841083146109d25783855284929081156109b35750600114610956575b6109539250038261061c565b90565b505f80805290917f290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e5635b81831061099757505090602061095392820101610947565b602091935080600191548385880101520191019091839261097f565b6020925061095394915060ff191682840152151560051b820101610947565b634e487b7160e01b5f52602260045260245ffd5b92607f1692610928565b60ff8114610a145760ff811690601f821161090157604051916108ee60408461061c565b506040515f6001548060011c9160018216918215610ab6575b6020841083146109d25783855284929081156109b35750600114610a57576109539250038261061c565b5060015f90815290917fb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf65b818310610a9a57505090602061095392820101610947565b6020919350806001915483858801015201910190918392610a82565b92607f1692610a2d565b91907f7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a08411610b37579160209360809260ff5f9560405194855216868401526040830152606082015282805260015afa156104f4575f516001600160a01b03811615610b2d57905f905f90565b505f906001905f90565b5050505f916003919056fea2646970667358221220d546e955583cf9468a9d454b37e004519a21266b7fe3e68a874ba36b177a570464736f6c634300081d0033",
}

// PaymentFacilitatorABI is the input ABI used to generate the binding from.
// Deprecated: Use PaymentFacilitatorMetaData.ABI instead.
var PaymentFacilitatorABI = PaymentFacilitatorMetaData.ABI

// PaymentFacilitatorBin is the compiled bytecode used for deploying new contracts.
// Deprecated: Use PaymentFacilitatorMetaData.Bin instead.
var PaymentFacilitatorBin = PaymentFacilitatorMetaData.Bin

// DeployPaymentFacilitator deploys a new Ethereum contract, binding an instance of PaymentFacilitator to it.
func DeployPaymentFacilitator(auth *bind.TransactOpts, backend bind.ContractBackend) (common.Address, *types.Transaction, *PaymentFacilitator, error) {
	parsed, err := PaymentFacilitatorMetaData.GetAbi()
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	if parsed == nil {
		return common.Address{}, nil, nil, errors.New("GetABI returned nil")
	}

	address, tx, contract, err := bind.DeployContract(auth, *parsed, common.FromHex(PaymentFacilitatorBin), backend)
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	return address, tx, &PaymentFacilitator{PaymentFacilitatorCaller: PaymentFacilitatorCaller{contract: contract}, PaymentFacilitatorTransactor: PaymentFacilitatorTransactor{contract: contract}, PaymentFacilitatorFilterer: PaymentFacilitatorFilterer{contract: contract}}, nil
}

// PaymentFacilitator is an auto generated Go binding around an Ethereum contract.
type PaymentFacilitator struct {
	PaymentFacilitatorCaller     // Read-only binding to the contract
	PaymentFacilitatorTransactor // Write-only binding to the contract
	PaymentFacilitatorFilterer   // Log filterer for contract events
}

// PaymentFacilitatorCaller is an auto generated read-only Go binding around an Ethereum contract.
type PaymentFacilitatorCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// PaymentFacilitatorTransactor is an auto generated write-only Go binding around an Ethereum contract.
type PaymentFacilitatorTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// PaymentFacilitatorFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type PaymentFacilitatorFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// PaymentFacilitatorSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type PaymentFacilitatorSession struct {
	Contract     *PaymentFacilitator // Generic contract binding to set the session for
	CallOpts     bind.CallOpts       // Call options to use throughout this session
	TransactOpts bind.TransactOpts   // Transaction auth options to use throughout this session
}

// PaymentFacilitatorCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type PaymentFacilitatorCallerSession struct {
	Contract *PaymentFacilitatorCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts             // Call options to use throughout this session
}

// PaymentFacilitatorTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type PaymentFacilitatorTransactorSession struct {
	Contract     *PaymentFacilitatorTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts             // Transaction auth options to use throughout this session
}

// PaymentFacilitatorRaw is an auto generated low-level Go binding around an Ethereum contract.
type PaymentFacilitatorRaw struct {
	Contract *PaymentFacilitator // Generic contract binding to access the raw methods on
}

// PaymentFacilitatorCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type PaymentFacilitatorCallerRaw struct {
	Contract *PaymentFacilitatorCaller // Generic read-only contract binding to access the raw methods on
}

// PaymentFacilitatorTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type PaymentFacilitatorTransactorRaw struct {
	Contract *PaymentFacilitatorTransactor // Generic write-only contract binding to access the raw methods on
}

// NewPaymentFacilitator creates a new instance of PaymentFacilitator, bound to a specific deployed contract.
func NewPaymentFacilitator(address common.Address, backend bind.ContractBackend) (*PaymentFacilitator, error) {
	contract, err := bindPaymentFacilitator(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &PaymentFacilitator{PaymentFacilitatorCaller: PaymentFacilitatorCaller{contract: contract}, PaymentFacilitatorTransactor: PaymentFacilitatorTransactor{contract: contract}, PaymentFacilitatorFilterer: PaymentFacilitatorFilterer{contract: contract}}, nil
}

// NewPaymentFacilitatorCaller creates a new read-only instance of PaymentFacilitator, bound to a specific deployed contract.
func NewPaymentFacilitatorCaller(address common.Address, caller bind.ContractCaller) (*PaymentFacilitatorCaller, error) {
	contract, err := bindPaymentFacilitator(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &PaymentFacilitatorCaller{contract: contract}, nil
}

// NewPaymentFacilitatorTransactor creates a new write-only instance of PaymentFacilitator, bound to a specific deployed contract.
func NewPaymentFacilitatorTransactor(address common.Address, transactor bind.ContractTransactor) (*PaymentFacilitatorTransactor, error) {
	contract, err := bindPaymentFacilitator(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &PaymentFacilitatorTransactor{contract: contract}, nil
}

// NewPaymentFacilitatorFilterer creates a new log filterer instance of PaymentFacilitator, bound to a specific deployed contract.
func NewPaymentFacilitatorFilterer(address common.Address, filterer bind.ContractFilterer) (*PaymentFacilitatorFilterer, error) {
	contract, err := bindPaymentFacilitator(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &PaymentFacilitatorFilterer{contract: contract}, nil
}

// bindPaymentFacilitator binds a generic wrapper to an already deployed contract.
func bindPaymentFacilitator(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := PaymentFacilitatorMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_PaymentFacilitator *PaymentFacilitatorRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _PaymentFacilitator.Contract.PaymentFacilitatorCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_PaymentFacilitator *PaymentFacilitatorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _PaymentFacilitator.Contract.PaymentFacilitatorTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_PaymentFacilitator *PaymentFacilitatorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _PaymentFacilitator.Contract.PaymentFacilitatorTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_PaymentFacilitator *PaymentFacilitatorCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _PaymentFacilitator.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_PaymentFacilitator *PaymentFacilitatorTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _PaymentFacilitator.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_PaymentFacilitator *PaymentFacilitatorTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _PaymentFacilitator.Contract.contract.Transact(opts, method, params...)
}

// CARTMANDATETYPEHASH is a free data retrieval call binding the contract method 0x2effed55.
//
// Solidity: function CART_MANDATE_TYPEHASH() view returns(bytes32)
func (_PaymentFacilitator *PaymentFacilitatorCaller) CARTMANDATETYPEHASH(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _PaymentFacilitator.contract.Call(opts, &out, "CART_MANDATE_TYPEHASH")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// CARTMANDATETYPEHASH is a free data retrieval call binding the contract method 0x2effed55.
//
// Solidity: function CART_MANDATE_TYPEHASH() view returns(bytes32)
func (_PaymentFacilitator *PaymentFacilitatorSession) CARTMANDATETYPEHASH() ([32]byte, error) {
	return _PaymentFacilitator.Contract.CARTMANDATETYPEHASH(&_PaymentFacilitator.CallOpts)
}

// CARTMANDATETYPEHASH is a free data retrieval call binding the contract method 0x2effed55.
//
// Solidity: function CART_MANDATE_TYPEHASH() view returns(bytes32)
func (_PaymentFacilitator *PaymentFacilitatorCallerSession) CARTMANDATETYPEHASH() ([32]byte, error) {
	return _PaymentFacilitator.Contract.CARTMANDATETYPEHASH(&_PaymentFacilitator.CallOpts)
}

// INTENTMANDATETYPEHASH is a free data retrieval call binding the contract method 0x2671fd24.
//
// Solidity: function INTENT_MANDATE_TYPEHASH() view returns(bytes32)
func (_PaymentFacilitator *PaymentFacilitatorCaller) INTENTMANDATETYPEHASH(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _PaymentFacilitator.contract.Call(opts, &out, "INTENT_MANDATE_TYPEHASH")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// INTENTMANDATETYPEHASH is a free data retrieval call binding the contract method 0x2671fd24.
//
// Solidity: function INTENT_MANDATE_TYPEHASH() view returns(bytes32)
func (_PaymentFacilitator *PaymentFacilitatorSession) INTENTMANDATETYPEHASH() ([32]byte, error) {
	return _PaymentFacilitator.Contract.INTENTMANDATETYPEHASH(&_PaymentFacilitator.CallOpts)
}

// INTENTMANDATETYPEHASH is a free data retrieval call binding the contract method 0x2671fd24.
//
// Solidity: function INTENT_MANDATE_TYPEHASH() view returns(bytes32)
func (_PaymentFacilitator *PaymentFacilitatorCallerSession) INTENTMANDATETYPEHASH() ([32]byte, error) {
	return _PaymentFacilitator.Contract.INTENTMANDATETYPEHASH(&_PaymentFacilitator.CallOpts)
}

// DomainSeparatorV4 is a free data retrieval call binding the contract method 0x78e890ba.
//
// Solidity: function domainSeparatorV4() view returns(bytes32)
func (_PaymentFacilitator *PaymentFacilitatorCaller) DomainSeparatorV4(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _PaymentFacilitator.contract.Call(opts, &out, "domainSeparatorV4")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DomainSeparatorV4 is a free data retrieval call binding the contract method 0x78e890ba.
//
// Solidity: function domainSeparatorV4() view returns(bytes32)
func (_PaymentFacilitator *PaymentFacilitatorSession) DomainSeparatorV4() ([32]byte, error) {
	return _PaymentFacilitator.Contract.DomainSeparatorV4(&_PaymentFacilitator.CallOpts)
}

// DomainSeparatorV4 is a free data retrieval call binding the contract method 0x78e890ba.
//
// Solidity: function domainSeparatorV4() view returns(bytes32)
func (_PaymentFacilitator *PaymentFacilitatorCallerSession) DomainSeparatorV4() ([32]byte, error) {
	return _PaymentFacilitator.Contract.DomainSeparatorV4(&_PaymentFacilitator.CallOpts)
}

// Eip712Domain is a free data retrieval call binding the contract method 0x84b0196e.
//
// Solidity: function eip712Domain() view returns(bytes1 fields, string name, string version, uint256 chainId, address verifyingContract, bytes32 salt, uint256[] extensions)
func (_PaymentFacilitator *PaymentFacilitatorCaller) Eip712Domain(opts *bind.CallOpts) (struct {
	Fields            [1]byte
	Name              string
	Version           string
	ChainId           *big.Int
	VerifyingContract common.Address
	Salt              [32]byte
	Extensions        []*big.Int
}, error) {
	var out []interface{}
	err := _PaymentFacilitator.contract.Call(opts, &out, "eip712Domain")

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
func (_PaymentFacilitator *PaymentFacilitatorSession) Eip712Domain() (struct {
	Fields            [1]byte
	Name              string
	Version           string
	ChainId           *big.Int
	VerifyingContract common.Address
	Salt              [32]byte
	Extensions        []*big.Int
}, error) {
	return _PaymentFacilitator.Contract.Eip712Domain(&_PaymentFacilitator.CallOpts)
}

// Eip712Domain is a free data retrieval call binding the contract method 0x84b0196e.
//
// Solidity: function eip712Domain() view returns(bytes1 fields, string name, string version, uint256 chainId, address verifyingContract, bytes32 salt, uint256[] extensions)
func (_PaymentFacilitator *PaymentFacilitatorCallerSession) Eip712Domain() (struct {
	Fields            [1]byte
	Name              string
	Version           string
	ChainId           *big.Int
	VerifyingContract common.Address
	Salt              [32]byte
	Extensions        []*big.Int
}, error) {
	return _PaymentFacilitator.Contract.Eip712Domain(&_PaymentFacilitator.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_PaymentFacilitator *PaymentFacilitatorCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _PaymentFacilitator.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_PaymentFacilitator *PaymentFacilitatorSession) Owner() (common.Address, error) {
	return _PaymentFacilitator.Contract.Owner(&_PaymentFacilitator.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_PaymentFacilitator *PaymentFacilitatorCallerSession) Owner() (common.Address, error) {
	return _PaymentFacilitator.Contract.Owner(&_PaymentFacilitator.CallOpts)
}

// UsedNonces is a free data retrieval call binding the contract method 0xfeb61724.
//
// Solidity: function usedNonces(bytes32 ) view returns(bool)
func (_PaymentFacilitator *PaymentFacilitatorCaller) UsedNonces(opts *bind.CallOpts, arg0 [32]byte) (bool, error) {
	var out []interface{}
	err := _PaymentFacilitator.contract.Call(opts, &out, "usedNonces", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// UsedNonces is a free data retrieval call binding the contract method 0xfeb61724.
//
// Solidity: function usedNonces(bytes32 ) view returns(bool)
func (_PaymentFacilitator *PaymentFacilitatorSession) UsedNonces(arg0 [32]byte) (bool, error) {
	return _PaymentFacilitator.Contract.UsedNonces(&_PaymentFacilitator.CallOpts, arg0)
}

// UsedNonces is a free data retrieval call binding the contract method 0xfeb61724.
//
// Solidity: function usedNonces(bytes32 ) view returns(bool)
func (_PaymentFacilitator *PaymentFacilitatorCallerSession) UsedNonces(arg0 [32]byte) (bool, error) {
	return _PaymentFacilitator.Contract.UsedNonces(&_PaymentFacilitator.CallOpts, arg0)
}

// ExecutePurchase is a paid mutator transaction binding the contract method 0x6d4fedb0.
//
// Solidity: function executePurchase((bytes32,address,uint256,uint256,uint256) intent, (address,address,uint256) cart, bytes userSignature, bytes cartSignature) returns()
func (_PaymentFacilitator *PaymentFacilitatorTransactor) ExecutePurchase(opts *bind.TransactOpts, intent PaymentFacilitatorIntentMandate, cart PaymentFacilitatorCartMandate, userSignature []byte, cartSignature []byte) (*types.Transaction, error) {
	return _PaymentFacilitator.contract.Transact(opts, "executePurchase", intent, cart, userSignature, cartSignature)
}

// ExecutePurchase is a paid mutator transaction binding the contract method 0x6d4fedb0.
//
// Solidity: function executePurchase((bytes32,address,uint256,uint256,uint256) intent, (address,address,uint256) cart, bytes userSignature, bytes cartSignature) returns()
func (_PaymentFacilitator *PaymentFacilitatorSession) ExecutePurchase(intent PaymentFacilitatorIntentMandate, cart PaymentFacilitatorCartMandate, userSignature []byte, cartSignature []byte) (*types.Transaction, error) {
	return _PaymentFacilitator.Contract.ExecutePurchase(&_PaymentFacilitator.TransactOpts, intent, cart, userSignature, cartSignature)
}

// ExecutePurchase is a paid mutator transaction binding the contract method 0x6d4fedb0.
//
// Solidity: function executePurchase((bytes32,address,uint256,uint256,uint256) intent, (address,address,uint256) cart, bytes userSignature, bytes cartSignature) returns()
func (_PaymentFacilitator *PaymentFacilitatorTransactorSession) ExecutePurchase(intent PaymentFacilitatorIntentMandate, cart PaymentFacilitatorCartMandate, userSignature []byte, cartSignature []byte) (*types.Transaction, error) {
	return _PaymentFacilitator.Contract.ExecutePurchase(&_PaymentFacilitator.TransactOpts, intent, cart, userSignature, cartSignature)
}

// PaymentFacilitatorEIP712DomainChangedIterator is returned from FilterEIP712DomainChanged and is used to iterate over the raw logs and unpacked data for EIP712DomainChanged events raised by the PaymentFacilitator contract.
type PaymentFacilitatorEIP712DomainChangedIterator struct {
	Event *PaymentFacilitatorEIP712DomainChanged // Event containing the contract specifics and raw log

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
func (it *PaymentFacilitatorEIP712DomainChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PaymentFacilitatorEIP712DomainChanged)
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
		it.Event = new(PaymentFacilitatorEIP712DomainChanged)
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
func (it *PaymentFacilitatorEIP712DomainChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PaymentFacilitatorEIP712DomainChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PaymentFacilitatorEIP712DomainChanged represents a EIP712DomainChanged event raised by the PaymentFacilitator contract.
type PaymentFacilitatorEIP712DomainChanged struct {
	Raw types.Log // Blockchain specific contextual infos
}

// FilterEIP712DomainChanged is a free log retrieval operation binding the contract event 0x0a6387c9ea3628b88a633bb4f3b151770f70085117a15f9bf3787cda53f13d31.
//
// Solidity: event EIP712DomainChanged()
func (_PaymentFacilitator *PaymentFacilitatorFilterer) FilterEIP712DomainChanged(opts *bind.FilterOpts) (*PaymentFacilitatorEIP712DomainChangedIterator, error) {

	logs, sub, err := _PaymentFacilitator.contract.FilterLogs(opts, "EIP712DomainChanged")
	if err != nil {
		return nil, err
	}
	return &PaymentFacilitatorEIP712DomainChangedIterator{contract: _PaymentFacilitator.contract, event: "EIP712DomainChanged", logs: logs, sub: sub}, nil
}

// WatchEIP712DomainChanged is a free log subscription operation binding the contract event 0x0a6387c9ea3628b88a633bb4f3b151770f70085117a15f9bf3787cda53f13d31.
//
// Solidity: event EIP712DomainChanged()
func (_PaymentFacilitator *PaymentFacilitatorFilterer) WatchEIP712DomainChanged(opts *bind.WatchOpts, sink chan<- *PaymentFacilitatorEIP712DomainChanged) (event.Subscription, error) {

	logs, sub, err := _PaymentFacilitator.contract.WatchLogs(opts, "EIP712DomainChanged")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PaymentFacilitatorEIP712DomainChanged)
				if err := _PaymentFacilitator.contract.UnpackLog(event, "EIP712DomainChanged", log); err != nil {
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
func (_PaymentFacilitator *PaymentFacilitatorFilterer) ParseEIP712DomainChanged(log types.Log) (*PaymentFacilitatorEIP712DomainChanged, error) {
	event := new(PaymentFacilitatorEIP712DomainChanged)
	if err := _PaymentFacilitator.contract.UnpackLog(event, "EIP712DomainChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// PaymentFacilitatorPurchaseExecutedIterator is returned from FilterPurchaseExecuted and is used to iterate over the raw logs and unpacked data for PurchaseExecuted events raised by the PaymentFacilitator contract.
type PaymentFacilitatorPurchaseExecutedIterator struct {
	Event *PaymentFacilitatorPurchaseExecuted // Event containing the contract specifics and raw log

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
func (it *PaymentFacilitatorPurchaseExecutedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PaymentFacilitatorPurchaseExecuted)
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
		it.Event = new(PaymentFacilitatorPurchaseExecuted)
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
func (it *PaymentFacilitatorPurchaseExecutedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PaymentFacilitatorPurchaseExecutedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PaymentFacilitatorPurchaseExecuted represents a PurchaseExecuted event raised by the PaymentFacilitator contract.
type PaymentFacilitatorPurchaseExecuted struct {
	Merchant    common.Address
	Token       common.Address
	Amount      *big.Int
	IntentNonce [32]byte
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterPurchaseExecuted is a free log retrieval operation binding the contract event 0x45638f9aaf623132810520da36d3347c87c81eb5dd05db4d00e7a5a33c22c6b3.
//
// Solidity: event PurchaseExecuted(address indexed merchant, address indexed token, uint256 amount, bytes32 indexed intentNonce)
func (_PaymentFacilitator *PaymentFacilitatorFilterer) FilterPurchaseExecuted(opts *bind.FilterOpts, merchant []common.Address, token []common.Address, intentNonce [][32]byte) (*PaymentFacilitatorPurchaseExecutedIterator, error) {

	var merchantRule []interface{}
	for _, merchantItem := range merchant {
		merchantRule = append(merchantRule, merchantItem)
	}
	var tokenRule []interface{}
	for _, tokenItem := range token {
		tokenRule = append(tokenRule, tokenItem)
	}

	var intentNonceRule []interface{}
	for _, intentNonceItem := range intentNonce {
		intentNonceRule = append(intentNonceRule, intentNonceItem)
	}

	logs, sub, err := _PaymentFacilitator.contract.FilterLogs(opts, "PurchaseExecuted", merchantRule, tokenRule, intentNonceRule)
	if err != nil {
		return nil, err
	}
	return &PaymentFacilitatorPurchaseExecutedIterator{contract: _PaymentFacilitator.contract, event: "PurchaseExecuted", logs: logs, sub: sub}, nil
}

// WatchPurchaseExecuted is a free log subscription operation binding the contract event 0x45638f9aaf623132810520da36d3347c87c81eb5dd05db4d00e7a5a33c22c6b3.
//
// Solidity: event PurchaseExecuted(address indexed merchant, address indexed token, uint256 amount, bytes32 indexed intentNonce)
func (_PaymentFacilitator *PaymentFacilitatorFilterer) WatchPurchaseExecuted(opts *bind.WatchOpts, sink chan<- *PaymentFacilitatorPurchaseExecuted, merchant []common.Address, token []common.Address, intentNonce [][32]byte) (event.Subscription, error) {

	var merchantRule []interface{}
	for _, merchantItem := range merchant {
		merchantRule = append(merchantRule, merchantItem)
	}
	var tokenRule []interface{}
	for _, tokenItem := range token {
		tokenRule = append(tokenRule, tokenItem)
	}

	var intentNonceRule []interface{}
	for _, intentNonceItem := range intentNonce {
		intentNonceRule = append(intentNonceRule, intentNonceItem)
	}

	logs, sub, err := _PaymentFacilitator.contract.WatchLogs(opts, "PurchaseExecuted", merchantRule, tokenRule, intentNonceRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PaymentFacilitatorPurchaseExecuted)
				if err := _PaymentFacilitator.contract.UnpackLog(event, "PurchaseExecuted", log); err != nil {
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

// ParsePurchaseExecuted is a log parse operation binding the contract event 0x45638f9aaf623132810520da36d3347c87c81eb5dd05db4d00e7a5a33c22c6b3.
//
// Solidity: event PurchaseExecuted(address indexed merchant, address indexed token, uint256 amount, bytes32 indexed intentNonce)
func (_PaymentFacilitator *PaymentFacilitatorFilterer) ParsePurchaseExecuted(log types.Log) (*PaymentFacilitatorPurchaseExecuted, error) {
	event := new(PaymentFacilitatorPurchaseExecuted)
	if err := _PaymentFacilitator.contract.UnpackLog(event, "PurchaseExecuted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
