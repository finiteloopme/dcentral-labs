package config

import (
	"github.com/finiteloopme/goutils/pkg/log"
	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	EthWebSocketUrl string `envconfig:"ETH_WEB_SOCKET_URL"`
	GcpProject      string `envconfig:"GCP_PROJECT"`
	GcpRegion       string `envconfig:"GCP_REGION"`
}

func (c *Config) Load() {
	prefix := "" // Should be empty
	err := envconfig.Process(prefix, c)
	if err != nil {
		log.Fatal(err)
	}
}
