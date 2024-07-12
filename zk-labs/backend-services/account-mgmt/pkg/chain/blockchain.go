package chain

import (
	// "context"
	// "crypto/ecdsa"
	// "fmt"
	// "math/big"

	// "github.com/ethereum/go-ethereum"
	// "github.com/ethereum/go-ethereum/common"
	// "github.com/ethereum/go-ethereum/common/hexutil"
	// "github.com/ethereum/go-ethereum/core/types"
	// "github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/finiteloopme/goutils/pkg/log"
	// "golang.org/x/crypto/sha3"
)

type ChainHandler struct {
	RpcEndpoint string
	ChainID     string
}

func (ch *ChainHandler) GetClient() (*ethclient.Client, error) {
	client, err := ethclient.Dial(ch.RpcEndpoint)
	if err != nil {
		log.Warn("error connecting to the network. ", err)
		return nil, err
	}
	return client, err
}
