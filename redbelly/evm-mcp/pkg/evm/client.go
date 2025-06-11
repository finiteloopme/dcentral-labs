package evm

import (
	"context"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/finiteloopme/goutils/pkg/log"
	oserr "github.com/finiteloopme/goutils/pkg/v2/os/err"
)

type Chain struct {
	Client   *ethclient.Client
	WsClient *ethclient.Client
	ChainID  *big.Int
	Signer   *Signer
}

func NewClient(rpcEndpoint string, wsEndpoint string, signer *Signer) *Chain {
	_client, err := ethclient.Dial(rpcEndpoint)
	oserr.PanicIfError(fmt.Sprintf("Unable to connect to RPC endpoint: %v", rpcEndpoint), err)
	// _wsClient, err := ethclient.Dial(wsEndpoint)
	// oserr.PanicIfError(fmt.Sprintf("Unable to connect to WS endpoint: %v", wsEndpoint), err)
	chainID, err := _client.ChainID(context.Background())
	oserr.PanicIfError("Unable to fetch chain ID", err)
	log.Infof("Connected to chainID: %v", chainID)
	return &Chain{
		Client: _client,
		// WsClient: _wsClient,
		ChainID: chainID,
		Signer:  signer,
	}
}

func (c *Chain) NewTransaction() *bind.TransactOpts {
	// txnOpts := bind.NewKeyedTransactor(c.Signer.PrivateKey)
	txnOpts, err := bind.NewKeyedTransactorWithChainID(c.Signer.PrivateKey, c.ChainID)
	oserr.PanicIfError("Unable to create transaction", err)
	nonce, err := c.Client.PendingNonceAt(context.Background(), *c.Signer.Address)
	oserr.PanicIfError("Unable to fetch nonce", err)
	gasPrice, err := c.Client.SuggestGasPrice(context.Background())
	oserr.PanicIfError("Unable to fetch gas price", err)
	txnOpts.Nonce = big.NewInt(int64(nonce))
	txnOpts.GasLimit = 300000 // Gas limit for the transaction
	txnOpts.GasPrice = gasPrice
	return txnOpts
}

func (c *Chain) NewTransactionWithValue(valueEth int64) *bind.TransactOpts {
	txnOpts := c.NewTransaction()
	txnOpts.Value = new(big.Int).Mul(big.NewInt(valueEth), big.NewInt(1_000_000_000_000_000_000)) // Convert ETH to Wei

	return txnOpts
}
