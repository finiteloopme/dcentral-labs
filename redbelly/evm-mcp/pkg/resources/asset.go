package resources

import (
	"context"

	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"
	"github.com/mark3labs/mcp-go/mcp"
)

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
	case "stock":
		stockContract := NewStockContract(chain, contractAddress)
		return AssetContract(stockContract)
	// case "crypto":
	// 	return NewCryptoAsset(chain))
	// case "bond":
	// 	return NewBondAsset(chain)
	// case "property":
	// 	return NewPropertyAsset(chain)
	// case "alternate":
	// 	return NewAlternateAsset(chain)
	default:
		return nil
	}
}
