package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/gorilla/websocket"
	"github.com/stretchr/testify/assert"
)

func setupTest(t *testing.T, handler http.Handler) (*httptest.Server, *websocket.Conn, func()) {
	t.Helper()
	server := httptest.NewServer(handler)
	wsURL := ""
	if strings.HasPrefix(server.URL, "https") {
		wsURL = strings.Replace(server.URL, "https", "wss", 1)
	} else if strings.HasPrefix(server.URL, "http") {
		wsURL = strings.Replace(server.URL, "http", "ws", 1)
	} else {
		t.Fatal("Unable to create web socket URL")
	}
	ws, _, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if err != nil {
		t.Fatal(err)
	}
	return server, ws, func() {
		ws.Close()
		server.Close()
	}
}

func TestWebsocketInfra(t *testing.T) {
	// conn := "localhost:8080"
	srv, ws, cancel := setupTest(t, GetWebSocketHandler())
	defer cancel()
	assert.NotNil(t, srv, "Unexpected server instance as nil")
	assert.NotNil(t, ws, "Unexpected ws instance as nil")
}

func TestValidRequest(t *testing.T) {
	// conn := "localhost:8080"
	_, ws, cancel := setupTest(t, GetWebSocketHandler())
	defer cancel()
	testMsg := &SendToPubsubRequest{}
	testMsg.Action = "transfer"
	testMsg.ItemType = "egg"
	testMsg.PlayerID = "kl"
	testMsg.Points = "10"
	data, err := json.Marshal(testMsg)
	if err != nil {
		t.Fatal(err)
	}
	err = ws.WriteMessage(websocket.TextMessage, data)
	assert.Nil(t, err, "Unexpected error writing to the websocket. %v", err)
}

func TestPubsubInfra(t *testing.T) {
	os.Setenv("GCP_PROJECT", "kunal-scratch")
	wsh := GetWebSocketHandler()
	topic := wsh.GetOrCreateTopic("test-dash-pubsub")
	assert.NotNil(t, topic, "Expected a valid topic")
	check := wsh.RemoveTopic(topic.ID())
	assert.Equal(t, true, check, "Expected the topic to deleted")
}

func TestPublishMsg(t *testing.T) {
	os.Setenv("GCP_PROJECT", "kunal-scratch")
	testMsg := SendToPubsubRequest{}
	testMsg.Action = "transfer"
	testMsg.ItemType = "egg"
	testMsg.PlayerID = "kl"
	testMsg.Points = "10"
	wsh := GetWebSocketHandler()
	err := wsh.SendToPubsub(testMsg)
	assert.Nil(t, err, "Unexpected error", err)
	cfg := GetConfig()
	check := wsh.RemoveTopic(cfg.ItemCollectedTopic)
	assert.Equal(t, true, check, "Expected the topic to deleted")

}
