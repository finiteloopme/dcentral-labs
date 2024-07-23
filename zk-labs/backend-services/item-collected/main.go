package main

import (
	"fmt"
	"net/http"

	"github.com/finiteloopme/goutils/pkg/log"
	"github.com/finiteloopme/goutils/pkg/os/env"
	"github.com/gorilla/websocket"
)

type webSocketHandler struct {
	upgrader websocket.Upgrader
}

type SendToPubsubRequest struct {
	Action   string `json:"action"`
	ItemType string `json:"itemType"`
	PlayerID string `json:"playerID"`
	Points   string `json:"points"`
}

type Config struct {
	ItemCollectedTopic string `envconfig:"ITEM_COLLECTED_TOPIC" default:"item-collected-topic" yaml:"pubsub.itemCollectedTopic"`
	CloudRunPort       string `envconfig:"PORT" deffault:"8080"`
}

func GetConfig() *Config {
	cfg := &Config{}
	env.Process("", cfg)
	return cfg
}

func (wsh webSocketHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
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
		log.Info(fmt.Sprintf("Receive message %s", string(message)))
	}
	// w.WriteHeader(http.StatusOK)
	// w.Write([]byte(fmt.Sprintf("Hello from the server.  Will be writing to topic: %v", GetConfig().ItemCollectedTopic)))
}

func main() {
	webSocketHandler := webSocketHandler{
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool { return true },
		},
	}
	log.Info("starting server...")
	http.Handle("/", webSocketHandler)
	cfg := GetConfig()
	// Start HTTP server.
	log.Info(fmt.Sprintf("listening on port %s", cfg.CloudRunPort))
	if err := http.ListenAndServe(":"+cfg.CloudRunPort, nil); err != nil {
		log.Fatal(err)
	}

}
