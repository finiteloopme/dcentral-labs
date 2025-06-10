package resources_test

import (
	"testing"

	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/resources"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestStockContract_GetAllAssets(t *testing.T) {
	// Given
	rpcURL := "https://governors.testnet.redbelly.network"
	wsURL := "wss://governors.testnet.redbelly.network/ws"
	contractAddress := "0x994B3cDc930993957e0B5fF50f0dA32B264c6364"

	signer := &evm.Signer{}
	chain := evm.NewClient(rpcURL, wsURL, signer)
	require.NotNil(t, chain, "EVM chain client should not be nil")

	assetContract := resources.NewAssetContract(chain, contractAddress, "stock")
	require.NotNil(t, assetContract, "Stock contract should not be nil")
	stockContract := assetContract.(*resources.StockContract)
	require.NotNil(t, stockContract, "Stock contract should not be nil")

	// When
	result, err := stockContract.GetAllStocks()

	// Then
	assert.NoError(t, err, "GetAllAssets should not return an error")
	assert.NotNil(t, result, "GetAllAssets result should not be nil")
	// t.Logf("Assets found: %s", result.Content) // Uncomment for debugging or to inspect the output
}
