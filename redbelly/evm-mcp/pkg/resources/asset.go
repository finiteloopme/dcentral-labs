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
	chain          *evm.Chain
	assetContracts map[string]AssetContract
}

func NewAssetAggretator(chain *evm.Chain, cfg *config.Config) *AssetAggretator {
	assetContracts := make(map[string]AssetContract)
	stockContract := NewAssetContract(chain, cfg.StockContractAddress, AssetTypeStock.String())
	bondContract := NewAssetContract(chain, cfg.BondContractAddress, AssetTypeBond.String())
	assetContracts[AssetTypeStock.String()] = stockContract
	assetContracts[AssetTypeBond.String()] = bondContract
	return &AssetAggretator{
		chain:          chain,
		assetContracts: assetContracts,
	}
}

type AssetContract interface {
	// RefreshContract(contractAddress string) error
	GetAllAssets(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error)
	// GetAssetsByIds(assetIds []*big.Int) (*mcp.CallToolResult, error)
	GetMyAssets(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error)
	Buy(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error)
	Sell(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error)
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
