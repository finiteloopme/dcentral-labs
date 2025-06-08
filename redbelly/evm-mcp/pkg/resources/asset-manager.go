package resources

import (
	"context"
	"fmt"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/generated/contract"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"
	"github.com/finiteloopme/goutils/pkg/log"
	"github.com/mark3labs/mcp-go/mcp"
)

// RWAManager provides methods to interact with the RWA_Manager smart contract.
type RWAManager struct {
	chain   *evm.Chain
	caller  *contract.AssetManagerRWACaller // Use the generated caller
	address common.Address
}

// NewRWAManager creates a new instance of RWAManager.
// It requires an EVM chain instance and the contract address.
func NewRWAManager(chain *evm.Chain, contractAddress common.Address) (*RWAManager, error) {
	caller, err := contract.NewAssetManagerRWACaller(contractAddress, chain.Client)
	if err != nil {
		return nil, fmt.Errorf("failed to instantiate AssetManagerRWACaller: %w", err)
	}

	return &RWAManager{
		chain:   chain,
		caller:  caller,
		address: contractAddress,
	}, nil
}

// GetAllAssets calls the getAllAssets function of the RWA_Manager smart contract.
// It now returns a slice of contract.IAssetManagerAsset, which is the generated type.
func (m *RWAManager) GetAllAssets(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	log.Infof("Getting all assets as user: %v", m.chain.Signer.Address.Hex())

	assets, err := m.caller.GetAllAssets(&bind.CallOpts{Context: ctx})
	if err != nil {
		return nil, fmt.Errorf("failed to call GetAllAssets on contract %s: %w", m.address.Hex(), err)
	}
	return mcp.NewToolResultText(fmt.Sprintf("%v", assets)), nil
}

func (m *RWAManager) SetRiskProfile(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	riskProfile, err := request.RequireString("riskProfile")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Risk Profile (low, medium, or high) is required: %v", err.Error())), nil
	}
	// default risk profile: Low
	riskConfig := "{\"stocks\": 20, \"bonds\": 30, \"cash\": 20, \"property\": 30}"
	switch riskProfile {
	case "low":
		log.Debug("Setting risk profile to low")
	case "medium":
		riskConfig = "{\"stocks\": 40, \"bonds\": 20, \"cash\": 20, \"property\": 20}"
		log.Info("Setting risk profile to medium")
	case "high":
		riskConfig = "{\"stocks\": 70, \"bonds\": 10, \"cash\": 10, \"property\": 10}"
		log.Info("Setting risk profile to high")
	default:
		// set the profile to low
		log.Warnf("Invalid risk profile %s, defaulting to low", riskProfile)
	}
	return mcp.NewToolResultText(riskConfig), nil
}
