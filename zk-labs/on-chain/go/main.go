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
	"sync"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/pkg/wallet"
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
	Item4Collection string `yaml:"item-collected"`
	// Item4Collection PubsubConfigType `yaml:"item-collected"`
	// Transfer2Player PubsubConfigType `yaml:"onchain-transfer"`
}

// type PubsubConfigType struct {
// 	PushEndpoint string `yaml:"to-push-endpoint"`
// 	TopicName    string `yaml:"from-topic"`
// }

type Config struct {
	RPC               string       `envconfig:"RPC" required:"true" yaml:"rpc"`
	ContractAddresses Addresses    `yaml:"contracts"`
	UserKeys          Keys         `yaml:"users"`
	Pubsub            PubsubConfig `yaml:"pubsub-config"`
	CloudRunPort      string       `envconfig:"PORT" default:"8080" yaml:"cloud-run-port"`
}

type ClientForChain struct {
	sync.Mutex
	cfg       *Config           //Config for this micro service
	ethClient *ethclient.Client //Client to ETH
	zkpToken  *token.Erc20      //ZKProof token contract
	eggNFT    *nft.Erc721       //EggNFT contract
	feaNFT    *nft.Erc721       //FeatherNFT contract
	owner     *Key              //Original owner of the contracts & assets on the chain
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

	c.owner = GetKeyFromHexPrivateKey(c.cfg.UserKeys.Owner)
	if c.owner == nil {
		log.Warn("error getting the owner. ", err)
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
		log.Warn("error getting pending nonce.", err)
		// log.Fatal(err)
	}

	gasPrice, err := c.ethClient.SuggestGasPrice(context.Background())
	if err != nil {
		log.Warn("error suggesting gas price.", err)
		// log.Fatal(err)
	}

	c.Lock()
	defer c.Unlock()
	auth, _ := bind.NewKeyedTransactorWithChainID(key.PrivateKey, c.GetChainID())
	// c.Unlock()
	auth.Nonce = big.NewInt(int64(nonce))
	auth.Value = big.NewInt(0)     // in wei
	auth.GasLimit = uint64(300000) // in units
	auth.GasPrice = gasPrice

	return auth
}

func (c *ClientForChain) ZKPBalanceOf(hexAddress string) *big.Int {
	if userBalance, err := c.zkpToken.BalanceOf(c.callOpts, common.HexToAddress(hexAddress)); err != nil {
		// if userBalance, err := c.zkpToken.BalanceOf(&bind.CallOpts{}, common.HexToAddress("0xd7BC8Ce7Fe81Ad8f4A22a714Cc13bed3396D44ef")); err != nil {
		log.Warn("unable to retrieve user balance.", err)
		return big.NewInt(-1)
	} else {
		return userBalance
	}

}

func (c *ClientForChain) GetBlockNumber(txn *types.Transaction) *big.Int {
	startCount := 1
	maxCount := 10
	sleepSec := 5

	for {
		tx, isPending, err := c.ethClient.TransactionByHash(context.Background(), txn.Hash())
		if err != nil {
			log.Warn("error getting block hash", err)
			return nil
		}
		if isPending {
			// backoff wai
			if startCount < maxCount {
				time.Sleep(time.Duration(startCount * sleepSec * int(time.Second)))
				startCount++
			} else {
				log.Warn("stopping exponential backoff to get block hash", err)
				return nil
			}
		} else {
			if receipt, err := c.ethClient.TransactionReceipt(context.Background(), tx.Hash()); err != nil {
				log.Warn("error getting block number", err)
				return nil
			} else {
				return receipt.BlockNumber
			}
		}
	}

}

func (c *ClientForChain) TransferZKP(fromPrivateKey string, toAddress common.Address, amount *big.Int) *types.Transaction {
	auth := c.NewTransactor(fromPrivateKey)
	tx, err := c.zkpToken.Transfer(auth, toAddress, amount)
	if err != nil {
		log.Warn("Unable to transfer tokens to address: "+toAddress.Hex(), err)
		// log.Fatal(err)
	} else {
		go log.Info(fmt.Sprintf("Transfered [%v] tokens to address [%v] at block [%v]; txn [%v]", amount, toAddress.Hex(), c.GetBlockNumber(tx), tx.Hash().Hex()))
	}

	return tx
}

func (c *ClientForChain) AwardAnEgg(fromPrivateKey string, toAddress common.Address) *types.Transaction {
	auth := c.NewTransactor(fromPrivateKey)
	tx, err := c.eggNFT.AwardItem(auth, toAddress)
	if err != nil {
		log.Warn("Unable to mint an Egg to address: "+toAddress.Hex(), err)
		// log.Fatal(err)
	} else {
		go log.Info(fmt.Sprintf("Minted an Egg to address [%v] at block [%v]; txn [%v]", toAddress.Hex(), c.GetBlockNumber(tx), tx.Hash().Hex()))
	}

	return tx
}

func (c *ClientForChain) WhoOwnsTheEgg(tokenId *big.Int) common.Address {
	owner, err := c.eggNFT.OwnerOf(c.callOpts, tokenId)
	if err != nil {
		log.Warn("error retrieving owner of the egg", err)
		// log.Fatal(err)
	}

	return owner
}

func (c *ClientForChain) AwardFeather(fromPrivateKey string, toAddress common.Address) *types.Transaction {
	auth := c.NewTransactor(fromPrivateKey)
	tx, err := c.feaNFT.AwardItem(auth, toAddress)
	if err != nil {
		log.Warn("Unable to mint a Feather to address: "+toAddress.Hex(), err)
		// log.Fatal(err)
	} else {
		go log.Info(fmt.Sprintf("Minted an Egg to address [%v] at block [%v]; txn [%v]", toAddress.Hex(), c.GetBlockNumber(tx), tx.Hash().Hex()))
	}

	return tx
}

func (c *ClientForChain) WhoOwnsTheFeather(tokenId *big.Int) common.Address {
	owner, err := c.feaNFT.OwnerOf(c.callOpts, tokenId)
	if err != nil {
		log.Warn("error retrieving owner of the Feather", err)
		// log.Fatal(err)
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

func (c CollectItemRequest) ToString() string {
	return fmt.Sprintf("{'action':'%v','itemType':'%v','playerID':'%v','points':'%v','playerAddress':'%v'}", c.Action, c.ItemType, c.PlayerID, c.Points, c.PlayerAddress)
}

// https://cloud.google.com/pubsub/docs/reference/rest/v1/PubsubMessage
type PubSubMessage struct {
	Message struct {
		Data []byte `json:"data,omitempty"`
		ID   string `json:"id"`
	} `json:"message"`
	Subscription string `json:"subscription"`
}

func (c *ClientForChain) HandleCollectItemRequest(w http.ResponseWriter, r *http.Request) {
	if body, err := io.ReadAll(r.Body); err != nil {
		log.Warn(fmt.Sprintf("ioutil.ReadAll: %v", err), err)
		// http.Error(w, "Bad Request", http.StatusBadRequest)
		return
	} else {
		go c.ProcessCollectItemRequest(body)
	}

}

func (c *ClientForChain) ProcessCollectItemRequest(data []byte) {
	var m PubSubMessage
	// byte slice unmarshalling handles base64 decoding.
	if err := json.Unmarshal(data, &m); err != nil {
		log.Warn(fmt.Sprintf("json.Unmarshal: %v", err), err)
		// http.Error(w, "Bad Request", http.StatusBadRequest)
		return
	}
	collectItemRequest := CollectItemRequest{}
	// collectItemRequest.Action = "transfer"
	// collectItemRequest.ItemType = ""
	// collectItemRequest.PlayerID = "M5vq82vcJteMTr8YML1Bebo6qkR2"
	// collectItemRequest.Points = "10"
	log.Info("Processing request: " + string(m.Message.Data))
	if err := json.Unmarshal(m.Message.Data, &collectItemRequest); err != nil {
		log.Warn("error unmarshalling CollectItemRequest. ", err)
	}
	if collectItemRequest.PlayerID == "" {
		log.Info("playerID not found. Not processing")
		return
	}
	// log.Info("Converted message: " + collectItemRequest.ToString())
	// Get User wallet
	wh := &wallet.WalletHandler{}
	wh.UserRepository = "users"
	wh.GCPProject = "kunal-scratch"
	// Creates a wallet if one does exists for the player
	if wallet, err := wh.CreateWallet(collectItemRequest.PlayerID); err != nil {
		log.Warn("error getting user wallet. ", err)
		return
	} else {
		switch collectItemRequest.ItemType {
		case "ItemType.egg":
			c.AwardAnEgg(c.cfg.UserKeys.Owner, common.HexToAddress(wallet.Address))
		case "ItemType.goldenFeather":
			c.AwardFeather(c.cfg.UserKeys.Owner, common.HexToAddress(wallet.Address))
		case "ItemType.acorn": //ignore. we don't mint nft for acorn
		case "": //ignore
		}
		if collectItemRequest.Points != "" {
			points := new(big.Int)
			points, ok := points.SetString(collectItemRequest.Points, 10)
			if !ok {
				log.Warn("error reading points to transfer.", err)
			} else {
				c.TransferZKP(c.cfg.UserKeys.Owner, common.HexToAddress(wallet.Address), points)
			}
		}
	}
}

func (c *ClientForChain) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	c.HandleCollectItemRequest(w, r)
}

func main() {
	cfg := &Config{}
	client := NewClient(cfg)
	srv := &http.Server{
		ReadTimeout:       59 * time.Minute,
		WriteTimeout:      59 * time.Minute,
		IdleTimeout:       59 * time.Minute,
		ReadHeaderTimeout: 59 * time.Minute,
		Handler:           client,
		Addr:              ":" + cfg.CloudRunPort,
	}

	// srv.HandleFunc("/", client.HandleCollectItemRequest)
	// http.HandleFunc(cfg.Pubsub.Transfer2Player.PushEndpoint, HandleTransferItemRequest)
	// Start HTTP server.
	log.Info(fmt.Sprintf("On chain microservice listening on port %s", cfg.CloudRunPort))
	// if err := srv.ListenAndServe(":"+cfg.CloudRunPort, nil); err != nil {
	if err := srv.ListenAndServe(); err != nil {
		log.Fatal(err)
	}
}
