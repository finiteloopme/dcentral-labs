package config

import (
	"github.com/finiteloopme/goutils/pkg/log"
	"github.com/finiteloopme/goutils/pkg/os/env"
)

type Config struct {
	EthWebSocketUrl  string `yaml:"eth-wss-url" envconfig:"ETH_WEB_SOCKET_URL"`
	BaseWebSocketUrl string `yaml:"base-wss-url" envconfig:"BASE_WEB_SOCKET_URL"`
	GcpProject       string `yaml:"gcp-project" envconfig:"GCP_PROJECT"`
	GcpRegion        string `yaml:"gcp-region" envconfig:"GCP_REGION"`
}

func (c *Config) Load() {
	prefix := "" // Should be empty
	err := env.Process(prefix, c)
	if err != nil {
		log.Fatal(err)
	}
}
