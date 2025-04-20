package config

import (
	"context"

	"github.com/finiteloopme/goutils/pkg/v2/os/env"
)

// Config holds the application configuration parsed from flags.
type Config struct {
	Endpoint string `flag:"endpoint" required:"true"`
	// ContractAddress string `flag:"contract_address" default:"0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"` // USDC contract on Eth
	ContractAddress string `flag:"contract_address" default:"0x29219dd400f2Bf60E5a23d13Be72B486D4038894"` // USDC.e bridged token on Sonic
	ChainType       string `flag:"chain_type" default:"EVM"`
}

// ParseAndValidateArgs parses & validates config:
// 1. Default values
// 2. .env file
// 3. Environment variables
// 4. Google Secret Manager
// 5. CLI flags
// It returns a Config struct or an error.
func ParseAndValidate() (*Config, error) {

	// --- Create Config ---
	config := &Config{}
	// --- Load Config ---
	err := env.ProcessConfig(context.Background(), "", config)

	return config, err
}
