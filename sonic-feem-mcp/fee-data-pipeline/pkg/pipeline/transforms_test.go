package pipeline

import (
	"context"
	"math/big"
	"strings"
	"testing"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/finiteloopme/dcentral-dev/sonic-feem-mcp/fee-data-pipeline/pkg/bigquery"
	"github.com/finiteloopme/dcentral-dev/sonic-feem-mcp/fee-data-pipeline/pkg/chain"
)

func TestDecodeLogFn(t *testing.T) {
	// Create a test log entry
	logEntry := types.Log{
		Address: common.HexToAddress("0x1234567890abcdef"),
		Topics: []common.Hash{
			common.HexToHash("0x1234567890abcdef"),
		},
		Data: []byte("0x1234567890abcdef"),
	}

	// Create a test ABI
	abiJSON := `[
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "projectId",
					"type": "uint256"
				}
			],
			"name": "ProjectCreated",
			"type": "event"
		}
	]`

	parsedABI, err := abi.JSON(strings.NewReader(abiJSON))
	if err != nil {
		t.Fatal(err)
	}

	// Create a decodeLogFn instance
	fn := &decodeLogFn{
		AbiJSON:   abiJSON,
		parsedABI: &parsedABI,
	}

	// Create a test context
	ctx := context.Background()

	// Create a test output
	var output chain.DecodedEvent

	// Process the log entry
	err = fn.ProcessElement(ctx, logEntry, func(event chain.DecodedEvent) {
		output = event
	})
	if err != nil {
		t.Fatal(err)
	}

	// Verify the output
	if output.EventName != "ProjectCreated" {
		t.Errorf("expected event name 'ProjectCreated', got '%s'", output.EventName)
	}
}

func TestConvertToBQRecordFn(t *testing.T) {
	// Create a test decoded event
	event := chain.DecodedEvent{
		Amount:      big.NewInt(100),
		ProjectId:   big.NewInt(1),
		EpochNumber: big.NewInt(2),
		Funder:      &common.Address{0x1},
		Recipient:   &common.Address{0x2},
		Version:     big.NewInt(3),
	}

	// Create a convertToBQRecordFn instance
	fn := &convertToBQRecordFn{}

	// Create a test context
	ctx := context.Background()

	// Create a test output
	var output bigquery.BQEventRecord

	// Process the event
	fn.ProcessElement(ctx, event, func(record bigquery.BQEventRecord) {
		output = record
	})

	// Verify the output
	if output.Amount != "100" {
		t.Errorf("expected amount '100', got '%s'", output.Amount)
	}
	if output.ProjectId != "1" {
		t.Errorf("expected project ID '1', got '%s'", output.ProjectId)
	}
	if output.EpochNumber != "2" {
		t.Errorf("expected epoch number '2', got '%s'", output.EpochNumber)
	}
	if output.Funder != "0x0000000000000000000000000000000000000001" {
		t.Errorf("expected funder '0x1', got '%s'", output.Funder)
	}
	if output.Recipient != "0x0000000000000000000000000000000000000002" {
		t.Errorf("expected recipient '0x2', got '%s'", output.Recipient)
	}
	if output.Version != "3" {
		t.Errorf("expected version '3', got '%s'", output.Version)
	}
}

func TestConvertToBQDuplicateRecordFn(t *testing.T) {
	// Create a test decoded event
	event := chain.DecodedEvent{
		Amount:      big.NewInt(100),
		ProjectId:   big.NewInt(1),
		EpochNumber: big.NewInt(2),
		Funder:      &common.Address{0x1},
		Recipient:   &common.Address{0x2},
		Version:     big.NewInt(3),
	}

	// Create a convertToBQDuplicateRecordFn instance
	fn := &convertToBQDuplicateRecordFn{}

	// Create a test context
	ctx := context.Background()

	// Create a test output
	var output bigquery.BQDuplicateRecord

	// Process the event
	fn.ProcessElement(ctx, event, func(record bigquery.BQDuplicateRecord) {
		output = record
	})

	// Verify the output
	if output.BQEventRecord.Amount != "100" {
		t.Errorf("expected amount '100', got '%s'", output.BQEventRecord.Amount)
	}
	if output.BQEventRecord.ProjectId != "1" {
		t.Errorf("expected project ID '1', got '%s'", output.BQEventRecord.ProjectId)
	}
	if output.BQEventRecord.EpochNumber != "2" {
		t.Errorf("expected epoch number '2', got '%s'", output.BQEventRecord.EpochNumber)
	}
	if output.BQEventRecord.Funder != "0x0000000000000000000000000000000000000001" {
		t.Errorf("expected funder '0x1', got '%s'", output.BQEventRecord.Funder)
	}
	if output.BQEventRecord.Recipient != "0x0000000000000000000000000000000000000002" {
		t.Errorf("expected recipient '0x2', got '%s'", output.BQEventRecord.Recipient)
	}
	if output.BQEventRecord.Version != "3" {
		t.Errorf("expected version '3', got '%s'", output.BQEventRecord.Version)
	}
	if output.DuplicateDetectionTime.IsZero() {
		t.Errorf("expected non-zero duplicate detection time")
	}
}

func TestDecodeLogFn_ProcessElement_Error(t *testing.T) {
	// Create a test log entry
	logEntry := types.Log{
		Address: common.HexToAddress("0x1234567890abcdef"),
		Topics: []common.Hash{
			common.HexToHash("0x1234567890abcdef"),
		},
		Data: []byte("0x1234567890abcdef"),
	}

	// Create a test ABI
	abiJSON := `[
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "projectId",
					"type": "uint256"
				}
			],
			"name": "ProjectCreated",
			"type": "event"
		}
	]`

	parsedABI, err := abi.JSON(strings.NewReader(abiJSON))
	if err != nil {
		t.Fatal(err)
	}

	// Create a decodeLogFn instance
	fn := &decodeLogFn{
		AbiJSON:   abiJSON,
		parsedABI: &parsedABI,
	}

	// Create a test context
	ctx := context.Background()

	// Process the log entry with an error
	err = fn.ProcessElement(ctx, logEntry, func(event chain.DecodedEvent) {})
	if err != nil {
		t.Fatal(err)
	}

	// Verify the error
	if err.Error() != "ABI not initialized" {
		t.Errorf("expected error 'ABI not initialized', got '%s'", err)
	}
}

func TestConvertToBQRecordFn_ProcessElement_Error(t *testing.T) {
	// Create a test decoded event
	event := chain.DecodedEvent{
		Amount:      big.NewInt(100),
		ProjectId:   big.NewInt(1),
		EpochNumber: big.NewInt(2),
		Funder:      &common.Address{0x1},
		Recipient:   &common.Address{0x2},
		Version:     big.NewInt(3),
	}

	// Create a convertToBQRecordFn instance
	fn := &convertToBQRecordFn{}

	// Create a test context
	ctx := context.Background()

	// Process the event with an error
	fn.ProcessElement(ctx, event, func(record bigquery.BQEventRecord) {})
}
