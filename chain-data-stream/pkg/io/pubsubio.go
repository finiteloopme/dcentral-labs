package io

import (
	"context"

	"cloud.google.com/go/pubsub"
	"github.com/ethereum/go-ethereum/core/types"
	t "github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/types"
	"github.com/finiteloopme/goutils/pkg/log"
)

type PubSubWriter struct {
	topic *pubsub.Topic
}

func NewPubSubWriter() TxnWriter {
	return &PubSubWriter{}
}

func (writer *PubSubWriter) Init(cfg *t.Config) error {
	ctx := context.Background()
	client, err := pubsub.NewClient(ctx, cfg.GcpProject)
	if err != nil {
		log.Info("Error creating PubSub client: " + err.Error())
		return err
	} else {
		topic := client.Topic(cfg.PubSubTopic)
		if topic == nil {
			topic, err = client.CreateTopic(ctx, cfg.PubSubTopic)
			if err != nil {
				log.Info("Error creating topic: " + err.Error())
				return err
			}
		} else {
			log.Info("Topic already exists.")
		}
		writer.topic = topic
		log.Info("Publishing to topic: " + writer.topic.ID())
	}
	return nil
}

func (writer *PubSubWriter) Write(txn *types.Transaction) (*types.Transaction, error) {
	line, err := txn.MarshalJSON()
	if err != nil {
		log.Info("Error marshalling txn: " + txn.Hash().Hex())
		return nil, err
	}
	writer.topic.Publish(context.Background(), &pubsub.Message{
		Data: line,
	})
	if err != nil {
		log.Info("Error publishing to the topic: " + err.Error())
		return nil, err
	}
	// else
	return txn, nil
}

func (writer *PubSubWriter) Close() error {
	writer.topic.Stop()
	return nil
}
