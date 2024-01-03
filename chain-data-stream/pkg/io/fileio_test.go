package io_test

import (
	"fmt"
	"testing"

	"github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/config"
	"github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/io"
	"github.com/stretchr/testify/assert"
)

func TestNewFileWriter(t *testing.T) {
	fw := io.NewFileWriter()
	assert.NotNil(t, fw, fmt.Sprintf("Expected a valid file desciptor"))
}

func setupConfig() *config.Config {
	cfg := &config.Config{}
	cfg.Load()
	return cfg
}

func TestInit(t *testing.T) {
	fw := io.NewFileWriter()
	assert.NoError(t, fw.Init(setupConfig()), "Unexpected error")
}
