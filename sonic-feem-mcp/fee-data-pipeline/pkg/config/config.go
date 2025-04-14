package config

import (
	"flag"
	"fmt"
	"regexp" // Import regexp for topic validation

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

	// Pub/Sub Options
	PubSubTopic string // Target Pub/Sub topic (format: projects/PROJECT_ID/topics/TOPIC_ID)
}

// ParseFlags defines and parses command-line flags, returning a Config struct.
func ParseFlags() *Config {
	cfg := &Config{}

	// GCP Flags
	// flag.StringVar(&cfg.ProjectID, "project", "", "GCP project ID (required)")
	// flag.StringVar(&cfg.Region, "region", "us-central1", "GCP region")
	// flag.StringVar(&cfg.TempLocation, "temp_location", "", "GCS path for temporary files (gs://bucket/temp) (required)")
	// flag.StringVar(&cfg.StagingLocation, "staging_location", "", "GCS path for staging files (gs://bucket/staging) (required)")
	// flag.StringVar(&cfg.WorkerMachineType, "worker_machine_type", "n1-standard-1", "Dataflow worker machine type")
	// flag.IntVar(&cfg.MaxNumWorkers, "max_num_workers", 1, "Maximum number of Dataflow workers")

	// Ethereum Flags
	flag.StringVar(&cfg.WebsocketURL, "websocket_url", "wss://rpc.soniclabs.com", "Sonic Chain WebSocket RPC URL")
	flag.StringVar(&cfg.ContractAddress, "contract_address", "0x0b5f073135df3f5671710f08b08c0c9258aecc35", "Contract address to monitor (required)")
	flag.StringVar(&cfg.ABIFilePath, "abi_file_path", "", "Path to the local contract ABI JSON file (required)")

	// Pub/Sub Flags
	flag.StringVar(&cfg.PubSubTopic, "pubsub_topic", "pubsub_topic", "Target Pub/Sub topic (format: projects/PROJECT_ID/topics/TOPIC_ID) (required)")

	flag.Parse()
	return cfg
}

// Validate checks if required configuration options are set and valid.
func (c *Config) Validate() error {
	var missing []string
	// if c.ProjectID == "" {
	// 	missing = append(missing, "project")
	// }
	// if c.TempLocation == "" {
	// 	missing = append(missing, "temp_location")
	// }
	// if c.StagingLocation == "" {
	// 	missing = append(missing, "staging_location")
	// }
	if c.ContractAddress == "" {
		missing = append(missing, "contract_address")
	}
	if c.ABIFilePath == "" {
		missing = append(missing, "abi-file-path")
	}
	// Check for Pub/Sub topic flag
	if c.PubSubTopic == "" {
		missing = append(missing, "pubsub-topic")
	}

	if len(missing) > 0 {
		return fmt.Errorf("missing required flags: %v", missing)
	}

	// Basic validation for contract address format
	if !common.IsHexAddress(c.ContractAddress) {
		return fmt.Errorf("invalid contract address format: %s", c.ContractAddress)
	}

	// Basic validation for Pub/Sub topic format
	// Regex for projects/PROJECT_ID/topics/TOPIC_ID
	topicRegex := `^projects\/[a-zA-Z0-9][a-zA-Z0-9-_]{5,29}\/topics\/[a-zA-Z][a-zA-Z0-9-_.~+%]{2,254}$`
	match, _ := regexp.MatchString(topicRegex, c.PubSubTopic)
	if !match {
		return fmt.Errorf("invalid pubsub-topic format: '%s'. Expected format: projects/PROJECT_ID/topics/TOPIC_ID", c.PubSubTopic)
	}

	return nil
}
