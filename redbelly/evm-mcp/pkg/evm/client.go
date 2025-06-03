package evm

import (
	"context"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/ethclient"
	oserr "github.com/finiteloopme/goutils/pkg/v2/os/err"
)

type Chain struct {
	Client  *ethclient.Client
	ChainID *big.Int
	Signer  *Signer
}

func NewClient(rpcEndpoint string, signer *Signer) *Chain {
	_client, err := ethclient.Dial(rpcEndpoint)
	oserr.PanicIfError(fmt.Sprintf("Unable to connect to RPC endpoint: %v", rpcEndpoint), err)
	chainID, err := _client.ChainID(context.Background())
	oserr.PanicIfError("Unable to fetch chain ID", err)
	return &Chain{
		Client:  _client,
		ChainID: chainID,
		Signer:  signer,
	}
}

func (c *Chain) NewTransaction() *bind.TransactOpts {
	txnOpts, err := bind.NewKeyedTransactorWithChainID(c.Signer.PrivateKey, c.ChainID)
	oserr.PanicIfError("Unable to create transaction", err)
	return txnOpts
}
