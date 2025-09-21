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

// AgentProxyCartMandate is an auto generated low-level Go binding around an user-defined struct.
type AgentProxyCartMandate struct {
	Merchant common.Address
	Token    common.Address
	Amount   *big.Int
}

// AgentProxyIntentMandate is an auto generated low-level Go binding around an user-defined struct.
type AgentProxyIntentMandate struct {
	Task          [32]byte
	Token         common.Address
	MaxPrice      *big.Int
	Expires       *big.Int
	ProxyContract common.Address
	Nonce         *big.Int
}

// AgentMetaData contains all meta data concerning the Agent contract.
var AgentMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"INTENT_MANDATE_TYPEHASH\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"domainSeparatorV4\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"eip712Domain\",\"inputs\":[],\"outputs\":[{\"name\":\"fields\",\"type\":\"bytes1\",\"internalType\":\"bytes1\"},{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"version\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"chainId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"verifyingContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"salt\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"extensions\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"executePurchase\",\"inputs\":[{\"name\":\"intent\",\"type\":\"tuple\",\"internalType\":\"structAgentProxy.IntentMandate\",\"components\":[{\"name\":\"task\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"maxPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expires\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"proxyContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"cart\",\"type\":\"tuple\",\"internalType\":\"structAgentProxy.CartMandate\",\"components\":[{\"name\":\"merchant\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"signature\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"usedNonces\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"EIP712DomainChanged\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PurchaseExecuted\",\"inputs\":[{\"name\":\"merchant\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"token\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"intentNonce\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SignerAddress\",\"inputs\":[{\"name\":\"signer\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SignerRecovered\",\"inputs\":[{\"name\":\"intentHash\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"StructHash\",\"inputs\":[{\"name\":\"structHash\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ECDSAInvalidSignature\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ECDSAInvalidSignatureLength\",\"inputs\":[{\"name\":\"length\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ECDSAInvalidSignatureS\",\"inputs\":[{\"name\":\"s\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"IntentExpired\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidShortString\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidSignature\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidToken\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NonceAlreadyUsed\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PriceTooHigh\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"StringTooLong\",\"inputs\":[{\"name\":\"str\",\"type\":\"string\",\"internalType\":\"string\"}]}]",
	Bin: "0x6101606040523461013c57604051610018604082610140565b600a81526020810190694167656e7450726f787960b01b825260405191610040604084610140565b600183526020830191603160f81b835261005981610177565b610120526100668461030d565b61014052519020918260e05251902080610100524660a0526040519060208201927f8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f8452604083015260608201524660808201523060a082015260a081526100cf60c082610140565b5190206080523060c052600280546001600160a01b03191633179055604051610b1590816104468239608051816106d6015260a05181610793015260c051816106a0015260e051816107250152610100518161074b015261012051816104510152610140518161047a0152f35b5f80fd5b601f909101601f19168101906001600160401b0382119082101761016357604052565b634e487b7160e01b5f52604160045260245ffd5b908151602081105f146101f1575090601f8151116101b15760208151910151602082106101a2571790565b5f198260200360031b1b161790565b604460209160405192839163305a27a960e01b83528160048401528051918291826024860152018484015e5f828201840152601f01601f19168101030190fd5b6001600160401b038111610163575f54600181811c91168015610303575b60208210146102ef57601f81116102bd575b50602092601f821160011461025e57928192935f92610253575b50508160011b915f199060031b1c1916175f5560ff90565b015190505f8061023b565b601f198216935f8052805f20915f5b8681106102a5575083600195961061028d575b505050811b015f5560ff90565b01515f1960f88460031b161c191690555f8080610280565b9192602060018192868501518155019401920161026d565b5f8052601f60205f20910160051c810190601f830160051c015b8181106102e45750610221565b5f81556001016102d7565b634e487b7160e01b5f52602260045260245ffd5b90607f169061020f565b908151602081105f14610338575090601f8151116101b15760208151910151602082106101a2571790565b6001600160401b03811161016357600154600181811c9116801561043b575b60208210146102ef57601f8111610408575b50602092601f82116001146103a757928192935f9261039c575b50508160011b915f199060031b1c19161760015560ff90565b015190505f80610383565b601f1982169360015f52805f20915f5b8681106103f057508360019596106103d8575b505050811b0160015560ff90565b01515f1960f88460031b161c191690555f80806103ca565b919260206001819286850151815501940192016103b7565b60015f52601f60205f20910160051c810190601f830160051c015b8181106104305750610369565b5f8155600101610423565b90607f169061035756fe6080806040526004361015610012575f80fd5b5f3560e01c9081632671fd24146105535750806378e890ba1461053157806384b0196e1461043957806385dfbf22146100b95780638da5cb5b146100915763feb617241461005e575f80fd5b3461008d57602036600319011261008d576004355f526003602052602060ff60405f2054166040519015158152f35b5f80fd5b3461008d575f36600319011261008d576002546040516001600160a01b039091168152602090f35b3461008d573660031901610140811261008d5760c01361008d5760603660c319011261008d576101243567ffffffffffffffff811161008d573660238201121561008d5780600401359067ffffffffffffffff821161008d57366024838301011161008d5761019c6101f67fbe0dd216a26822dd9c8e08ed5232dce2f55e5a737d727aa8824f91799d83510d60206101ed946004359061027b61015a6105e5565b6044359889935f87604288886064359e8f9861018e6101776105fb565b9a60a4359b8c916040519687958b8701998a61063d565b03601f1981018352826105af565b5190206101a761069d565b906040519161190160f01b835260028301526022820152209d80602483601f19601f84011601956101db60405197886105af565b8287520183860137830101528b6109af565b909891986109e9565b7f47d111cfb750f0d31eb095fdf0de6e3aaebfb9210bc32bd19d5b2520a122e861856040518c8152a16040516001600160a01b03909716808852967f4155a17c87b28c45436a9c67a3ce67e91726731fe5c9c14c06dcd7ddcec6abbf908690a161018e6102616105e5565b9161026a6105fb565b8a6040519687958a8701998a61063d565b519020604051908152a16002546001600160a01b03160361042a57421161041b576101043590811161040c576102af610611565b6001600160a01b036102bf6105e5565b166001600160a01b03909116036103fd57815f52600360205260ff60405f2054166103ef575f828152600360205260409020805460ff191660011790556001600160a01b0361030c610611565b6002549116906020906001600160a01b03166064610328610627565b915f60405195869485936323b872dd60e01b8552600485015260018060a01b031660248401528760448401525af180156103e4576103ad575b5061036a610627565b907f45638f9aaf623132810520da36d3347c87c81eb5dd05db4d00e7a5a33c22c6b36020610396610611565b6040519384526001600160a01b03908116941692a4005b6020813d6020116103dc575b816103c6602093836105af565b8101031261008d57518015158114610361575f80fd5b3d91506103b9565b6040513d5f823e3d90fd5b623f613760e71b5f5260045ffd5b63c1ab6dc160e01b5f5260045ffd5b63127f08c960e11b5f5260045ffd5b631022c88d60e21b5f5260045ffd5b638baa579f60e01b5f5260045ffd5b3461008d575f36600319011261008d576104d56104757f00000000000000000000000000000000000000000000000000000000000000006107b9565b61049e7f00000000000000000000000000000000000000000000000000000000000000006108df565b60206104e3604051926104b183856105af565b5f84525f368137604051958695600f60f81b875260e08588015260e087019061058b565b90858203604087015261058b565b4660608501523060808501525f60a085015283810360c08501528180845192838152019301915f5b82811061051a57505050500390f35b83518552869550938101939281019260010161050b565b3461008d575f36600319011261008d57602061054b61069d565b604051908152f35b3461008d575f36600319011261008d57807f19ac96c45d832fdcb558cba6b351903a6e8ceed3234926732e8d5bdf7c0d580060209252f35b805180835260209291819084018484015e5f828201840152601f01601f1916010190565b90601f8019910116810190811067ffffffffffffffff8211176105d157604052565b634e487b7160e01b5f52604160045260245ffd5b6024356001600160a01b038116810361008d5790565b6084356001600160a01b038116810361008d5790565b60e4356001600160a01b038116810361008d5790565b60c4356001600160a01b038116810361008d5790565b7f19ac96c45d832fdcb558cba6b351903a6e8ceed3234926732e8d5bdf7c0d5800815260208101919091526001600160a01b03918216604082015260608101929092526080820192909252911660a082015260c081019190915260e00190565b307f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03161480610790575b156106f8577f000000000000000000000000000000000000000000000000000000000000000090565b60405160208101907f8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f82527f000000000000000000000000000000000000000000000000000000000000000060408201527f000000000000000000000000000000000000000000000000000000000000000060608201524660808201523060a082015260a0815261078a60c0826105af565b51902090565b507f000000000000000000000000000000000000000000000000000000000000000046146106cf565b60ff81146107ff5760ff811690601f82116107f057604051916107dd6040846105af565b6020808452838101919036833783525290565b632cd44ac360e21b5f5260045ffd5b506040515f5f548060011c91600182169182156108d5575b6020841083146108c15783855284929081156108a25750600114610845575b610842925003826105af565b90565b505f80805290917f290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e5635b81831061088657505090602061084292820101610836565b602091935080600191548385880101520191019091839261086e565b6020925061084294915060ff191682840152151560051b820101610836565b634e487b7160e01b5f52602260045260245ffd5b92607f1692610817565b60ff81146109035760ff811690601f82116107f057604051916107dd6040846105af565b506040515f6001548060011c91600182169182156109a5575b6020841083146108c15783855284929081156108a2575060011461094657610842925003826105af565b5060015f90815290917fb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf65b81831061098957505090602061084292820101610836565b6020919350806001915483858801015201910190918392610971565b92607f169261091c565b81519190604183036109df576109d89250602082015190606060408401519301515f1a90610a5d565b9192909190565b50505f9160029190565b6004811015610a4957806109fb575050565b60018103610a125763f645eedf60e01b5f5260045ffd5b60028103610a2d575063fce698f760e01b5f5260045260245ffd5b600314610a375750565b6335e2f38360e21b5f5260045260245ffd5b634e487b7160e01b5f52602160045260245ffd5b91907f7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a08411610ad4579160209360809260ff5f9560405194855216868401526040830152606082015282805260015afa156103e4575f516001600160a01b03811615610aca57905f905f90565b505f906001905f90565b5050505f916003919056fea2646970667358221220c49f6fa54998e87c9a14b5d7109c646f764e594addd8a9186dd900c18580704a64736f6c634300081d0033",
}

// AgentABI is the input ABI used to generate the binding from.
// Deprecated: Use AgentMetaData.ABI instead.
var AgentABI = AgentMetaData.ABI

// AgentBin is the compiled bytecode used for deploying new contracts.
// Deprecated: Use AgentMetaData.Bin instead.
var AgentBin = AgentMetaData.Bin

// DeployAgent deploys a new Ethereum contract, binding an instance of Agent to it.
func DeployAgent(auth *bind.TransactOpts, backend bind.ContractBackend) (common.Address, *types.Transaction, *Agent, error) {
	parsed, err := AgentMetaData.GetAbi()
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	if parsed == nil {
		return common.Address{}, nil, nil, errors.New("GetABI returned nil")
	}

	address, tx, contract, err := bind.DeployContract(auth, *parsed, common.FromHex(AgentBin), backend)
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	return address, tx, &Agent{AgentCaller: AgentCaller{contract: contract}, AgentTransactor: AgentTransactor{contract: contract}, AgentFilterer: AgentFilterer{contract: contract}}, nil
}

// Agent is an auto generated Go binding around an Ethereum contract.
type Agent struct {
	AgentCaller     // Read-only binding to the contract
	AgentTransactor // Write-only binding to the contract
	AgentFilterer   // Log filterer for contract events
}

// AgentCaller is an auto generated read-only Go binding around an Ethereum contract.
type AgentCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// AgentTransactor is an auto generated write-only Go binding around an Ethereum contract.
type AgentTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// AgentFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type AgentFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// AgentSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type AgentSession struct {
	Contract     *Agent            // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// AgentCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type AgentCallerSession struct {
	Contract *AgentCaller  // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts // Call options to use throughout this session
}

// AgentTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type AgentTransactorSession struct {
	Contract     *AgentTransactor  // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// AgentRaw is an auto generated low-level Go binding around an Ethereum contract.
type AgentRaw struct {
	Contract *Agent // Generic contract binding to access the raw methods on
}

// AgentCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type AgentCallerRaw struct {
	Contract *AgentCaller // Generic read-only contract binding to access the raw methods on
}

// AgentTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type AgentTransactorRaw struct {
	Contract *AgentTransactor // Generic write-only contract binding to access the raw methods on
}

// NewAgent creates a new instance of Agent, bound to a specific deployed contract.
func NewAgent(address common.Address, backend bind.ContractBackend) (*Agent, error) {
	contract, err := bindAgent(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &Agent{AgentCaller: AgentCaller{contract: contract}, AgentTransactor: AgentTransactor{contract: contract}, AgentFilterer: AgentFilterer{contract: contract}}, nil
}

// NewAgentCaller creates a new read-only instance of Agent, bound to a specific deployed contract.
func NewAgentCaller(address common.Address, caller bind.ContractCaller) (*AgentCaller, error) {
	contract, err := bindAgent(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &AgentCaller{contract: contract}, nil
}

// NewAgentTransactor creates a new write-only instance of Agent, bound to a specific deployed contract.
func NewAgentTransactor(address common.Address, transactor bind.ContractTransactor) (*AgentTransactor, error) {
	contract, err := bindAgent(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &AgentTransactor{contract: contract}, nil
}

// NewAgentFilterer creates a new log filterer instance of Agent, bound to a specific deployed contract.
func NewAgentFilterer(address common.Address, filterer bind.ContractFilterer) (*AgentFilterer, error) {
	contract, err := bindAgent(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &AgentFilterer{contract: contract}, nil
}

// bindAgent binds a generic wrapper to an already deployed contract.
func bindAgent(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := AgentMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Agent *AgentRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Agent.Contract.AgentCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Agent *AgentRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Agent.Contract.AgentTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Agent *AgentRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Agent.Contract.AgentTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Agent *AgentCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Agent.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Agent *AgentTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Agent.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Agent *AgentTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Agent.Contract.contract.Transact(opts, method, params...)
}

// INTENTMANDATETYPEHASH is a free data retrieval call binding the contract method 0x2671fd24.
//
// Solidity: function INTENT_MANDATE_TYPEHASH() view returns(bytes32)
func (_Agent *AgentCaller) INTENTMANDATETYPEHASH(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _Agent.contract.Call(opts, &out, "INTENT_MANDATE_TYPEHASH")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// INTENTMANDATETYPEHASH is a free data retrieval call binding the contract method 0x2671fd24.
//
// Solidity: function INTENT_MANDATE_TYPEHASH() view returns(bytes32)
func (_Agent *AgentSession) INTENTMANDATETYPEHASH() ([32]byte, error) {
	return _Agent.Contract.INTENTMANDATETYPEHASH(&_Agent.CallOpts)
}

// INTENTMANDATETYPEHASH is a free data retrieval call binding the contract method 0x2671fd24.
//
// Solidity: function INTENT_MANDATE_TYPEHASH() view returns(bytes32)
func (_Agent *AgentCallerSession) INTENTMANDATETYPEHASH() ([32]byte, error) {
	return _Agent.Contract.INTENTMANDATETYPEHASH(&_Agent.CallOpts)
}

// DomainSeparatorV4 is a free data retrieval call binding the contract method 0x78e890ba.
//
// Solidity: function domainSeparatorV4() view returns(bytes32)
func (_Agent *AgentCaller) DomainSeparatorV4(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _Agent.contract.Call(opts, &out, "domainSeparatorV4")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DomainSeparatorV4 is a free data retrieval call binding the contract method 0x78e890ba.
//
// Solidity: function domainSeparatorV4() view returns(bytes32)
func (_Agent *AgentSession) DomainSeparatorV4() ([32]byte, error) {
	return _Agent.Contract.DomainSeparatorV4(&_Agent.CallOpts)
}

// DomainSeparatorV4 is a free data retrieval call binding the contract method 0x78e890ba.
//
// Solidity: function domainSeparatorV4() view returns(bytes32)
func (_Agent *AgentCallerSession) DomainSeparatorV4() ([32]byte, error) {
	return _Agent.Contract.DomainSeparatorV4(&_Agent.CallOpts)
}

// Eip712Domain is a free data retrieval call binding the contract method 0x84b0196e.
//
// Solidity: function eip712Domain() view returns(bytes1 fields, string name, string version, uint256 chainId, address verifyingContract, bytes32 salt, uint256[] extensions)
func (_Agent *AgentCaller) Eip712Domain(opts *bind.CallOpts) (struct {
	Fields            [1]byte
	Name              string
	Version           string
	ChainId           *big.Int
	VerifyingContract common.Address
	Salt              [32]byte
	Extensions        []*big.Int
}, error) {
	var out []interface{}
	err := _Agent.contract.Call(opts, &out, "eip712Domain")

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
func (_Agent *AgentSession) Eip712Domain() (struct {
	Fields            [1]byte
	Name              string
	Version           string
	ChainId           *big.Int
	VerifyingContract common.Address
	Salt              [32]byte
	Extensions        []*big.Int
}, error) {
	return _Agent.Contract.Eip712Domain(&_Agent.CallOpts)
}

// Eip712Domain is a free data retrieval call binding the contract method 0x84b0196e.
//
// Solidity: function eip712Domain() view returns(bytes1 fields, string name, string version, uint256 chainId, address verifyingContract, bytes32 salt, uint256[] extensions)
func (_Agent *AgentCallerSession) Eip712Domain() (struct {
	Fields            [1]byte
	Name              string
	Version           string
	ChainId           *big.Int
	VerifyingContract common.Address
	Salt              [32]byte
	Extensions        []*big.Int
}, error) {
	return _Agent.Contract.Eip712Domain(&_Agent.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Agent *AgentCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Agent.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Agent *AgentSession) Owner() (common.Address, error) {
	return _Agent.Contract.Owner(&_Agent.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Agent *AgentCallerSession) Owner() (common.Address, error) {
	return _Agent.Contract.Owner(&_Agent.CallOpts)
}

// UsedNonces is a free data retrieval call binding the contract method 0xfeb61724.
//
// Solidity: function usedNonces(bytes32 ) view returns(bool)
func (_Agent *AgentCaller) UsedNonces(opts *bind.CallOpts, arg0 [32]byte) (bool, error) {
	var out []interface{}
	err := _Agent.contract.Call(opts, &out, "usedNonces", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// UsedNonces is a free data retrieval call binding the contract method 0xfeb61724.
//
// Solidity: function usedNonces(bytes32 ) view returns(bool)
func (_Agent *AgentSession) UsedNonces(arg0 [32]byte) (bool, error) {
	return _Agent.Contract.UsedNonces(&_Agent.CallOpts, arg0)
}

// UsedNonces is a free data retrieval call binding the contract method 0xfeb61724.
//
// Solidity: function usedNonces(bytes32 ) view returns(bool)
func (_Agent *AgentCallerSession) UsedNonces(arg0 [32]byte) (bool, error) {
	return _Agent.Contract.UsedNonces(&_Agent.CallOpts, arg0)
}

// ExecutePurchase is a paid mutator transaction binding the contract method 0x85dfbf22.
//
// Solidity: function executePurchase((bytes32,address,uint256,uint256,address,uint256) intent, (address,address,uint256) cart, bytes signature) returns()
func (_Agent *AgentTransactor) ExecutePurchase(opts *bind.TransactOpts, intent AgentProxyIntentMandate, cart AgentProxyCartMandate, signature []byte) (*types.Transaction, error) {
	return _Agent.contract.Transact(opts, "executePurchase", intent, cart, signature)
}

// ExecutePurchase is a paid mutator transaction binding the contract method 0x85dfbf22.
//
// Solidity: function executePurchase((bytes32,address,uint256,uint256,address,uint256) intent, (address,address,uint256) cart, bytes signature) returns()
func (_Agent *AgentSession) ExecutePurchase(intent AgentProxyIntentMandate, cart AgentProxyCartMandate, signature []byte) (*types.Transaction, error) {
	return _Agent.Contract.ExecutePurchase(&_Agent.TransactOpts, intent, cart, signature)
}

// ExecutePurchase is a paid mutator transaction binding the contract method 0x85dfbf22.
//
// Solidity: function executePurchase((bytes32,address,uint256,uint256,address,uint256) intent, (address,address,uint256) cart, bytes signature) returns()
func (_Agent *AgentTransactorSession) ExecutePurchase(intent AgentProxyIntentMandate, cart AgentProxyCartMandate, signature []byte) (*types.Transaction, error) {
	return _Agent.Contract.ExecutePurchase(&_Agent.TransactOpts, intent, cart, signature)
}

// AgentEIP712DomainChangedIterator is returned from FilterEIP712DomainChanged and is used to iterate over the raw logs and unpacked data for EIP712DomainChanged events raised by the Agent contract.
type AgentEIP712DomainChangedIterator struct {
	Event *AgentEIP712DomainChanged // Event containing the contract specifics and raw log

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
func (it *AgentEIP712DomainChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AgentEIP712DomainChanged)
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
		it.Event = new(AgentEIP712DomainChanged)
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
func (it *AgentEIP712DomainChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AgentEIP712DomainChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AgentEIP712DomainChanged represents a EIP712DomainChanged event raised by the Agent contract.
type AgentEIP712DomainChanged struct {
	Raw types.Log // Blockchain specific contextual infos
}

// FilterEIP712DomainChanged is a free log retrieval operation binding the contract event 0x0a6387c9ea3628b88a633bb4f3b151770f70085117a15f9bf3787cda53f13d31.
//
// Solidity: event EIP712DomainChanged()
func (_Agent *AgentFilterer) FilterEIP712DomainChanged(opts *bind.FilterOpts) (*AgentEIP712DomainChangedIterator, error) {

	logs, sub, err := _Agent.contract.FilterLogs(opts, "EIP712DomainChanged")
	if err != nil {
		return nil, err
	}
	return &AgentEIP712DomainChangedIterator{contract: _Agent.contract, event: "EIP712DomainChanged", logs: logs, sub: sub}, nil
}

// WatchEIP712DomainChanged is a free log subscription operation binding the contract event 0x0a6387c9ea3628b88a633bb4f3b151770f70085117a15f9bf3787cda53f13d31.
//
// Solidity: event EIP712DomainChanged()
func (_Agent *AgentFilterer) WatchEIP712DomainChanged(opts *bind.WatchOpts, sink chan<- *AgentEIP712DomainChanged) (event.Subscription, error) {

	logs, sub, err := _Agent.contract.WatchLogs(opts, "EIP712DomainChanged")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AgentEIP712DomainChanged)
				if err := _Agent.contract.UnpackLog(event, "EIP712DomainChanged", log); err != nil {
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
func (_Agent *AgentFilterer) ParseEIP712DomainChanged(log types.Log) (*AgentEIP712DomainChanged, error) {
	event := new(AgentEIP712DomainChanged)
	if err := _Agent.contract.UnpackLog(event, "EIP712DomainChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AgentPurchaseExecutedIterator is returned from FilterPurchaseExecuted and is used to iterate over the raw logs and unpacked data for PurchaseExecuted events raised by the Agent contract.
type AgentPurchaseExecutedIterator struct {
	Event *AgentPurchaseExecuted // Event containing the contract specifics and raw log

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
func (it *AgentPurchaseExecutedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AgentPurchaseExecuted)
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
		it.Event = new(AgentPurchaseExecuted)
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
func (it *AgentPurchaseExecutedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AgentPurchaseExecutedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AgentPurchaseExecuted represents a PurchaseExecuted event raised by the Agent contract.
type AgentPurchaseExecuted struct {
	Merchant    common.Address
	Token       common.Address
	Amount      *big.Int
	IntentNonce [32]byte
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterPurchaseExecuted is a free log retrieval operation binding the contract event 0x45638f9aaf623132810520da36d3347c87c81eb5dd05db4d00e7a5a33c22c6b3.
//
// Solidity: event PurchaseExecuted(address indexed merchant, address indexed token, uint256 amount, bytes32 indexed intentNonce)
func (_Agent *AgentFilterer) FilterPurchaseExecuted(opts *bind.FilterOpts, merchant []common.Address, token []common.Address, intentNonce [][32]byte) (*AgentPurchaseExecutedIterator, error) {

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

	logs, sub, err := _Agent.contract.FilterLogs(opts, "PurchaseExecuted", merchantRule, tokenRule, intentNonceRule)
	if err != nil {
		return nil, err
	}
	return &AgentPurchaseExecutedIterator{contract: _Agent.contract, event: "PurchaseExecuted", logs: logs, sub: sub}, nil
}

// WatchPurchaseExecuted is a free log subscription operation binding the contract event 0x45638f9aaf623132810520da36d3347c87c81eb5dd05db4d00e7a5a33c22c6b3.
//
// Solidity: event PurchaseExecuted(address indexed merchant, address indexed token, uint256 amount, bytes32 indexed intentNonce)
func (_Agent *AgentFilterer) WatchPurchaseExecuted(opts *bind.WatchOpts, sink chan<- *AgentPurchaseExecuted, merchant []common.Address, token []common.Address, intentNonce [][32]byte) (event.Subscription, error) {

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

	logs, sub, err := _Agent.contract.WatchLogs(opts, "PurchaseExecuted", merchantRule, tokenRule, intentNonceRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AgentPurchaseExecuted)
				if err := _Agent.contract.UnpackLog(event, "PurchaseExecuted", log); err != nil {
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
func (_Agent *AgentFilterer) ParsePurchaseExecuted(log types.Log) (*AgentPurchaseExecuted, error) {
	event := new(AgentPurchaseExecuted)
	if err := _Agent.contract.UnpackLog(event, "PurchaseExecuted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AgentSignerAddressIterator is returned from FilterSignerAddress and is used to iterate over the raw logs and unpacked data for SignerAddress events raised by the Agent contract.
type AgentSignerAddressIterator struct {
	Event *AgentSignerAddress // Event containing the contract specifics and raw log

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
func (it *AgentSignerAddressIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AgentSignerAddress)
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
		it.Event = new(AgentSignerAddress)
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
func (it *AgentSignerAddressIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AgentSignerAddressIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AgentSignerAddress represents a SignerAddress event raised by the Agent contract.
type AgentSignerAddress struct {
	Signer common.Address
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterSignerAddress is a free log retrieval operation binding the contract event 0x4155a17c87b28c45436a9c67a3ce67e91726731fe5c9c14c06dcd7ddcec6abbf.
//
// Solidity: event SignerAddress(address signer)
func (_Agent *AgentFilterer) FilterSignerAddress(opts *bind.FilterOpts) (*AgentSignerAddressIterator, error) {

	logs, sub, err := _Agent.contract.FilterLogs(opts, "SignerAddress")
	if err != nil {
		return nil, err
	}
	return &AgentSignerAddressIterator{contract: _Agent.contract, event: "SignerAddress", logs: logs, sub: sub}, nil
}

// WatchSignerAddress is a free log subscription operation binding the contract event 0x4155a17c87b28c45436a9c67a3ce67e91726731fe5c9c14c06dcd7ddcec6abbf.
//
// Solidity: event SignerAddress(address signer)
func (_Agent *AgentFilterer) WatchSignerAddress(opts *bind.WatchOpts, sink chan<- *AgentSignerAddress) (event.Subscription, error) {

	logs, sub, err := _Agent.contract.WatchLogs(opts, "SignerAddress")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AgentSignerAddress)
				if err := _Agent.contract.UnpackLog(event, "SignerAddress", log); err != nil {
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

// ParseSignerAddress is a log parse operation binding the contract event 0x4155a17c87b28c45436a9c67a3ce67e91726731fe5c9c14c06dcd7ddcec6abbf.
//
// Solidity: event SignerAddress(address signer)
func (_Agent *AgentFilterer) ParseSignerAddress(log types.Log) (*AgentSignerAddress, error) {
	event := new(AgentSignerAddress)
	if err := _Agent.contract.UnpackLog(event, "SignerAddress", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AgentSignerRecoveredIterator is returned from FilterSignerRecovered and is used to iterate over the raw logs and unpacked data for SignerRecovered events raised by the Agent contract.
type AgentSignerRecoveredIterator struct {
	Event *AgentSignerRecovered // Event containing the contract specifics and raw log

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
func (it *AgentSignerRecoveredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AgentSignerRecovered)
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
		it.Event = new(AgentSignerRecovered)
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
func (it *AgentSignerRecoveredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AgentSignerRecoveredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AgentSignerRecovered represents a SignerRecovered event raised by the Agent contract.
type AgentSignerRecovered struct {
	IntentHash [32]byte
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterSignerRecovered is a free log retrieval operation binding the contract event 0x47d111cfb750f0d31eb095fdf0de6e3aaebfb9210bc32bd19d5b2520a122e861.
//
// Solidity: event SignerRecovered(bytes32 intentHash)
func (_Agent *AgentFilterer) FilterSignerRecovered(opts *bind.FilterOpts) (*AgentSignerRecoveredIterator, error) {

	logs, sub, err := _Agent.contract.FilterLogs(opts, "SignerRecovered")
	if err != nil {
		return nil, err
	}
	return &AgentSignerRecoveredIterator{contract: _Agent.contract, event: "SignerRecovered", logs: logs, sub: sub}, nil
}

// WatchSignerRecovered is a free log subscription operation binding the contract event 0x47d111cfb750f0d31eb095fdf0de6e3aaebfb9210bc32bd19d5b2520a122e861.
//
// Solidity: event SignerRecovered(bytes32 intentHash)
func (_Agent *AgentFilterer) WatchSignerRecovered(opts *bind.WatchOpts, sink chan<- *AgentSignerRecovered) (event.Subscription, error) {

	logs, sub, err := _Agent.contract.WatchLogs(opts, "SignerRecovered")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AgentSignerRecovered)
				if err := _Agent.contract.UnpackLog(event, "SignerRecovered", log); err != nil {
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

// ParseSignerRecovered is a log parse operation binding the contract event 0x47d111cfb750f0d31eb095fdf0de6e3aaebfb9210bc32bd19d5b2520a122e861.
//
// Solidity: event SignerRecovered(bytes32 intentHash)
func (_Agent *AgentFilterer) ParseSignerRecovered(log types.Log) (*AgentSignerRecovered, error) {
	event := new(AgentSignerRecovered)
	if err := _Agent.contract.UnpackLog(event, "SignerRecovered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AgentStructHashIterator is returned from FilterStructHash and is used to iterate over the raw logs and unpacked data for StructHash events raised by the Agent contract.
type AgentStructHashIterator struct {
	Event *AgentStructHash // Event containing the contract specifics and raw log

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
func (it *AgentStructHashIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AgentStructHash)
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
		it.Event = new(AgentStructHash)
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
func (it *AgentStructHashIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AgentStructHashIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AgentStructHash represents a StructHash event raised by the Agent contract.
type AgentStructHash struct {
	StructHash [32]byte
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterStructHash is a free log retrieval operation binding the contract event 0xbe0dd216a26822dd9c8e08ed5232dce2f55e5a737d727aa8824f91799d83510d.
//
// Solidity: event StructHash(bytes32 structHash)
func (_Agent *AgentFilterer) FilterStructHash(opts *bind.FilterOpts) (*AgentStructHashIterator, error) {

	logs, sub, err := _Agent.contract.FilterLogs(opts, "StructHash")
	if err != nil {
		return nil, err
	}
	return &AgentStructHashIterator{contract: _Agent.contract, event: "StructHash", logs: logs, sub: sub}, nil
}

// WatchStructHash is a free log subscription operation binding the contract event 0xbe0dd216a26822dd9c8e08ed5232dce2f55e5a737d727aa8824f91799d83510d.
//
// Solidity: event StructHash(bytes32 structHash)
func (_Agent *AgentFilterer) WatchStructHash(opts *bind.WatchOpts, sink chan<- *AgentStructHash) (event.Subscription, error) {

	logs, sub, err := _Agent.contract.WatchLogs(opts, "StructHash")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AgentStructHash)
				if err := _Agent.contract.UnpackLog(event, "StructHash", log); err != nil {
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

// ParseStructHash is a log parse operation binding the contract event 0xbe0dd216a26822dd9c8e08ed5232dce2f55e5a737d727aa8824f91799d83510d.
//
// Solidity: event StructHash(bytes32 structHash)
func (_Agent *AgentFilterer) ParseStructHash(log types.Log) (*AgentStructHash, error) {
	event := new(AgentStructHash)
	if err := _Agent.contract.UnpackLog(event, "StructHash", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
