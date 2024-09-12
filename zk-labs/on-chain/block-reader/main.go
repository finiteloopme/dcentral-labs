package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/finiteloopme/goutils/pkg/log"
	"github.com/finiteloopme/goutils/pkg/os/env"
	// "github.com/gorilla/websocket"
)

type PubsubConfig struct {
	BlockReader string `yaml:"block-reader"`
}

type Config struct {
	RPC          string       `envconfig:"RPC" required:"true" yaml:"rpc"`
	Pubsub       PubsubConfig `yaml:"pubsub-config"`
	CloudRunPort string       `envconfig:"PORT" default:"8080" yaml:"cloud-run-port"`
}

type BlockReader struct {
	cfg *Config //Config for this micro service
	// upgrader websocket.Upgrader
}

func NewReader(_cfg *Config) *BlockReader {
	b := &BlockReader{
		// upgrader: websocket.Upgrader{
		// 	// Allow requests from all sources
		// 	CheckOrigin: func(r *http.Request) bool { return true },
		// },
	}
	b.cfg = _cfg
	if err := env.Process("", b.cfg); err != nil {
		log.Warn("error reading configfuration. ", err)
		// log.Fatal(err)
	}

	return b
}

func (c *BlockReader) HandleRequest(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "GET":
		c.HandleGet(w, r)
	case "POST":
		c.HandlePost(w, r)
	}
}

// https://cloud.google.com/pubsub/docs/reference/rest/v1/PubsubMessage
type PubSubMessage struct {
	Message struct {
		Data []byte `json:"data,omitempty"`
		ID   string `json:"id"`
	} `json:"message"`
	Subscription string `json:"subscription"`
}

type BlockReaderReqest struct {
	BlockNumber string `json:"blockNumber"`
}

func (b *BlockReader) HandlePost(w http.ResponseWriter, r *http.Request) {
	var m PubSubMessage
	var block BlockReaderReqest
	data, err := io.ReadAll(r.Body)
	if err != nil {
		log.Warn(fmt.Sprintf("ioutil.ReadAll: %v", err), err)
		return
	}
	// byte slice unmarshalling handles base64 decoding.
	if err := json.Unmarshal(data, &m); err != nil {
		log.Warn(fmt.Sprintf("json.Unmarshal pubsub: %v", err), err)
		return
	}
	if err := json.Unmarshal(m.Message.Data, &block); err != nil {
		log.Warn(fmt.Sprintf("json.Unmarshal block reader: %v", err), err)
		return
	}
	go b.PrintZKProof(block)
}

func (blockReader *BlockReader) PrintZKProof(block BlockReaderReqest) {
	startCount := 1
	maxCount := 20
	sleepSec := 5

	for {
		// backoff wait
		if startCount < maxCount {
			time.Sleep(time.Duration(startCount * sleepSec * int(time.Second)))
			startCount++
			resp, err := http.Get(blockReader.cfg.RPC + "/" + block.BlockNumber)
			if resp.StatusCode != http.StatusOK || err != nil {
				log.Warn(fmt.Sprintf("error reading block proof. status: %v", resp.Status), err)
				return
			}
			if body, err := io.ReadAll(resp.Body); err == nil {
				message := string(body)
				if !strings.Contains(message, "Error: block does not exist") {
					log.Info(fmt.Sprintf("Proof for the block [%v] is here: %v", block.BlockNumber, blockReader.cfg.RPC+"/"+block.BlockNumber))
					return
				}
			} else {
				log.Warn("error reading response from the Jerigon RPC. ", err)
				return
			}
		} else {
			log.Warn("stopping exponential backoff to get proof for block: "+block.BlockNumber, errors.New("timeout: fetching proof"))
			return
		}
	}

}

func (b *BlockReader) HandleGet(w http.ResponseWriter, r *http.Request) {
	err := fmt.Errorf("unimplemented %v", "function")
	log.Warn("GET not implemented.", err)
}

func (c *BlockReader) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	c.HandleRequest(w, r)
}

func main() {
	cfg := &Config{}
	client := NewReader(cfg)
	srv := &http.Server{
		ReadTimeout:       59 * time.Minute,
		WriteTimeout:      59 * time.Minute,
		IdleTimeout:       59 * time.Minute,
		ReadHeaderTimeout: 59 * time.Minute,
		Handler:           client,
		Addr:              ":" + cfg.CloudRunPort,
	}

	// Start HTTP server.
	log.Info(fmt.Sprintf("On chain microservice listening on port %s", cfg.CloudRunPort))
	// if err := srv.ListenAndServe(":"+cfg.CloudRunPort, nil); err != nil {
	if err := srv.ListenAndServe(); err != nil {
		log.Fatal(err)
	}
}
