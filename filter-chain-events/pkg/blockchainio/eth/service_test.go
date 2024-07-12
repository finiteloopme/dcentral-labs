package eth_test

// import (
// 	"context"
// 	"testing"

// 	"github.com/apache/beam/sdks/v2/go/pkg/beam"
// 	"github.com/apache/beam/sdks/v2/go/pkg/beam/x/beamx"
// 	"github.com/apache/beam/sdks/v2/go/pkg/beam/x/debug"
// 	"github.com/finiteloopme/dcentral-labs/filter-chain-events/pkg/blockchainio/eth"
// 	"github.com/finiteloopme/dcentral-labs/filter-chain-events/pkg/config"
// 	"github.com/finiteloopme/dcentral-labs/filter-chain-events/pkg/filter"
// 	"github.com/stretchr/testify/assert"
// )

// func TestRead(t *testing.T) {
// 	v := &config.Config{}
// 	v.Load()

// 	beam.Init()
// 	p, s := beam.NewPipelineWithRoot()
// 	col := eth.Read(s, v.EthWebSocketUrl, filter.Filter{})
// 	debug.Print(s, col)

// 	err := beamx.Run(context.Background(), p)
// 	assert.Nil(nil, "Unexpected error: "+err.Error())
// }
