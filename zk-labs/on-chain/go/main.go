package main

import (
	"context"
	token "contracts/erc20"
	nft "contracts/erc721"
	"crypto/ecdsa"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
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

type Config struct {
	RPC               string    `envconfig:"RPC" required:"true" yaml:"rpc"`
	ContractAddresses Addresses `yaml:"contracts"`
	UserKeys          Keys      `yaml:"users"`
}

type ClientForChain struct {
	client   *ethclient.Client
	cfg      *Config
	zkpToken *token.Erc20
	eggNFT   *nft.Erc721
	feaNFT   *nft.Erc721
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
	if c.client, err = ethclient.Dial(c.cfg.RPC); err != nil {
		log.Warn("error creating client for the chain. ", err)
		log.Fatal(err)
	}

	// Load smart contracts
	if c.zkpToken, err = token.NewErc20(common.HexToAddress(c.cfg.ContractAddresses.ZKPTokenAddress), c.client); err != nil {
		log.Warn("error loading ZKP token contract. ", err)
		log.Fatal(err)
	}

	if c.eggNFT, err = nft.NewErc721(common.HexToAddress(c.cfg.ContractAddresses.EggNFTAddress), c.client); err != nil {
		log.Warn("error loading egg NFT contract. ", err)
		log.Fatal(err)

	}
	if c.feaNFT, err = nft.NewErc721(common.HexToAddress(c.cfg.ContractAddresses.FeaAddress), c.client); err != nil {
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
	bigInt, err := c.client.ChainID(context.Background())
	if err != nil {
		log.Warn("error retrieving chain id", err)
		bigInt = big.NewInt(0)
	}
	return bigInt
}

func (c *ClientForChain) NewTransactor(fromPrivateKey string) *bind.TransactOpts {

	key := GetKeyFromHexPrivateKey(fromPrivateKey)
	nonce, err := c.client.PendingNonceAt(context.Background(), key.Address)
	if err != nil {
		log.Fatal(err)
	}

	gasPrice, err := c.client.SuggestGasPrice(context.Background())
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
	if userBalance, err := c.zkpToken.BalanceOf(&bind.CallOpts{}, common.HexToAddress(hexAddress)); err != nil {
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

func GetChainID(client *ethclient.Client) *big.Int {
	bigInt, err := client.ChainID(context.Background())
	if err != nil {
		log.Warn("error retrieving chain id", err)
		bigInt = big.NewInt(0)
	}
	return bigInt
}

func main() {
	cfg := &Config{}
	client := NewClient(cfg)
	ownerKey := GetKeyFromHexPrivateKey(cfg.UserKeys.Owner)
	user1Key := GetKeyFromHexPrivateKey(cfg.UserKeys.User1)
	log.Info(fmt.Sprintf("Balance of owner is: %v", client.ZKPBalanceOf(ownerKey.Address.Hex())))
	log.Info(fmt.Sprintf("Balance of user1 is: %v", client.ZKPBalanceOf(user1Key.Address.Hex())))
	client.TransferZKP(cfg.UserKeys.Owner, user1Key.Address, big.NewInt(10))
	log.Info(fmt.Sprintf("Balance of owner is: %v", client.ZKPBalanceOf(ownerKey.Address.Hex())))
	log.Info(fmt.Sprintf("Balance of user1 is: %v", client.ZKPBalanceOf(user1Key.Address.Hex())))
}