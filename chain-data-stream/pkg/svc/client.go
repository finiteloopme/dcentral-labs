package svc

import (
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/ethereum/go-ethereum/ethclient/gethclient"
	"github.com/finiteloopme/goutils/pkg/log"
)

type Client struct {
	gethclient *gethclient.Client
	ethclient  *ethclient.Client
}

func NewConnection(url string) *Client {
	_ethclient, err := ethclient.Dial(url)
	if err != nil {
		log.Fatal(err)
	}
	_gethclient := gethclient.New(_ethclient.Client())

	return &Client{
		ethclient:  _ethclient,
		gethclient: _gethclient,
	}

}
