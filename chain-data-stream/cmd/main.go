package main

import (
	"github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/config"
	"github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/svc"
	"github.com/finiteloopme/goutils/pkg/log"
)

func main() {
	log.Info("In main")
	v := &config.Config{}
	v.Load()
	log.Info("Connecting to: " + v.EthWebSocketUrl)
	svc.NewConnection(v.EthWebSocketUrl)
	log.Info("Existing")

}
