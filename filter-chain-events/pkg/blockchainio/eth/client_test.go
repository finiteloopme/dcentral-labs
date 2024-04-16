package eth_test

import (
	"testing"

	"github.com/finiteloopme/dcentral-labs/filter-chain-events/pkg/blockchainio/eth"
	"github.com/finiteloopme/dcentral-labs/filter-chain-events/pkg/config"
	"github.com/stretchr/testify/assert"
)

func TestNewConnection(t *testing.T) {
	v := &config.Config{}
	v.Load()
	client := eth.Connect(v.EthWebSocketUrl)
	assert.NotNil(t, client, "Expected a client connection.  Received nil")
}
