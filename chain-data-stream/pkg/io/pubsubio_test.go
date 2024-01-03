package io_test

import (
	"fmt"
	"testing"

	"github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/io"
	"github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/types"
	"github.com/stretchr/testify/assert"
)

func TestPubSubWriter(t *testing.T) {
	pubsub := io.NewPubSubWriter()
	assert.NotNil(t, pubsub, fmt.Sprintf("Expected a valid Pubsub writer"))
}

func setupPubSubConfig() *types.Config {
	cfg := &types.Config{}
	cfg.Load()
	return cfg
}

func TestPubSubInit(t *testing.T) {
	fw := io.NewFileWriter()
	assert.NoError(t, fw.Init(setupConfig()), "Unexpected error")
}
