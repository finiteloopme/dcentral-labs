package svc

import (
	"context"

	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/rpc"
)

func (client *Client) SubscribeToPendingTxns(ctx context.Context, ch chan<- *types.Transaction) (*rpc.ClientSubscription, error) {
	return client.c.SubscribeFullPendingTransactions(ctx, ch)
}
