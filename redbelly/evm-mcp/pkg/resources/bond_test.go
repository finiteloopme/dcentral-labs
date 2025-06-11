package resources_test

import (
	"testing"

	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/resources"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestBondContract_GetAllAssets(t *testing.T) {
	// Given
	rpcURL := "https://governors.testnet.redbelly.network"
	wsURL := "wss://governors.testnet.redbelly.network/ws"
	contractAddress := "0x65c0cc0A876b77665B7e9AE00312E52a07f09D43"

	// signer := &evm.Signer{}
	chain := evm.NewClient(rpcURL, wsURL)
	require.NotNil(t, chain, "EVM chain client should not be nil")

	assetContract := resources.NewAssetContract(chain, contractAddress, "bond")
	require.NotNil(t, assetContract, "Bond contract should not be nil")
	bondContract := assetContract.(*resources.BondContract)
	require.NotNil(t, bondContract, "Bond contract should not be nil")

	// When
	result, err := bondContract.GetAllBonds()

	// Then
	assert.NoError(t, err, "GetAllAssets should not return an error")
	assert.NotNil(t, result, "GetAllAssets result should not be nil")
}
