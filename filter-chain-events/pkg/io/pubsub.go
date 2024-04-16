package io

import (
	"context"

	"cloud.google.com/go/pubsub"
	"github.com/finiteloopme/goutils/pkg/log"
	"google.golang.org/api/iterator"
)

type PubSubClient struct {
	ctx    context.Context
	client *pubsub.Client
}

func NewPubSub(ctx context.Context, projectID string) (*PubSubClient, error) {
	client, err := pubsub.NewClient(ctx, projectID)
	return &PubSubClient{
		ctx:    ctx,
		client: client,
	}, err
}

func (pubsub *PubSubClient) Create(topicName string) *pubsub.Topic {
	topic := pubsub.GetTopic(topicName)
	if topic == nil {
		_topic, err := pubsub.client.CreateTopic(pubsub.ctx, topicName)
		if err != nil {
			log.Fatal(err)
		}
		topic = _topic
	}

	return topic
}

// Return a topic with the specified name.  Nil if topic doesn't exist
func (pubsub *PubSubClient) GetTopic(topicName string) *pubsub.Topic {
	iter := pubsub.client.Topics(pubsub.ctx)
	topic, err := iter.Next()
	for err != iterator.Done {
		if err == nil {
			exists, err := topic.Exists(pubsub.ctx)
			if exists && err != nil {
				log.Debug("Found topic: " + topic.String())
				return topic
			}
		}
		topic, err = iter.Next()
	}
	return nil
}
