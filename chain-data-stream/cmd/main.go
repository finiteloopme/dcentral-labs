package main

import (
	"context"
	"time"

	"github.com/ethereum/go-ethereum/core/types"
	"github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/config"
	"github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/io"
	"github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/svc"
	"github.com/finiteloopme/goutils/pkg/log"
)

func main() {
	// Load the config
	v := &config.Config{}
	v.Load()

	// Establish a connection
	log.Debug("Connecting to: " + v.EthWebSocketUrl)
	client := svc.NewConnection(v.EthWebSocketUrl)

	// Subscribe to receive pending transactions
	ch := make(chan *types.Transaction)
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	go client.SubscribeToPendingTxns(ctx, ch)

	// Write to a file
	fw := io.NewFileWriter()
	fw.Init(v)

	// Publish to pubsub
	pubsub := io.NewPubSubWriter()
	pubsub.Init(v)

	// handle the received transactions
	for txn := range ch {
		//msg, _ := txn.MarshalJSON()
		//log.Info(string(msg))
		go fw.Write(txn)
		go pubsub.Write(txn)
	}

}
