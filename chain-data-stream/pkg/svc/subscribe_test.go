package svc_test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/core/types"
	"github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/config"
	"github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/svc"
	"github.com/stretchr/testify/assert"
)

func TestSubscribeToPendingTxns(t *testing.T) {
	v := &config.Config{}
	v.Load()
	client := svc.NewConnection(v.EthWebSocketUrl)
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	_, err := client.SubscribeToPendingTxns(ctx, make(chan<- *types.Transaction))
	assert.NoError(t, err, fmt.Sprintf("Encountered unexpected error: %s", err))
}
