package main

import (
	"context"
	"flag"
	"fmt"
	"log"

	"github.com/ethereum/go-ethereum/ethclient"
)

// Config holds the application configuration, populated from CLI arguments
type Config struct {
	RPCEndpoint string
	// Add other configuration fields here as needed
}

// parseFlags parses the command-line arguments and returns a Config struct.
func parseFlags() (*Config, error) {
	cfg := &Config{}

	flag.StringVar(&cfg.RPCEndpoint, "rpc-endpoint", "http://127.0.0.1:8545", "The RPC endpoint of the EVM chain")
	// Example for another potential flag:
	// flag.BoolVar(&cfg.Verbose, "verbose", false, "Enable verbose logging")

	flag.Parse()

	if cfg.RPCEndpoint == "" {
		return nil, fmt.Errorf("RPC endpoint must be provided via --rpc-endpoint flag")
	}
	return cfg, nil
}

func main() {
	cfg, err := parseFlags()
	if err != nil {
		log.Fatal("RPC endpoint must be provided via --rpc-endpoint flag")
	}

	client, err := ethclient.Dial(cfg.RPCEndpoint)
	if err != nil {
		log.Fatalf("Failed to connect to the Ethereum client: %v", err)
	}

	fmt.Println("Successfully connected to an EVM chain!")

	// Optional: You can perform a simple action to verify, like getting the latest block number
	header, err := client.HeaderByNumber(context.Background(), nil) // nil for latest block
	if err != nil {
		log.Fatalf("Failed to get latest block header: %v", err)
	}
	fmt.Printf("Latest block number: %s\n", header.Number.String())
}
