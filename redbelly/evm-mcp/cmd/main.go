package main

import (
	"context"
	"crypto/ecdsa"
	"flag"
	"fmt"
	"log"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	assetmanager "github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/resources"

	mcp "github.com/metoro-io/mcp-golang"
	"github.com/metoro-io/mcp-golang/transport/stdio"
)

// Config holds the application configuration, populated from CLI arguments
type Config struct {
	RPCEndpoint        string
	PrivateKey         *ecdsa.PrivateKey // Owner's private key
	PublicKey          *ecdsa.PublicKey  // Owner's public key, derived from PrivateKey
	OwnerAddress       common.Address    // Owner's address, derived from PublicKey
	RWAContractAddress string            // RWA_Manager contract address
	// Add other configuration fields here as needed
}

// parseFlags parses the command-line arguments and returns a Config struct.
func parseFlags() (*Config, error) {
	cfg := &Config{}

	// Define flags
	flag.StringVar(&cfg.RPCEndpoint, "rpc-endpoint", "http://127.0.0.1:8545", "The RPC endpoint of the EVM chain")
	privateKeyHex := flag.String("private-key", "", "Owner's private key (hex encoded, e.g., 0x...)")
	flag.StringVar(&cfg.RWAContractAddress, "rwa-contract-address", "0xc6e7DF5E7b4f2A278906862b61205850344D4e7d", "The address of the RWA_Manager smart contract")

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
		pkBytes, err := hexutil.Decode(*privateKeyHex)
		if err != nil {
			return nil, fmt.Errorf("invalid private key hex: %v", err)
		}

		cfg.PrivateKey, err = crypto.ToECDSA(pkBytes)
		if err != nil {
			return nil, fmt.Errorf("failed to parse private key: %v", err)
		}

		publicKey := cfg.PrivateKey.Public()
		cfg.PublicKey, _ = publicKey.(*ecdsa.PublicKey) // Type assertion
		cfg.OwnerAddress = crypto.PubkeyToAddress(*cfg.PublicKey)
	}

	return cfg, nil
}

func main() {
	cfg, err := parseFlags()
	if err != nil {
		log.Fatalf("Error parsing flags: %v", err)
	}
	done := make(chan struct{})
	server := mcp.NewServer(stdio.NewStdioServerTransport())

	client, err := ethclient.Dial(cfg.RPCEndpoint)
	if err != nil {
		log.Fatalf("Failed to connect to the Ethereum client: %v", err)
	}

	// Use a default ABI path or make it configurable as well if needed
	abiPath := "/Users/kunall/scratchpad/dcentral-labs/redbelly/portfolio-manager/abi/RWA_Manager.json"

	// Ensure RWAContractAddress is provided if it's essential for RWAManager initialization
	if cfg.RWAContractAddress == "" {
		log.Fatalf("RWA contract address must be provided via --rwa-contract-address flag")
	}

	rwaManager, err := assetmanager.NewRWAManager(client,
		// cfg.OwnerAddress,
		common.HexToAddress(cfg.RWAContractAddress), // Use the parsed address
		abiPath)
	fmt.Println("Successfully connected to an EVM chain!")
	if cfg.PrivateKey != nil {
		fmt.Printf("Owner Address derived from private key: %s\n", cfg.OwnerAddress.Hex())
	}
	r, err := rwaManager.GetAllAssets(context.Background())
	fmt.Println(r)
	err = server.RegisterTool(
		"list-assets", "Get all the on chain assets available and managed by the asset manager",
		func(sample *HelloArguments) (*mcp.ToolResponse, error) {
			assets, _ := rwaManager.GetAllAssets(context.Background())
			return mcp.NewToolResponse(
				mcp.NewTextContent(fmt.Sprintf("%v", assets)),
			), nil
		})
	if err != nil {
		log.Fatalf("Failed to register tool: %v", err)
	}

	err = server.Serve()
	if err != nil {
		log.Fatalf("Failed to serve: %v", err)
	}
	_ = client
	<-done

	// // Optional: You can perform a simple action to verify, like getting the latest block number
	// header, err := client.HeaderByNumber(context.Background(), nil) // nil for latest block
	// if err != nil {
	// 	log.Fatalf("Failed to get latest block header: %v", err)
	// }
	// fmt.Printf("Latest block number: %s\n", header.Number.String())
}

type HelloArguments struct {
	Submitter string `json:"submitter" jsonschema:"optional,description=The name of the person calling this tool'"`
}
