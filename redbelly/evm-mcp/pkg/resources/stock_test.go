package resources_test

import (
	"math/big"
	"testing"

	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/resources"
	"github.com/mark3labs/mcp-go/mcp"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// setupStockContract initializes and returns a StockContract instance for testing.
func setupStockContract(t *testing.T) *resources.StockContract {
	t.Helper()

	rpcURL := "https://governors.testnet.redbelly.network"
	wsURL := "wss://governors.testnet.redbelly.network/ws"
	contractAddress := "0x994B3cDc930993957e0B5fF50f0dA32B264c6364"

	// IMPORTANT: For transactional tests like Buy, a signer with a private key and funds is required.
	// The current signer is a placeholder and will not work for actual transactions.
	// To run transactional tests successfully, replace with a valid signer:
	// privateKey := "YOUR_PRIVATE_KEY_HERE" // Ensure this account has funds on the testnet
	// signer, err := evm.NewSignerFromPrivateKey(privateKey, rpcURL) // Assuming such a constructor or similar
	// require.NoError(t, err, "Failed to create signer from private key")
	// require.NotNil(t, signer)
	signer := evm.NewSigner("dbd2324b3528247c6a7b15ef04244cdbdbae8d3593426edf4720091e52423a54")

	chain := evm.NewClient(rpcURL, wsURL, signer)
	require.NotNil(t, chain, "EVM chain client should not be nil")

	// Assuming NewAssetContract returns an AssetManager interface,
	// and for "stock", it's specifically a *resources.StockContract.
	assetManager := resources.NewAssetContract(chain, contractAddress, "stock")
	require.NotNil(t, assetManager, "Asset manager should not be nil")

	stockContract, ok := assetManager.(*resources.StockContract)
	require.True(t, ok, "Asset manager should be of type *resources.StockContract")
	require.NotNil(t, stockContract, "Stock contract should not be nil")

	return stockContract
}

func TestStockContractOperations(t *testing.T) {
	// Setup is done once for all sub-tests
	stockContract := setupStockContract(t)

	t.Run("GetAllStocks", func(t *testing.T) {
		// When
		result, err := stockContract.GetAllStocks()

		// Then
		assert.NoError(t, err, "GetAllStocks should not return an error")
		assert.NotNil(t, result, "GetAllStocks result should not be nil")
		// Example of a more specific assertion if 'result' is expected to be a slice:
		// if err == nil {
		//  // This assertion depends on the actual return type and expected state.
		//  // assert.GreaterOrEqual(t, len(result), 0, "GetAllStocks should return a list of stocks")
		// }
	})

	t.Run("BuyStock", func(t *testing.T) {
		// Given
		assetID := "4" // A valid assetID might be obtainable from GetAllStocks
		quantity := big.NewInt(10)

		// When
		// This call is expected to fail or not complete successfully due to the placeholder signer.

		// request := mcp.CallToolRequest{
		// 	Params: mcp.CallToolParams{
		// 		Name: "assetId",
		// 		Arguments: map[string]any{
		// 			"assetId":     assetID,
		// 			"tokenAmount": quantity,
		// 		},
		// 	},
		// }
		var req mcp.CallToolRequest
		req.Params.Name = "buy-stock"
		req.Params.Arguments = map[string]any{
			"assetId":     assetID,
			"tokenAmount": quantity.String(),
		}

		tx, err := stockContract.Buy(
			t.Context(),
			req,
		)
		assert.NoError(t, err, "Buy operation should not return an error")
		assert.NotNil(t, tx, "Transaction object should not be nil")

		// Then
		// With a placeholder signer, an error is expected when trying to send a transaction.
		// assert.Error(t, err, "Buy operation should return an error due to placeholder signer or network issue")
		// assert.Nil(t, tx, "Transaction object should be nil when Buy operation fails")
		// Note: For a successful test, `setupStockContract` needs a funded signer.
	})
}
