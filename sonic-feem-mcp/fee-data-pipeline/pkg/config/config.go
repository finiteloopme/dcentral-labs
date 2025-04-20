package config

import (
	"flag"
	"fmt"

	// Import regexp for topic validation
	"github.com/ethereum/go-ethereum/common" // Import common for validation
)

// Config holds all the pipeline configuration parameters.
type Config struct {
	// GCP Options
	ProjectID         string
	Region            string
	TempLocation      string
	StagingLocation   string
	WorkerMachineType string
	MaxNumWorkers     int

	// Ethereum Options
	WebsocketURL    string
	ContractAddress string
	ABIFilePath     string // Path to the local JSON ABI file

	// BigQuery Options
	SrcBQProject string
	SrcBQDataset string
	SrcBQTable   string

	DstBQProject string
	DstBQDataset string
	DstBQTable   string

	// Block configuration
	StartFromBlock int64
}

// ParseFlags defines and parses command-line flags, returning a Config struct.
func ParseFlags() *Config {
	cfg := &Config{}

	// Ethereum Flags
	flag.StringVar(&cfg.WebsocketURL, "websocket_url", "wss://rpc.soniclabs.com", "Sonic Chain WebSocket RPC URL")
	flag.StringVar(&cfg.ContractAddress, "contract_address", "0x0b5f073135df3f5671710f08b08c0c9258aecc35", "Contract address to monitor (required)")
	flag.StringVar(&cfg.ABIFilePath, "abi_file_path", "", "Path to the local contract ABI JSON file (required)")

	// BQ Flags
	flag.StringVar(&cfg.SrcBQProject, "src_bq_project", "kunal-scratch", "ID of the source project (required)")
	flag.StringVar(&cfg.SrcBQDataset, "src_bq_dataset", "sonic_mainnet", "ID of the source dataset (required)")
	flag.StringVar(&cfg.SrcBQTable, "src_bq_table", "logs", "Name of the source table (required)")

	flag.StringVar(&cfg.DstBQProject, "dst_bq_project", "kunal-scratch", "ID of the destination project (required)")
	flag.StringVar(&cfg.DstBQDataset, "dst_bq_dataset", "sonic_feem", "ID of the destination dataset (required)")
	flag.StringVar(&cfg.DstBQTable, "dst_bq_table", "feem_events", "Name of the destination table (required)")

	flag.Int64Var(&cfg.StartFromBlock, "start_from_block", 0, "Block number to start from (optional)")

	flag.Parse()
	return cfg
}

// Validate checks if required configuration options are set and valid.
func (c *Config) Validate() error {
	var missing []string
	if c.ContractAddress == "" {
		missing = append(missing, "contract_address")
	}
	if c.ContractAddress == "" {
		missing = append(missing, "contract_address")
	}
	if c.ABIFilePath == "" {
		missing = append(missing, "abi_file_path")
	}
	// Check for BQ topic flag
	if c.SrcBQProject == "" {
		missing = append(missing, "src_bq_project")
	}
	if c.SrcBQDataset == "" {
		missing = append(missing, "src_bq_dataset")
	}
	if c.SrcBQTable == "" {
		missing = append(missing, "src_bq_table")
	}
	if c.DstBQProject == "" {
		missing = append(missing, "dst_bq_project")
	}
	if c.DstBQDataset == "" {
		missing = append(missing, "dst_bq_dataset")
	}
	if c.DstBQTable == "" {
		missing = append(missing, "dst_bq_table")
	}

	if len(missing) > 0 {
		return fmt.Errorf("missing required flags: %v", missing)
	}

	// Basic validation for contract address format
	if !common.IsHexAddress(c.ContractAddress) {
		return fmt.Errorf("invalid contract address format: %s", c.ContractAddress)
	}

	return nil
}
