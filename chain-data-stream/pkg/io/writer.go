package io

import (
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/config"
)

type TxnWriter interface {
	Init(*config.Config) error
	Write(*types.Transaction) (*types.Transaction, error)
	Close() error
}
