package svc

import (
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/ethereum/go-ethereum/ethclient/gethclient"
	"github.com/finiteloopme/goutils/pkg/log"
)

type Client struct {
	c *gethclient.Client
}

func NewConnection(url string) *Client {
	ethc, err := ethclient.Dial(url)
	if err != nil {
		log.Fatal(err)
	}
	gethc := gethclient.New(ethc.Client())
	return &Client{c: gethc}
}
