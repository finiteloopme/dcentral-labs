package config

import (
	"flag"
	"fmt"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"
	oserr "github.com/finiteloopme/goutils/pkg/v2/os/err"
)

// Config holds the application configuration, populated from CLI arguments
type Config struct {
	RPCEndpoint       string
	WebsocketEndpoint string
	Signer            *evm.Signer

	RWAContractAddress       string // RWA_Manager contract address
	StockContractAddress     string
	BondContractAddress      string
	PropertyContractAddress  string
	AlternateContractAddress string

	// Add other configuration fields here as needed
}

// parseFlags parses the command-line arguments and returns a Config struct.
func ParseFlags() (*Config, error) {
	cfg := &Config{}

	// Define flags
	// flag.StringVar(&cfg.RPCEndpoint, "rpc-endpoint", "http://127.0.0.1:8545", "The RPC endpoint of the EVM chain")
	// flag.StringVar(&cfg.WebsocketEndpoint, "ws-endpoint", "ws://127.0.0.1:8545", "The Websocket endpoint of the EVM chain")
	// flag.StringVar(&cfg.RWAContractAddress, "rwa-contract-address", "0xc6e7DF5E7b4f2A278906862b61205850344D4e7d", "The address of the RWA_Manager smart contract")
	flag.StringVar(&cfg.RPCEndpoint, "rpc-endpoint", "https://governors.mainnet.redbelly.network", "The RPC endpoint of the EVM chain")
	flag.StringVar(&cfg.WebsocketEndpoint, "ws-endpoint", "wss://governors.mainnet.redbelly.network", "The Websocket endpoint of the EVM chain")
	flag.StringVar(&cfg.RWAContractAddress, "rwa-contract-address", "0xc6e7DF5E7b4f2A278906862b61205850344D4e7d", "The address of the Real World Asset Manager smart contract")
	flag.StringVar(&cfg.StockContractAddress, "stock-contract-address", "0x994B3cDc930993957e0B5fF50f0dA32B264c6364", "The address of the Real World Asset Manager smart contract")
	flag.StringVar(&cfg.BondContractAddress, "bond-contract-address", "0x65c0cc0A876b77665B7e9AE00312E52a07f09D43", "The address of the Real World Asset Manager smart contract")
	flag.StringVar(&cfg.PropertyContractAddress, "property-contract-address", "0x72f045851Bb460D707204F173917c6Fa21D9aDFF", "The address of the Real World Asset Manager smart contract")
	flag.StringVar(&cfg.AlternateContractAddress, "alternate-contract-address", "0xbC534Ff297988CDDDD62A50Cb98Ae89670F1111C", "The address of the Real World Asset Manager smart contract")
	privateKeyHex := flag.String("private-key", "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", "Owner's private key (hex encoded, remove 0x prefix if present)")

	// Example for another potential flag:
	// flag.BoolVar(&cfg.Verbose, "verbose", false, "Enable verbose logging")

	flag.Parse()

	// Validate required flags
	if cfg.RPCEndpoint == "" {
		return nil, fmt.Errorf("RPC endpoint must be provided via --rpc-endpoint flag")
	}

	// Validate RWAContractAddress if provided (optional, but good practice)
	if cfg.RWAContractAddress != "" && !common.IsHexAddress(cfg.RWAContractAddress) {
		return nil, fmt.Errorf("invalid RWA contract address: %s", cfg.RWAContractAddress)
	}

	// Process private key if provided
	if *privateKeyHex != "" {
		cfg.Signer = evm.NewSigner(*privateKeyHex)
	} else {
		// generate a new signer
		privateKey, err := crypto.GenerateKey()
		oserr.PanicIfError("Error generating a signer key", err)
		cfg.Signer = evm.PrivateKeyToSigner(privateKey)
	}

	return cfg, nil
}
