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

func TestAsset_GetAllAssets(t *testing.T) {
	// Given
	rpcURL := "https://governors.testnet.redbelly.network"
	wsURL := "wss://governors.testnet.redbelly.network/ws"
	cfg := &config.Config{}
	cfg.AlternateContractAddress = "0xbC534Ff297988CDDDD62A50Cb98Ae89670F1111C"
	cfg.BondContractAddress = "0x65c0cc0A876b77665B7e9AE00312E52a07f09D43"
	cfg.PropertyContractAddress = "0x72f045851Bb460D707204F173917c6Fa21D9aDFF"
	cfg.StockContractAddress = "0x994B3cDc930993957e0B5fF50f0dA32B264c6364"

	cfg.RPCEndpoint = rpcURL
	cfg.WebsocketEndpoint = wsURL

	cfg.Signer = &evm.Signer{}

	chain := evm.NewClient(rpcURL, wsURL, cfg.Signer)
	require.NotNil(t, chain, "EVM chain client should not be nil")

	assetAggregator := resources.NewAssetAggretator(chain, cfg)
	require.NotNil(t, assetAggregator, "Asset Aggregator should not be nil")

	// When
	result, err := assetAggregator.GetAllAssets(context.Background(), mcp.CallToolRequest{})

	// Then
	assert.NoError(t, err, "GetAllAssets should not return an error")
	assert.NotNil(t, result, "GetAllAssets result should not be nil")
}
