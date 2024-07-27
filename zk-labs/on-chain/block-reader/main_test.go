package main

import (
	"testing"
)

func TestFetchProof(t *testing.T) {
	cfg := &Config{}
	blockNumber := &BlockReaderReqest{
		BlockNumber: "16575",
	}
	client := NewReader(cfg)
	client.PrintZKProof(*blockNumber)
}
