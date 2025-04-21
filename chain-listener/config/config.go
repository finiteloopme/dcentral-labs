package config

import (
	"flag"
	// "github.com/finiteloopme/goutils/pkg/v2/os/env"
)

// Config holds the application configuration parsed from flags.
type Config struct {
	Endpoint *string `flag:"chain-rpc-endpoint" env:"ENDPOINT" required:"true"`
	// ContractAddress string `flag:"contract_address" default:"0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"` // USDC contract on Eth
	ContractAddress *string `flag:"contract-address" env:"CONTRACT_ADDRESS" default:"0x29219dd400f2Bf60E5a23d13Be72B486D4038894"` // USDC.e bridged token on Sonic
	ChainType       *string `flag:"chain-type" env:"CHAIN_TYPE" default:"EVM"`
}

// ParseAndValidateArgs parses & validates config:
// 1. Default values
// 2. .env file
// 3. Environment variables
// 4. Google Secret Manager
// 5. CLI flags
// It returns a Config struct or an error.
func ParseAndValidate() (*Config, error) {
	// TODO: fix the config/env library
	// // --- Create Config ---
	// config := &Config{}
	// // --- Load Config ---
	// err := env.ProcessConfig(context.Background(), "", config, "../.env")

	// Only works with CLI flags
	config := &Config{}
	config.Endpoint = flag.String("chain-rpc-endpoint", "", "Endpoint to connect to")
	config.ContractAddress = flag.String("contract-address", "0x29219dd400f2Bf60E5a23d13Be72B486D4038894", "Contract address")
	config.ChainType = flag.String("chain-type", "default", "Chain type")
	flag.Parse()
	return config, nil
}
