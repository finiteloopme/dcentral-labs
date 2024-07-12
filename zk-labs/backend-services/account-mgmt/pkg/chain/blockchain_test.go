package chain_test

import (
	"testing"

	"github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/pkg/chain"
	"github.com/stretchr/testify/assert"
)

func TestGetClient(t *testing.T) {
	chainHandler := &chain.ChainHandler{
		// https://eth-mainnet.public.blastapi.io
		// https://rpc.ankr.com/eth
		RpcEndpoint: "https://eth.llamarpc.com",
		ChainID:     "1",
	}
	client, err := chainHandler.GetClient()
	assert.NoError(t, err, "Unexpected error connecting to the network")
	assert.NotEmpty(t, client, "Expected a valid connection the the network")
}
