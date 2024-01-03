package svc_test

import (
	"testing"

	"github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/config"
	"github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/svc"
	"github.com/stretchr/testify/assert"
)

func TestNewConnection(t *testing.T) {
	v := &config.Config{}
	v.Load()
	client := svc.NewConnection(v.EthWebSocketUrl)
	assert.NotNil(t, client, "Expected a client connection.  Received nil")
}
