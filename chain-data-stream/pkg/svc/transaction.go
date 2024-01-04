package svc

import (
	"context"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
)

// Given a transaction hash, returns the transaction, is it pending & error
func (client *Client) Transaction(hash string) (*types.Transaction, bool, error) {
	return client.ethclient.TransactionByHash(context.Background(), common.HexToHash(hash))
}
