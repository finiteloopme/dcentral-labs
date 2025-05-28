package evm

import (
	"fmt"

	"github.com/ethereum/go-ethereum/ethclient"
	oserr "github.com/finiteloopme/goutils/pkg/v2/os/err"
)

type Chain struct {
	Client *ethclient.Client
}

func NewClient(rpcEndpoint string) *Chain {
	_client, err := ethclient.Dial(rpcEndpoint)
	oserr.PanicIfError(fmt.Sprintf("Unable to connect to RPC endpoint: %v", rpcEndpoint), err)

	return &Chain{
		Client: _client,
	}

}
