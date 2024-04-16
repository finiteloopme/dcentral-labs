package eth

import (
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/ethereum/go-ethereum/ethclient/gethclient"
	"github.com/finiteloopme/goutils/pkg/log"
)

type EthClient struct {
	// WebsocketURL string
	gethclient *gethclient.Client
	ethclient  *ethclient.Client
}

// Returns *EthClient but doesn't connect to the chain
// Call Connect() explicitly to establish a connection
// func NewClient(url string) EthClient {
// 	return EthClient{
// 		WebsocketURL: url,
// 	}
// }

func Connect(wsURL string) *EthClient {
	if wsURL == "" {
		panic("Valid websocket url must be provided before trying to connect to the chain")
	}
	_ethclient, err := ethclient.Dial(wsURL)
	if err != nil {
		log.Fatal(err)
	}
	return &EthClient{
		ethclient:  _ethclient,
		gethclient: gethclient.New(_ethclient.Client()),
	}

}
