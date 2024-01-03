package io

import (
	"github.com/ethereum/go-ethereum/core/types"
	t "github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/types"
)

type TxnWriter interface {
	Init(*t.Config) error
	Write(*types.Transaction) (*types.Transaction, error)
	Close() error
}
