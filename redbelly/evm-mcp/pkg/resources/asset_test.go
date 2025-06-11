package resources_test

import (
	"context"
	"testing"

	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/config"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/resources"
	"github.com/mark3labs/mcp-go/mcp"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func setupAssetAggregatorTest(t *testing.T) (*resources.AssetAggretator, *config.Config) {
	rpcURL := "https://governors.testnet.redbelly.network" // Consider making this configurable or using a mock for unit tests
	wsURL := "wss://governors.testnet.redbelly.network/ws"
	cfg := &config.Config{}
	cfg.AlternateContractAddress = "0xbC534Ff297988CDDDD62A50Cb98Ae89670F1111C"
	cfg.BondContractAddress = "0x65c0cc0A876b77665B7e9AE00312E52a07f09D43"
	cfg.PropertyContractAddress = "0x72f045851Bb460D707204F173917c6Fa21D9aDFF"
	cfg.StockContractAddress = "0x994B3cDc930993957e0B5fF50f0dA32B264c6364"

	cfg.RPCEndpoint = rpcURL
	cfg.WebsocketEndpoint = wsURL

	// cfg.Signer = &evm.Signer{}

	chain := evm.NewClient(rpcURL, wsURL)
	require.NotNil(t, chain, "EVM chain client should not be nil")

	assetAggregator := resources.NewAssetAggretator(chain, cfg)
	require.NotNil(t, assetAggregator, "Asset Aggregator should not be nil")
	return assetAggregator, cfg
}

func TestAsset_GetAllAssets(t *testing.T) {
	// Given
	assetAggregator, _ := setupAssetAggregatorTest(t)

	// When
	result, err := assetAggregator.GetAllAssets(context.Background(), mcp.CallToolRequest{})

	// Then
	assert.NoError(t, err, "GetAllAssets should not return an error")
	assert.NotNil(t, result, "GetAllAssets result should not be nil")
}

func TestAsset_RegisterUser(t *testing.T) {
	// Given
	assetAggregator, _ := setupAssetAggregatorTest(t)

	// When
	// Assuming RegisterUser takes a CallToolRequest, adjust if necessary
	// For a real test, you might need to populate CallToolRequest with user details
	var req mcp.CallToolRequest
	req.Params.Name = "buy-stock"
	req.Params.Arguments = map[string]any{
		"userName":    "Testing123",
		"signer":      "dbd2324b3528247c6a7b15ef04244cdbdbae8d3593426edf4720091e52423a54",
		"riskProfile": "Low",
	}
	result, err := assetAggregator.RegisterUser(t.Context(), req)

	// Then
	assert.NoError(t, err, "RegisterUser should not return an error")
	assert.NotNil(t, result, "RegisterUser result should not be nil")

	r2, err := assetAggregator.GetMyAssets(t.Context(), mcp.CallToolRequest{})
	assert.NoError(t, err, "RegisterUser should not return an error")
	assert.NotNil(t, r2, "RegisterUser result should not be nil")
}

func TestAsset_GetMyAssets(t *testing.T) {
	// Given
	assetAggregator, _ := setupAssetAggregatorTest(t)

	// When
	// Assuming GetMyAssets takes a CallToolRequest, adjust if necessary
	// For a real test, CallToolRequest might need to identify the user
	result, err := assetAggregator.GetMyAssets(context.Background(), mcp.CallToolRequest{})
	// Then
	assert.NoError(t, err, "GetMyAssets should not return an error")
	assert.NotNil(t, result, "GetMyAssets result should not be nil")
}
