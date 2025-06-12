package resources

import (
	"context"
	"fmt"

	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/config"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"
	"github.com/finiteloopme/goutils/pkg/log"
	"github.com/mark3labs/mcp-go/mcp"
)

type AssetType int

const (
	AssetTypeStock AssetType = iota
	AssetTypeBond
	AssetTypeProperty
	AssetTypeAlternate
)

func (s AssetType) String() string {
	switch s {
	case AssetTypeStock:
		return "stock"
	case AssetTypeBond:
		return "bond"
	case AssetTypeProperty:
		return "property"
	case AssetTypeAlternate:
		return "alternate"
	default:
		return "unknown"
	}
}

type AssetAggretator struct {
	chain *evm.Chain
	// signer         *evm.Signer
	cfg            *config.Config
	assetContracts map[string]AssetContract
}

func NewAssetAggretator(chain *evm.Chain, cfg *config.Config) *AssetAggretator {
	assetAgg := &AssetAggretator{
		chain: chain,
		cfg:   cfg,
	}
	assetAgg.RefreshAssetContracts()
	return assetAgg
}

func (a *AssetAggretator) RefreshAssetContracts() {
	assetContracts := make(map[string]AssetContract)
	stockContract := NewAssetContract(a.chain, a.cfg.StockContractAddress, AssetTypeStock.String())
	bondContract := NewAssetContract(a.chain, a.cfg.BondContractAddress, AssetTypeBond.String())
	assetContracts[AssetTypeStock.String()] = stockContract
	assetContracts[AssetTypeBond.String()] = bondContract
	a.assetContracts = assetContracts
}

type AssetContract interface {
	// RefreshContract(contractAddress string) error
	GetAllAssets(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error)
	// GetAssetsByIds(assetIds []*big.Int) (*mcp.CallToolResult, error)
	GetMyAssets(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error)
	Buy(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error)
	Sell(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error)
	SubscribeToPurchase(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error)
}

func NewAssetContract(chain *evm.Chain, contractAddress string, assetType string) AssetContract {
	switch assetType {
	case AssetTypeStock.String():
		stockContract := NewStockContract(chain, contractAddress)
		return AssetContract(stockContract)
	case AssetTypeBond.String():
		bondContract := NewBondContract(chain, contractAddress)
		return AssetContract(bondContract)
	// case "property":
	// 	return NewPropertyAsset(chain)
	// case "alternate":
	// 	return NewAlternateAsset(chain)
	default:
		return nil
	}
}

func (a *AssetAggretator) GetAllAssets(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {

	log.Infof("Getting all assets with req: %v", request)
	result := mcp.NewToolResultText("")
	for contractType, contract := range a.assetContracts {
		log.Infof("Getting all %s assets", contractType)
		assets, err := contract.GetAllAssets(ctx, request)
		if err != nil {
			e := fmt.Errorf("failed to get all the %s assets: %w", contractType, err)
			log.Warn("%v", e)
			er := mcp.NewToolResultText(e.Error())
			result.Content = append(result.Content, er.Content...)
		} else {
			result.Content = append(result.Content, assets.Content...)
		}
		log.Infof("Got all %s assets: %v", contractType, assets)
	}
	return result, nil
}

func (a *AssetAggretator) Buy(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	_, err := request.RequireString("signer")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Private key for the user is required: %v", err.Error())), nil
	}
	assetType, err := request.RequireString("assetType")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Asset type is required: %v", err.Error())), nil
	}
	assetContract := a.assetContracts[assetType]
	if assetContract == nil {
		return mcp.NewToolResultText(fmt.Sprintf("Invalid asset type: %s", assetType)), nil
	}
	return assetContract.Buy(ctx, request)
}

func (a *AssetAggretator) Sell(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	_, err := request.RequireString("signer")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Private key for the user is required: %v", err.Error())), nil
	}
	assetType, err := request.RequireString("assetType")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Asset type is required: %v", err.Error())), nil
	}
	assetContract := a.assetContracts[assetType]
	if assetContract == nil {
		return mcp.NewToolResultText(fmt.Sprintf("Invalid asset type: %s", assetType)), nil
	}
	return assetContract.Sell(ctx, request)
}

func (a *AssetAggretator) GetMyAssets(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	_, err := request.RequireString("signer")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Private key for the user has not been set: %v", err.Error())), nil
	}
	// log.Infof("Getting all assets for user: %v", signer)
	result := mcp.NewToolResultText("")
	for contractType, contract := range a.assetContracts {
		log.Infof("Getting all %s assets", contractType)
		assets, err := contract.GetMyAssets(ctx, request)
		if err != nil {
			e := fmt.Errorf("failed to get personal assets of type: %s: %w", contractType, err)
			log.Warn("%v", e)
			result.Content = append(result.Content, mcp.NewToolResultText(e.Error()).Content...)
		} else {
			result.Content = append(result.Content, assets.Content...)
		}
	}
	return result, nil
}

func (a *AssetAggretator) RegisterUser(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	userName, err := request.RequireString("userName")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("User name is required: %v", err.Error())), nil
	}
	_ = userName
	_, err = request.RequireString("signer")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Private key for the user is required: %v", err.Error())), nil
	}
	// log.Infof("Setting the signer to: %v", signer)
	// a.cfg.Signer = evm.NewSigner(signer)
	// a.signer = evm.NewSigner(signer)
	// log.Infof("With chain pub address: %v", a.signer.Address.Hex())
	// log.Infof("With cfg pub address: %v", a.cfg.Signer.Address.Hex())
	// a.RefreshAssetContracts()
	riskProfile, err := request.RequireString("riskProfile")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Risk Profile (low, medium, or high) is required: %v", err.Error())), nil
	}
	return mcp.NewToolResultText(fmt.Sprintf("User %s, has been set to have an investment risk profile of %s", userName, riskProfile)), nil
}

func (a *AssetAggretator) SetRiskProfile(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	riskProfile, err := request.RequireString("riskProfile")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Risk Profile (low, medium, or high) is required: %v", err.Error())), nil
	}
	// default risk profile: Low
	riskConfig := "{\"stocks\": 10, \"bonds\": 40, \"alternate\": 10, \"property\": 40}"
	switch riskProfile {
	case "low":
		log.Debug("Setting risk profile to low")
	case "medium":
		riskConfig = "{\"stocks\": 40, \"bonds\": 20, \"alternate\": 20, \"property\": 20}"
		log.Info("Setting risk profile to medium")
	case "high":
		riskConfig = "{\"stocks\": 30, \"bonds\": 10, \"alternate\": 50, \"property\": 10}"
		log.Info("Setting risk profile to high")
	default:
		// set the profile to low
		log.Warnf("Invalid risk profile %s, defaulting to low", riskProfile)
	}
	return mcp.NewToolResultText(riskConfig), nil
}

func (a *AssetAggretator) SubscribeToPurchase(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	_, err := request.RequireString("signer")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Private key for the user is required: %v", err.Error())), nil
	}
	assetType, err := request.RequireString("assetType")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Asset type is required: %v", err.Error())), nil
	}
	assetContract := a.assetContracts[assetType]
	if assetContract == nil {
		return mcp.NewToolResultText(fmt.Sprintf("Invalid asset type: %s", assetType)), nil
	}
	return assetContract.SubscribeToPurchase(ctx, request)
}
