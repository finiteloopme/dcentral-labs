package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"cloud.google.com/go/pubsub"
	"github.com/finiteloopme/goutils/pkg/gcp"
	"github.com/finiteloopme/goutils/pkg/log"
	"github.com/finiteloopme/goutils/pkg/os/env"
	"github.com/gorilla/websocket"
)

type WebSocketHandler struct {
	upgrader     websocket.Upgrader
	pubsubClient *pubsub.Client
}

func GetWebSocketHandler() *WebSocketHandler {
	client, err := pubsub.NewClient(context.Background(), gcp.GetProjectID())
	if err != nil {
		log.Warn("error creating pubsub client. ", err)
	}
	return &WebSocketHandler{
		upgrader: websocket.Upgrader{
			// Allow requests from all sources
			CheckOrigin: func(r *http.Request) bool { return true },
		},
		pubsubClient: client,
	}
}

// Should be same as CollectItemRequest in the orchestrator
type SendToPubsubRequest struct {
	Action        string `json:"action"`
	ItemType      string `json:"itemType"`
	PlayerID      string `json:"playerID"`
	Points        string `json:"points"`
	PlayerAddress string `json:"playerAddress,omitempty"`
}

type Config struct {
	ItemCollectedTopic string `envconfig:"ITEM_COLLECTED_TOPIC" default:"item-collected-topic" yaml:"pubsub.itemCollectedTopic"`
	CloudRunPort       string `envconfig:"PORT" default:"8080"`
}

func GetConfig() *Config {
	cfg := &Config{}
	env.Process("", cfg)
	return cfg
}

func (wsh WebSocketHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	c, err := wsh.upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Warn("error upgrading connection to websocket", err)
		return
	}
	defer func() {
		log.Info("closing connection")
		c.Close()
	}()
	for {
		mt, message, err := c.ReadMessage()
		if err != nil {
			log.Warn("error reading message from client", err)
			return
		}
		if mt == websocket.BinaryMessage {
			// We don't expect a binary message
			err = c.WriteMessage(websocket.TextMessage, []byte("server doesn't support binary messages"))
			if err != nil {
				log.Warn("Error %s when sending message to client", err)
			}
			return
		}
		// Process the message here
		msg := &SendToPubsubRequest{}
		if err := json.Unmarshal(message, msg); err != nil {
			log.Warn("unable to read msg", err)
		} else {
			log.Info(fmt.Sprintf("Received a notification for player: %s", msg.PlayerID))
		}

	}
}

func (wsh WebSocketHandler) SendToPubsub(record SendToPubsubRequest) error {
	data, err := json.Marshal(record)
	cfg := GetConfig()
	ctx := context.Background()
	if err != nil {
		log.Warn("error marshalling json record.", err)
		return err
	}
	msg := &pubsub.Message{
		Data: data,
	}
	msgID, err := wsh.GetOrCreateTopic(cfg.ItemCollectedTopic).Publish(ctx, msg).Get(ctx)
	if msgID != "" {
		log.Debug(fmt.Sprintf("published a msg with id: %v", msgID))
	}
	return err
}

func (wsh WebSocketHandler) GetOrCreateTopic(topicName ...string) *pubsub.Topic {
	cfg := GetConfig()
	if len(topicName) > 0 {
		cfg.ItemCollectedTopic = topicName[0]
	}
	topic := wsh.pubsubClient.Topic(cfg.ItemCollectedTopic)
	if exists, err := topic.Exists(context.Background()); err != nil {
		log.Warn("error checking if topic exists.", err)
		return nil
	} else if !exists {
		// create the topic
		log.Info(fmt.Sprintf("Topic %v doesn't exist.  Creating it", cfg.ItemCollectedTopic))
		if topic, err = wsh.pubsubClient.CreateTopic(context.Background(), cfg.ItemCollectedTopic); err != nil {
			log.Warn("error creating topic.", err)
			return nil
		}
	}
	return topic
}

func (wsh WebSocketHandler) RemoveTopic(topicName ...string) bool {
	cfg := GetConfig()
	if len(topicName) > 0 {
		cfg.ItemCollectedTopic = topicName[0]
	}
	topic := wsh.pubsubClient.Topic(cfg.ItemCollectedTopic)
	if err := topic.Delete(context.Background()); err != nil {
		log.Warn("error deleting topic.", err)
		return false
	}
	return true
}

// func sendToPubsub()
// func (wsh WebSocketHandler) SendToPubsub(msg SendToPubsubRequest) {
// 	cfg := GetConfig()

// }

func main() {
	webSocketHandler := GetWebSocketHandler()
	log.Info("starting server...")
	http.Handle("/", webSocketHandler)
	cfg := GetConfig()
	// Start HTTP server.
	log.Info(fmt.Sprintf("listening on port %s", cfg.CloudRunPort))
	if err := http.ListenAndServe(":"+cfg.CloudRunPort, nil); err != nil {
		log.Fatal(err)
	}

}
