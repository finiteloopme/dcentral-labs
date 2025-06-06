package resources

import (
	"math/big"
	"testing"

	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	testRPCURL        = "http://127.0.0.1:8545"
	testWsURL         = "ws://127.0.0.1:8545"
	testPrivateKey    = "4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356"
	testStockContract = "0x663F3ad617193148711d28f5334eE4Ed07016602"
)

func setupStockAsset(t *testing.T) *StockAsset {
	t.Helper()
	signer := evm.NewSigner(testPrivateKey)
	chain := evm.NewClient(testRPCURL, testWsURL, signer)

	stockAsset := NewStockAsset(chain)

	return stockAsset
}

func TestStockAsset_Buy(t *testing.T) {
	// Skip this test if running in short mode or if the test environment is not set up.
	// This test interacts with a live blockchain node.
	if testing.Short() {
		t.Skip("Skipping live blockchain test in short mode.")
	}

	stockAsset := setupStockAsset(t)

	// Define test parameters
	assetIdToBuy := big.NewInt(1) // Assuming asset ID 1 exists
	tokenAmount := int64(3)       // Amount of tokens (e.g., Wei or the smallest unit of the token)

	t.Run("SuccessfulBuy", func(t *testing.T) {
		tx, err := stockAsset.Buy(assetIdToBuy, tokenAmount)

		require.NoError(t, err, "Buy method returned an error")
		require.NotNil(t, tx, "Transaction should not be nil")

		// Optional: Wait for the transaction to be mined and check receipt
		// This makes it more of an integration test.
		// For a pure unit test, you might mock the transactor.
		t.Logf("Buy transaction sent: %s", tx.Hash().Hex())

		// Example: Check if the transaction was successful (requires waiting for mining)
		// receipt, err := bind.WaitMined(context.Background(), stockAsset.chain.Client, tx)
		// require.NoError(t, err, "Failed to wait for transaction to be mined")
		// assert.Equal(t, types.ReceiptStatusSuccessful, receipt.Status, "Transaction was not successful")

		assert.True(t, tx.Value().Cmp(big.NewInt(tokenAmount*1000000000000000000)) == 0, "Transaction value does not match token amount")
	})
}
