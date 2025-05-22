package assetmanager

import (
	"context"
	"fmt"
	"os" // Used for os.ReadFile
	"strings"

	"github.com/ethereum/go-ethereum" // For ethereum.CallMsg
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

// Asset mirrors the RWA_Manager.Asset struct in Solidity.
// The field names must be exported (start with an uppercase letter)
// and should correspond to the Solidity struct field names for automatic unmarshalling.
type Asset struct {
	ContractAddress common.Address
	Category        string
}

// RWAManager provides methods to interact with the RWA_Manager smart contract.
type RWAManager struct {
	client   *ethclient.Client
	contract abi.ABI // Changed to store the parsed ABI directly
	address  common.Address
}

// NewRWAManager creates a new instance of RWAManager.
// It requires an Ethereum client, the contract address, and the path to the ABI JSON file.
func NewRWAManager(client *ethclient.Client, contractAddress common.Address, abiPath string) (*RWAManager, error) {
	abiBytes, err := os.ReadFile(abiPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read ABI file from %s: %w", abiPath, err)
	}

	parsedABI, err := abi.JSON(strings.NewReader(string(abiBytes)))
	if err != nil {
		return nil, fmt.Errorf("failed to parse ABI: %w", err)
	}

	return &RWAManager{
		client:   client,
		contract: parsedABI,
		address:  contractAddress,
	}, nil
}

// GetAllAssets calls the getAllAssets function of the RWA_Manager smart contract.
func (m *RWAManager) GetAllAssets(ctx context.Context) ([]Asset, error) {
	// 1. Pack the call data for the "getAllAssets" method (it has no arguments)
	callData, err := m.contract.Pack("getAllAssets")
	if err != nil {
		return nil, fmt.Errorf("failed to pack getAllAssets call data: %w", err)
	}

	// 2. Make the contract call
	msg := ethereum.CallMsg{
		To:   &m.address,
		Data: callData,
	}
	outputBytes, err := m.client.CallContract(ctx, msg, nil) // nil for blockNumber means latest
	if err != nil {
		return nil, fmt.Errorf("failed to call getAllAssets on contract %s: %w", m.address.Hex(), err)
	}

	// 3. Unpack the results into our Go struct slice
	var assets []Asset
	err = m.contract.UnpackIntoInterface(&assets, "getAllAssets", outputBytes)
	if err != nil {
		return nil, fmt.Errorf("failed to unpack getAllAssets output: %w", err)
	}

	return assets, nil
}
