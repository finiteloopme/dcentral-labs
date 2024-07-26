package main

import (
	"context"
	token "contracts/erc20"
	nft "contracts/erc721"
	"crypto/ecdsa"
	"encoding/json"
	"fmt"
	"io"
	"math/big"
	"net/http"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	_ "github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/pkg/account"
	_ "github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/pkg/wallet"
	"github.com/finiteloopme/goutils/pkg/log"
	"github.com/finiteloopme/goutils/pkg/os/env"
	// store "./contracts" // for demo
)

type Addresses struct {
	ZKPTokenAddress string `envconfig:"ZKP_TOKEN_ADDRESS" required:"true" yaml:"zkp"`
	EggNFTAddress   string `envconfig:"EGG_NFT_ADDRESS" required:"true" yaml:"egg"`
	FeaAddress      string `envconfig:"FEATHER_NFT_ADDRESS" required:"true" yaml:"fea"`
}

type Keys struct {
	Owner string `envconfig:"OWNER_KEY" yaml:"owner"`
	User1 string `envconfig:"USER1_KEY" yaml:"user1"`
	User2 string `envconfig:"USER2_KEY" yaml:"user2"`
	User3 string `envconfig:"USER2_KEY" yaml:"user3"`
}

type PubsubConfig struct {
	Item4Collection PubsubConfigType `yaml:"item-collected"`
	Transfer2Player PubsubConfigType `yaml:"onchain-transfer"`
}

type PubsubConfigType struct {
	PushEndpoint string `yaml:"to-push-endpoint"`
	TopicName    string `yaml:"from-topic"`
}

type Config struct {
	RPC               string       `envconfig:"RPC" required:"true" yaml:"rpc"`
	ContractAddresses Addresses    `yaml:"contracts"`
	UserKeys          Keys         `yaml:"users"`
	Pubsub            PubsubConfig `yaml:"pubsub-config"`
	CloudRunPort      string       `envconfig:"PORT" default:"8080" yaml:"cloud-run-port"`
}

type ClientForChain struct {
	ethClient *ethclient.Client
	cfg       *Config
	zkpToken  *token.Erc20
	eggNFT    *nft.Erc721
	feaNFT    *nft.Erc721
	callOpts  *bind.CallOpts
}

func NewClient(_cfg *Config) *ClientForChain {
	c := &ClientForChain{}
	var err error

	// Read configuration
	c.cfg = _cfg
	if err = env.Process("", c.cfg); err != nil {
		log.Warn("error reading configfuration. ", err)
		// log.Fatal(err)
	}

	// Connect to RPC endpoint
	if c.ethClient, err = ethclient.Dial(c.cfg.RPC); err != nil {
		log.Warn("error creating client for the chain. ", err)
		log.Fatal(err)
	}

	// Connect to RPC with owner key
	ownerKey := GetKeyFromHexPrivateKey(c.cfg.UserKeys.Owner)
	c.callOpts = &bind.CallOpts{
		From: ownerKey.Address,
	}

	// Load smart contracts
	if c.zkpToken, err = token.NewErc20(common.HexToAddress(c.cfg.ContractAddresses.ZKPTokenAddress), c.ethClient); err != nil {
		log.Warn("error loading ZKP token contract. ", err)
		log.Fatal(err)
	}

	if c.eggNFT, err = nft.NewErc721(common.HexToAddress(c.cfg.ContractAddresses.EggNFTAddress), c.ethClient); err != nil {
		log.Warn("error loading egg NFT contract. ", err)
		log.Fatal(err)

	}
	if c.feaNFT, err = nft.NewErc721(common.HexToAddress(c.cfg.ContractAddresses.FeaAddress), c.ethClient); err != nil {
		log.Warn("error loading feather NFT contract. ", err)
		log.Fatal(err)
	}

	return c
}

type Key struct {
	Address    common.Address
	PrivateKey *ecdsa.PrivateKey
}

func GetKeyFromHexPrivateKey(privateKey string) *Key {
	key := &Key{}
	var err error
	if key.PrivateKey, err = crypto.HexToECDSA(privateKey); err != nil {
		log.Warn("error reading private key. ", err)
		return nil
	}
	key.Address = crypto.PubkeyToAddress(key.PrivateKey.PublicKey)
	return key
}

func (c *ClientForChain) GetChainID() *big.Int {
	bigInt, err := c.ethClient.ChainID(context.Background())
	if err != nil {
		log.Warn("error retrieving chain id", err)
		bigInt = big.NewInt(0)
	}
	return bigInt
}

func (c *ClientForChain) NewTransactor(fromPrivateKey string) *bind.TransactOpts {

	key := GetKeyFromHexPrivateKey(fromPrivateKey)
	nonce, err := c.ethClient.PendingNonceAt(context.Background(), key.Address)
	if err != nil {
		log.Fatal(err)
	}

	gasPrice, err := c.ethClient.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	auth, _ := bind.NewKeyedTransactorWithChainID(key.PrivateKey, c.GetChainID())
	auth.Nonce = big.NewInt(int64(nonce))
	auth.Value = big.NewInt(0)     // in wei
	auth.GasLimit = uint64(300000) // in units
	auth.GasPrice = gasPrice

	return auth
}

func (c *ClientForChain) ZKPBalanceOf(hexAddress string) *big.Int {
	if userBalance, err := c.zkpToken.BalanceOf(c.callOpts, common.HexToAddress(hexAddress)); err != nil {
		log.Warn("unable to retrieve user balance.", err)
		return big.NewInt(-1)
	} else {
		return userBalance
	}

}

func (c *ClientForChain) TransferZKP(fromPrivateKey string, toAddress common.Address, amount *big.Int) *types.Transaction {
	auth := c.NewTransactor(fromPrivateKey)
	tx, err := c.zkpToken.Transfer(auth, toAddress, amount)
	if err != nil {
		log.Fatal(err)
	}

	return tx
}

func (c *ClientForChain) AwardAnEgg(fromPrivateKey string, toAddress common.Address) *types.Transaction {
	auth := c.NewTransactor(fromPrivateKey)
	tx, err := c.eggNFT.AwardItem(auth, toAddress)
	if err != nil {
		log.Fatal(err)
	}

	return tx
}

func (c *ClientForChain) WhoOwnsTheEgg(tokenId *big.Int) common.Address {
	owner, err := c.eggNFT.OwnerOf(c.callOpts, tokenId)
	if err != nil {
		log.Fatal(err)
	}

	return owner
}

func (c *ClientForChain) AwardFeather(fromPrivateKey string, toAddress common.Address) *types.Transaction {
	auth := c.NewTransactor(fromPrivateKey)
	tx, err := c.feaNFT.AwardItem(auth, toAddress)
	if err != nil {
		log.Fatal(err)
	}

	return tx
}

func (c *ClientForChain) WhoOwnsTheFeather(tokenId *big.Int) common.Address {
	owner, err := c.feaNFT.OwnerOf(c.callOpts, tokenId)
	if err != nil {
		log.Fatal(err)
	}

	return owner
}

func GetChainID(client *ethclient.Client) *big.Int {
	bigInt, err := client.ChainID(context.Background())
	if err != nil {
		log.Warn("error retrieving chain id", err)
		bigInt = big.NewInt(0)
	}
	return bigInt
}

// Should represent the SendToPubsubRequest in [item-collection] microservice
type CollectItemRequest struct {
	Action        string `json:"action"`
	ItemType      string `json:"itemType"`
	PlayerID      string `json:"playerID"`
	Points        string `json:"points"`
	PlayerAddress string `json:"playerAddress,omitempty"`
}

// https://cloud.google.com/pubsub/docs/reference/rest/v1/PubsubMessage
type PubSubMessage struct {
	Message struct {
		Data []byte `json:"data,omitempty"`
		ID   string `json:"id"`
	} `json:"message"`
	Subscription string `json:"subscription"`
}

func HandleCollectItemRequest(w http.ResponseWriter, r *http.Request) {
	if body, err := io.ReadAll(r.Body); err != nil {
		log.Warn(fmt.Sprintf("ioutil.ReadAll: %v", err), err)
		// http.Error(w, "Bad Request", http.StatusBadRequest)
		return
	} else {
		go ProcessCollectItemRequest(body)
	}

}

func ProcessCollectItemRequest(data []byte) {
	var m PubSubMessage
	// byte slice unmarshalling handles base64 decoding.
	if err := json.Unmarshal(data, &m); err != nil {
		log.Warn(fmt.Sprintf("json.Unmarshal: %v", err), err)
		// http.Error(w, "Bad Request", http.StatusBadRequest)
		return
	}
	collectItemRequest := CollectItemRequest{}
	if err := json.Unmarshal(m.Message.Data, &collectItemRequest); err != nil {
		log.Warn("error unmarshalling CollectItemRequest. ", err)
	}
	//
}

func HandleTransferItemRequest(w http.ResponseWriter, r *http.Request) {

}

func SendMessage(topic string, msg interface{}) {

}

func main() {
	cfg := &Config{}
	http.HandleFunc(cfg.Pubsub.Item4Collection.PushEndpoint, HandleCollectItemRequest)
	http.HandleFunc(cfg.Pubsub.Transfer2Player.PushEndpoint, HandleTransferItemRequest)

	// client := NewClient(cfg)
	// ownerKey := GetKeyFromHexPrivateKey(cfg.UserKeys.Owner)
	// user1Key := GetKeyFromHexPrivateKey(cfg.UserKeys.User1)
	// user2Key := GetKeyFromHexPrivateKey(cfg.UserKeys.User2)
	// log.Info(fmt.Sprintf("Balance of owner is: %v", client.ZKPBalanceOf(ownerKey.Address.Hex())))
	// log.Info(fmt.Sprintf("Balance of user1 is: %v", client.ZKPBalanceOf(user1Key.Address.Hex())))
	// client.TransferZKP(cfg.UserKeys.Owner, user1Key.Address, big.NewInt(10))
	// log.Info(fmt.Sprintf("Balance of owner is: %v", client.ZKPBalanceOf(ownerKey.Address.Hex())))
	// log.Info(fmt.Sprintf("Balance of user1 is: %v", client.ZKPBalanceOf(user1Key.Address.Hex())))
	// client.AwardAnEgg(cfg.UserKeys.Owner, user1Key.Address)
	// client.AwardFeather(cfg.UserKeys.Owner, user2Key.Address)

	// log.Info((fmt.Sprintf("Owner of egg1 is: %v", client.WhoOwnsTheEgg(big.NewInt(1)))))
	// log.Info((fmt.Sprintf("Owner of feather1 is: %v", client.WhoOwnsTheFeather(big.NewInt(1)))))
}
