package config

import (
	"flag"
	"fmt"

	"github.com/ethereum/go-ethereum/common"
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
	BQDataset        string
	BQTable          string
	BQDuplicateTable string
}

// ParseFlags defines and parses command-line flags, returning a Config struct.
func ParseFlags() *Config {
	cfg := &Config{}

	// GCP Flags
	flag.StringVar(&cfg.ProjectID, "gcp_project", "kunal-scratch", "GCP project ID (required)")
	flag.StringVar(&cfg.Region, "gcp_region", "us-central1", "GCP region")
	// flag.StringVar(&cfg.TempLocation, "temp_location", "", "GCS path for temporary files (gs://bucket/temp) (required)")
	// flag.StringVar(&cfg.StagingLocation, "staging_location", "", "GCS path for staging files (gs://bucket/staging) (required)")
	// flag.StringVar(&cfg.WorkerMachineType, "worker_machine_type", "n2-standard-8", "Dataflow worker machine type")
	// flag.IntVar(&cfg.MaxNumWorkers, "max_num_workers", 1, "Maximum number of Dataflow workers")

	// Ethereum Flags
	flag.StringVar(&cfg.WebsocketURL, "websocket_url", "wss://rpc.soniclabs.com", "Sonic Chain WebSocket RPC URL")
	flag.StringVar(&cfg.ContractAddress, "contract_address", "0x0b5f073135df3f5671710f08b08c0c9258aecc35", "Contract address to monitor (required)")
	// *** IMPORTANT: Provide a default or require this flag if an explorer API exists ***
	flag.StringVar(&cfg.ABIFilePath, "abi_file_path", "https://explorer.soniclabs.com/api", "Base URL of the Sonic Chain block explorer API for ABI fetching (required if not providing ABI manually)") // Placeholder URL

	// BigQuery Flags
	flag.StringVar(&cfg.BQDataset, "bq_dataset", "kunal-scratch.sonic-feem", "BigQuery dataset ID (required)")
	flag.StringVar(&cfg.BQTable, "bq_table", "feem-events", "BigQuery main table ID (required)")
	flag.StringVar(&cfg.BQDuplicateTable, "bq_duplicate_table", "feem-events-duplicates", "BigQuery duplicate events table ID (required)")

	flag.Parse()
	return cfg
}

// Validate checks if required configuration options are set.
func (c *Config) Validate() error {
	var missing []string
	if c.ProjectID == "" {
		missing = append(missing, "gcp_project")
	}
	// if c.TempLocation == "" {
	// 	missing = append(missing, "temp_location")
	// }
	// if c.StagingLocation == "" {
	// 	missing = append(missing, "staging_location")
	// }
	if c.ContractAddress == "" {
		missing = append(missing, "contract_address")
	}
	// Check for the new ABI file path flag
	if c.ABIFilePath == "" {
		missing = append(missing, "abi_file_path")
	}
	if c.BQDataset == "" {
		missing = append(missing, "bq_dataset")
	}
	if c.BQTable == "" {
		missing = append(missing, "bq_table")
	}
	if c.BQDuplicateTable == "" {
		missing = append(missing, "bq_duplicate_table")
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
