package io

import (
	"fmt"
	"os"

	"github.com/ethereum/go-ethereum/core/types"
	"github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/config"
	"github.com/finiteloopme/goutils/pkg/log"
)

type FileWriter struct {
	file *os.File
}

func NewFileWriter() TxnWriter {
	return &FileWriter{}
}

func (fw *FileWriter) Init(cfg *config.Config) error {
	file, err := os.OpenFile(cfg.FilePath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Info("Error opening file: " + err.Error())
		return err
	} else {
		log.Info("Writing to file: " + file.Name())
		fw.file = file
	}
	return nil
}

func (fw *FileWriter) Write(txn *types.Transaction) (*types.Transaction, error) {
	line, err := txn.MarshalJSON()
	if err != nil {
		log.Info("Error marshalling txn: " + txn.Hash().Hex())
		return nil, err
	}
	_, err = fmt.Fprintln(fw.file, string(line))
	if err != nil {
		log.Info("Error writing to the file: " + err.Error())
		return nil, err
	}
	// else
	return txn, nil
}

func (fw *FileWriter) Close() error {
	return fw.file.Close()
}
