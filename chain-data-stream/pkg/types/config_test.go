package types_test

import (
	"fmt"
	"os"
	"testing"

	"github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/types"
	"github.com/stretchr/testify/assert"
)

func TestLoad(t *testing.T) {
	const testValue = "testing123"
	os.Setenv("ETH_WEB_SOCKET_URL", testValue)
	v := &types.Config{}
	v.Load()
	assert.EqualValues(t, testValue, v.EthWebSocketUrl, fmt.Sprintf("Expected %s, received %s", testValue, v.EthWebSocketUrl))
}
