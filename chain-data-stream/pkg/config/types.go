package config

import (
	"github.com/finiteloopme/goutils/pkg/log"
	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	EthWebSocketUrl string `envconfig:"ETH_WEB_SOCKET_URL"`
	BqDataSet       string `envconfig:"BQ_DATA_SET"`
	PubSubTopic     string `envconfig:"PUB_SUB_TOPIC"`
}

func (c *Config) Load() {
	prefix := "" // Should be empty
	err := envconfig.Process(prefix, c)
	if err != nil {
		log.Fatal(err)
	}
}
