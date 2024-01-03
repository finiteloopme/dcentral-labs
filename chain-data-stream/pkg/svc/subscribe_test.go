package svc_test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/core/types"
	"github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/svc"
	cfgt "github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/types"
	"github.com/stretchr/testify/assert"
)

func TestSubscribeToPendingTxns(t *testing.T) {
	v := &cfgt.Config{}
	v.Load()
	client := svc.NewConnection(v.EthWebSocketUrl)
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	_, err := client.SubscribeToPendingTxns(ctx, make(chan<- *types.Transaction))
	assert.NoError(t, err, fmt.Sprintf("Encountered unexpected error: %s", err))
}
