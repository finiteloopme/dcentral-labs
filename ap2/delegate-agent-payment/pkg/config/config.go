// Package config provides functionality for managing application configuration.
package config

import (
	"github.com/spf13/viper"
)

// Config holds all the configuration parameters for the application.
// It is populated from a configuration file (e.g., config.toml) and/or environment variables.
// The `mapstructure` tags are used by Viper to map the config keys to the struct fields.
type Config struct {
	// RPCUrl is the URL of the Ethereum JSON-RPC endpoint.
	RPCUrl string `mapstructure:"rpcURL"`
	// ChainID is the ID of the Ethereum chain (e.g., 31337 for a local anvil node).
	ChainID int64 `mapstructure:"chainID"`
	// ContractsFile is the file path where deployed contract addresses are stored.
	ContractsFile string `mapstructure:"contractsFile"`
	// TaskFile is the file path where the user's signed intent mandate is stored.
	TaskFile string `mapstructure:"taskFile"`
	// MerchantAddress is the Ethereum address of the merchant to be paid.
	MerchantAddress string `mapstructure:"merchantAddress"`
	// MerchantServerURL is the URL for the new merchant server.
	MerchantServerURL string `mapstructure:"merchantServerURL"`
	// UserPrivateKey is the private key of the user account.
	UserPrivateKey string `mapstructure:"USER_PRIVATE_KEY"`
	// AgentPrivateKey is the private key of the agent/facilitator account.
	AgentPrivateKey string `mapstructure:"AGENT_PRIVATE_KEY"`
}

// LoadConfig reads configuration from a file and environment variables.
// It uses the Viper library to handle configuration loading and unmarshaling.
func LoadConfig() (config Config, err error) {
	// Set the path for the configuration file to the current directory.
	viper.AddConfigPath(".")
	// Set the name of the configuration file (without extension).
	viper.SetConfigName("config")
	// Set the type of the configuration file.
	viper.SetConfigType("toml")

	// Enable Viper to read environment variables automatically.
	// This allows overriding config file values with environment variables.
	viper.AutomaticEnv()

	// Attempt to read the configuration file.
	err = viper.ReadInConfig()
	if err != nil {
		return
	}

	// Unmarshal the loaded configuration into the Config struct.
	err = viper.Unmarshal(&config)
	return
}
